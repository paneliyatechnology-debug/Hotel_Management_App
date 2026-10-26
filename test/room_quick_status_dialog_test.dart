import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/core/widgets/status_badge.dart';
import 'package:my_own_pms_system/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:my_own_pms_system/features/rooms/data/models/room_model.dart';
import 'package:my_own_pms_system/features/rooms/presentation/widgets/room_quick_status_dialog.dart';

class _FakeDashboardRepository implements IDashboardRepository {
  String? lastUpdatedRoomId;
  RoomStatus? lastUpdatedStatus;

  @override
  Future<void> updateRoomStatus(String roomId, RoomStatus newStatus) async {
    lastUpdatedRoomId = roomId;
    lastUpdatedStatus = newStatus;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildTestWidget({
    required RoomModel room,
    required _FakeDashboardRepository repository,
  }) {
    final bloc = DashboardBloc(repository: repository);

    return MaterialApp(
      home: BlocProvider<DashboardBloc>.value(
        value: bloc,
        child: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showRoomQuickStatusDialog(
                    context: context,
                    room: room,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('available room shows Cleaning and Maintenance buttons', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final repo = _FakeDashboardRepository();
    final room = const RoomModel(
      id: '1',
      roomNumber: '101',
      floor: 'Floor 1',
      roomType: 'Family Room',
      pricePerNight: 4000,
      status: RoomStatus.available,
    );

    await tester.pumpWidget(buildTestWidget(room: room, repository: repo));
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Room #101 Status'), findsOneWidget);
    expect(find.text('Cleaning'), findsOneWidget);
    expect(find.text('Maintenance'), findsOneWidget);
    // Should NOT have an option to change to Available since it's already Available
    expect(find.widgetWithText(ElevatedButton, 'Available'), findsNothing);

    // Tap Cleaning
    await tester.tap(find.byKey(const Key('quick_status_cleaning')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));

    expect(repo.lastUpdatedRoomId, '1');
    expect(repo.lastUpdatedStatus, RoomStatus.cleaning);
  });

  testWidgets('cleaning room shows Available and Maintenance buttons', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final repo = _FakeDashboardRepository();
    final room = const RoomModel(
      id: '2',
      roomNumber: '102',
      floor: 'Floor 1',
      roomType: 'Family Room',
      pricePerNight: 4000,
      status: RoomStatus.cleaning,
    );

    await tester.pumpWidget(buildTestWidget(room: room, repository: repo));
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Room #102 Status'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Maintenance'), findsOneWidget);
    // Should NOT have an option to change to Cleaning
    expect(find.widgetWithText(ElevatedButton, 'Cleaning'), findsNothing);

    // Tap Available
    await tester.tap(find.byKey(const Key('quick_status_available')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));

    expect(repo.lastUpdatedRoomId, '2');
    expect(repo.lastUpdatedStatus, RoomStatus.available);
  });

  testWidgets('maintenance room shows Available and Cleaning buttons', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final repo = _FakeDashboardRepository();
    final room = const RoomModel(
      id: '3',
      roomNumber: '103',
      floor: 'Floor 1',
      roomType: 'Family Room',
      pricePerNight: 4000,
      status: RoomStatus.maintenance,
    );

    await tester.pumpWidget(buildTestWidget(room: room, repository: repo));
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Room #103 Status'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Cleaning'), findsOneWidget);
    // Should NOT have an option to change to Maintenance
    expect(find.widgetWithText(ElevatedButton, 'Maintenance'), findsNothing);

    // Tap Cleaning
    await tester.tap(find.byKey(const Key('quick_status_cleaning')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));

    expect(repo.lastUpdatedRoomId, '3');
    expect(repo.lastUpdatedStatus, RoomStatus.cleaning);
  });
}
