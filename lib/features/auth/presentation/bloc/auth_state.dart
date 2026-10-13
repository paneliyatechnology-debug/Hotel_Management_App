import 'package:equatable/equatable.dart';
import '../../data/models/auth_user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthUserModel? user;
  final String? token;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.errorMessage,
    this.successMessage,
  });

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isFailure => status == AuthStatus.failure;

  AuthState copyWith({
    AuthStatus? status,
    AuthUserModel? user,
    String? token,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        token,
        errorMessage,
        successMessage,
      ];
}
