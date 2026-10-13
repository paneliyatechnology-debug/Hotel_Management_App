import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user_model.dart';
import '../models/login_response_model.dart';
import '../models/refresh_token_response_model.dart';

class AuthRepository {
  static const String baseUrl =
      'https://hotelmanagementbackend-dev.up.railway.app/api/v1/auth/login';
  static const String refreshUrl =
      'https://hotelmanagementbackend-dev.up.railway.app/api/v1/auth/refresh-token';
  static const String meUrl =
      'https://hotelmanagementbackend-dev.up.railway.app/api/v1/auth/me';

  static const String _tokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userDataKey = 'auth_user_data';
  static const String _loginResponseKey = 'auth_login_response';
  static const String _rememberStationKey = 'auth_remember_station';

  final http.Client _client;

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

      final Map<String, dynamic> jsonResponse =
          jsonDecode(response.body) as Map<String, dynamic>;

      final loginResponse = LoginResponseModel.fromJson(jsonResponse);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          loginResponse.success) {
        // After login, save login response in SharedPreferences
        await _saveSession(loginResponse);
        return loginResponse;
      } else {
        final errorMsg = loginResponse.message.isNotEmpty
            ? loginResponse.message
            : 'Login failed. Please check your credentials.';
        throw Exception(errorMsg);
      }
    } on FormatException {
      throw Exception('Invalid response received from hotel server.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connection error: $e');
    }
  }

  /// Calls the refresh-token API and saves new tokens to SharedPreferences
  Future<RefreshTokenResponseModel> refreshToken({String? providedRefreshToken}) async {
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

      // Set Cookie header matching Postman spec:
      // Cookie: refreshToken=...; token=...
      final cookieParts = <String>[];
      cookieParts.add('refreshToken=$tokenToUse');
      if (currentAccessToken != null && currentAccessToken.isNotEmpty) {
        cookieParts.add('token=$currentAccessToken');
      }
      headers['Cookie'] = cookieParts.join('; ');

      final body = jsonEncode({
        'refreshToken': tokenToUse,
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
      if (token != null && token.isNotEmpty) cookieParts.add('token=$token');
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
          final user = AuthUserModel.fromJson(
              jsonResponse['data'] as Map<String, dynamic>);
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
