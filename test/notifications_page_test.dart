import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/features/notifications/presentation/pages/notifications_page.dart';

void main() {
  testWidgets('NotificationsPage renders header, search, filter chips, and alerts', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationsPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar Title & subtitle
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Live Front Desk & System Alerts'), findsOneWidget);

    // Verify search bar exists
    expect(find.byType(TextField), findsOneWidget);

    // Verify filter chips
    expect(find.text('All (6)'), findsOneWidget);
    expect(find.text('Unread (3)'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(find.text('Billing (2)'), findsOneWidget);

    // Verify notification titles
    expect(find.text('Pending Settlement Overdue'), findsOneWidget);
    expect(find.text('Express Check-In Completed'), findsOneWidget);
    expect(find.text('Housekeeping Service Requested'), findsOneWidget);

    // Tap on Unread filter chip
    await tester.tap(find.textContaining('Unread'));
    await tester.pumpAndSettle();

    // Verify unread items are still present
    expect(find.text('Pending Settlement Overdue'), findsOneWidget);
  });
}
