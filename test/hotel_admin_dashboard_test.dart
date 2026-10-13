import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/features/dashboard/data/models/hotel_stats_model.dart';
import 'package:my_own_pms_system/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/hotel_admin_dashboard_view.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/mobile_main_screen.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/widgets/hotel_admin_charts.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/widgets/hotel_admin_drawer.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/widgets/hotel_admin_operations_banner.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/widgets/hotel_admin_telemetry_cards.dart';
import 'package:my_own_pms_system/features/rooms/presentation/bloc/rooms_bloc.dart';
import 'package:my_own_pms_system/features/check_in_wizard/presentation/bloc/check_in_bloc.dart';
import 'package:my_own_pms_system/features/guests/data/repositories/guests_repository.dart';
import 'package:my_own_pms_system/features/guests/presentation/bloc/guests_bloc.dart';
import 'package:my_own_pms_system/features/auth/data/repositories/auth_repository.dart';
import 'package:my_own_pms_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestHotelAdminApp({String role = 'HOTEL_ADMIN'}) {
  final dashboardRepo = DashboardRepository();
  final guestsRepo = GuestsRepository();
  final authRepo = AuthRepository();

  return MultiBlocProvider(
    providers: [
      BlocProvider<DashboardBloc>(create: (_) => DashboardBloc(repository: dashboardRepo)),
      BlocProvider<RoomsBloc>(create: (_) => RoomsBloc(repository: dashboardRepo)),
      BlocProvider<CheckInBloc>(create: (_) => CheckInBloc(repository: dashboardRepo)),
      BlocProvider<GuestsBloc>(create: (_) => GuestsBloc(repository: guestsRepo)),
      BlocProvider<AuthBloc>(create: (_) => AuthBloc(repository: authRepo)),
    ],
    child: MaterialApp(
      home: MobileMainScreen(initialRole: role),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Hotel Admin Dashboard 2026 Mobile Design Tests', () {
    testWidgets('HotelAdminOperationsBanner renders Gujarati greeting, Resort Name & Inventory',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HotelAdminOperationsBanner(
                resortName: 'Niraj Resort',
                location: 'Gujarat, India',
                totalRooms: 4,
                occupancyPercentage: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Niraj Resort'), findsOneWidget);
      expect(find.textContaining('Gujarat, India'), findsOneWidget);
      expect(find.textContaining('LIVE OPERATIONS CENTER'), findsOneWidget);
      expect(find.text('Sync Live Status'), findsOneWidget);
    });

    testWidgets('HotelAdminTelemetryCards renders all 4 financial telemetry cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const stats = HotelStatsModel(
        availableVacant: 4,
        occupiedInHouse: 0,
        housekeepingQueue: 0,
        maintenanceBlocked: 0,
        totalInHouseGuests: 0,
        todayCash: 0,
        todayOnline: 0,
        totalToday: 0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HotelAdminTelemetryCards(stats: stats),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Financial & Revenue Telemetry'), findsOneWidget);
      expect(find.text("TODAY'S REVENUE"), findsOneWidget);
      expect(find.text("TODAY'S EARNINGS"), findsOneWidget);
      expect(find.text('TOTAL GUESTS'), findsOneWidget);
      expect(find.text('MONTHLY REVENUE'), findsOneWidget);
      expect(find.text('Live Real-time Audit'), findsOneWidget);
      expect(find.text('Live Counter'), findsOneWidget);
      expect(find.text('78.5% Margin'), findsOneWidget);
    });

    testWidgets('Hotel Admin Charts render Live Room Occupancy & Spline dynamics',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const stats = HotelStatsModel(
        availableVacant: 4,
        occupiedInHouse: 0,
        housekeepingQueue: 0,
        maintenanceBlocked: 0,
        totalInHouseGuests: 0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  LiveRoomOccupancyDonutCard(stats: stats, totalRooms: 4),
                  RevenueDynamicsSplineCard(),
                  DailyRevenueGoalCard(),
                  WeeklyReceptionTrafficCard(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live Room Occupancy'), findsOneWidget);
      expect(find.text('Revenue & Collection Dynamics'), findsOneWidget);
      expect(find.text('Daily Revenue Goal'), findsOneWidget);
      expect(find.text('Weekly Reception Traffic'), findsOneWidget);
      expect(find.text('98% UPI'), findsOneWidget);
      expect(find.text('32% Cash'), findsOneWidget);
      expect(find.text('Target: ₹35,000 / Day'), findsOneWidget);
      expect(find.text('53%'), findsOneWidget);
    });

    testWidgets('HotelAdminDrawer renders all website navigation links and user profile',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: HotelAdminDrawer(
              staffName: 'Niraj Vekariya',
              email: 'nirajvekariya2209@gmail.com',
              selectedNavIndex: 0,
              onNavItemSelected: (_) {},
            ),
            body: const SizedBox(),
          ),
        ),
      );

      // Open drawer
      final state = tester.state<ScaffoldState>(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('GRAND ROYALE'), findsOneWidget);
      expect(find.text('Hotel Admin PMS'), findsOneWidget);
      expect(find.text('MAIN NAVIGATION'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Daily Collections'), findsOneWidget);
      expect(find.text('Guest Directory'), findsOneWidget);
      expect(find.text('Staff Management'), findsOneWidget);
      expect(find.text('Rooms & Tariffs'), findsOneWidget);
      expect(find.text('Subscription Plan'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Niraj Vekariya'), findsOneWidget);
      expect(find.text('nirajvekariya2209@gmail.com'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('MobileMainScreen renders Hotel Admin PMS dashboard when role is HOTEL_ADMIN',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestHotelAdminApp(role: 'HOTEL_ADMIN'));
      await tester.pumpAndSettle();

      // Top Header verifies Hotel Admin
      expect(find.text('GRAND ROYALE • HOTEL ADMIN'), findsOneWidget);


      // Verifies Hotel Admin Dashboard View widgets
      expect(find.byType(HotelAdminDashboardView), findsOneWidget);
      expect(find.text("TODAY'S REVENUE"), findsOneWidget);
      expect(find.text('Live Room Occupancy'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Revenue & Collection Dynamics'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Revenue & Collection Dynamics'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Daily Revenue Goal'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Daily Revenue Goal'), findsOneWidget);
      expect(find.text('Weekly Reception Traffic'), findsOneWidget);
    });
  });
}
