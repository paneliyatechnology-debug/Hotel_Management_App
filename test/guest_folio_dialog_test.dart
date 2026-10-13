import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/core/widgets/status_badge.dart';
import 'package:my_own_pms_system/features/dashboard/data/models/guest_folio_model.dart';
import 'package:my_own_pms_system/features/folios/presentation/widgets/guest_folio_details_dialog.dart';

void main() {
  testWidgets('GuestFolioDetailsDialog renders on mobile without overflow', (tester) async {
    // Standard phone screen (390 x 844) matching user device
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final testFolio = GuestFolioModel(
      id: 'BK-691571-125',
      guestName: 'Keyur Sangani',
      assignedRoom: 'Room #01',
      roomType: 'Deluxe Suite',
      checkInDate: DateTime.now().subtract(const Duration(days: 1)),
      checkOutDate: DateTime.now(),
      status: FolioStatus.departed,
      roomRatePerNight: 4500.0,
      totalAmount: 4500.0,
      advancePaid: 4500.0,
      phone: '+91 98765 43210',
      email: 'jatin.patel@gmail.com',
      gender: 'Male',
      idType: 'AADHAAR',
      idNumber: '5654 3234 5666',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => GuestFolioDetailsDialog(folio: testFolio),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Tap to open the dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog header and personal info contain guest name
    expect(find.text('Keyur Sangani'), findsWidgets);
    expect(find.text('DEPARTED'), findsOneWidget);
    expect(find.text('PAID'), findsOneWidget);
    expect(find.text('Booking #BK-691571-125 • Room #01'), findsOneWidget);

    // Verify all 4 tabs are visible without scroll
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Rooms'), findsOneWidget);
    expect(find.text('Billing'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);

    // Verify Body content is visible
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Govt KYC ID Proof'), findsOneWidget);

    // Verify footer actions are visible and NOT overflowed
    expect(find.text('Guest Folio PDF'), findsOneWidget);
    expect(find.text('ID Proofs (.ZIP)'), findsOneWidget);
    expect(find.text('Send on WhatsApp'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    // Scroll inside the tab body to verify scrollability
    await tester.drag(find.text('Personal Information'), const Offset(0, -200));
    await tester.pumpAndSettle();

    // Tap Close to dismiss
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Keyur Sangani'), findsNothing);
  });

  testWidgets('GuestFolioDetailsDialog renders on compact phone (360x640) without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final testFolio = GuestFolioModel(
      id: 'BK-691571-125',
      guestName: 'Keyur Sangani',
      assignedRoom: 'Room #01',
      roomType: 'Deluxe Suite',
      checkInDate: DateTime.now().subtract(const Duration(days: 1)),
      checkOutDate: DateTime.now(),
      status: FolioStatus.departed,
      roomRatePerNight: 4500.0,
      totalAmount: 4500.0,
      advancePaid: 4500.0,
      phone: '+91 98765 43210',
      email: 'jatin.patel@gmail.com',
      gender: 'Male',
      idType: 'AADHAAR',
      idNumber: '5654 3234 5666',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => GuestFolioDetailsDialog(folio: testFolio),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Keyur Sangani'), findsWidgets);
    expect(find.text('Guest Folio PDF'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });
}
