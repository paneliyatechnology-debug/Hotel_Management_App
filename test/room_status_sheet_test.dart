import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/core/widgets/status_badge.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/widgets/modern_room_bottom_sheet.dart';
import 'package:my_own_pms_system/features/rooms/data/models/room_model.dart';

void main() {
  testWidgets('a different status is sent only after Update Status', (tester) async {
    RoomStatus? sent;
    final room = RoomModel(
      id: '14',
      roomNumber: '#101',
      floor: 'Floor 2',
      roomType: 'Family Room',
      pricePerNight: 4000,
      status: RoomStatus.available,
    );

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              ModernRoomBottomSheet.show(
                context: context,
                room: room,
                onStatusChanged: (status) => sent = status,
                onExpressCheckIn: () {},
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Update Status'), findsNothing);
    await tester.tap(find.text('Cleaning'));
    await tester.pumpAndSettle();

    expect(sent, isNull);
    expect(find.text('Update Status'), findsOneWidget);

    await tester.tap(find.text('Update Status'));
    await tester.pumpAndSettle();
    expect(sent, RoomStatus.cleaning);
  });

  testWidgets('occupied room shows Checkout instead of the status switcher', (tester) async {
    var checkedOut = false;
    final room = RoomModel(
      id: '16',
      roomNumber: '#202',
      floor: 'Floor 2',
      roomType: 'Deluxe Room',
      pricePerNight: 4000,
      status: RoomStatus.occupied,
      currentGuestName: 'Ravi Shah',
    );

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              ModernRoomBottomSheet.show(
                context: context,
                room: room,
                onStatusChanged: (_) {},
                onExpressCheckIn: () {},
                onCheckout: () => checkedOut = true,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('QUICK STATUS SWITCHER'), findsNothing);
    expect(find.text('Update Status'), findsNothing);

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    expect(checkedOut, isTrue);
  });

  testWidgets('cleaning room shows only Available and marks the room available', (tester) async {
    RoomStatus? sent;
    final room = RoomModel(
      id: '18',
      roomNumber: '#104',
      floor: 'Floor 1',
      roomType: 'Family Room',
      pricePerNight: 4000,
      status: RoomStatus.cleaning,
    );

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              ModernRoomBottomSheet.show(
                context: context,
                room: room,
                onStatusChanged: (status) => sent = status,
                onExpressCheckIn: () {},
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Available'), findsOneWidget);
    expect(find.text('QUICK STATUS SWITCHER'), findsNothing);
    expect(find.text('Occupied'), findsNothing);
    expect(find.text('Repair'), findsNothing);
    expect(find.text('Cleaning'), findsNothing);
    expect(find.text('Update Status'), findsNothing);

    await tester.tap(find.text('Available'));
    await tester.pumpAndSettle();

    expect(sent, isNull);
    expect(find.text('Mark room available?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Available'));
    await tester.pumpAndSettle();
    expect(sent, RoomStatus.available);
  });
}
