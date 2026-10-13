class RefreshTokenResponseModel {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;

  const RefreshTokenResponseModel({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
  });

  /// Compatibility getter for access token
  String? get token => accessToken;

  factory RefreshTokenResponseModel.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      accessToken: json['accessToken'] as String? ?? json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
}
