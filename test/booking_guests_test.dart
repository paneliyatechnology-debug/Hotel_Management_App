import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/core/widgets/status_badge.dart';
import 'package:my_own_pms_system/features/check_in_wizard/data/models/check_in_form_data.dart';
import 'package:my_own_pms_system/features/check_in_wizard/presentation/steps/step_1_guest_identity.dart';
import 'package:my_own_pms_system/features/dashboard/data/models/guest_folio_model.dart';
import 'package:my_own_pms_system/features/folios/presentation/widgets/guest_folio_details_view.dart';
import 'package:my_own_pms_system/features/rooms/data/models/room_model.dart';

void main() {
  final Map<String, dynamic> sampleApiResponse = {
    "id": 75,
    "hotel_id": 1,
    "booking_number": "NR/2026-27/0036",
    "primary_guest_name": "Niraj",
    "guests": [
      {"id": 99, "name": "Niraj", "display_order": 1},
      {"id": 100, "name": "Niraj 1", "display_order": 2},
      {"id": 101, "name": "Niraj 2", "display_order": 3},
      {"id": 102, "name": "Niraj 3", "display_order": 4},
      {"id": 103, "name": "Niraj 4", "display_order": 5},
      {"id": 104, "name": "Niraj 5", "display_order": 6}
    ],
    "mobile_number": "9426886960",
    "email": "abc@gmail.com",
    "address": "Nikol, Ahmedabad",
    "room_id": [49],
    "created_by": 3,
    "check_in_date": "2026-10-24T14:00:00.000Z",
    "check_out_date": "2026-10-25T12:00:00.000Z",
    "actual_check_in": "2026-10-24T13:20:10.000Z",
    "actual_check_out": null,
    "number_of_nights": 1,
    "adults": 6,
    "children": 0,
    "base_amount": 3500,
    "tax_amount": 450,
    "gst_rate": 18,
    "cgst_rate": 9,
    "sgst_rate": 9,
    "gst_amount": 450,
    "cgst_amount": 225,
    "sgst_amount": 225,
    "taxable_amount": 2500,
    "discount_amount": 1000,
    "extra_charges_total": 0,
    "late_checkout_charge": 0,
    "late_checkout_hours": 0,
    "total_amount": 2950,
    "paid_amount": 2000,
    "due_amount": 950,
    "payment_status": "PARTIALLY_PAID",
    "booking_status": "CHECKED_IN",
    "signatures": [
      "https://api.myownpms.com/uploads/bookings/signatures/1792848009716-96687377-signature.png"
    ],
    "images": [
      "https://api.myownpms.com/uploads/bookings/images/1792848009715-263392369-scaled_c06bfff3-4423-453f-a28a-66244d4d642a3689062.jpg"
    ],
    "notes": "",
    "hotel": {
      "id": 1,
      "name": "Niraj Resort",
      "slug": "niraj-resort"
    },
    "rooms": [
      {
        "id": 49,
        "room_number": "201",
        "floor": 2,
        "room_type_name": "Family Room"
      }
    ]
  };

  test('GuestFolioModel.fromJson parses guests list accurately', () {
    final folio = GuestFolioModel.fromJson(sampleApiResponse);

    expect(folio.id, '75');
    expect(folio.bookingId, 'NR/2026-27/0036');
    expect(folio.guestName, 'Niraj');
    expect(folio.adultCount, 6);
    expect(folio.guests.length, 6);

    expect(folio.guests[0].id, 99);
    expect(folio.guests[0].name, 'Niraj');
    expect(folio.guests[0].displayOrder, 1);

    expect(folio.guests[1].name, 'Niraj 1');
    expect(folio.guests[1].displayOrder, 2);

    expect(folio.guests[5].name, 'Niraj 5');
    expect(folio.guests[5].displayOrder, 6);
  });

  testWidgets('GuestFolioDetailsView renders registered guests correctly', (tester) async {
    final folio = GuestFolioModel.fromJson(sampleApiResponse);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuestFolioDetailsView(
            folio: folio,
            isDialog: false,
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify Guests section header is displayed with count
    expect(find.text('Guests (6)'), findsOneWidget);
    expect(find.text('6 Registered'), findsOneWidget);

    // Verify Primary tag
    expect(find.text('Primary'), findsOneWidget);

    // Verify guest names in the card
    expect(find.text('Niraj'), findsWidgets);
    expect(find.text('Niraj 1'), findsOneWidget);
    expect(find.text('Niraj 2'), findsOneWidget);
    expect(find.text('Niraj 3'), findsOneWidget);
    expect(find.text('Niraj 4'), findsOneWidget);
    expect(find.text('Niraj 5'), findsOneWidget);

    // Verify display order badges
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('6'), findsWidgets);
  });

  test('GuestFolioModel.fromJson correctly handles unpaid / null payment booking', () {
    final unpaidResponse = {
      "id": 76,
      "hotel_id": 1,
      "booking_number": "NR/2026-27/0037",
      "primary_guest_name": "abc",
      "guests": [
        {"id": 105, "name": "abc", "display_order": 1}
      ],
      "mobile_number": "9408036136",
      "email": "abc@gmail.com",
      "address": "",
      "room_id": [1],
      "created_by": 3,
      "check_in_date": "2026-10-26T05:30:00.000Z",
      "check_out_date": "2026-10-27T05:30:00.000Z",
      "actual_check_in": "2026-10-26T05:17:54.000Z",
      "actual_check_out": null,
      "number_of_nights": 1,
      "adults": 1,
      "children": 0,
      "base_amount": 4000,
      "tax_amount": 720,
      "gst_rate": 18,
      "cgst_rate": 9,
      "sgst_rate": 9,
      "gst_amount": 720,
      "cgst_amount": 360,
      "sgst_amount": 360,
      "taxable_amount": 4000,
      "discount_amount": 0,
      "extra_charges_total": 0,
      "late_checkout_charge": 0,
      "late_checkout_hours": 0,
      "total_amount": 4720,
      "paid_amount": 0,
      "due_amount": 4720,
      "payment_status": "PENDING",
      "booking_status": "CHECKED_IN",
      "signatures": [],
      "images": [],
      "notes": "CASH advance at check-in",
      "payment_history": []
    };

    final folio = GuestFolioModel.fromJson(unpaidResponse);

    expect(folio.id, '76');
    expect(folio.totalAmount, 4720.0);
    expect(folio.advancePaid, 0.0);
    expect(folio.paidAmount, 0.0);
    expect(folio.pendingAmount, 4720.0);
    expect(folio.hasPayment, false);
    expect(folio.paymentMode, '');
    expect(folio.payments, isEmpty);
    expect(folio.paymentStatusLabel, 'PENDING');
  });

  testWidgets('GuestFolioDetailsView hides payment info when payment is null / empty', (tester) async {
    final unpaidResponse = {
      "id": 76,
      "hotel_id": 1,
      "booking_number": "NR/2026-27/0037",
      "primary_guest_name": "abc",
      "guests": [
        {"id": 105, "name": "abc", "display_order": 1}
      ],
      "mobile_number": "9408036136",
      "email": "abc@gmail.com",
      "address": "",
      "room_id": [1],
      "check_in_date": "2026-10-26T05:30:00.000Z",
      "check_out_date": "2026-10-27T05:30:00.000Z",
      "base_amount": 4000,
      "tax_amount": 720,
      "total_amount": 4720,
      "paid_amount": 0,
      "due_amount": 4720,
      "payment_status": "PENDING",
      "booking_status": "CHECKED_IN",
      "payment_history": []
    };

    final folio = GuestFolioModel.fromJson(unpaidResponse);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuestFolioDetailsView(
            folio: folio,
            isDialog: false,
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify "Payment Method" row is NOT shown on the screen
    expect(find.text('Payment Method'), findsNothing);

    // Verify Ledger tab shows count 0
    expect(find.text('Ledger (0)'), findsOneWidget);

    // Tap on Ledger tab to open it
    await tester.tap(find.text('Ledger (0)'));
    await tester.pumpAndSettle();

    // Verify empty state is displayed and NO fake/dummy payment records exist
    expect(find.text('No Payment Records'), findsOneWidget);
    expect(find.text('ADVANCE'), findsNothing);
  });

  test('CheckInFormData.fromFolio auto fills all details including multiple guests, primary guest, room, and keycard', () {
    final folio = GuestFolioModel.fromJson(sampleApiResponse);
    const room = RoomModel(
      id: '49',
      roomNumber: '103',
      floor: 'Floor 1',
      roomType: 'Family Room',
      pricePerNight: 4000,
      status: RoomStatus.occupied,
      keyCode: 'KC-103',
    );

    final form = CheckInFormData.fromFolio(folio, room);

    // Primary Guest Identity
    expect(form.guestFullName, 'Niraj');
    expect(form.contactPhone, '9426886960');
    expect(form.email, 'abc@gmail.com');
    expect(form.residentialAddress, 'Nikol, Ahmedabad');

    // Auto-filled Accompanying Guests
    expect(form.secondGuestName, 'Niraj 1');
    expect(form.accompanyingGuests.length, 4);
    expect(form.accompanyingGuests[0].name, 'Niraj 2');
    expect(form.accompanyingGuests[1].name, 'Niraj 3');
    expect(form.accompanyingGuests[2].name, 'Niraj 4');
    expect(form.accompanyingGuests[3].name, 'Niraj 5');

    // Total guests count and party type
    expect(form.numberOfGuests, 6);
    expect(form.partyType, 'Family / Group');

    // Room and keycard details
    expect(form.selectedRoomNumber, '103');
    expect(form.assignedKeycardNumber, 'KC-201');
    expect(form.isRoomPreLocked, isTrue);
  });

  testWidgets('Typing into Guest Name field preserves forward order and does not revert or reverse letters', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    var currentData = CheckInFormData();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Step1GuestIdentity(
                  formData: currentData,
                  onDataChanged: (updated) {
                    setState(() => currentData = updated);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Type "Niraj" into Main Guest Name character by character
    final mainGuestFinder = find.widgetWithText(TextField, 'Enter guest name').first;
    await tester.enterText(mainGuestFinder, 'N');
    await tester.pump();
    await tester.enterText(mainGuestFinder, 'Ni');
    await tester.pump();
    await tester.enterText(mainGuestFinder, 'Nir');
    await tester.pump();
    await tester.enterText(mainGuestFinder, 'Nira');
    await tester.pump();
    await tester.enterText(mainGuestFinder, 'Niraj');
    await tester.pumpAndSettle();

    expect(find.text('Niraj'), findsOneWidget);
    expect(find.text('jaRNi'), findsNothing);
    expect(currentData.guestFullName, 'Niraj');

    // 2. Type "Rohan" into additional Guest Name field character by character
    final additionalGuestFinder = find.widgetWithText(TextField, 'Enter guest name').at(1);
    await tester.enterText(additionalGuestFinder, 'R');
    await tester.pump();
    await tester.enterText(additionalGuestFinder, 'Ro');
    await tester.pump();
    await tester.enterText(additionalGuestFinder, 'Roh');
    await tester.pump();
    await tester.enterText(additionalGuestFinder, 'Roha');
    await tester.pump();
    await tester.enterText(additionalGuestFinder, 'Rohan');
    await tester.pumpAndSettle();

    expect(find.text('Rohan'), findsOneWidget);
    expect(find.text('nahoR'), findsNothing);
    expect(currentData.secondGuestName, 'Rohan');
  });
}
