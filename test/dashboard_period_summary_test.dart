import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/widgets/dashboard_period_summary_card.dart';

void main() {
  testWidgets('Date summary shows collections for the selected dates', (tester) async {
    DateTime? start;
    DateTime? end;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardPeriodSummaryCard(
            loader: ({required DateTime startDate, required DateTime endDate}) async {
              start = startDate;
              end = endDate;
              return const DashboardSummary(
                periodStartDate: '19-10-2026',
                periodEndDate: '19-10-2026',
                totalCollectedAmount: 6600,
                cashCollectedAmount: 6540,
                upiCollectedAmount: 60,
                totalOutstandingAmount: 540,
                totalBookingCount: 2,
                totalGuestCount: 6,
                totalBookingAmount: 7080,
                totalDiscountAmount: 2000,
              );
            },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(start, isNotNull);
    expect(start, end);
    expect(find.text('Date summary'), findsOneWidget);
    expect(find.text('19-10-2026'), findsOneWidget);
    expect(find.text('₹6,600'), findsWidgets);
    expect(find.text('₹540'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('UPI'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('This year'), findsOneWidget);
    expect(find.text('Custom date'), findsOneWidget);
    expect(find.text('Start date'), findsNothing);

    await tester.ensureVisible(find.text('Custom date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom date'));
    await tester.pumpAndSettle();
    expect(find.text('Start date'), findsOneWidget);
    expect(find.text('End date'), findsOneWidget);

    await tester.ensureVisible(find.text('Yesterday'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yesterday'));
    await tester.pumpAndSettle();
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 1));
    expect(find.text('Start date'), findsNothing);
    expect(start, yesterday);
    expect(end, yesterday);
  });
}
