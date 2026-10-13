import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/core/widgets/status_badge.dart';
import 'package:my_own_pms_system/features/check_in_wizard/data/models/check_in_form_data.dart';
import 'package:my_own_pms_system/features/check_in_wizard/presentation/widgets/check_in_success_dialog.dart';
import 'package:my_own_pms_system/features/dashboard/data/models/guest_folio_model.dart';
import 'package:my_own_pms_system/features/folios/presentation/widgets/guest_folio_details_dialog.dart';

void main() {
  testWidgets('CheckInSuccessDialog renders correctly matching design', (WidgetTester tester) async {
    final folio = GuestFolioModel(
      id: 'BK-579337-516',
      bookingId: 'BK-579337-516',
      guestName: 'Niraj Vekariya',
      phone: '0884921811',
      email: 'niraj.v@example.com',
      assignedRoom: '03',
      roomType: 'Deluxe Room',
      checkInDate: DateTime(2026, 10, 9),
      checkOutDate: DateTime(2026, 10, 10),
      status: FolioStatus.inHouse,
      idType: 'Aadhaar Card',
      idNumber: '5421-9876-1234',
      isGovtIdVerified: true,
      roomRatePerNight: 5000,
      advancePaid: 5600,
      totalAmount: 5600,
    );

    final formData = CheckInFormData(
      guestFullName: 'Niraj Vekariya',
      contactPhone: '0884921811',
      selectedRoomNumber: '03',
      roomType: 'Deluxe Room',
      checkInDate: DateTime(2026, 10, 9),
      checkOutDate: DateTime(2026, 10, 10),
    );

    bool doneClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckInSuccessDialog(
            folio: folio,
            formData: formData,
            onDone: () {
              doneClicked = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Header
    expect(find.text('Check-In Completed Successfully!'), findsOneWidget);
    expect(find.text('Guest has been assigned to Room 03'), findsOneWidget);

    // 2. Verify Key-Value details
    expect(find.text('Guest Name:'), findsOneWidget);
    expect(find.text('Niraj Vekariya'), findsOneWidget);

    expect(find.text('Mobile Number:'), findsOneWidget);
    expect(find.text('0884921811'), findsOneWidget);

    expect(find.text('Booking Ref #:'), findsOneWidget);
    expect(find.text('#BK-579337-516'), findsOneWidget);

    expect(find.text('Room Allocation:'), findsOneWidget);
    expect(find.text('Room 03'), findsOneWidget);

    expect(find.text('Check-in & Check-out:'), findsOneWidget);
    expect(find.text('2026-10-09 to 2026-10-10'), findsOneWidget);

    // 3. Verify Buttons
    expect(find.text('Print Folio PDF'), findsOneWidget);
    expect(find.text('Send WhatsApp'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // 4. Test Done Button
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(doneClicked, isTrue);

    // 5. Test Print Folio PDF opens Folio Details Dialog
    await tester.tap(find.text('Print Folio PDF'));
    await tester.pumpAndSettle();
    expect(find.byType(GuestFolioDetailsDialog), findsOneWidget);
  });
}
