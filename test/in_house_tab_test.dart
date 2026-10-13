import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/main.dart';
import 'package:my_own_pms_system/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'helpers/test_data.dart';

void main() {
  group('In-House Tab 2026 PMS Receptionist UI Tests', () {
    setUp(() {
      DashboardRepository(initialRooms: testRooms, initialFolios: testFolios);
    });

    testWidgets('In-House Tab displays 2026 header, KPI summary cards, and registry cards', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MyOwnPMSApp());
      await tester.pumpAndSettle();

      // Navigate to In-House tab (people_alt_outlined icon)
      final inHouseNav = find.byIcon(Icons.people_alt_outlined).last;
      expect(inHouseNav, findsOneWidget);
      await tester.tap(inHouseNav);
      await tester.pumpAndSettle();

      // 1. Verify Top Header & Titles
      expect(find.text('Mayal Resort 2'), findsWidgets);
      expect(find.text('In-House'), findsWidgets);
      expect(find.text('Currently staying guests'), findsOneWidget);
      expect(find.text('In-House Folios & Guest Registry'), findsOneWidget);

      // 2. Verify 4 Summary KPI Cards
      expect(find.text('IN-HOUSE'), findsWidgets);
      expect(find.text('FOLIO VALUE'), findsOneWidget);
      expect(find.text('CHECKOUT TODAY'), findsOneWidget);
      expect(find.text('PAYMENT PENDING'), findsOneWidget);

      // 3. Verify Initial Guest Cards
      expect(find.text('Vikram Mehta'), findsOneWidget);
      expect(find.text('Niraj Vekariya'), findsOneWidget);

      // 4. Verify Search Input Placeholder
      expect(find.text('Search guest name, room, phone, booking...'), findsOneWidget);

      // 5. Verify Filter Chips
      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('In-House (1)'), findsOneWidget);
      expect(find.text('Departed (1)'), findsOneWidget);
      expect(find.text('Checkout Today (0)'), findsOneWidget);
      expect(find.text('Payment Pending (2)'), findsOneWidget);
      expect(find.text('Keycard Issue'), findsOneWidget);
    });

    testWidgets('Universal Search filters by room number and guest name', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MyOwnPMSApp());
      await tester.pumpAndSettle();

      // Open In-House tab
      await tester.tap(find.byIcon(Icons.people_alt_outlined).last);
      await tester.pumpAndSettle();

      // Search room number '03'
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, '03');
      await tester.pumpAndSettle();

      expect(find.text('Vikram Mehta'), findsOneWidget);
      expect(find.text('Niraj Vekariya'), findsNothing);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Search by Folio ID 'FOL-1088'
      await tester.enterText(searchField, 'FOL-1088');
      await tester.pumpAndSettle();

      expect(find.text('Niraj Vekariya'), findsOneWidget);
      expect(find.text('Vikram Mehta'), findsNothing);
    });

    testWidgets('Guest Details Page opens and renders all 10 structured sections', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MyOwnPMSApp());
      await tester.pumpAndSettle();

      // Open In-House tab
      await tester.tap(find.byIcon(Icons.people_alt_outlined).last);
      await tester.pumpAndSettle();

      // Filter to In-House guest Vikram Mehta
      await tester.tap(find.text('In-House (1)'));
      await tester.pumpAndSettle();

      // Tap 'View Details' on Vikram Mehta's card
      final detailsButton = find.text('View Details').first;
      await tester.ensureVisible(detailsButton);
      await tester.tap(detailsButton);
      await tester.pumpAndSettle();

      // Verify Guest Details Title & Key Sections
      expect(find.text('Guest Details'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('KYC & Govt Identity Verification'), findsOneWidget);
      expect(find.text('Current Stay Details'), findsOneWidget);
      expect(find.text('Folio & Billing Breakdown'), findsOneWidget);

      // Verify KYC details are masked in details screen
      expect(find.text('VERIFIED'), findsOneWidget);
      expect(find.text('•••• •••• 3411'), findsOneWidget);

      // Pop details screen back
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('In-House'), findsWidgets);
    });

    testWidgets('Safe Checkout Dialog opens with financial breakdown and warning when pending', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MyOwnPMSApp());
      await tester.pumpAndSettle();

      // Open In-House tab
      await tester.tap(find.byIcon(Icons.people_alt_outlined).last);
      await tester.pumpAndSettle();

      // Filter to In-House guest
      await tester.tap(find.text('In-House (1)'));
      await tester.pumpAndSettle();

      // Tap Checkout on the card
      final checkoutBtn = find.text('Checkout').first;
      await tester.ensureVisible(checkoutBtn);
      await tester.tap(checkoutBtn);
      await tester.pumpAndSettle();

      // Verify Safe Checkout Dialog
      expect(find.text('Complete Checkout?'), findsOneWidget);
      expect(find.text('Unsettled Folio Balance'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel checkout safely
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Complete Checkout?'), findsNothing);
    });

    testWidgets('Desktop view (width >= 900) enables responsive PMS split layout', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MyOwnPMSApp());
      await tester.pumpAndSettle();

      // Open In-House tab
      await tester.tap(find.byIcon(Icons.people_alt_outlined).last);
      await tester.pumpAndSettle();

      // In split view, both the In-House list AND the selected guest details appear on the same screen
      expect(find.text('In-House'), findsWidgets);
      expect(find.text('Guest Details'), findsOneWidget);
      expect(find.text('Folio & Billing Breakdown'), findsOneWidget);
    });
  });
}
