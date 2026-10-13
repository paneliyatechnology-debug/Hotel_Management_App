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
    final token = await authRepository.getValidAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
      final existingCookie = request.headers['Cookie'];
      final tokenCookie = 'token=$token';
      request.headers['Cookie'] = existingCookie != null && existingCookie.isNotEmpty
          ? '$existingCookie; $tokenCookie'
          : tokenCookie;
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
          final retryRequest = _copyRequest(originalRequestCopy, token: newToken);
          return await _inner.send(retryRequest);
        }
      } catch (_) {
        // Return original 401 response if refresh fails
      }
    }

    return response;
  }

  http.Request _copyRequest(http.Request original, {String? token}) {
    final copy = http.Request(original.method, original.url);
    copy.headers.addAll(original.headers);
    if (token != null) {
      copy.headers['Authorization'] = 'Bearer $token';
      final existingCookie = copy.headers['Cookie'];
      final tokenCookie = 'token=$token';
      copy.headers['Cookie'] = existingCookie != null && existingCookie.isNotEmpty
          ? '$existingCookie; $tokenCookie'
          : tokenCookie;
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
