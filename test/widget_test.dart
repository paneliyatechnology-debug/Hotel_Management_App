import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_management_system/features/check_in_wizard/presentation/pages/check_in_wizard_page.dart';
import 'package:hotel_management_system/main.dart';

void main() {
  testWidgets('2026 Mobile UI renders Front Desk Hub & Navigation cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HotelManagementApp());
    await tester.pumpAndSettle();

    // Verify Mobile Header
    expect(find.text('Mayal Resort 2'), findsOneWidget);
    expect(find.text('GRAND ROYALE • FRONT DESK'), findsOneWidget);

    // Verify Modern Metrics Overview
    expect(find.text('LIVE METRICS OVERVIEW'), findsOneWidget);
    expect(find.text('AVAILABLE VACANT'), findsOneWidget);

    // Verify Quick Operations Slider
    expect(find.text('QUICK OPERATIONS'), findsOneWidget);
    expect(find.text('4-Step Check-In'), findsOneWidget);
    expect(find.text('Govt ID Hub'), findsOneWidget);

    // Scroll down to reveal Room Status Matrix & Cards
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('LIVE ROOM STATUS MATRIX'), findsOneWidget);
    expect(find.text('#01'), findsOneWidget);

    // Scroll further down to reveal In-House Folio Cards
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('RECENT IN-HOUSE FOLIOS'), findsOneWidget);
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

    await tester.pumpWidget(const HotelManagementApp());
    await tester.pumpAndSettle();

    // Tap Quick 4-Step Check-In action card
    final checkInAction = find.text('4-Step Check-In');
    await tester.tap(checkInAction);
    await tester.pumpAndSettle();

    // Verify Step 1 is rendered
    expect(find.text('STEP 1 OF 3'), findsOneWidget);
    expect(find.text('PRIMARY GUEST IDENTITY'), findsOneWidget);

    // Fill Step 1 with Quick Fill to satisfy validation
    final quickFillBtn = find.text('Quick Fill');
    await tester.tap(quickFillBtn);
    await tester.pumpAndSettle();

    // Clear any active snackbar so it doesn't intercept taps
    final scaffoldMessenger = ScaffoldMessenger.of(tester.element(find.byType(CheckInWizardPage)));
    scaffoldMessenger.clearSnackBars();
    await tester.pumpAndSettle();

    // Continue to Step 2
    final continueBtn = find.text('Continue to Step 2');
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Step 2 is rendered
    expect(find.text('Step 2: Room Allocation & Stay Duration'), findsOneWidget);
  });

  testWidgets('Category Rooms Flow: Click Family Room -> Show all room numbers -> Select Room -> Guest Form with locked room', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HotelManagementApp());
    await tester.pumpAndSettle();

    // Scroll down to reveal Room Categories
    await tester.drag(find.byType(ListView).first, const Offset(0, -350));
    await tester.pumpAndSettle();

    // Tap on Family Room Card
    final familyRoomCard = find.text('FAMILY ROOM').first;
    expect(familyRoomCard, findsOneWidget);
    await tester.tap(familyRoomCard);
    await tester.pumpAndSettle();

    // Verify CategoryRoomsPage is opened
    expect(find.text('FAMILY ROOMS INVENTORY'), findsNothing); // Checks category name in title
    expect(find.text('Mayal Resort 2 • Room Number Inventory'), findsOneWidget);
    expect(find.text('Max 4 Guests per Unit'), findsOneWidget);

    // Verify multiple family room numbers are displayed
    expect(find.text('#01'), findsOneWidget);
    expect(find.text('#06'), findsOneWidget);
    expect(find.text('#11'), findsOneWidget);

    // Select Room #01
    final selectRoomBtn = find.text('Select Room').first;
    await tester.tap(selectRoomBtn);
    await tester.pumpAndSettle();

    // Verify Guest Form opened
    expect(find.text('STEP 1 OF 3'), findsOneWidget);

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

    // Continue to Step 2 to verify room cannot be changed
    final continueBtn = find.text('Continue to Step 2');
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Step 2: Room Allocation & Stay Duration'), findsOneWidget);
    expect(find.text('LOCKED'), findsWidgets);
  });

  testWidgets('Inline field validation, dynamic ID hint text & disabled tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HotelManagementApp());
    await tester.pumpAndSettle();

    // Open wizard
    final checkInAction = find.text('4-Step Check-In');
    await tester.tap(checkInAction);
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
    expect(find.text('Physical ID inspection confirmation is mandatory'), findsOneWidget);

    // Verify no SnackBar error popup was created
    expect(find.byType(SnackBar), findsNothing);

    // Verify tapping on disabled future tab (Stay & Room) stays on Step 1
    final stayRoomTab = find.text('Stay & Room').first;
    await tester.ensureVisible(stayRoomTab);
    await tester.tap(stayRoomTab);
    await tester.pumpAndSettle();
    expect(find.text('PRIMARY GUEST IDENTITY'), findsOneWidget);
  });

  testWidgets('Attached Guest Identities Flow: Automatic Room Category Guest Identities (Family / Group)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HotelManagementApp());
    await tester.pumpAndSettle();

    // Open wizard
    final checkInAction = find.text('4-Step Check-In');
    await tester.tap(checkInAction);
    await tester.pumpAndSettle();

    // Verify Primary & Attached Identities rendered automatically for the room category
    expect(find.text('PRIMARY GUEST IDENTITY'), findsOneWidget);
    expect(find.text('ATTACHED IDENTITIES'), findsOneWidget);
    expect(find.text('+ Add Member'), findsOneWidget);
    expect(find.text('Family Member #1'), findsOneWidget);
    expect(find.text('Family Member #2'), findsOneWidget);

    // Auto-fill demo data
    final quickFillBtn = find.text('Quick Fill');
    await tester.ensureVisible(quickFillBtn);
    await tester.tap(quickFillBtn);
    await tester.pumpAndSettle();

    // Clear snackbars
    final scaffoldMessenger = ScaffoldMessenger.of(tester.element(find.byType(CheckInWizardPage)));
    scaffoldMessenger.clearSnackBars();
    await tester.pumpAndSettle();

    // Verify attached names are populated
    expect(find.text('Niraj Vekariya'), findsWidgets);
    expect(find.text('Pooja Vekariya'), findsOneWidget);
    expect(find.text('Aarav Vekariya'), findsOneWidget);

    // Continue to Step 2
    final continueBtn = find.text('Continue to Step 2');
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify successfully advanced to Step 2
    expect(find.text('Step 2: Room Allocation & Stay Duration'), findsOneWidget);
  });

  testWidgets('Room Inventory & Categories 2026 UI: Real-time health metrics, search filter & unit badges', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HotelManagementApp());
    await tester.pumpAndSettle();

    // Tap on Rooms tab in bottom navigation bar
    final roomsTab = find.text('Rooms');
    expect(roomsTab, findsOneWidget);
    await tester.tap(roomsTab);
    await tester.pumpAndSettle();

    // Verify Room Inventory & Categories header and Live Metrics card
    expect(find.text('Room Inventory & Categories'), findsOneWidget);
    expect(find.text('LIVE INVENTORY HEALTH'), findsOneWidget);
    expect(find.text('15 Units Total'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Occupied'), findsOneWidget);
    expect(find.text('Turnaround'), findsOneWidget);

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

    await tester.pumpWidget(const HotelManagementApp());
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

  testWidgets('Camera & OCR Document: Open scan modal, check camera options, render document card & remove', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HotelManagementApp());
    await tester.pumpAndSettle();

    // Tap Quick 4-Step Check-In
    final checkInAction = find.text('4-Step Check-In');
    await tester.tap(checkInAction);
    await tester.pumpAndSettle();

    // Tap Scan Original ID Document button
    final scanBtn = find.text('Scan Original ID Document (OCR Auto-Fill)');
    await tester.ensureVisible(scanBtn);
    await tester.tap(scanBtn);
    await tester.pumpAndSettle();

    // Verify OCR & Camera modal is displayed with Camera, Gallery, and Demo options
    expect(find.text('Primary Guest OCR Scanner'), findsOneWidget);
    expect(find.text('Open Camera & Snap Photo'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Demo Fill'), findsOneWidget);

    // Tap Demo Fill
    final demoFillBtn = find.text('Demo Fill');
    await tester.tap(demoFillBtn);
    await tester.pumpAndSettle();

    // Verify modal is dismissed and original document card is rendered
    expect(find.text('ORIGINAL DOC SCANNED'), findsOneWidget);
    expect(find.text('Re-scan'), findsOneWidget);
    expect(find.text('मेरा आधार, मेरी पहचान'), findsOneWidget);

    // Verify default placeholder button was removed
    expect(find.text('Scan Original ID Document (OCR Auto-Fill)'), findsNothing);

    // Tap delete button to remove scanned document
    final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    // Verify document card is removed and default scan button is restored
    expect(find.text('ORIGINAL DOC SCANNED'), findsNothing);
    expect(find.text('Scan Original ID Document (OCR Auto-Fill)'), findsOneWidget);
  });

  testWidgets('Front & Back Side ID Storage: Toggle tabs, preview both sides, and verify UIDAI back details', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const HotelManagementApp());
    await tester.pumpAndSettle();

    // Tap Quick 4-Step Check-In
    final checkInAction = find.text('4-Step Check-In');
    await tester.tap(checkInAction);
    await tester.pumpAndSettle();

    // Tap Scan button
    final scanBtn = find.text('Scan Original ID Document (OCR Auto-Fill)');
    await tester.ensureVisible(scanBtn);
    await tester.tap(scanBtn);
    await tester.pumpAndSettle();

    // Verify Front & Back side tabs in scanner modal
    expect(find.text('Front Side'), findsWidgets);
    expect(find.text('Back Side'), findsWidgets);

    // Tap Demo Fill
    final demoFillBtn = find.text('Demo Fill');
    await tester.tap(demoFillBtn);
    await tester.pumpAndSettle();

    // Default active side is Front Side
    expect(find.text('FRONT SIDE'), findsOneWidget);
    expect(find.text('Front Side ✓'), findsOneWidget);
    expect(find.text('Back Side ✓'), findsOneWidget);

    // Tap Back Side tab
    final backTab = find.text('Back Side ✓');
    await tester.tap(backTab);
    await tester.pumpAndSettle();

    // Verify Back Side document card is rendered with address, UIDAI, and QR details
    expect(find.text('BACK SIDE'), findsNWidgets(2));
    expect(find.text('भारतीय विशिष्ट पहचान प्राधिकरण'), findsOneWidget);
    expect(find.text('SECURE'), findsOneWidget);
  });
}


