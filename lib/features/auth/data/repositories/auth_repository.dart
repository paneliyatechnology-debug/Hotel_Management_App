import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/auth_user_model.dart';
import '../models/login_response_model.dart';
import '../models/refresh_token_response_model.dart';

class AuthRepository {
  static const String baseUrl = ApiConstants.loginUrl;
  static const String refreshUrl = ApiConstants.refreshTokenUrl;
  static const String forgotPasswordUrl = ApiConstants.forgotPasswordUrl;
  static const String meUrl = ApiConstants.meUrl;

  static const String _tokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userDataKey = 'auth_user_data';
  static const String _loginResponseKey = 'auth_login_response';
  static const String _rememberStationKey = 'auth_remember_station';

  final http.Client _client;
  Future<RefreshTokenResponseModel>? _ongoingRefresh;

  AuthRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Executes login API request
  Future<LoginResponseModel> login({
    required String email,
    required String password,
    bool rememberStation = true,
  }) async {
    try {
      final url = Uri.parse(baseUrl);
      final body = jsonEncode({
        'email': email.trim(),
        'password': password,
      });

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      Map<String, dynamic> jsonResponse = {};
      try {
        jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      final extractedMessage = (jsonResponse['message'] ??
              jsonResponse['error'] ??
              jsonResponse['msg'] ??
              jsonResponse['detail'])
          ?.toString();

      final loginResponse = LoginResponseModel.fromJson(jsonResponse);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          loginResponse.success) {
        // After login, save login response in SharedPreferences
        await _saveSession(loginResponse);
        return loginResponse;
      } else {
        final errorMsg = (extractedMessage != null && extractedMessage.isNotEmpty)
            ? extractedMessage
            : (loginResponse.message.isNotEmpty
                ? loginResponse.message
                : 'Login failed (Status: ${response.statusCode}). Please check your credentials.');
        throw Exception(errorMsg);
      }
    } on FormatException {
      throw Exception('Invalid response received from hotel server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connection error: $e');
    }
  }

  /// Executes forgot-password API request
  Future<String> forgotPassword({required String email}) async {
    try {
      final url = Uri.parse(forgotPasswordUrl);
      final body = jsonEncode({
        'email': email.trim(),
      });

      final token = await getSavedToken();
      final refreshToken = await getSavedRefreshToken();

      final headers = ApiConstants.defaultHeaders(
        token: token,
        refreshToken: refreshToken,
      );

      final response = await _client.post(
        url,
        headers: headers,
        body: body,
      );

      final Map<String, dynamic> jsonResponse =
          jsonDecode(response.body) as Map<String, dynamic>;

      final success = jsonResponse['success'] as bool? ?? false;
      final message = jsonResponse['message'] as String? ?? '';

      if (response.statusCode >= 200 && response.statusCode < 300 && success) {
        return message.isNotEmpty
            ? message
            : 'A password reset link has been sent to your email. Please check your inbox or spam folder.';
      } else {
        throw Exception(message.isNotEmpty
            ? message
            : 'Failed to send password reset link. Please check the email.');
      }
    } on FormatException {
      throw Exception('Invalid response received from hotel server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connection error: $e');
    }
  }

  /// Calls POST /api/v1/auth/refresh-token and saves the new tokens.
  /// Concurrent callers share one in-flight refresh.
  Future<RefreshTokenResponseModel> refreshToken({String? providedRefreshToken}) {
    if (providedRefreshToken == null && _ongoingRefresh != null) {
      return _ongoingRefresh!;
    }
    late final Future<RefreshTokenResponseModel> tracked;
    tracked = _performRefresh(providedRefreshToken).whenComplete(() {
      if (identical(_ongoingRefresh, tracked)) _ongoingRefresh = null;
    });
    if (providedRefreshToken == null) _ongoingRefresh = tracked;
    return tracked;
  }

  Future<RefreshTokenResponseModel> _performRefresh(String? providedRefreshToken) async {
    try {
      final tokenToUse = providedRefreshToken ?? await getSavedRefreshToken();
      if (tokenToUse == null || tokenToUse.isEmpty) {
        throw Exception('No refresh token available. Please sign in again.');
      }

      final currentAccessToken = await getSavedToken();

      final url = Uri.parse(refreshUrl);
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final cookieParts = <String>[];
      if (currentAccessToken != null && currentAccessToken.isNotEmpty) {
        cookieParts.add('accessToken=$currentAccessToken');
      }
      cookieParts.add('refreshToken=$tokenToUse');
      headers['Cookie'] = cookieParts.join('; ');

      final body = jsonEncode({
        'refresh_token': tokenToUse,
      });

      final response = await _client.post(
        url,
        headers: headers,
        body: body,
      );

      final Map<String, dynamic> jsonResponse =
          jsonDecode(response.body) as Map<String, dynamic>;

      final refreshResponse = RefreshTokenResponseModel.fromJson(jsonResponse);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          refreshResponse.success) {
        // Store new tokens in SharedPreferences
        await _saveRefreshedTokens(refreshResponse);
        return refreshResponse;
      } else {
        final errorMsg = refreshResponse.message.isNotEmpty
            ? refreshResponse.message
            : 'Token refresh failed.';
        // If refresh token has expired or is invalid, clear session
        if (response.statusCode == 401 || response.statusCode == 403) {
          await logout();
        }
        throw Exception(errorMsg);
      }
    } on FormatException {
      throw Exception('Invalid response received from hotel server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Refresh token error: $e');
    }
  }

  /// Updates SharedPreferences with refreshed tokens
  Future<void> _saveRefreshedTokens(RefreshTokenResponseModel refreshModel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newAccessToken = refreshModel.accessToken;
      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        await prefs.setString(_tokenKey, newAccessToken);
      }
      final newRefreshToken = refreshModel.refreshToken;
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await prefs.setString(_refreshTokenKey, newRefreshToken);
      }
      if (refreshModel.user != null) {
        await prefs.setString(_userDataKey, jsonEncode(refreshModel.user!.toJson()));
      }

      // Also update saved LoginResponseModel in SharedPreferences
      final rawLoginResponse = prefs.getString(_loginResponseKey);
      if (rawLoginResponse != null && rawLoginResponse.isNotEmpty) {
        try {
          final Map<String, dynamic> loginMap =
              jsonDecode(rawLoginResponse) as Map<String, dynamic>;
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            loginMap['accessToken'] = newAccessToken;
            loginMap['token'] = newAccessToken;
          }
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            loginMap['refreshToken'] = newRefreshToken;
          }
          await prefs.setString(_loginResponseKey, jsonEncode(loginMap));
        } catch (_) {}
      }
    } catch (_) {
      // Local storage persistence failure should not block token refresh
    }
  }

  /// Safely extracts expiration timestamp in seconds from JWT token
  static int? getJwtExpiration(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decodedBytes = base64Decode(normalized);
      final jsonStr = utf8.decode(decodedBytes);
      final payload = jsonDecode(jsonStr) as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is int) return exp;
      if (exp is num) return exp.toInt();
      if (exp is String) return int.tryParse(exp);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Checks if token is expired or expiring within [thresholdSeconds] (default 60s)
  static bool isTokenExpired(String? token, {int thresholdSeconds = 60}) {
    if (token == null || token.isEmpty) return true;
    final exp = getJwtExpiration(token);
    if (exp == null) return false;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (exp - thresholdSeconds) <= nowSeconds;
  }

  /// Returns a valid access token. If expired, automatically refreshes it and saves to SharedPreferences!
  Future<String?> getValidAccessToken() async {
    final token = await getSavedToken();
    if (token == null || token.isEmpty) return null;

    if (isTokenExpired(token)) {
      try {
        final refreshed = await refreshToken();
        return refreshed.accessToken;
      } catch (_) {
        return null;
      }
    }
    return token;
  }

  /// Saves session tokens, user data, and complete login response to SharedPreferences
  Future<void> _saveSession(LoginResponseModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = model.accessToken ?? model.token ?? '';
      if (token.isNotEmpty) {
        await prefs.setString(_tokenKey, token);
      }
      if (model.refreshToken != null && model.refreshToken!.isNotEmpty) {
        await prefs.setString(_refreshTokenKey, model.refreshToken!);
      }
      if (model.data != null) {
        await prefs.setString(_userDataKey, jsonEncode(model.data!.toJson()));
      }
      // Save entire login response in SharedPreferences
      await prefs.setString(_loginResponseKey, jsonEncode(model.toJson()));
      await prefs.setBool(_rememberStationKey, true);
    } catch (_) {
      // Local storage persistence failure should not block login
    }
  }

  /// Checks if a valid login response / token is available in SharedPreferences
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final rawResponse = prefs.getString(_loginResponseKey);
      final rawUser = prefs.getString(_userDataKey);
      return (token != null && token.isNotEmpty) ||
          (rawResponse != null && rawResponse.isNotEmpty) ||
          (rawUser != null && rawUser.isNotEmpty);
    } catch (_) {
      return false;
    }
  }

  /// Retrieves cached user session
  Future<AuthUserModel?> getSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUser = prefs.getString(_userDataKey);
      if (rawUser != null && rawUser.isNotEmpty) {
        final Map<String, dynamic> jsonMap =
            jsonDecode(rawUser) as Map<String, dynamic>;
        return AuthUserModel.fromJson(jsonMap);
      }
    } catch (_) {}
    return null;
  }

  /// Retrieves saved token
  Future<String?> getSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (_) {}
    return null;
  }

  /// Retrieves saved refresh token
  Future<String?> getSavedRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (_) {}
    return null;
  }

  /// Retrieves full saved LoginResponseModel from SharedPreferences
  Future<LoginResponseModel?> getSavedLoginResponse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawResponse = prefs.getString(_loginResponseKey);
      if (rawResponse != null && rawResponse.isNotEmpty) {
        final Map<String, dynamic> jsonMap =
            jsonDecode(rawResponse) as Map<String, dynamic>;
        return LoginResponseModel.fromJson(jsonMap);
      }
    } catch (_) {}
    return null;
  }

  /// Fetches current authenticated user profile from /auth/me API
  Future<AuthUserModel?> fetchMe() async {
    try {
      final token = await getValidAccessToken();
      final refreshToken = await getSavedRefreshToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final cookieParts = <String>[];
      if (token != null && token.isNotEmpty) {
        cookieParts.add('accessToken=$token');
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        cookieParts.add('refreshToken=$refreshToken');
      }
      if (cookieParts.isNotEmpty) {
        headers['Cookie'] = cookieParts.join('; ');
      }

      final response = await _client
          .get(Uri.parse(meUrl), headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse =
            jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          final userMap = (data is Map<String, dynamic> &&
                  data['user'] is Map<String, dynamic>)
              ? data['user'] as Map<String, dynamic>
              : (data as Map<String, dynamic>);
          final user = AuthUserModel.fromJson(userMap);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
          return user;
        }
      }
    } catch (_) {
      // Graceful offline fallback to cached session
    }
    return getSavedUser();
  }

  /// Clears user session and removes SharedPreferences on log out
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userDataKey);
      await prefs.remove(_loginResponseKey);
      await prefs.remove(_rememberStationKey);
    } catch (_) {}
  }
}
