import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(const AuthState()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<TokenRefreshRequested>(_onTokenRefreshRequested);
    on<ProfileRefreshRequested>(_onProfileRefreshRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthErrorDismissed>(_onAuthErrorDismissed);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final response = await repository.login(
        email: event.email,
        password: event.password,
        rememberStation: event.rememberStation,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: response.data,
        token: response.accessToken ?? response.token,
        successMessage: response.message.isNotEmpty
            ? response.message
            : 'Login successful.',
      ));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await repository.isLoggedIn();

    if (isLoggedIn) {
      // Proactively refresh if token has expired
      final token = await repository.getValidAccessToken();
      final user = await repository.getSavedUser();

      if (token != null && token.isNotEmpty) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          token: token,
          user: user,
        ));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onTokenRefreshRequested(
    TokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final response = await repository.refreshToken(
        providedRefreshToken: event.refreshToken,
      );
      if (response.accessToken != null && response.accessToken!.isNotEmpty) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          token: response.accessToken,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Session expired. Please sign in again.',
      ));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onProfileRefreshRequested(
    ProfileRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await repository.fetchMe();
      if (user != null) {
        emit(state.copyWith(user: user));
      }
    } catch (_) {}
  }

  void _onAuthErrorDismissed(
    AuthErrorDismissed event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }
}
