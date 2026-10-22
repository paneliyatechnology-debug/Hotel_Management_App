import 'auth_user_model.dart';

class LoginResponseModel {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final AuthUserModel? data;

  const LoginResponseModel({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.data,
  });

  /// Compatibility getter for access token
  String? get token => accessToken;

  /// Convenience getter for user
  AuthUserModel? get user => data;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? dataMap;
    if (json['data'] is Map<String, dynamic>) {
      dataMap = json['data'] as Map<String, dynamic>;
    }

    final accessToken = _readToken(dataMap, const ['accessToken', 'access_token', 'token']) ??
        _readToken(json, const ['accessToken', 'access_token', 'token']);

    final refreshToken = _readToken(dataMap, const ['refreshToken', 'refresh_token']) ??
        _readToken(json, const ['refreshToken', 'refresh_token']);

    AuthUserModel? parsedUser;
    if (dataMap != null) {
      if (dataMap['user'] is Map<String, dynamic>) {
        parsedUser =
            AuthUserModel.fromJson(dataMap['user'] as Map<String, dynamic>);
      } else {
        parsedUser = AuthUserModel.fromJson(dataMap);
      }
    } else if (json['user'] is Map<String, dynamic>) {
      parsedUser = AuthUserModel.fromJson(json['user'] as Map<String, dynamic>);
    }

    return LoginResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      accessToken: accessToken,
      refreshToken: refreshToken,
      data: parsedUser,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'data': {
          if (accessToken != null) 'accessToken': accessToken,
          if (refreshToken != null) 'refreshToken': refreshToken,
          if (data != null) 'user': data?.toJson(),
        },
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
