import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../dashboard/presentation/pages/admin_rooms_tariffs_page.dart';
import '../../../dashboard/presentation/pages/status_rooms_page.dart';
import '../../../dashboard/presentation/pages/admin_settings_page.dart';
import '../../../dashboard/presentation/pages/admin_staff_management_page.dart';
import '../../../dashboard/presentation/pages/admin_subscription_page.dart';
import '../../../dashboard/presentation/pages/hotel_admin_dashboard_view.dart';
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
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
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
    StaffDirectoryMemory.clear();
    RoomsDirectoryMemory.clear();
    AdminDashboardMemory.clear();
    SubscriptionPlansMemory.clear();
    HotelSettingsMemory.clear();
    StatusRoomsMemory.clear();
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

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final message = await repository.forgotPassword(email: event.email);
      emit(state.copyWith(
        status: AuthStatus.forgotPasswordSuccess,
        successMessage: message,
      ));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: message,
      ));
    }
  }
}
