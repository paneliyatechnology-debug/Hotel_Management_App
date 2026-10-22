import 'auth_user_model.dart';

class RefreshTokenResponseModel {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final AuthUserModel? user;

  const RefreshTokenResponseModel({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  /// Compatibility getter for access token
  String? get token => accessToken;

  factory RefreshTokenResponseModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? dataMap;
    if (json['data'] is Map<String, dynamic>) {
      dataMap = json['data'] as Map<String, dynamic>;
    }

    final accessToken = _readToken(dataMap, const ['accessToken', 'access_token', 'token']) ??
        _readToken(json, const ['accessToken', 'access_token', 'token']);

    final refreshToken = _readToken(dataMap, const ['refreshToken', 'refresh_token']) ??
        _readToken(json, const ['refreshToken', 'refresh_token']);

    AuthUserModel? user;
    final rawUser = dataMap?['user'];
    if (rawUser is Map) {
      user = AuthUserModel.fromJson(Map<String, dynamic>.from(rawUser));
    }

    return RefreshTokenResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
}

String? _readToken(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
  }
  return null;
}
