import 'package:http/http.dart' as http;
import 'auth_repository.dart';

/// An HTTP client wrapper that automatically attaches authorization tokens,
/// proactively refreshes expired access tokens, and handles 401 Unauthorized
/// responses by refreshing the token and retrying the request.
class AuthenticatedHttpClient extends http.BaseClient {
  final AuthRepository authRepository;
  final http.Client _inner;

  AuthenticatedHttpClient({
    required this.authRepository,
    http.Client? innerClient,
  }) : _inner = innerClient ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. Proactively get a valid access token (refreshes if expired)
    final token = await authRepository.getValidAccessToken() ??
        await authRepository.getSavedToken();
    final refreshToken = await authRepository.getSavedRefreshToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      final existingCookie = request.headers['Cookie'];
      final alreadyHasAccessToken = existingCookie != null &&
          existingCookie.split(';').any((part) => part.trim().startsWith('accessToken='));
      if (!alreadyHasAccessToken) {
        final parts = <String>[];
        if (existingCookie != null && existingCookie.isNotEmpty) {
          parts.add(existingCookie);
        }
        parts.add('accessToken=$token');
        if (refreshToken != null &&
            refreshToken.isNotEmpty &&
            (existingCookie == null || !existingCookie.contains('refreshToken='))) {
          parts.add('refreshToken=$refreshToken');
        }
        request.headers['Cookie'] = parts.join('; ');
      }
    }

    // 2. Clone request for potential retry on 401 if it's a standard Request
    http.Request? originalRequestCopy;
    if (request is http.Request) {
      originalRequestCopy = _copyRequest(request);
    }

    // 3. Send request
    final response = await _inner.send(request);

    // 4. If 401 Unauthorized, attempt refresh and retry
    if (response.statusCode == 401 && originalRequestCopy != null) {
      try {
        final refreshResult = await authRepository.refreshToken();
        final newToken = refreshResult.accessToken;
        if (newToken != null && newToken.isNotEmpty) {
          final retryRequest = _copyRequest(
            originalRequestCopy,
            token: newToken,
            refreshToken: refreshResult.refreshToken ?? refreshToken,
          );
          return await _inner.send(retryRequest);
        }
      } catch (_) {
        // Return original 401 response if refresh fails
      }
    }

    return response;
  }

  http.Request _copyRequest(http.Request original, {String? token, String? refreshToken}) {
    final copy = http.Request(original.method, original.url);
    copy.headers.addAll(original.headers);
    if (token != null) {
      copy.headers['Authorization'] = 'Bearer $token';
      copy.headers['Cookie'] = _cookieWithAccessToken(
        copy.headers['Cookie'],
        accessToken: token,
        refreshToken: refreshToken,
      );
    }
    copy.encoding = original.encoding;
    copy.bodyBytes = original.bodyBytes;
    copy.followRedirects = original.followRedirects;
    copy.maxRedirects = original.maxRedirects;
    return copy;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

String _cookieWithAccessToken(
  String? existing, {
  required String accessToken,
  String? refreshToken,
}) {
  final parts = <String>[];
  if (existing != null) {
    for (final raw in existing.split(';')) {
      final part = raw.trim();
      if (part.isEmpty ||
          part.startsWith('accessToken=') ||
          part.startsWith('token=') ||
          part.startsWith('refreshToken=')) {
        continue;
      }
      parts.add(part);
    }
  }
  parts.add('accessToken=$accessToken');
  if (refreshToken != null && refreshToken.isNotEmpty) {
    parts.add('refreshToken=$refreshToken');
  }
  return parts.join('; ');
}
