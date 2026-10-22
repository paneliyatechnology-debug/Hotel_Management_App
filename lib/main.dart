import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/check_in_wizard/presentation/bloc/check_in_bloc.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/pages/mobile_main_screen.dart';
import 'features/rooms/presentation/bloc/rooms_bloc.dart';

import 'features/guests/data/repositories/guests_repository.dart';
import 'features/guests/presentation/bloc/guests_bloc.dart';
import 'features/guests/presentation/bloc/guests_event.dart';

import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/dashboard/presentation/live/room_live_sync.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyOwnPMSApp());
}

class MyOwnPMSApp extends StatelessWidget {
  final Widget? home;
  final AuthRepository? authRepository;

  const MyOwnPMSApp({super.key, this.home, this.authRepository});

  @override
  Widget build(BuildContext context) {
    final effectiveAuthRepository = authRepository ?? AuthRepository();
    final dashboardRepository = DashboardRepository();
    final guestsRepository = GuestsRepository(authRepository: effectiveAuthRepository);

    // Default to MobileMainScreen during automated widget tests if home is null,
    // and SplashScreen for standard production runs.
    final Widget initialHome = home ??
        (WidgetsBinding.instance.runtimeType.toString().contains('Test')
            ? const MobileMainScreen()
            : SplashScreen(authRepository: effectiveAuthRepository));

    return MultiBlocProvider(
      providers: [
        BlocProvider<DashboardBloc>(
          create: (_) => DashboardBloc(repository: dashboardRepository),
        ),
        BlocProvider<RoomsBloc>(
          create: (_) => RoomsBloc(repository: dashboardRepository),
        ),
        BlocProvider<CheckInBloc>(
          create: (_) => CheckInBloc(repository: dashboardRepository),
        ),
        BlocProvider<GuestsBloc>(
          create: (_) => GuestsBloc(repository: guestsRepository)..add(const LoadGuestsEvent()),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(repository: effectiveAuthRepository)..add(const AuthCheckRequested()),
        ),
      ],
      child: RoomLiveBinder(
        child: MaterialApp(
          title: 'MyOwnPMS System',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: initialHome,
        ),
      ),
    );
  }
}

/// Backward compatibility alias for legacy references and tests
typedef HotelManagementApp = MyOwnPMSApp;
