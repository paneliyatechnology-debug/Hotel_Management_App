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

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      accessToken: json['accessToken'] as String? ?? json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      data: json['data'] != null
          ? AuthUserModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'data': data?.toJson(),
      };
}
