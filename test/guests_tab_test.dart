import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/features/guests/data/repositories/guests_repository.dart';
import 'package:my_own_pms_system/features/guests/presentation/bloc/guests_bloc.dart';
import 'package:my_own_pms_system/features/guests/presentation/bloc/guests_event.dart';
import 'package:my_own_pms_system/features/guests/presentation/pages/guests_tab_screen.dart';
import 'package:my_own_pms_system/main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Widget createGuestsTestApp() {
  final repo = GuestsRepository();
  return BlocProvider<GuestsBloc>(
    create: (_) => GuestsBloc(repository: repo)..add(const LoadGuestsEvent()),
    child: const MaterialApp(
      home: GuestsTabScreen(),
    ),
  );
}

void main() {
  testWidgets('Guests Tab 2026 UI: Universal search, Status chips & Guest card list', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MyOwnPMSApp());
    await tester.pumpAndSettle();

    // Tap Guests tab in bottom navigation (Index 3)
    final guestsNav = find.byIcon(Icons.badge_outlined);
    expect(guestsNav, findsOneWidget);
    await tester.tap(guestsNav);
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Guests'), findsWidgets);
    expect(find.text('Search and manage guest records'), findsOneWidget);

    // Verify Universal Search Bar Placeholder
    expect(find.text('Search guest name, mobile, email, room...'), findsOneWidget);

    // Verify Status Filter Chips
    expect(find.text('All (128)'), findsOneWidget);
    expect(find.text('In-House (8)'), findsOneWidget);
    expect(find.text('Checked-Out (120)'), findsOneWidget);

    // Verify Prominent Guest cards
    expect(find.text('Rahul Sharma'), findsWidgets);
    expect(find.text('Priya Patel'), findsWidgets);
  });

  testWidgets('Universal Search & Empty State with Clear Filters', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createGuestsTestApp());
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);

    // 1. Search by name 'Rahul'
    await tester.enterText(searchField, 'Rahul');
    await tester.pumpAndSettle();
    expect(find.text('Rahul Sharma'), findsWidgets);
    expect(find.text('Priya Patel'), findsNothing);

    // 2. Search by mobile '9876543210'
    await tester.enterText(searchField, '9876543210');
    await tester.pumpAndSettle();
    expect(find.text('Rahul Sharma'), findsWidgets);
    expect(find.text('Priya Patel'), findsNothing);

    // 3. Search by room '203'
    await tester.enterText(searchField, '203');
    await tester.pumpAndSettle();
    expect(find.text('Rahul Sharma'), findsWidgets);

    // 4. Search by Booking ID 'BK-1024'
    await tester.enterText(searchField, 'BK-1024');
    await tester.pumpAndSettle();
    expect(find.text('Rahul Sharma'), findsWidgets);

    // 5. Search non-matching term to trigger Empty State
    await tester.enterText(searchField, 'XYZUnknownGuest999');
    await tester.pumpAndSettle();
    expect(find.text('No guests found'), findsOneWidget);
    expect(find.text('Try a different name, mobile number, email or date range.'), findsOneWidget);

    // 6. Tap Clear Filters button in empty state
    final clearBtn = find.text('Clear Filters');
    expect(clearBtn, findsOneWidget);
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    // Returns full list
    expect(find.text('Rahul Sharma'), findsWidgets);
    expect(find.text('Priya Patel'), findsWidgets);
  });

  testWidgets('Status filter tabs (In-House & Checked-Out)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createGuestsTestApp());
    await tester.pumpAndSettle();

    // Tap In-House filter chip
    await tester.tap(find.text('In-House (8)'));
    await tester.pumpAndSettle();

    // In-House guest visible, Checked-Out guest hidden
    expect(find.text('Rahul Sharma'), findsWidgets);
    expect(find.text('Sneha Kulkarni'), findsNothing);

    // Tap Checked-Out filter chip
    final checkedOutChip = find.text('Checked-Out (120)');
    await tester.ensureVisible(checkedOutChip);
    await tester.tap(checkedOutChip);
    await tester.pumpAndSettle();

    // Checked-Out guest visible, In-House guest hidden
    expect(find.text('Priya Patel'), findsWidgets);
    expect(find.text('Rahul Sharma'), findsNothing);
  });

  testWidgets('Date filter bottom sheet with quick filters & custom date range', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createGuestsTestApp());
    await tester.pumpAndSettle();

    // Tap Date filter button
    final dateFilterBtn = find.text('Date');
    expect(dateFilterBtn, findsOneWidget);
    await tester.tap(dateFilterBtn);
    await tester.pumpAndSettle();

    // Verify modal options
    expect(find.text('Filter by Date'), findsOneWidget);
    expect(find.text('QUICK DATE FILTERS'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);
    expect(find.text('This Year'), findsOneWidget);
    expect(find.text('Last Week'), findsOneWidget);
    expect(find.text('Last Month'), findsOneWidget);
    expect(find.text('Last Year'), findsOneWidget);

    expect(find.text('CUSTOM DATE RANGE'), findsOneWidget);
    expect(find.text('From Date'), findsOneWidget);
    expect(find.text('To Date'), findsOneWidget);
    expect(find.text('Apply Filter'), findsOneWidget);
  });

  testWidgets('Advanced Filters bottom sheet: Guest, Room, Stay, Status, Payment', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createGuestsTestApp());
    await tester.pumpAndSettle();

    // Tap Filters button
    final filtersBtn = find.text('Filters');
    expect(filtersBtn, findsOneWidget);
    await tester.tap(filtersBtn);
    await tester.pumpAndSettle();

    // Verify sections
    expect(find.text('Filter Guests'), findsOneWidget);
    expect(find.text('GUEST DETAILS'), findsOneWidget);
    expect(find.text('ROOM INFORMATION'), findsOneWidget);

    // Scroll down inside filter sheet
    await tester.drag(find.byType(ListView).last, const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(find.text('STAY STATUS'), findsOneWidget);
    expect(find.text('PAYMENT STATUS'), findsNothing);
    expect(find.text('Room Category'), findsNothing);
    expect(find.text('Cancelled'), findsNothing);
    expect(find.text('Clear All'), findsOneWidget);
    expect(find.text('Apply Filters'), findsOneWidget);
  });

  testWidgets('Guest Details: KYC Verification, Current Stay, Multi-Year History (2024-2026) & Stay Modal', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createGuestsTestApp());
    await tester.pumpAndSettle();

    // Tap on Rahul Sharma's card
    final rahulCard = find.text('Rahul Sharma').first;
    await tester.tap(rahulCard);
    await tester.pumpAndSettle();

    expect(find.text('Guest Details'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsWidgets);
    expect(find.text('IN-HOUSE'), findsWidgets);
    expect(find.textContaining('Room #203'), findsWidgets);

    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('rahul@gmail.com'), findsOneWidget);

    expect(find.text('KYC & Govt Identity Verification'), findsOneWidget);
    expect(find.text('VERIFIED'), findsOneWidget);
    expect(find.text('AADHAAR CARD'), findsOneWidget);
    expect(find.text('•••• •••• 4819'), findsOneWidget);
    expect(find.text('Guest Folio PDF'), findsOneWidget);
  });
}

