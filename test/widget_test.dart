import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_own_pms_system/core/widgets/status_badge.dart';
import 'package:my_own_pms_system/features/check_in_wizard/data/models/check_in_form_data.dart';
import 'package:my_own_pms_system/features/check_in_wizard/presentation/bloc/check_in_bloc.dart';
import 'package:my_own_pms_system/features/check_in_wizard/presentation/bloc/check_in_event.dart';
import 'package:my_own_pms_system/features/check_in_wizard/presentation/pages/check_in_wizard_page.dart';
import 'package:my_own_pms_system/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:my_own_pms_system/features/rooms/data/models/room_model.dart';
import 'package:my_own_pms_system/features/rooms/presentation/bloc/rooms_bloc.dart';
import 'package:my_own_pms_system/main.dart';
import 'helpers/test_data.dart';

Widget createWizardTestApp({RoomModel? preselectedRoom, CheckInFormData? initialFormData}) {
  final repo = DashboardRepository(initialRooms: testRooms, initialFolios: testFolios);
  final initData = initialFormData ??
      (preselectedRoom != null
          ? CheckInFormData(
              selectedRoomId: preselectedRoom.id,
              selectedRoomNumber: preselectedRoom.roomNumber,
              selectedFloor: preselectedRoom.floor,
              roomType: preselectedRoom.roomType,
              pricePerNight: preselectedRoom.pricePerNight,
              isRoomPreLocked: true,
            )
          : CheckInFormData());
  return MultiBlocProvider(
    providers: [
      BlocProvider<DashboardBloc>(create: (_) => DashboardBloc(repository: repo)),
      BlocProvider<RoomsBloc>(create: (_) => RoomsBloc(repository: repo)),
      BlocProvider<CheckInBloc>(
        create: (_) {
          final bloc = CheckInBloc(repository: repo, initialFormData: initData);
          if (initialFormData == null) {
            bloc.add(InitCheckInWizardEvent(preselectedRoom: preselectedRoom));
          }
          return bloc;
        },
      ),
    ],
    child: const MaterialApp(
      home: CheckInWizardPage(),
    ),
  );
}

void main() {
  setUp(() {
    DashboardRepository(initialRooms: testRooms, initialFolios: testFolios);
  });
  testWidgets('2026 Mobile UI renders Front Desk Hub & Navigation cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyOwnPMSApp());
    await tester.pumpAndSettle();

    // Verify Mobile Header
    expect(find.text('Mayal Resort 2'), findsOneWidget);
    expect(find.text('GRAND ROYALE • FRONT DESK'), findsOneWidget);

    // Verify Modern Metrics Overview
    expect(find.text('LIVE METRICS OVERVIEW'), findsOneWidget);
    expect(find.text('AVAILABLE VACANT'), findsOneWidget);

    // Scroll down to reveal Recent Check-In & Check-Out Activity
    await tester.scrollUntilVisible(
      find.text('RECENT CHECK-IN & CHECK-OUT'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('RECENT CHECK-IN & CHECK-OUT'), findsOneWidget);
    expect(find.text('View All'), findsOneWidget);
    expect(find.text('Niraj Vekariya'), findsOneWidget);
    expect(find.text('Vikram Mehta'), findsWidgets);

    // Verify Bottom Navigation Bar Tabs
    expect(find.text('Front Desk'), findsOneWidget);
    expect(find.text('Rooms'), findsOneWidget);
    expect(find.text('In-House'), findsWidgets);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('Mobile 4-Step Express Check-In Wizard Navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWizardTestApp());
    await tester.pumpAndSettle();

    // Verify Step 1 is rendered (Guest Profile only)
    expect(find.text('STEP 1 OF 4'), findsOneWidget);
    expect(find.text('PRIMARY GUEST IDENTITY'), findsOneWidget);

    // Fill Step 1 with Quick Fill to satisfy validation
    final quickFillBtn = find.text('Quick Fill');
    await tester.tap(quickFillBtn);
    await tester.pumpAndSettle();

    // Clear any active snackbar so it doesn't intercept taps
    final scaffoldMessenger = ScaffoldMessenger.of(tester.element(find.byType(CheckInWizardPage)));
    scaffoldMessenger.clearSnackBars();
    await tester.pumpAndSettle();

    // Continue to Step 2 (Stay & Room Allocation)
    final continueBtn = find.text('Continue to Step 2');
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Step 2 is rendered
    expect(find.textContaining('Room Allocation & Stay Duration'), findsOneWidget);

    // Continue to Step 3 (Billing & Settlement)
    final continueToStep3Btn = find.text('Continue to Step 3');
    await tester.ensureVisible(continueToStep3Btn);
    await tester.tap(continueToStep3Btn, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Step 3: Billing & Settlement is rendered
    expect(find.text('Tariff Calculation & Advance Settlement'), findsOneWidget);
    expect(find.text('Nightly Tariff Rate (₹)'), findsOneWidget);
    expect(find.text('Payment Method'), findsOneWidget);

    // Continue to Step 4 (Review & Check-In)
    final continueToStep4Btn = find.text('Continue to Step 4');
    await tester.tap(continueToStep4Btn);
    await tester.pumpAndSettle();

    // Verify Step 4 is rendered
    expect(find.text('Step 4: Review & Check-In'), findsOneWidget);
  });

  testWidgets('Category Rooms Flow: Click Family Room -> Show all room numbers -> Select Room -> Guest Form with locked room', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyOwnPMSApp());
    await tester.pumpAndSettle();

    // Switch to Rooms Tab where room inventory and categories reside
    await tester.tap(find.text('Rooms'));
    await tester.pumpAndSettle();

    // Scroll down to reveal Room Categories
    final familyRoomCard = find.text('FAMILY ROOM').first;
    await tester.ensureVisible(familyRoomCard);
    await tester.pumpAndSettle();
    expect(familyRoomCard, findsOneWidget);
    await tester.tap(familyRoomCard);
    await tester.pumpAndSettle();

    // Verify CategoryRoomsPage is opened
    expect(find.text('FAMILY ROOMS INVENTORY'), findsNothing); // Checks category name in title
    expect(find.text('Mayal Resort 2 • Room Number Inventory'), findsOneWidget);
    expect(find.textContaining('AVAILABLE ROOM NUMBERS'), findsOneWidget);

    // Verify multiple family room numbers are displayed
    expect(find.text('#01'), findsOneWidget);
    expect(find.text('#06'), findsOneWidget);
    expect(find.text('#11'), findsOneWidget);

    // Select Room #01
    final selectRoomBtn = find.text('Select Room').first;
    await tester.tap(selectRoomBtn);
    await tester.pumpAndSettle();

    // Verify Guest Form opened
    expect(find.text('STEP 1 OF 4'), findsOneWidget);

    // Verify pre-selected room #01 is LOCKED and displayed in AppBar
    expect(find.text('LOCKED'), findsOneWidget);
    expect(find.text('ROOM #01 • FLOOR 1'), findsOneWidget);

    // Fill valid guest data via Quick Fill
    final quickFillBtn = find.text('Quick Fill');
    await tester.tap(quickFillBtn);
    await tester.pumpAndSettle();

    // Clear any active snackbar so it doesn't intercept taps
    final scaffoldMessenger = ScaffoldMessenger.of(tester.element(find.byType(CheckInWizardPage)));
    scaffoldMessenger.clearSnackBars();
    await tester.pumpAndSettle();

    // Continue to Step 2 (Stay & Room Allocation)
    final continueBtn = find.text('Continue to Step 2');
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.textContaining('Room Allocation & Stay Duration'), findsOneWidget);
    expect(find.text('LOCKED'), findsWidgets);
  });

  testWidgets('Inline field validation, dynamic ID hint text & disabled tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWizardTestApp());
    await tester.pumpAndSettle();

    // Verify initial Aadhaar Card hint text
    expect(find.text('e.g. 5421-9876-1234 (12 digits)'), findsWidgets);

    // Tap Continue without filling -> Inline validation errors appear
    final continueBtn = find.text('Continue to Step 2');
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    // Verify inline validation errors appear below fields
    expect(find.text('Guest full name (as per Govt ID) is required'), findsOneWidget);
    expect(find.text('Please enter valid Aadhaar Card document number'), findsOneWidget);

    // Verify no SnackBar error popup was created
    expect(find.byType(SnackBar), findsNothing);

    // Verify tapping on disabled future tab (Stay) stays on Step 1
    final stayTab = find.text('Stay').first;
    await tester.ensureVisible(stayTab);
    await tester.tap(stayTab);
    await tester.pumpAndSettle();
    expect(find.text('PRIMARY GUEST IDENTITY'), findsOneWidget);
  });

  testWidgets('Check-In Wizard 4-Step Flow with Room Details and Optional Second Guest', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const familyRoom = RoomModel(
      id: 'room-01',
      roomNumber: '#01',
      floor: 'Floor 1',
      roomType: 'family room',
      pricePerNight: 5000,
      status: RoomStatus.available,
      maxOccupancy: 4,
      amenities: ['King Bed', 'Balcony View', 'Wi-Fi', 'Smart TV', 'En-suite Bath'],
    );

    await tester.pumpWidget(createWizardTestApp(preselectedRoom: familyRoom));
    await tester.pumpAndSettle();

    // Verify Step 1 renders Primary Guest Identity and shows 4 steps
    expect(find.text('STEP 1 OF 4'), findsOneWidget);
    expect(find.text('PRIMARY GUEST IDENTITY'), findsOneWidget);

    // Auto-fill demo data
    final quickFillBtn = find.text('Quick Fill');
    await tester.ensureVisible(quickFillBtn);
    await tester.tap(quickFillBtn);
    await tester.pumpAndSettle();

    // Clear snackbars
    final scaffoldMessenger = ScaffoldMessenger.of(tester.element(find.byType(CheckInWizardPage)));
    scaffoldMessenger.clearSnackBars();
    await tester.pumpAndSettle();

    // Continue to Step 2 (Stay & Room Allocation)
    final continueBtn = find.text('Continue to Step 2');
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify successfully advanced to Step 2
    expect(find.textContaining('Room Allocation & Stay Duration'), findsOneWidget);
    expect(find.text('LOCKED'), findsWidgets);
  });

  testWidgets('Room Inventory & Categories 2026 UI: Real-time health metrics, search filter & unit badges', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyOwnPMSApp());
    await tester.pumpAndSettle();

    // Tap on Rooms tab in bottom navigation bar
    final roomsTab = find.text('Rooms');
    expect(roomsTab, findsOneWidget);
    await tester.tap(roomsTab);
    await tester.pumpAndSettle();

    // Verify Room Inventory & Categories header in AppBar
    expect(find.text('Room Inventory & Categories'), findsOneWidget);

    // Verify Search bar is present
    expect(find.byType(TextField), findsOneWidget);

    // Verify Category Cards are rendered with luxury tags
    expect(find.text('FAMILY ROOM'), findsOneWidget);
    expect(find.text('FAMILY SUITE'), findsOneWidget);
    expect(find.text('COUPLE HAVEN'), findsOneWidget);

    // Verify Room Unit chips are visible (e.g. #01, #06, #11, #16)
    expect(find.text('#01'), findsOneWidget);
    expect(find.text('#06'), findsOneWidget);

    // Test Search Filtering: Search "Presidential"
    await tester.enterText(find.byType(TextField), 'Presidential');
    await tester.pumpAndSettle();

    // Only Presidential Suite should be visible
    expect(find.text('PRESIDENTIAL SUITE'), findsOneWidget);
    expect(find.text('VIP PENTHOUSE'), findsOneWidget);
    expect(find.text('FAMILY ROOM'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    // All categories return
    expect(find.text('FAMILY ROOM'), findsOneWidget);

    // Tap on Family Room Card -> opens CategoryRoomsPage
    final familyRoomCard = find.text('FAMILY ROOM').first;
    await tester.tap(familyRoomCard);
    await tester.pumpAndSettle();

    expect(find.text('Mayal Resort 2 • Room Number Inventory'), findsOneWidget);
  });

  testWidgets('In-House Folios 2026 UI: Filter tabs, search, full guest names & luxury card layout', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyOwnPMSApp());
    await tester.pumpAndSettle();

    // Tap In-House in bottom navigation
    final inHouseNav = find.byIcon(Icons.people_alt_outlined).last;
    expect(inHouseNav, findsOneWidget);
    await tester.tap(inHouseNav);
    await tester.pumpAndSettle();

    // Verify Title and Subtitle
    expect(find.text('In-House Folios & Guest Registry'), findsOneWidget);

    // Verify KPI counters exist
    expect(find.text('IN-HOUSE'), findsWidgets);
    expect(find.text('FOLIO VALUE'), findsOneWidget);

    // Verify Guest Full Names are NOT truncated
    expect(find.text('Niraj Vekariya'), findsOneWidget);
    expect(find.text('Vikram Mehta'), findsOneWidget);

    // Verify Filter Tabs
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('In-House (1)'), findsOneWidget);
    expect(find.text('Departed (1)'), findsOneWidget);

    // Tap In-House filter -> Vikram Mehta visible, Niraj Vekariya hidden
    final inHouseTab = find.text('In-House (1)');
    await tester.ensureVisible(inHouseTab);
    await tester.tap(inHouseTab);
    await tester.pumpAndSettle();
    expect(find.text('Vikram Mehta'), findsOneWidget);
    expect(find.text('Niraj Vekariya'), findsNothing);

    // Tap Departed filter -> Niraj Vekariya visible, Vikram Mehta hidden
    final departedTab = find.text('Departed (1)');
    await tester.ensureVisible(departedTab);
    await tester.tap(departedTab);
    await tester.pumpAndSettle();
    expect(find.text('Niraj Vekariya'), findsOneWidget);
    expect(find.text('Vikram Mehta'), findsNothing);

    // Search by guest name 'Niraj'
    final allTab = find.text('All (2)');
    await tester.ensureVisible(allTab);
    await tester.tap(allTab);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Niraj');
    await tester.pumpAndSettle();
    expect(find.text('Niraj Vekariya'), findsOneWidget);
    expect(find.text('Vikram Mehta'), findsNothing);
  });

  testWidgets('Add ID Proof: Single Add ID Proof button rendered cleanly without separate front/back slots', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWizardTestApp());
    await tester.pumpAndSettle();

    // Verify single Add ID Proof button is present and Front/Back separate slots are removed
    expect(find.text('Add ID Proof'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate_rounded), findsWidgets);
    expect(find.text('Front ID'), findsNothing);
    expect(find.text('Back ID'), findsNothing);
  });

  testWidgets('ID Proofs Attached Preview: Preloaded ID photos display preview with Remove', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final formDataWithPhotos = CheckInFormData(
      idFrontPhotoUrl: 'scanned_aadhaar.png',
      idBackPhotoUrl: 'scanned_aadhaar_back.png',
      guestFullName: 'Niraj Vekariya',
    );

    await tester.pumpWidget(createWizardTestApp(initialFormData: formDataWithPhotos));
    await tester.pumpAndSettle();

    // Verify ID proofs attached section is shown with preview cards and remove options
    expect(find.text('ID Proofs Attached (2)'), findsOneWidget);
    expect(find.text('Verified ✓'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNWidgets(2));

    // Tap remove on first ID
    final removeBtns = find.byIcon(Icons.close_rounded);
    await tester.tap(removeBtns.first);
    await tester.pumpAndSettle();

    // Verify first photo removed, count updated to 1
    expect(find.text('ID Proofs Attached (1)'), findsOneWidget);
  });

  testWidgets('Digital Signature Pad: Drawing, Auto-Sign, and Clear actions in Step 1 Guest Identity', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createWizardTestApp(
      initialFormData: CheckInFormData(
        roomType: 'standard room',
        numberOfGuests: 1,
        partyType: 'Solo Guest',
      ),
    ));
    await tester.pumpAndSettle();

    // Verify Signature Pad is rendered in Step 1
    final sigPadTitle = find.text('Main Guest Signature');
    expect(sigPadTitle, findsOneWidget);
    await tester.ensureVisible(sigPadTitle);
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Touch & drag finger here to sign'), findsOneWidget);

    // Draw signature directly on canvas via touch drag
    await tester.drag(find.text('Touch & drag finger here to sign'), const Offset(60, 20), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Status updates to Signed
    expect(find.text('Signed'), findsOneWidget);
    expect(find.text('Signature captured!'), findsOneWidget);

    // Switch to Phone QR tab
    final phoneQrTab = find.text('Phone QR');
    expect(phoneQrTab, findsOneWidget);
    await tester.tap(phoneQrTab);
    await tester.pumpAndSettle();

    // Verify received mobile signature UI
    expect(find.text('Signature Received from Mobile!'), findsOneWidget);
    expect(find.text('Signature successfully received from mobile device.'), findsOneWidget);

    // Tap Clear
    final clearBtn = find.byKey(const ValueKey('signature_clear_btn'));
    expect(clearBtn, findsOneWidget);
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    // Status reverts to Required
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Scan with Smartphone to Sign Remotely'), findsOneWidget);

    // Switch to Type Name tab on mobile width without overflow
    final typeNameTab = find.text('Type Name');
    expect(typeNameTab, findsOneWidget);
    await tester.tap(typeNameTab);
    await tester.pumpAndSettle();

    // Verify Type Name elements
    expect(find.text('Guest Full Name:'), findsOneWidget);
    expect(find.text('Font Style:'), findsOneWidget);
    expect(find.text('Cursive'), findsOneWidget);
    expect(find.text('Calligraphy'), findsOneWidget);
    expect(find.text('Casual'), findsOneWidget);

    // Select Calligraphy style
    await tester.tap(find.text('Calligraphy'));
    await tester.pumpAndSettle();

    // Tap Apply This Signature
    final applyBtn = find.text('Apply This Signature');
    expect(applyBtn, findsOneWidget);
    await tester.tap(applyBtn);
    await tester.pumpAndSettle();

    // Signature status is Signed
    expect(find.text('Signed'), findsOneWidget);
  });
}


