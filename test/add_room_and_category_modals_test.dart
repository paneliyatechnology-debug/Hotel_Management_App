import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_own_pms_system/features/dashboard/data/repositories/hotel_admin_repository.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_rooms_tariffs_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RoomsDirectoryMemory.clear();
  });

  testWidgets('Add Category and Add Room modals have improved UI with zero GST calculations', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/room-types')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                '_id': 'cat-1',
                'name': 'Deluxe Room',
                'basePrice': 2500,
                'capacity': {'adults': 2, 'children': 0},
                'bedCount': 1,
                'bedType': '1 King Size Bed',
                'amenities': ['Free High-Speed WiFi'],
                'images': [],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      } else if (request.url.path.endsWith('/rooms')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Physical rooms retrieved successfully.',
            'data': {
              'rooms': [
                {
                  'id': 13,
                  'hotel_id': 2,
                  'room_number': '101',
                  'room_type_id': 22,
                  'room_type_name': 'Deluxe Room',
                  'floor': 1,
                  'status': 'AVAILABLE',
                  'custom_price_per_night': 1000,
                  'amenities': ['High-Speed Wi-Fi'],
                  'is_active': true,
                  'deleted_at': null,
                  'images': [],
                },
              ],
              'total': 1,
              'page': 1,
              'limit': 10,
              'totalPages': 1,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{"success": false}', 400);
    });

    final repo = HotelAdminRepository(client: mockClient);

    await tester.pumpWidget(
      MaterialApp(
        home: AdminRoomsTariffsPage(repository: repo),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Open Add Room Modal
    final addRoomBtn = find.text('Add Room');
    expect(addRoomBtn, findsOneWidget);
    await tester.tap(addRoomBtn);
    await tester.pumpAndSettle();

    // Verify Add Room modal opened
    expect(find.text('Add New Room'), findsOneWidget);
    expect(find.text('ROOM IDENTIFICATION'), findsOneWidget);
    expect(find.text('ROOM TARIFF (NO TAX)'), findsOneWidget);

    // Verify NO GST texts exist
    expect(find.text('Enable GST (Goods & Services Tax)'), findsNothing);
    expect(find.text('LIVE ROOM TAX BREAKDOWN'), findsNothing);
    expect(find.textContaining('CGST'), findsNothing);
    expect(find.textContaining('SGST'), findsNothing);

    // Close modal
    final cancelBtn = find.text('Cancel');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    // Switch to Categories Tab
    await tester.tap(find.textContaining('Categories & Tariffs'));
    await tester.pumpAndSettle();

    // Open Add Category Modal
    final addCategoryBtn = find.text('Add Category');
    expect(addCategoryBtn, findsOneWidget);
    await tester.tap(addCategoryBtn);
    await tester.pumpAndSettle();

    // Verify Add Category modal opened with only required fields (Category Name & Description)
    expect(find.text('Create Room Category'), findsOneWidget);
    // Sheet should sit on the bottom and hug its content, not cover the page.
    expect(tester.getTopLeft(find.text('Create Room Category')).dy, greaterThan(500));
    expect(find.text('Category name'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Optional'), findsOneWidget);
    expect(find.text('PREVIEW'), findsNothing);
    expect(find.text('Quick select'), findsNothing);
    expect(find.text('Save & Create Category'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('categoryNameField')), 'Executive Suite');
    await tester.pump();
    final nameField = tester.widget<TextField>(find.byKey(const Key('categoryNameField')));
    expect(nameField.controller?.text, 'Executive Suite');

    // Verify unneeded fields (Tariff, Capacity, Amenities, GST) are removed
    expect(find.text('BASE TARIFF (PER NIGHT)'), findsNothing);
    expect(find.text('GUEST CAPACITY & BEDS'), findsNothing);
    expect(find.text('Enable GST (Goods & Services Tax)'), findsNothing);
    expect(find.text('LIVE ROOM TAX BREAKDOWN'), findsNothing);
    expect(find.textContaining('CGST'), findsNothing);
    expect(find.textContaining('SGST'), findsNothing);
  });
}
