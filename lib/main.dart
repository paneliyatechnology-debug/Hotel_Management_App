import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/check_in_wizard/presentation/bloc/check_in_bloc.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/pages/mobile_main_screen.dart';
import 'features/rooms/presentation/bloc/rooms_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HotelManagementApp());
}

class HotelManagementApp extends StatelessWidget {
  const HotelManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardRepository = DashboardRepository();

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
      ],
      child: MaterialApp(
        title: 'Grand Royale - Front Desk Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MobileMainScreen(),
      ),
    );
  }
}
