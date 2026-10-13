import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_own_pms_system/features/dashboard/data/repositories/hotel_admin_repository.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/pages/admin_rooms_tariffs_page.dart';

void main() {
  testWidgets('Add Category and Add Room modals have improved UI with zero GST calculations', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/api/v1/admin/room-types')) {
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
      } else if (request.url.path.contains('/api/v1/admin/rooms')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                '_id': 'room-1',
                'roomNumber': '101',
                'roomType': {'_id': 'cat-1', 'name': 'Deluxe Room'},
                'status': 'AVAILABLE',
                'floor': 1,
              },
            ],
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

    // Verify Add Category modal opened
    expect(find.text('Create Room Category'), findsOneWidget);
    expect(find.text('CATEGORY DETAILS'), findsOneWidget);
    expect(find.text('BASE TARIFF (PER NIGHT)'), findsOneWidget);
    expect(find.text('GUEST CAPACITY & BEDS'), findsOneWidget);

    // Verify NO GST texts exist in Category modal either
    expect(find.text('Enable GST (Goods & Services Tax)'), findsNothing);
    expect(find.text('LIVE ROOM TAX BREAKDOWN'), findsNothing);
    expect(find.textContaining('CGST'), findsNothing);
    expect(find.textContaining('SGST'), findsNothing);
  });
}
