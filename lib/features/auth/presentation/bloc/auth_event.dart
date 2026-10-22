import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  final bool rememberStation;

  const LoginSubmitted({
    required this.email,
    required this.password,
    this.rememberStation = true,
  });

  @override
  List<Object?> get props => [email, password, rememberStation];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class AuthErrorDismissed extends AuthEvent {
  const AuthErrorDismissed();
}

class TokenRefreshRequested extends AuthEvent {
  final String? refreshToken;
  const TokenRefreshRequested({this.refreshToken});

  @override
  List<Object?> get props => [refreshToken];
}

class ProfileRefreshRequested extends AuthEvent {
  const ProfileRefreshRequested();
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  const ForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}
