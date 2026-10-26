import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/main.dart';

void main() {
  group('Receptionist More Tab Tests', () {
    testWidgets('More Tab renders User Profile, Account Information, and Session Sign Out cards', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MyOwnPMSApp());
      await tester.pumpAndSettle();

      // Navigate to More Tab (index 4)
      final moreNav = find.text('More');
      expect(moreNav, findsOneWidget);
      await tester.tap(moreNav);
      await tester.pumpAndSettle();

      // 1. Verify User Profile & Shift Card
      expect(find.text('Tushar Paneliya'), findsOneWidget);
      expect(find.text('Active Shift'), findsOneWidget);
      expect(find.text('Niraj Resort'), findsWidgets);
      expect(find.textContaining('Role: RECEPTIONIST'), findsOneWidget);
      expect(find.text('Front Desk Verified'), findsOneWidget);

      // 2. Verify Account & Hotel Information Card
      expect(find.text('Account & Hotel Information'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('paneliyatechnology@gmail.com'), findsOneWidget);
      expect(find.text('Contact Phone'), findsOneWidget);
      expect(find.text('8849218118'), findsOneWidget);
      expect(find.text('Hotel Property'), findsOneWidget);
      expect(find.textContaining('218, Arth Bussiness Center'), findsOneWidget);
      expect(find.text('Check-In / Out Policy'), findsNothing);
      expect(find.textContaining('Check-In: 14:00 | Check-Out: 12:00'), findsNothing);

      // 3. Verify Account Session & Sign Out Card
      expect(find.text('Account Session & Sign Out'), findsOneWidget);
      expect(find.text('Sign Out / Logout'), findsOneWidget);
    });

    testWidgets('Sign Out / Logout button opens confirmation modal', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MyOwnPMSApp());
      await tester.pumpAndSettle();

      // Open More tab
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // Find and tap Sign Out / Logout
      final signOutFinder = find.text('Sign Out / Logout');
      await tester.ensureVisible(signOutFinder);
      await tester.pumpAndSettle();
      await tester.tap(signOutFinder);
      await tester.pumpAndSettle();

      // Verify sign out confirmation dialog opens
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Confirm Sign Out'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel to dismiss
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Sign Out'), findsNothing);
    });
  });
}
