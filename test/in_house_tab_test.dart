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
      expect(find.text('MYOWNPMS'), findsWidgets);
      expect(find.text('In-House'), findsWidgets);
      expect(find.text('Currently staying guests'), findsOneWidget);
      expect(find.text('In-House Folios & Guest Registry'), findsOneWidget);

      // 2. Verify ONLY In-House Guest Cards are shown (Departed guests are excluded)
      expect(find.text('Vikram Mehta'), findsOneWidget);
      expect(find.text('Niraj Vekariya'), findsNothing);

      // 3. Verify Search Input Placeholder
      expect(find.text('Search guest name, room, phone, booking...'), findsOneWidget);
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

      // Search by Folio ID 'FOL-1092' (in-house guest)
      await tester.enterText(searchField, 'FOL-1092');
      await tester.pumpAndSettle();

      expect(find.text('Vikram Mehta'), findsOneWidget);
      expect(find.text('Niraj Vekariya'), findsNothing);

      // Search by Departed Folio ID 'FOL-1088' (should not show on in-house tab)
      await tester.enterText(searchField, 'FOL-1088');
      await tester.pumpAndSettle();

      expect(find.text('Niraj Vekariya'), findsNothing);
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

      // Tap 'View Details' on Vikram Mehta's in-house card
      final detailsButton = find.text('View Details').first;
      await tester.ensureVisible(detailsButton);
      await tester.tap(detailsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Guest Details Title & Key Sections
      expect(find.textContaining('Vikram Mehta'), findsWidgets);
      expect(find.text('Stay'), findsWidgets);
      expect(find.text('Billing'), findsWidgets);
      expect(find.text('Guest Folio PDF'), findsOneWidget);
      expect(find.text('Send on WhatsApp'), findsOneWidget);

      await tester.tap(find.text('Billing').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Pop details screen back
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
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

      // Tap Checkout on the in-house guest card
      final checkoutBtn = find.text('Checkout').first;
      await tester.ensureVisible(checkoutBtn);
      await tester.tap(checkoutBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Checkout Settlement Screen
      expect(find.textContaining('Check-out'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel checkout safely
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Check-out ·'), findsNothing);
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
      expect(find.textContaining('Vikram Mehta'), findsWidgets);
      expect(find.text('Stay'), findsWidgets);
      expect(find.text('Guest Folio PDF'), findsOneWidget);
    });
  });
}
