import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_own_pms_system/features/dashboard/data/models/admin_models.dart';
import 'package:my_own_pms_system/features/dashboard/data/repositories/hotel_admin_repository.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_daily_collections_page.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_staff_management_page.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_rooms_tariffs_page.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_subscription_page.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_settings_page.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_revenue_reports_page.dart';

void main() {
  group('HotelAdminRepository Live API Contract Tests', () {
    test('fetchDailyCollections returns telemetry and transactions correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/api/v1/admin/daily-collections'));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'telemetry': {
                'todayGross': 5000,
                'todayCash': 3000,
                'todayUpi': 2000,
                'cashInDrawer': 3000,
                'totalVaultSettled': 50000,
                'unsettledCount': 2,
              },
              'transactions': [
                {
                  '_id': 'tx-1',
                  'receiptNumber': 'RCP-1001',
                  'guestName': 'Niraj Vekariya',
                  'roomNumber': '101',
                  'paymentMethod': 'CASH',
                  'total': 3000,
                  'status': 'PAID',
                }
              ]
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);
      final res = await repo.fetchDailyCollections();
      final telemetry = res['telemetry'] as DailyCollectionsTelemetry;
      final txs = res['transactions'] as List<AdminPaymentTransaction>;

      expect(telemetry.todayGross, 5000);
      expect(telemetry.cashInDrawer, 3000);
      expect(telemetry.todayUpi, 2000);
      expect(txs.length, 1);
      expect(txs.first.guestName, 'Niraj Vekariya');
      expect(txs.first.paymentMethod, 'CASH');
    });

    test('settleHandover posts notes and returns success payload', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, contains('/api/v1/admin/daily-collections/handover'));
        final body = jsonDecode(request.body);
        expect(body['notes'], 'Shift Close Handover');
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Cash drawer successfully settled! Front desk counter reset to 0.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);
      final res = await repo.settleHandover(notes: 'Shift Close Handover');
      expect(res['success'], true);
      expect(res['message'], contains('successfully settled'));
    });

    test('fetchStaffMembers returns parsed list of staff', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/api/v1/admin/receptionists'));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                '_id': 'staff-1',
                'name': 'Tushar Paneliya',
                'email': 'paneliyatechnology@gmail.com',
                'phone': '8849218118',
                'role': 'RECEPTIONIST',
                'employeeId': 'EMP-7779',
                'status': 'ACTIVE',
                'shift': 'Morning (07:00 - 15:00)',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);
      final list = await repo.fetchStaffMembers();
      expect(list.length, 1);
      expect(list.first.name, 'Tushar Paneliya');
      expect(list.first.employeeId, 'EMP-7779');
      expect(list.first.isActive, true);
    });

    test('createStaffMember sends clean 10 digit phone and fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, contains('/api/v1/admin/receptionists'));
        final body = jsonDecode(request.body);
        expect(body['name'], 'New Staff');
        expect(body['phone'], '9876543210');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              '_id': 'staff-2',
              'name': 'New Staff',
              'email': 'staff@hotel.com',
              'phone': '9876543210',
              'employeeId': 'EMP-8888',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);
      final staff = await repo.createStaffMember(
        name: 'New Staff',
        email: 'staff@hotel.com',
        phone: '+91 98765 43210',
      );
      expect(staff.staff.id, 'staff-2');
      expect(staff.staff.employeeId, 'EMP-8888');
    });

    test('fetchRoomTypes returns list of room categories', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/api/v1/admin/room-types'));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                '_id': 'cat-1',
                'hotel': 'hotel-1',
                'name': 'DELUX ROOM',
                'basePrice': 2099,
                'bedCount': 1,
                'bedType': '1 King Size Bed',
                'capacity': {'adults': 2, 'children': 0},
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);
      final types = await repo.fetchRoomTypes();
      expect(types.length, 1);
      expect(types.first.name, 'DELUX ROOM');
      expect(types.first.basePrice, 2099);
      expect(types.first.adults, 2);
    });
  });

  group('Hotel Admin UI Screens Tests', () {
    testWidgets('AdminDailyCollectionsPage renders telemetry cards & handover button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'telemetry': {
                'todayGross': 1000,
                'todayCash': 1000,
                'todayUpi': 0,
                'cashInDrawer': 1000,
                'totalVaultSettled': 74570,
                'unsettledCount': 1,
              },
              'transactions': []
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = HotelAdminRepository(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDailyCollectionsPage(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Collections & Handover'), findsOneWidget);
      expect(find.text('Front Desk Cash Drawer'), findsOneWidget);
      expect(find.text('Handover Cash to Vault'), findsOneWidget);
      expect(find.text('Total Historical Vault Settled'), findsOneWidget);
      expect(find.text('Recent Receipts Log'), findsOneWidget);
    });

    testWidgets('AdminStaffManagementPage renders staff directory & add staff button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                '_id': 'st-1',
                'name': 'Tushar Paneliya',
                'email': 'tushar@test.com',
                'phone': '8849218118',
                'employeeId': 'EMP-7779',
                'status': 'ACTIVE',
                'shift': 'Morning (07:00 - 15:00)',
                'role': 'RECEPTIONIST',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminStaffManagementPage(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Staff Management'), findsOneWidget);
      expect(find.text('Add Staff'), findsOneWidget);
      expect(find.text('Tushar Paneliya'), findsOneWidget);
      expect(find.text('EMP-7779'), findsOneWidget);
    });

    testWidgets('AdminRoomsTariffsPage renders rooms inventory and categories tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/rooms')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  '_id': 'rm-1',
                  'roomNumber': '101',
                  'floor': 1,
                  'status': 'AVAILABLE',
                  'roomType': 'Deluxe Room',
                  'pricePerNight': 2099,
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  '_id': 'cat-1',
                  'name': 'DELUX ROOM',
                  'basePrice': 2099,
                  'capacity': {'adults': 2, 'children': 0},
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
      });

      final repo = HotelAdminRepository(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminRoomsTariffsPage(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rooms & Tariffs Management'), findsOneWidget);
      expect(find.textContaining('Rooms Inventory'), findsOneWidget);
      expect(find.textContaining('Categories & Tariffs'), findsOneWidget);
      expect(find.text('Room 101'), findsOneWidget);
    });

    testWidgets('AdminSubscriptionPage renders subscription details & progress bar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'subscription': {
                'plan': 'PREMIUM',
                'status': 'TRIAL',
                'daysLeft': 386,
                'totalDays': 395,
                'elapsedDays': 10,
                'elapsedPercentage': 3,
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminSubscriptionPage(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subscription & Plan'), findsOneWidget);
      expect(find.text('PREMIUM PLAN'), findsOneWidget);
      expect(find.text('386 Days Left'), findsOneWidget);
      expect(find.text('Request Trial Extension'), findsOneWidget);
    });

    testWidgets('AdminSettingsPage renders operating timings, GST and bank details',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'settings': {
                'checkInTime': '14:00',
                'checkOutTime': '12:00',
                'timezone': 'Asia/Kolkata',
                'upiId': 'hotel@upi',
                'gstEnabled': true,
                'bankDetails': {
                  'bankName': 'HDFC Bank',
                  'accountNumber': '1234567890',
                }
              }
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminSettingsPage(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hotel Settings & Policies'), findsOneWidget);
      expect(find.text('Operating Timings'), findsOneWidget);
      expect(find.text('Tax & GST Invoicing'), findsOneWidget);
      expect(find.text('Save Hotel Settings'), findsOneWidget);
    });

    testWidgets('AdminRevenueReportsPage renders revenue stream breakdown and transactions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('revenue-details')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'totalRevenue': 65070,
                'totalTransactions': 22,
                'dateRange': {'label': '05 Oct 2026 - 10 Oct 2026'},
                'revenueBreakdown': {
                  'roomBooking': 65070,
                  'foodRestaurant': 0,
                  'extraServices': 0,
                },
                'transactions': [
                  {
                    'id': 'tx-1',
                    'receiptNumber': 'RCP-152187',
                    'guestName': 'Tushar',
                    'roomNumber': '101',
                    'paymentMethod': 'UPI',
                    'total': 1080,
                  }
                ]
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'totalRevenue': 65070,
                'paymentBreakdown': [
                  {'_id': 'UPI', 'total': 37730, 'count': 14},
                  {'_id': 'CASH', 'total': 37840, 'count': 12},
                ]
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
      });

      final repo = HotelAdminRepository(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminRevenueReportsPage(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Revenue Reports & Analytics'), findsOneWidget);
      expect(find.text('AUDITED REVENUE'), findsOneWidget);
      expect(find.text('Revenue Stream Breakdown'), findsOneWidget);
      expect(find.text('Payment Channels Volume'), findsOneWidget);
      expect(find.text('Audited Transaction Ledger'), findsOneWidget);
    });
  });
}
