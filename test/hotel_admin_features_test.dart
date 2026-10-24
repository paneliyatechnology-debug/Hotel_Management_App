import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_own_pms_system/features/dashboard/data/models/admin_models.dart';
import 'package:my_own_pms_system/features/dashboard/data/repositories/hotel_admin_repository.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_daily_collections_page.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_staff_management_page.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_rooms_tariffs_page.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_subscription_page.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_settings_page.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_revenue_reports_page.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/status_rooms_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StaffDirectoryMemory.clear();
    RoomsDirectoryMemory.clear();
    SubscriptionPlansMemory.clear();
    HotelSettingsMemory.clear();
    StatusRoomsMemory.clear();
  });

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

    test('fetchStaffMembers loads GET /users and parses data.users', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/users'));
        expect(request.url.queryParameters['role'], 'RECEPTIONIST');
        expect(request.url.queryParameters['is_active'], 'true');
        expect(request.url.queryParameters['sort_by'], 'created_at');
        expect(request.url.queryParameters['sort_order'], 'desc');
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['limit'], '10');
        expect(request.url.queryParameters.containsKey('hotel_id'), isFalse);
        expect(request.headers['accept'], 'application/json');
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Users retrieved successfully.',
            'data': {
              'users': [
                {
                  'id': 8,
                  'name': 'Tushar Paneliya',
                  'email': 'paneliyatechnology@gmail.com',
                  'phone': '8849218118',
                  'role': 'RECEPTIONIST',
                  'employee_id': 'EMP-7779',
                  'is_active': true,
                  'shift': 'Morning (07:00 - 15:00)',
                }
              ],
              'total': 1,
              'page': 1,
              'limit': 10,
              'total_pages': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);
      final list = await repo.fetchStaffMembers();
      expect(list.length, 1);
      expect(list.first.id, '8');
      expect(list.first.name, 'Tushar Paneliya');
      expect(list.first.employeeId, 'EMP-7779');
      expect(list.first.isActive, true);
    });

    test('fetchStaffMembers returns an empty directory when data.users is empty', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Users retrieved successfully.',
            'data': {
              'users': [],
              'total': 0,
              'page': 1,
              'limit': 10,
              'total_pages': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);
      final list = await repo.fetchStaffMembers();
      expect(list, isEmpty);
    });

    test('createStaffMember posts /users with +91 phone and hotel from the token', () async {
      final header = base64Url.encode(utf8.encode('{"alg":"none"}')).replaceAll('=', '');
      final payload = base64Url
          .encode(utf8.encode(jsonEncode({
            'id': '3',
            'role': 'HOTEL_ADMIN',
            'hotel_id': 2,
            'exp': 1999999999,
          })))
          .replaceAll('=', '');
      SharedPreferences.setMockInitialValues({
        'auth_access_token': '$header.$payload.sig',
      });

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/users');
        expect(request.headers['Accept'], 'application/json');
        expect(request.headers['content-type'], contains('application/json'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Rohit Deshmukh');
        expect(body['email'], 'rohit81056@frontdesk.com');
        expect(body.containsKey('password'), isFalse);
        expect(body['phone'], '+919876543210');
        expect(body['role'], 'RECEPTIONIST');
        expect(body['hotel_id'], 2);
        expect(body['is_active'], true);
        expect(body['must_change_password'], true);
        expect(body.containsKey('shift'), isFalse);
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'User created successfully.',
            'data': {
              'id': 15,
              'name': 'Rohit Deshmukh',
              'email': 'rohit81056@frontdesk.com',
              'phone': '+919876543210',
              'role': 'RECEPTIONIST',
              'must_change_password': true,
              'failed_login_attempts': 0,
              'is_active': true,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);
      final staff = await repo.createStaffMember(
        name: 'Rohit Deshmukh',
        email: 'rohit81056@frontdesk.com',
        phone: '9876543210',
      );
      expect(staff.message, 'User created successfully.');
      expect(staff.staff.id, '15');
      expect(staff.staff.phone, '+919876543210');
      expect(staff.staff.mustChangePassword, isTrue);
      expect(staff.staff.isActive, isTrue);
    });

    test('updateStaffMember puts name, +91 phone, and is_active', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/users/15');
        expect(request.headers['Accept'], 'application/json');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Rohit Deshmukh (Senior Front Desk)');
        expect(body['phone'], '+919876543299');
        expect(body['is_active'], true);
        expect(body.containsKey('email'), isFalse);
        expect(body.containsKey('hotel_id'), isFalse);
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'User updated successfully.',
            'data': {
              'id': 15,
              'name': 'Rohit Deshmukh (Senior Front Desk)',
              'email': 'rohit81056@frontdesk.com',
              'phone': '+919876543299',
              'role': 'RECEPTIONIST',
              'is_active': true,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);
      final staff = await repo.updateStaffMember(
        '15',
        name: 'Rohit Deshmukh (Senior Front Desk)',
        phone: '9876543299',
        isActive: true,
      );
      expect(staff.message, 'User updated successfully.');
      expect(staff.staff.id, '15');
      expect(staff.staff.name, 'Rohit Deshmukh (Senior Front Desk)');
      expect(staff.staff.phone, '+919876543299');
    });

    test('deleteStaffMember sends DELETE /users/:id with no body', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/users/15');
        expect(request.headers['Accept'], 'application/json');
        expect(request.body, isEmpty);
        expect(request.url.queryParameters.containsKey('hotel_id'), isFalse);
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'User deleted successfully.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);
      final message = await repo.deleteStaffMember('15');
      expect(message, 'User deleted successfully.');
    });

    test('fetchRoomTypes returns list of room categories', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/room-types'));
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

    test('updateRoomStatus patches /rooms/{id}/status with only the status', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/rooms/14/status');
        expect(request.headers['content-type'], contains('application/json'));
        expect(request.headers['Accept'], 'application/json');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {'status': 'CLEANING'});
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Room status updated successfully.',
            'data': {
              'id': 14,
              'room_number': '101',
              'room_type_name': 'Family Room',
              'floor': 2,
              'status': 'CLEANING',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);
      final message = await repo.updateRoomStatus('14', 'CLEANING');
      expect(message, 'Room status updated successfully.');
    });
  });

  group('Hotel Admin UI Screens Tests', () {
    testWidgets('AdminDailyCollectionsPage renders dashboard summary sections',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/dashboard/summary'));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'period_start_date': '2026-10-24',
              'period_end_date': '2026-10-24',
              'total_collected_amount': 48500,
              'total_outstanding_amount': 3200,
              'total_booking_count': 12,
              'total_guest_count': 18,
              'total_booking_amount': 52000,
              'total_discount_amount': 2000,
              'total_extra_charges_amount': 800,
              'total_late_checkout_charges_amount': 500,
              'collection_by_payment_method': [
                {
                  'payment_method_id': 5,
                  'name': 'CASH',
                  'is_system': true,
                  'collected_amount': 18500,
                },
                {
                  'payment_method_id': 7,
                  'name': 'UPI',
                  'is_system': true,
                  'collected_amount': 22000,
                },
                {
                  'payment_method_id': 6,
                  'name': 'CARD',
                  'is_system': true,
                  'collected_amount': 6000,
                },
                {
                  'payment_method_id': 8,
                  'name': 'BANK_TRANSFER',
                  'is_system': true,
                  'collected_amount': 0,
                },
              ],
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDailyCollectionsPage(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Collections'), findsOneWidget);
      expect(find.text('TOTAL COLLECTED'), findsOneWidget);
      expect(find.text('Payment Breakdown'), findsOneWidget);
      expect(find.text('Billing Summary'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Guests'), findsOneWidget);
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

    testWidgets('Add Staff posts the users API from the form', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Map<String, dynamic>? created;
      final createClient = MockClient((request) async {
        if (request.method == 'POST') {
          created = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'User created successfully.',
              'data': {
                'id': 15,
                'name': 'Rohit Deshmukh',
                'email': 'rohit81056@frontdesk.com',
                'phone': '+919876543210',
                'role': 'RECEPTIONIST',
                'is_active': true,
                'must_change_password': true,
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'users': [], 'total': 0, 'page': 1, 'limit': 10, 'total_pages': 1},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdminStaffManagementPage(
            repository: HotelAdminRepository(client: createClient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Staff'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Ramesh Patel'), 'Rohit Deshmukh');
      await tester.enterText(find.widgetWithText(TextFormField, 'staff@yourhotel.com'), 'rohit81056@frontdesk.com');
      expect(find.text('Temporary Password *'), findsNothing);
      await tester.enterText(find.widgetWithText(TextFormField, '9820155667'), '9876543210');
      await tester.ensureVisible(find.text('Onboard Staff'));
      await tester.tap(find.text('Onboard Staff'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(created?['name'], 'Rohit Deshmukh');
      expect(created?['email'], 'rohit81056@frontdesk.com');
      expect(created?.containsKey('password'), isFalse);
      expect(created?['phone'], '+919876543210');
      expect(created?['role'], 'RECEPTIONIST');
      expect(created?['is_active'], true);
      expect(created?['must_change_password'], true);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Edit Staff puts name, phone, and is_active', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Map<String, dynamic>? updated;
      String? method;
      String? path;
      final client = MockClient((request) async {
        if (request.method == 'PUT') {
          method = request.method;
          path = request.url.path;
          updated = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'User updated successfully.',
              'data': {
                'id': 15,
                'name': 'Rohit Deshmukh (Senior Front Desk)',
                'phone': '+919876543299',
                'is_active': true,
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'users': [
                {
                  'id': 15,
                  'name': 'Rohit Deshmukh',
                  'email': 'rohit81056@frontdesk.com',
                  'phone': '+919876543210',
                  'role': 'RECEPTIONIST',
                  'is_active': true,
                }
              ],
              'total': 1,
              'page': 1,
              'limit': 10,
              'total_pages': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdminStaffManagementPage(repository: HotelAdminRepository(client: client)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Rohit Deshmukh (Senior Front Desk)');
      await tester.enterText(fields.at(2), '9876543299');
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(method, 'PUT');
      expect(path, '/api/v1/users/15');
      expect(updated?['name'], 'Rohit Deshmukh (Senior Front Desk)');
      expect(updated?['phone'], '+919876543299');
      expect(updated?['is_active'], true);
      expect(updated?.containsKey('email'), isFalse);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Remove confirms and deletes the staff user', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? method;
      String? path;
      var listCalls = 0;
      final client = MockClient((request) async {
        if (request.method == 'DELETE') {
          method = request.method;
          path = request.url.path;
          expect(request.body, isEmpty);
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'User deleted successfully.',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        listCalls++;
        final users = listCalls == 1
            ? [
                {
                  'id': 15,
                  'name': 'Rohit Deshmukh',
                  'email': 'rohit81056@frontdesk.com',
                  'phone': '+919876543210',
                  'role': 'RECEPTIONIST',
                  'is_active': true,
                }
              ]
            : <Map<String, dynamic>>[];
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'users': users,
              'total': users.length,
              'page': 1,
              'limit': 10,
              'total_pages': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdminStaffManagementPage(repository: HotelAdminRepository(client: client)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Staff Member?'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Remove'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(method, 'DELETE');
      expect(path, '/api/v1/users/15');
      await tester.pump(const Duration(seconds: 4));
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

    testWidgets('AdminSubscriptionPage renders monthly plans from the plans API',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/subscription-plans'));
        expect(request.url.queryParameters['billingCycle'], 'MONTHLY');
        expect(request.url.queryParameters['isActive'], 'true');
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['limit'], '10');
        expect(request.url.query, isNot(contains('hotel_id')));
        expect(request.headers['accept'], contains('application/json'));
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Subscription plans retrieved successfully.',
            'data': {
              'is_trial_used': true,
              'plans': [
                {
                  'id': 7,
                  'name': 'Free Trial',
                  'code': 'TRIAL',
                  'billingCycle': 'MONTHLY',
                  'price': 0,
                  'maxRooms': 50,
                  'description': '30-Day Free Trial plan for newly registered hotels.',
                  'badge': 'FREE TRIAL',
                  'isPopular': false,
                  'is_current_plan': false,
                  'is_trial_used': true,
                  'displayOrder': 0,
                  'features': [],
                },
                {
                  'id': 2,
                  'name': 'Professional Resort',
                  'billingCycle': 'MONTHLY',
                  'price': 9999,
                  'maxRooms': 50,
                  'description': 'Designed for mid-size hotels.',
                  'badge': 'MOST POPULAR',
                  'isPopular': true,
                  'is_current_plan': true,
                  'displayOrder': 2,
                  'features': ['Up to 50 Rooms Inventory'],
                },
              ],
            },
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

      expect(find.text('Subscription Plan'), findsOneWidget);
      expect(find.text('Free Trial'), findsNothing);
      expect(find.text('FREE TRIAL'), findsNothing);
      expect(find.text('Professional Resort'), findsOneWidget);
      expect(find.text('MOST POPULAR'), findsOneWidget);
      expect(find.text('Up to 50 Rooms Inventory'), findsOneWidget);
      expect(find.text('Active plan'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Purchase plan'), findsNothing);
    });

    testWidgets('AdminSubscriptionPage purchases the selected plan', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? purchaseUrl;
      String? purchaseMethod;
      String? purchaseBody;
      String? contentType;

      final mockClient = MockClient((request) async {
        if (request.method == 'POST') {
          purchaseUrl = request.url.toString();
          purchaseMethod = request.method;
          purchaseBody = request.body;
          contentType = request.headers['content-type'];
          expect(request.url.path, endsWith('/subscription-plans/2/purchase'));
          expect(request.url.query, isNot(contains('hotel_id')));
          expect(request.headers['accept'], contains('application/json'));
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Subscription plan purchased successfully.',
              'data': {
                'id': 16,
                'plan_id': 1,
                'amount': 9999,
                'billing_cycle': 'MONTHLY',
                'payment_method': 'CASH',
                'status': 'PAID',
                'auto_renew': false,
                'starts_at': '2026-10-16T10:31:21.000Z',
                'ends_at': '2026-11-16T10:31:21.000Z',
                'plan': {
                  'id': 2,
                  'name': 'Professional Resort',
                  'code': 'MONTHLY_PRO',
                  'billingCycle': 'MONTHLY',
                  'price': 9999,
                  'maxRooms': 50,
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'plans': [
                {
                  'id': 2,
                  'name': 'Professional Resort',
                  'billingCycle': 'MONTHLY',
                  'price': 9999,
                  'maxRooms': 50,
                  'badge': 'MOST POPULAR',
                  'isPopular': true,
                  'displayOrder': 1,
                  'features': ['Up to 50 Rooms Inventory'],
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        MaterialApp(home: AdminSubscriptionPage(repository: HotelAdminRepository(client: mockClient))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Purchase plan'));
      await tester.pumpAndSettle();
      expect(find.text('Purchase Professional Resort?'), findsOneWidget);

      await tester.tap(find.text('Confirm purchase'));
      await tester.pumpAndSettle();

      expect(purchaseMethod, 'POST');
      expect(purchaseUrl, contains('/subscription-plans/2/purchase'));
      expect(purchaseUrl, isNot(contains('hotel_id')));
      expect(purchaseBody, isEmpty);
      expect(contentType, isNull);
      expect(find.text('Plan purchased'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('16 Oct 2026'), findsOneWidget);
      expect(find.text('16 Nov 2026'), findsOneWidget);
    });

    testWidgets('AdminSettingsPage renders operating timings, GST and bank details',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      http.Request? saved;
      final mockClient = MockClient((request) async {
        if (request.method == 'PUT' && request.url.path.endsWith('/hotels/me')) {
          saved = request;
          expect(request.headers['accept'], contains('application/json'));
          expect(request.headers['content-type'], contains('multipart/form-data'));
          expect(request.url.query, isNot(contains('hotel_id')));
          expect(request.body, contains('Niraj Resort'));
          expect(request.body, contains('Ahmedabad'));
          expect(request.body, contains('name="gst_enabled"'));
          expect(request.body, contains('Free WiFi'));
          expect(request.body, isNot(contains('name="phone"')));
          return http.Response(
            jsonEncode({'success': true, 'message': 'Hotel updated'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/auth/me'));
        expect(request.headers['accept'], contains('application/json'));
        expect(request.url.query, isNot(contains('hotel_id')));
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'User profile retrieved successfully.',
            'data': {
              'id': 3,
              'name': 'Niraj Vekariya',
              'email': 'nirajvekariya2209@gmail.com',
              'phone': '9426886960',
              'role': 'HOTEL_ADMIN',
              'hotel': {
                'id': 2,
                'name': 'Niraj Resort',
                'address': 'ABC Complex, Nikol',
                'city': 'Ahmedabad',
                'state': 'Gujarat',
                'country': 'India',
                'pincode': '302006',
                'gst_number': '08AAAAA1234A1Z5',
                'pan_number': 'ABCDE1234F',
                'bank_name': '',
                'bank_account_holder': '',
                'bank_account_number': '',
                'bank_ifsc_code': '',
                'bank_branch': '',
                'hotel_type': 'Resort',
                'website': '',
                'settings': {
                  'check_in_time': '14:00',
                  'check_out_time': '12:00',
                  'timezone': 'Asia/Kolkata',
                  'currency': 'INR',
                  'tax_percentage': 18,
                  'gst_enabled': true,
                  'upi_id': '',
                  'late_checkout_grace_minutes': 10,
                  'amenities': ['Free WiFi', '24/7 Room Service', 'Air Conditioning'],
                  'policies': ['Valid Government ID required at check-in', 'No smoking in standard rooms'],
                },
                'owner': {
                  'id': 3,
                  'name': 'Niraj Vekariya',
                  'email': 'nirajvekariya2209@gmail.com',
                  'phone': '9426886960',
                },
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: AdminSettingsPage(repository: HotelAdminRepository(client: mockClient)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hotel Settings & Policies'), findsOneWidget);
      expect(find.text('Hotel logo'), findsOneWidget);
      expect(find.text('Hotel name'), findsOneWidget);
      expect(find.text('Niraj Resort'), findsOneWidget);
      expect(find.text('Owner name'), findsOneWidget);
      expect(find.text('Niraj Vekariya'), findsOneWidget);
      expect(find.text('Hotel email'), findsOneWidget);
      expect(find.text('nirajvekariya2209@gmail.com'), findsOneWidget);
      expect(find.text('Mobile number'), findsOneWidget);
      expect(find.text('9426886960'), findsOneWidget);
      expect(find.text('ABC Complex, Nikol'), findsOneWidget);
      expect(find.text('Ahmedabad'), findsOneWidget);
      expect(find.text('08AAAAA1234A1Z5'), findsOneWidget);
      expect(find.text('Operating Timings'), findsOneWidget);
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
      expect(find.text('GST %'), findsOneWidget);
      expect(find.text('GST enabled'), findsOneWidget);
      expect(find.text('Free WiFi, 24/7 Room Service, Air Conditioning'), findsOneWidget);
      expect(find.text('Save Hotel Settings'), findsOneWidget);

      await tester.tap(find.text('Save Hotel Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(saved, isNotNull);
      expect(saved!.method, 'PUT');
      await tester.pump(const Duration(seconds: 4));
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
