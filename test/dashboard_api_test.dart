import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_own_pms_system/core/widgets/status_badge.dart';
import 'package:my_own_pms_system/features/dashboard/data/models/booking_list_query.dart';
import 'package:my_own_pms_system/features/dashboard/data/models/guest_folio_model.dart';
import 'package:my_own_pms_system/features/dashboard/data/models/hotel_stats_model.dart';
import 'package:my_own_pms_system/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:my_own_pms_system/features/rooms/data/models/room_model.dart';
import 'package:my_own_pms_system/features/rooms/data/models/room_category_model.dart';
import 'package:my_own_pms_system/features/check_in_wizard/data/models/check_in_form_data.dart';
import 'package:my_own_pms_system/features/dashboard/data/repositories/hotel_admin_repository.dart';

const _checkedInBookingsResponse = '''
{
  "success": true,
  "message": "Bookings retrieved successfully.",
  "data": {
    "bookings": [
      {
        "id": 21,
        "hotel_id": 2,
        "booking_number": "BK-20261014-60A797",
        "primary_guest_name": "Niraj Vekariya",
        "mobile_number": "9426886960",
        "rooms": [
          {
            "id": 18,
            "room_number": "101",
            "floor": 1,
            "room_type_name": "Family Room"
          }
        ]
      },
      {
        "id": 20,
        "hotel_id": 2,
        "booking_number": "BK-20261014-3407DB",
        "primary_guest_name": "Ravi Shah",
        "mobile_number": "9876543210",
        "rooms": [
          {
            "id": 16,
            "room_number": "202",
            "floor": 2,
            "room_type_name": "Deluxe Room"
          }
        ]
      },
      {
        "id": 19,
        "hotel_id": 2,
        "booking_number": "BK-20261014-59040B",
        "primary_guest_name": "Niraj Vekariya",
        "mobile_number": "9876543210",
        "rooms": [
          {
            "id": 17,
            "room_number": "102",
            "floor": 1,
            "room_type_name": "Family Room"
          }
        ]
      }
    ],
    "total": 3,
    "page": 1,
    "limit": 10,
    "totalPages": 1
  }
}
''';

void main() {
  const dashboardApiResponse = '''
{
    "success": true,
    "data": {
        "rooms": {
            "available": 4,
            "cleaning": 0,
            "currentGuests": 1
        },
        "collections": {
            "todayCash": 1500,
            "todayOnline": 3500,
            "totalToday": 5000
        },
        "todayArrivals": [{"id": "arr-1"}],
        "todayDepartures": []
    }
}
''';

  const availableRoomsApiResponse = '''
{
    "success": true,
    "count": 4,
    "data": [
        {
            "_id": "6ab79cdc027d7d64ebd89d2d",
            "hotel": "6aae2b5b972e18bc49941888",
            "roomNumber": "01",
            "roomType": {
                "capacity": {
                    "adults": 2,
                    "children": 1
                },
                "_id": "6ab79c76027d7d64ebd89ce7",
                "hotel": "6aae2b5b972e18bc49941888",
                "name": "Standard Room",
                "description": "",
                "basePrice": 4000,
                "bedCount": 1,
                "bedType": "1 King Size Bed",
                "amenities": [
                    "Free High-Speed WiFi",
                    "Air Conditioner (AC)",
                    "Smart 4K LED TV",
                    "Attached Bathroom & Geyser"
                ],
                "images": [],
                "isActive": true,
                "isDeleted": false,
                "createdAt": "2026-09-26T10:20:38.213Z",
                "updatedAt": "2026-09-26T10:20:38.213Z",
                "__v": 0
            },
            "floor": 1,
            "status": "AVAILABLE",
            "seatingCapacity": 2,
            "bedCount": 1,
            "bedType": "1 King Size Bed",
            "notes": "",
            "amenities": [
                "Free High-Speed WiFi",
                "Air Conditioner (AC)",
                "Smart 4K LED TV",
                "Attached Bathroom & Geyser"
            ],
            "cleaningDurationMinutes": 15,
            "isActive": true,
            "isDeleted": false,
            "createdAt": "2026-09-26T10:22:20.959Z",
            "updatedAt": "2026-09-26T10:55:50.084Z",
            "__v": 0,
            "cleaningStartedAt": "2026-09-26T10:55:23.028Z",
            "guestName": "Niraj Vekariya"
        },
        {
            "_id": "6ab79d47027d7d64ebd89ded",
            "hotel": "6aae2b5b972e18bc49941888",
            "roomNumber": "02",
            "roomType": {
                "capacity": {
                    "adults": 2,
                    "children": 1
                },
                "_id": "6ab79c00027d7d64ebd89c5d",
                "hotel": "6aae2b5b972e18bc49941888",
                "name": "Family Room",
                "description": "",
                "basePrice": 1000,
                "bedCount": 1,
                "bedType": "1 King Size Bed",
                "amenities": [
                    "Free High-Speed WiFi",
                    "Air Conditioner (AC)"
                ]
            },
            "floor": 2,
            "status": "AVAILABLE",
            "guestName": ""
        }
    ]
}
''';

  const bookingsApiResponse = '''
{
    "success": true,
    "total": 1,
    "count": 1,
    "page": 1,
    "totalPages": 1,
    "data": [
        {
            "guestsCount": {
                "adults": 2,
                "children": 0
            },
            "_id": "6ab7a45a4254457467809f92",
            "hotel": "6aae2b5b972e18bc49941888",
            "bookingNumber": "BK-058260-778",
            "guest": {
                "_id": "6ab7a45a4254457467809f8e",
                "name": "Niraj Vekariya",
                "fullName": "Niraj Vekariya",
                "phone": "08849218118",
                "mobileNumber": "08849218118",
                "email": "nirajvekariya2209@gmail.com",
                "govtIdType": "AADHAAR",
                "govtIdNumber": "1234 5678 9123"
            },
            "room": {
                "_id": "6ab79cdc027d7d64ebd89d2d",
                "roomNumber": "01",
                "floor": 1,
                "status": "AVAILABLE"
            },
            "roomNumber": "01",
            "roomType": {
                "name": "Standard Room",
                "basePrice": 4000
            },
            "checkInDate": "2026-09-26",
            "checkOutDate": "2026-09-27",
            "checkInTime": "16:24",
            "checkOutTime": "12:00",
            "actualCheckIn": "2026-09-26T10:54:18.260Z",
            "numberOfNights": 1
        }
    ]
}
''';

  const postBookingApiResponse = '''
{
    "success": true,
    "message": "Guest Niraj Vekariya checked in to Room 01 successfully!",
    "data": {
        "booking": {
            "hotel": "6aae2b5b972e18bc49941888",
            "bookingNumber": "BK-075006-458",
            "guest": "6ab7a45a4254457467809f8e",
            "room": "6ab79cdc027d7d64ebd89d2d",
            "rooms": [
                "6ab79cdc027d7d64ebd89d2d"
            ],
            "roomNumber": "01",
            "roomNumbers": [
                "01"
            ],
            "roomType": "6ab79c76027d7d64ebd89ce7",
            "createdBy": "6ab79556e8c303418bf76402",
            "checkInDate": "2026-09-28T16:11:00.000Z",
            "checkOutDate": "2026-09-29T12:00:00.000Z",
            "checkInTime": "16:11",
            "checkOutTime": "12:00",
            "actualCheckIn": "2026-09-28T10:41:15.006Z",
            "numberOfNights": 1,
            "guestsCount": {
                "adults": 1,
                "children": 0
            },
            "accompanyingGuests": [],
            "baseAmount": 4000,
            "taxAmount": 0,
            "discountAmount": 0,
            "securityDepositAmount": 0,
            "extraChargesTotal": 0,
            "totalAmount": 4000,
            "paidAmount": 4000,
            "dueAmount": 0,
            "status": "CHECKED_IN",
            "guestSignature": "",
            "specialRequests": "",
            "notes": "",
            "_id": "6aba444bb73b8d74b91b8101",
            "createdAt": "2026-09-28T10:41:15.008Z",
            "updatedAt": "2026-09-28T10:41:15.008Z",
            "__v": 0
        },
        "receiptNumber": "RCP-075022"
    }
}
''';

  group('Receptionist Dashboard API Data Models Test', () {
    test('HotelStatsModel parses dashboard response accurately', () {
      final json = jsonDecode(dashboardApiResponse) as Map<String, dynamic>;
      final stats = HotelStatsModel.fromJson(json);

      expect(stats.availableVacant, 4);
      expect(stats.occupiedInHouse, 0);
      expect(stats.housekeepingQueue, 0);
      expect(stats.maintenanceBlocked, 0);
      expect(stats.totalInHouseGuests, 1);
      expect(stats.todayCash, 1500.0);
      expect(stats.todayOnline, 3500.0);
      expect(stats.totalToday, 5000.0);
      expect(stats.todayArrivals.length, 1);
      expect(stats.todayDepartures.length, 0);
    });

    test('RoomModel parses available rooms API response accurately', () {
      final json = jsonDecode(availableRoomsApiResponse) as Map<String, dynamic>;
      final roomsList = (json['data'] as List)
          .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(roomsList.length, 2);
      expect(roomsList[0].roomNumber, '#01');
      expect(roomsList[0].roomType, 'Standard Room');
      expect(roomsList[0].pricePerNight, 4000.0);
      expect(roomsList[0].status, RoomStatus.available);
      expect(roomsList[0].currentGuestName, 'Niraj Vekariya');
      expect(roomsList[0].maxOccupancy, 3); // 2 adults + 1 child
      expect(roomsList[0].floor, 'Floor 1');

      expect(roomsList[1].roomNumber, '#02');
      expect(roomsList[1].roomType, 'Family Room');
      expect(roomsList[1].pricePerNight, 1000.0);
      expect(roomsList[1].floor, 'Floor 2');
    });

    test('Live 7-Room API JSON parses correctly and groups into room categories', () {
      final liveJson = {
        "success": true,
        "count": 7,
        "data": [
          {
            "gstEnabled": true,
            "gstRate": 18,
            "cgstRate": 9,
            "sgstRate": 9,
            "taxInclusive": false,
            "_id": "6abce360513926b760aff585",
            "hotel": "6abce211513926b760aff542",
            "roomNumber": "01",
            "roomType": {
              "capacity": {"adults": 2, "children": 0},
              "gstEnabled": true,
              "gstRate": 18,
              "_id": "6abce335513926b760aff580",
              "name": "Family Room",
              "basePrice": 0,
              "bedCount": 1,
              "bedType": "1 King Size Bed",
            },
            "floor": 1,
            "status": "AVAILABLE",
            "customPricePerNight": 2000,
            "bedCount": 1,
            "bedType": "1 King Size Bed",
            "isAvailable": true,
          },
          {
            "gstEnabled": true,
            "gstRate": 18,
            "_id": "6abce383513926b760aff591",
            "roomNumber": "01",
            "roomType": {
              "capacity": {"adults": 2, "children": 0},
              "_id": "6abce327513926b760aff57c",
              "name": "Deluxe Room",
              "basePrice": 0,
            },
            "floor": 2,
            "status": "AVAILABLE",
            "customPricePerNight": 3000,
            "bedCount": 1,
            "bedType": "1 King Size Bed",
            "isAvailable": true,
          },
          {
            "gstEnabled": true,
            "gstRate": 18,
            "_id": "6abce395513926b760aff59a",
            "roomNumber": "01",
            "roomType": {
              "capacity": {"adults": 2, "children": 0},
              "_id": "6abce304513926b760aff578",
              "name": "Couple Room",
              "basePrice": 0,
            },
            "floor": 3,
            "status": "AVAILABLE",
            "customPricePerNight": 5000,
            "bedCount": 1,
            "bedType": "1 King Size Bed",
            "isAvailable": true,
          },
          {
            "gstEnabled": true,
            "gstRate": 18,
            "_id": "6abe27bb48737b246de2b75e",
            "roomNumber": "01",
            "roomType": {
              "capacity": {"adults": 2, "children": 0},
              "_id": "6abe278048737b246de2b61e",
              "name": "Deluxe Room",
              "basePrice": 0,
            },
            "floor": 5,
            "status": "AVAILABLE",
            "customPricePerNight": 5000,
            "bedCount": 2,
            "bedType": "2 Double Beds",
            "isAvailable": true,
          },
          {
            "gstEnabled": true,
            "gstRate": 18,
            "_id": "6abce3b6513926b760aff5a6",
            "roomNumber": "02",
            "roomType": {
              "capacity": {"adults": 2, "children": 0},
              "_id": "6abce2f7513926b760aff574",
              "name": "Standard Room",
              "basePrice": 0,
            },
            "floor": 1,
            "status": "AVAILABLE",
            "bedCount": 1,
            "bedType": "1 King Size Bed",
            "isAvailable": true,
          },
          {
            "gstEnabled": true,
            "gstRate": 18,
            "_id": "6abe284948737b246de2b8da",
            "roomNumber": "02",
            "roomType": {
              "capacity": {"adults": 2, "children": 0},
              "_id": "6abe278048737b246de2b61e",
              "name": "Deluxe Room",
              "basePrice": 0,
            },
            "floor": 5,
            "status": "AVAILABLE",
            "customPricePerNight": 1000,
            "bedCount": 1,
            "bedType": "1 King Size Bed",
            "isAvailable": true,
          },
          {
            "gstEnabled": true,
            "gstRate": 18,
            "_id": "6abe286248737b246de2b9aa",
            "roomNumber": "03",
            "roomType": {
              "capacity": {"adults": 2, "children": 0},
              "_id": "6abe278048737b246de2b61e",
              "name": "Deluxe Room",
              "basePrice": 0,
            },
            "floor": 5,
            "status": "AVAILABLE",
            "customPricePerNight": 2000,
            "bedCount": 1,
            "bedType": "1 King Size Bed",
            "isAvailable": true,
          }
        ]
      };

      final parsedRooms = (liveJson['data'] as List)
          .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(parsedRooms.length, 7);
      expect(parsedRooms[0].roomType, 'Family Room');
      expect(parsedRooms[0].pricePerNight, 2000.0);
      expect(parsedRooms[0].bedInfoLabel, '1 King Size Bed');
      expect(parsedRooms[0].gstRate, 18.0);
      expect(parsedRooms[0].gstEnabled, true);

      // Verify category grouping
      final categories = RoomCategoryGroup.groupFromRooms(parsedRooms);
      expect(categories.isNotEmpty, true);

      // Verify Deluxe group with 3 rooms on floor 5
      final deluxeGroup = categories.firstWhere((c) => c.roomTypeId == '6abe278048737b246de2b61e');
      expect(deluxeGroup.rooms.length, 3);
      expect(deluxeGroup.availableCount, 3);
      expect(deluxeGroup.displayPrice, '₹2,000');
    });

    test('GuestFolioModel parses bookings API response accurately', () {
      final json = jsonDecode(bookingsApiResponse) as Map<String, dynamic>;
      final bookingsList = (json['data'] as List)
          .map((e) => GuestFolioModel.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(bookingsList.length, 1);
      final booking = bookingsList[0];
      expect(booking.id, '6ab7a45a4254457467809f92');
      expect(booking.bookingId, 'BK-058260-778');
      expect(booking.guestName, 'Niraj Vekariya');
      expect(booking.status, FolioStatus.inHouse);
      expect(booking.phone, '08849218118');
      expect(booking.email, 'nirajvekariya2209@gmail.com');
      expect(booking.assignedRoom, 'Room #01');
      expect(booking.idType, 'AADHAAR');
      expect(booking.idNumber, '1234 5678 9123');
      expect(booking.isGovtIdVerified, true);
      expect(booking.roomRatePerNight, 4000.0);
      expect(booking.totalAmount, 4000.0);
    });

    test('GuestFolioModel parses POST booking check-in API response accurately', () {
      final json = jsonDecode(postBookingApiResponse) as Map<String, dynamic>;
      final bookingJson = json['data']['booking'] as Map<String, dynamic>;
      final receiptNumber = json['data']['receiptNumber']?.toString();
      final folio = GuestFolioModel.fromJson(bookingJson).copyWith(
        receiptNumber: receiptNumber,
      );

      expect(folio.id, '6aba444bb73b8d74b91b8101');
      expect(folio.bookingId, 'BK-075006-458');
      expect(folio.effectiveBookingId, 'BK-075006-458');
      expect(folio.receiptNumber, 'RCP-075022');
      expect(folio.guestId, '6ab7a45a4254457467809f8e');
      expect(folio.status, FolioStatus.inHouse);
      expect(folio.assignedRoom, 'Room #01');
      expect(folio.totalAmount, 4000.0);
      expect(folio.advancePaid, 4000.0);
      expect(folio.numberOfGuests, 1);
    });
  });

  group('DashboardRepository with Mock HTTP Client', () {
    late http.Client mockClient;
    late DashboardRepository repository;
    bool isCheckedOut = false;

    setUp(() {
      isCheckedOut = false;
      mockClient = MockClient((request) async {
        if (request.url.path.contains('/dashboard')) {
          return http.Response(dashboardApiResponse, 200, headers: {'content-type': 'application/json'});
        } else if (request.url.path.endsWith('/rooms') || request.url.path.contains('/rooms/available')) {
          return http.Response(availableRoomsApiResponse, 200, headers: {'content-type': 'application/json'});
        } else if (request.url.path.contains('/bookings')) {
          if (request.url.path.contains('/check-out')) {
            expect(request.method, 'POST');
            expect(request.url.path, contains('/api/v1/bookings/'));
            expect(request.url.path, endsWith('/check-out'));
            expect(request.headers['content-type'], contains('application/json'));
            expect(request.headers['accept'], contains('application/json'));
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['paid_amount'], 60);
            expect(body['payment_method'], 'UPI');
            expect(body['notes'], 'Collected remaining balance at the desk');
            expect(body.containsKey('late_checkout_charge'), isFalse);
            expect(body.containsKey('late_checkout_hours'), isFalse);
            expect(body.containsKey('hotel_id'), isFalse);
            expect(body.containsKey('dailyRoomRate'), isFalse);
            isCheckedOut = true;
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Checkout completed successfully. Room is now marked for cleaning.',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'POST') {
            expect(request.url.path, '/api/v1/bookings');
            expect(request.headers['content-type'], contains('multipart/form-data'));
            expect(request.body, contains('name="primary_guest_name"'));
            expect(request.body, contains('Niraj Vekariya'));
            expect(request.body, contains('name="mobile_number"'));
            expect(request.body, contains('08849218118'));
            expect(request.body, contains('name="email"'));
            expect(request.body, contains('nirajvekariya2209@gmail.com'));
            expect(request.body, contains('name="address"'));
            expect(request.body, contains('name="booking_status"'));
            expect(request.body, contains('CHECKED_IN'));
            expect(request.body, contains('name="paid_amount"'));
            expect(request.body, contains('2000'));
            return http.Response(postBookingApiResponse, 201, headers: {'content-type': 'application/json'});
          }
          if (isCheckedOut) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'bookings': [],
                  'total': 0,
                  'page': 1,
                  'limit': 10,
                  'totalPages': 1,
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(bookingsApiResponse, 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{"error": "not found"}', 404);
      });

      repository = DashboardRepository(client: mockClient);
    });

    test('fetchReceptionistDashboard returns live parsed stats', () async {
      final stats = await repository.fetchReceptionistDashboard();
      expect(stats.availableVacant, 4);
      expect(stats.occupiedInHouse, 0);
      expect(stats.housekeepingQueue, 0);
      expect(stats.maintenanceBlocked, 0);
      expect(stats.totalInHouseGuests, 1);
      expect(stats.totalToday, 5000.0);
    });

    test('fetchAvailableRooms sets live rooms into repository inventory', () async {
      final rooms = await repository.fetchAvailableRooms();
      expect(rooms.length, 2);
      expect(rooms[0].roomNumber, '#01');
      expect(rooms[0].currentGuestName, 'Niraj Vekariya');
      expect(rooms[1].roomNumber, '#02');
      expect(rooms[1].roomType, 'Family Room');
    });

    test('fetchAvailableRooms applies hotel gst_enabled and tax_percentage', () async {
      Uri? requested;
      final repo = DashboardRepository(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'rooms': [
                  {
                    'id': 29,
                    'room_number': '104',
                    'room_type_name': 'Family Room',
                    'floor': 1,
                    'status': 'AVAILABLE',
                    'custom_price_per_night': 4000,
                  },
                ],
                'total': 1,
                'page': 1,
                'limit': 10,
                'totalPages': 1,
                'hotel': {
                  'id': 2,
                  'gst_enabled': true,
                  'tax_percentage': 18,
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final rooms = await repo.fetchAvailableRooms();
      expect(requested!.queryParameters['sort_by'], 'floor');
      expect(requested!.queryParameters['sort_order'], 'asc');
      expect(requested!.queryParameters.containsKey('hotel_id'), isFalse);
      expect(rooms.single.pricePerNight, 4000);
      expect(rooms.single.gstEnabled, isTrue);
      expect(rooms.single.gstRate, 18);
      expect(rooms.single.cgstRate, 9);
      expect(rooms.single.sgstRate, 9);
    });

    test('fetchBookings sets live bookings into repository folios', () async {
      final folios = await repository.fetchBookings();
      expect(folios.length, 1);
      expect(folios[0].guestName, 'Niraj Vekariya');
      expect(folios[0].bookingId, 'BK-058260-778');
      expect(folios[0].status, FolioStatus.inHouse);
    });

    test('fetchBookings loads only CHECKED_IN rows from /api/v1/bookings', () async {
      Uri? requestedUri;
      final repo = DashboardRepository(
        client: MockClient((request) async {
          requestedUri = request.url;
          expect(request.method, 'GET');
          return http.Response(_checkedInBookingsResponse, 200, headers: {'content-type': 'application/json'});
        }),
      );

      final folios = await repo.fetchBookings(status: 'CHECKED_IN');

      expect(requestedUri?.path, '/api/v1/bookings');
      expect(requestedUri?.queryParameters['booking_status'], 'CHECKED_IN');
      expect(requestedUri?.queryParameters['page'], '1');
      expect(requestedUri?.queryParameters['limit'], '10');
      expect(requestedUri?.queryParameters.containsKey('hotel_id'), isFalse);
      expect(requestedUri?.queryParameters.containsKey('room_id'), isFalse);
      expect(requestedUri?.queryParameters.containsKey('payment_status'), isFalse);
      expect(folios.map((folio) => folio.id), ['21', '20', '19']);
      expect(folios.map((folio) => folio.bookingId), [
        'BK-20261014-60A797',
        'BK-20261014-3407DB',
        'BK-20261014-59040B',
      ]);
      expect(folios.map((folio) => folio.guestName), [
        'Niraj Vekariya',
        'Ravi Shah',
        'Niraj Vekariya',
      ]);
      expect(folios.map((folio) => folio.phone), [
        '9426886960',
        '9876543210',
        '9876543210',
      ]);
      expect(folios.map((folio) => folio.assignedRoom), ['Room #101', 'Room #202', 'Room #102']);
      expect(folios.map((folio) => folio.roomType), ['Family Room', 'Deluxe Room', 'Family Room']);
      expect(folios.map((folio) => folio.floor), ['Floor 1', 'Floor 2', 'Floor 1']);
      expect(folios.every((folio) => folio.status == FolioStatus.inHouse), isTrue);
    });

    test('fetchBookings default request sends only page and limit', () async {
      Uri? requestedUri;
      final repo = DashboardRepository(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(_checkedInBookingsResponse, 200, headers: {'content-type': 'application/json'});
        }),
      );

      await repo.fetchBookings();

      expect(requestedUri?.path, '/api/v1/bookings');
      expect(requestedUri?.queryParameters['page'], '1');
      expect(requestedUri?.queryParameters['limit'], '10');
      expect(requestedUri?.queryParameters.keys, ['page', 'limit']);
    });

    test('fetchBookings sends guest filters only when they are filled', () async {
      Uri? requestedUri;
      final repo = DashboardRepository(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(_checkedInBookingsResponse, 200, headers: {'content-type': 'application/json'});
        }),
      );

      await repo.fetchBookings(
        query: const BookingListQuery(
          bookingStatus: 'CHECKED_IN',
          paymentStatus: 'PENDING',
          roomId: '14',
          bookingNumber: 'BK-',
          primaryGuestName: 'Ravi',
          guestName: 'Shah',
          mobileNumber: '98765',
          search: 'Ravi',
          checkInFrom: '2026-10-01',
          checkInTo: '2026-10-31',
          checkOutFrom: '2026-10-01',
          checkOutTo: '2026-10-31',
        ),
      );

      final params = requestedUri!.queryParameters;
      expect(requestedUri?.path, '/api/v1/bookings');
      expect(params['page'], '1');
      expect(params['limit'], '10');
      expect(params['booking_status'], 'CHECKED_IN');
      expect(params['payment_status'], 'PENDING');
      expect(params['room_id'], '14');
      expect(params['booking_number'], 'BK-');
      expect(params['primary_guest_name'], 'Ravi');
      expect(params['guest_name'], 'Shah');
      expect(params['mobile_number'], '98765');
      expect(params['search'], 'Ravi');
      expect(params['check_in_from'], '2026-10-01');
      expect(params['check_in_to'], '2026-10-31');
      expect(params['check_out_from'], '2026-10-01');
      expect(params['check_out_to'], '2026-10-31');
      expect(params.containsKey('hotel_id'), isFalse);
    });

    test('completeCheckIn sends POST request to /bookings and returns parsed folio with receipt', () async {
      // First populate inventory
      await repository.fetchAvailableRooms();

      final formData = CheckInFormData(
        guestFullName: 'Niraj Vekariya',
        contactPhone: '08849218118',
        email: 'nirajvekariya2209@gmail.com',
        selectedRoomId: '6ab79cdc027d7d64ebd89d2d',
        selectedRoomNumber: '01',
        selectedFloor: 'Floor 1',
        roomType: 'Standard Room',
        pricePerNight: 4000,
        checkInDate: DateTime.parse('2026-09-26T12:00:00.000Z'),
        checkOutDate: DateTime.parse('2026-09-28T11:00:00.000Z'),
        residentialAddress: '12 Lake Road, Pune',
        advancePaid: 2000,
        paymentMode: 'Cash Desk',
        numberOfGuests: 2,
      );

      final folio = await repository.completeCheckIn(formData);

      expect(folio.id, '6aba444bb73b8d74b91b8101');
      expect(folio.bookingId, 'BK-075006-458');
      expect(folio.effectiveBookingId, 'BK-075006-458');
      expect(folio.receiptNumber, 'RCP-075022');
      expect(folio.status, FolioStatus.inHouse);
      expect(folio.guestName, 'Niraj Vekariya');
      expect(folio.assignedRoom, 'Room #01');
      expect(folio.totalAmount, 4000.0);

      // Verify room status was updated to occupied
      final updatedRooms = await repository.getRooms();
      final room01 = updatedRooms.firstWhere((r) => r.roomNumber == '#01');
      expect(room01.status, RoomStatus.occupied);
    });

    test('completeCheckIn posts the live bookings form including address and room id', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/bookings');
        expect(request.headers['Accept'], 'application/json');
        expect(request.headers['content-type'], contains('multipart/form-data'));
        final body = request.body;
        expect(body, contains('name="primary_guest_name"'));
        expect(body, contains('Ravi Shah'));
        expect(body, contains('name="secondary_guest_name"'));
        expect(body, contains('Meera Shah'));
        expect(body, contains('name="mobile_number"'));
        expect(body, contains('9876543210'));
        expect(body, contains('name="email"'));
        expect(body, contains('guest@example.com'));
        expect(body, contains('name="address"'));
        expect(body, contains('12 Lake Road, Pune'));
        expect(body, contains('name="room_id"'));
        expect(body, contains('[14]'));
        expect(body, contains('name="check_in_date"'));
        expect(body, contains('2026-10-14T14:00:00.000Z'));
        expect(body, contains('name="check_out_date"'));
        expect(body, contains('2026-10-16T12:00:00.000Z'));
        expect(body, contains('name="adults"'));
        expect(body, contains('2'));
        expect(body, contains('name="children"'));
        expect(body, contains('name="base_amount"'));
        expect(body, contains('7000'));
        expect(body, contains('name="discount_amount"'));
        expect(body, contains('name="gst_rate"'));
        expect(body, contains('18'));
        expect(body, contains('name="paid_amount"'));
        expect(body, contains('2000'));
        expect(body, contains('name="payment_method"'));
        expect(body, contains('UPI'));
        expect(body, contains('name="notes"'));
        expect(body, contains('Late arrival after 10 pm'));
        expect(body, contains('name="booking_status"'));
        expect(body, contains('CHECKED_IN'));
        expect(body.contains('hotel_id'), isFalse);
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Booking created successfully.',
            'data': {
              'id': 17,
              'booking_number': 'BK-20261014-E056A8',
              'primary_guest_name': 'Ravi Shah',
              'mobile_number': '9876543210',
              'address': '12 Lake Road, Pune',
              'email': 'guest@example.com',
              'room_id': [14],
              'check_in_date': '2026-10-14T14:00:00.000Z',
              'check_out_date': '2026-10-16T12:00:00.000Z',
              'number_of_nights': 2,
              'adults': 2,
              'children': 0,
              'base_amount': 7000,
              'total_amount': 8260,
              'paid_amount': 2000,
              'booking_status': 'CHECKED_IN',
              'room': {
                'id': 14,
                'room_number': '101',
                'floor': 2,
                'room_type_name': 'Family Room',
              },
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = DashboardRepository(client: mock);
      final folio = await repo.completeCheckIn(CheckInFormData(
        guestFullName: 'Ravi Shah',
        secondGuestName: 'Meera Shah',
        contactPhone: '9876543210',
        email: 'guest@example.com',
        residentialAddress: '12 Lake Road, Pune',
        selectedRoomId: '14',
        selectedRoomNumber: '101',
        pricePerNight: 3500,
        numberOfGuests: 2,
        advancePaid: 2000,
        paymentMode: 'UPI / QR Code (PhonePe/GPay)',
        specialRequests: 'Late arrival after 10 pm',
        checkInDate: DateTime.parse('2026-10-14T14:00:00.000Z'),
        checkOutDate: DateTime.parse('2026-10-16T12:00:00.000Z'),
      ));

      expect(folio.id, '17');
      expect(folio.bookingId, 'BK-20261014-E056A8');
      expect(folio.guestName, 'Ravi Shah');
      expect(folio.phone, '9876543210');
      expect(folio.address, '12 Lake Road, Pune');
      expect(folio.assignedRoom, 'Room #101');
      expect(folio.roomType, 'Family Room');
      expect(folio.totalAmount, 8260);
      expect(folio.advancePaid, 2000);
      expect(folio.status, FolioStatus.inHouse);
    });

    test('updateRoomStatus patches the room status endpoint', () async {
      final repo = DashboardRepository(
        client: MockClient((request) async {
          if (request.method != 'PATCH') {
            return http.Response('{"success": false}', 404);
          }
          expect(request.url.path, '/api/v1/rooms/14/status');
          expect(request.headers['content-type'], contains('application/json'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {'status': 'CLEANING'});
          expect(body.containsKey('hotel_id'), isFalse);
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
        }),
        initialRooms: [
          RoomModel(
            id: '14',
            roomNumber: '#101',
            floor: 'Floor 2',
            roomType: 'Family Room',
            pricePerNight: 4000,
            status: RoomStatus.occupied,
          ),
        ],
      );

      await repo.updateRoomStatus('14', RoomStatus.cleaning);
      final rooms = await repo.getRooms();
      expect(rooms.single.id, '14');
      expect(rooms.single.status, RoomStatus.cleaning);
    });

    test('marking a cleaning room available sends AVAILABLE and stays available', () async {
      Map<String, dynamic>? patchedBody;
      final repo = DashboardRepository(
        client: MockClient((request) async {
          if (request.method == 'PATCH') {
            patchedBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Room status updated successfully.',
                'data': {
                  'id': 18,
                  'room_number': '105',
                  'room_type_name': 'Family Room',
                  'floor': 1,
                  'status': 'OCCUPIED',
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'GET' && request.url.path.endsWith('/rooms')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'rooms': [
                    {
                      'id': 18,
                      'room_number': '105',
                      'room_type_name': 'Family Room',
                      'floor': 1,
                      'status': 'OCCUPIED',
                    }
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
          return http.Response('{"success": true, "data": {}}', 200);
        }),
        initialRooms: [
          RoomModel(
            id: '18',
            roomNumber: '#105',
            floor: 'Floor 1',
            roomType: 'Family Room',
            pricePerNight: 4000,
            status: RoomStatus.cleaning,
          ),
        ],
        initialFolios: [
          GuestFolioModel(
            id: '21',
            guestName: 'Niraj Vekariya',
            email: 'niraj@example.com',
            phone: '9426886960',
            assignedRoom: 'Room #105',
            roomType: 'Family Room',
            checkInDate: DateTime.parse('2026-10-14T12:00:00.000Z'),
            checkOutDate: DateTime.parse('2026-10-15T12:00:00.000Z'),
            status: FolioStatus.inHouse,
            idType: 'Aadhaar Card',
            idNumber: 'Pending ID',
            roomRatePerNight: 4000,
            advancePaid: 0,
            totalAmount: 4000,
          ),
        ],
      );

      await repo.updateRoomStatus('18', RoomStatus.available);
      expect(patchedBody, {'status': 'AVAILABLE'});
      expect(patchedBody!.containsKey('hotel_id'), isFalse);

      final rooms = await repo.getRooms();
      expect(rooms.single.id, '18');
      expect(rooms.single.status, RoomStatus.available);
    });

    test('fetchBooking loads GET /api/v1/bookings/{id} and maps the booking', () async {
      final repo = DashboardRepository(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/bookings/21');
          expect(request.url.queryParameters.containsKey('hotel_id'), isFalse);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 21,
                'booking_number': 'BK-20261014-60A797',
                'primary_guest_name': 'Niraj Vekariya',
                'secondary_guest_name': 'Niraj Vekariya 2',
                'mobile_number': '9426886960',
                'email': 'nirajvekariya@gmail.com',
                'address': 'ABC Complex, Nikol, Ahmedabad',
                'booking_status': 'CHECKED_OUT',
                'payment_status': 'PAID',
                'check_in_date': '2026-10-14T00:00:00.000Z',
                'check_out_date': '2026-10-15T00:00:00.000Z',
                'nights': 1,
                'adults': 3,
                'children': 0,
                'base_amount': 1000,
                'tax_amount': 180,
                'gst_rate': 18,
                'cgst_amount': 90,
                'sgst_amount': 90,
                'total_amount': 1180,
                'paid_amount': 1180,
                'due_amount': 0,
                'notes': 'Collected remaining balance at the desk',
                'rooms': [
                  {'id': 18, 'room_number': '101', 'floor': 1, 'room_type_name': 'Family Room'}
                ],
                'creator': {'id': 18, 'name': 'Tushar Paneliya', 'role': 'RECEPTIONIST'},
                'images': ['https://example.com/id-front.jpg', 'https://example.com/id-back.jpg'],
                'signatures': ['https://example.com/signature.png'],
                'payment_history': [
                  {
                    'id': 8,
                    'amount': 1180,
                    'payment_method': 'UPI',
                    'status': 'PAID',
                    'source': 'CHECKOUT',
                    'received_by': {'id': 18, 'name': 'Tushar Paneliya'},
                    'received_at': '2026-10-15T10:00:00.000Z',
                  }
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final folio = await repo.fetchBooking('21');
      expect(folio, isNotNull);
      expect(folio!.id, '21');
      expect(folio.bookingId, 'BK-20261014-60A797');
      expect(folio.guestName, 'Niraj Vekariya');
      expect(folio.secondaryGuestName, 'Niraj Vekariya 2');
      expect(folio.email, 'nirajvekariya@gmail.com');
      expect(folio.address, 'ABC Complex, Nikol, Ahmedabad');
      expect(folio.phone, '9426886960');
      expect(folio.status, FolioStatus.departed);
      expect(folio.assignedRoom, 'Room #101');
      expect(folio.roomId, '18');
      expect(folio.roomType, 'Family Room');
      expect(folio.totalAmount, 1180);
      expect(folio.advancePaid, 1180);
      expect(folio.tax, 180);
      expect(folio.roomCharges, 1000);
      expect(folio.guestNotes, 'Collected remaining balance at the desk');
      expect(folio.createdByName, 'Tushar Paneliya');
      expect(folio.adultCount, 3);
      expect(folio.payments.single.paymentMethod, 'UPI');
      expect(folio.payments.single.amount, 1180);
      expect(folio.idImageUrls, ['https://example.com/id-front.jpg', 'https://example.com/id-back.jpg']);
      expect(folio.signatureUrls, ['https://example.com/signature.png']);
      expect(folio.payments.single.reference, 'CHECKOUT · Tushar Paneliya');
      expect(folio.gstRate, 18);
      expect(folio.cgstAmount, 90);
      expect(folio.sgstAmount, 90);
    });

    test('updateBooking sends PUT /api/v1/bookings/{id} without hotel_id', () async {
      Map<String, dynamic>? body;
      final repo = DashboardRepository(
        client: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/v1/bookings/1');
          expect(request.url.queryParameters.containsKey('hotel_id'), isFalse);
          expect(request.headers['Accept'], 'application/json');
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 1,
                'booking_number': 'BK-1',
                'primary_guest_name': 'Niraj Vekariya',
                'mobile_number': '9426886960',
                'booking_status': 'CHECKED_IN',
                'check_in_date': '2026-10-19T14:00:00.000Z',
                'check_out_date': '2026-10-20T12:00:00.000Z',
                'base_amount': 4000,
                'paid_amount': 1000,
                'rooms': [
                  {'id': 14, 'room_number': '101'}
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final folio = await repo.updateBooking(
        bookingId: '1',
        guestName: 'Niraj Vekariya',
        phone: '9426886960',
        email: 'niraj@example.com',
        address: 'Nikol, Ahmedabad',
        roomId: '14',
        checkInDate: DateTime(2026, 10, 19),
        checkOutDate: DateTime(2026, 10, 20),
        adults: 2,
        children: 0,
        baseAmount: 4000,
        discountAmount: 0,
        extraCharges: 0,
        gstRate: 18,
        paidAmount: 1000,
        notes: 'Late arrival',
      );

      expect(body!['primary_guest_name'], 'Niraj Vekariya');
      expect(body!['room_id'], '[14]');
      expect(body!['booking_status'], 'CHECKED_IN');
      expect(body!['paid_amount'], 1000);
      expect(body!['payment_method'], 'UPI');
      expect(body!.containsKey('hotel_id'), isFalse);
      expect(folio.id, '1');
      expect(folio.guestName, 'Niraj Vekariya');
    });

    test('updateBookingFromForm sends the id photo and signature on PUT', () async {
      final dir = await Directory.systemTemp.createTemp('update-booking-images');
      final photo = File('${dir.path}/aadhaar.jpg');
      await photo.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
      addTearDown(() => dir.delete(recursive: true));

      final repo = DashboardRepository(
        client: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/v1/bookings/13');
          expect(request.url.queryParameters.containsKey('hotel_id'), isFalse);
          final body = utf8.decode(request.bodyBytes, allowMalformed: true);
          expect(body, contains('name="images"'));
          expect(body, contains('filename="aadhaar.jpg"'));
          expect(body, contains('name="signatures"'));
          expect(body, contains('name="primary_guest_name"'));
          expect(body.contains('hotel_id'), isFalse);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 13,
                'booking_number': 'NR/2026-27/0006',
                'primary_guest_name': 'Niraj Vekariya',
                'booking_status': 'CHECKED_IN',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final folio = await repo.updateBookingFromForm(CheckInFormData(
        editingBookingId: '13',
        guestFullName: 'Niraj Vekariya',
        contactPhone: '9426886960',
        selectedRoomId: '4',
        selectedRoomNumber: '104',
        pricePerNight: 4000,
        idPhotos: [photo.path],
        signaturePoints: [const Offset(8, 12), const Offset(30, 18)],
        checkInDate: DateTime(2026, 10, 21),
        checkOutDate: DateTime(2026, 10, 22),
      ));

      expect(folio.id, '13');
    });

    test('fetchBookingPdf loads GET /api/v1/bookings/{id}/pdf and downloads the file', () async {
      final calls = <String>[];
      final repo = DashboardRepository(
        client: MockClient((request) async {
          calls.add('${request.method} ${request.url}');
          expect(request.url.queryParameters.containsKey('hotel_id'), isFalse);
          if (request.url.path.endsWith('/pdf')) {
            expect(request.headers['Accept'], 'application/json');
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Booking folio generated successfully.',
                'data': {
                  'url': 'https://example.com/uploads/pdfs/booking_BK.pdf',
                  'file_name': 'booking_BK.pdf',
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          expect(request.url.toString(), 'https://example.com/uploads/pdfs/booking_BK.pdf');
          return http.Response(
            '%PDF-1.4 folio',
            200,
            headers: {'content-type': 'application/pdf'},
          );
        }),
      );

      final pdf = await repo.fetchBookingPdf('4');
      expect(calls, [
        'GET https://hotelmanagementbackendnew-production.up.railway.app/api/v1/bookings/4/pdf',
        'GET https://example.com/uploads/pdfs/booking_BK.pdf',
      ]);
      expect(pdf.fileName, 'booking_BK.pdf');
      expect(pdf.url, 'https://example.com/uploads/pdfs/booking_BK.pdf');
      expect(utf8.decode(pdf.bytes), '%PDF-1.4 folio');
    });

    test('completeCheckIn surfaces the booking API error instead of a local folio', () async {
      final repo = DashboardRepository(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/bookings');
          final body = request.body;
          expect(body, contains('name="room_id"'));
          expect(body, contains('[14]'));
          expect(body, contains('name="primary_guest_name"'));
          expect(body, contains('Niraj Vekariya'));
          expect(body, contains('name="mobile_number"'));
          expect(body, contains('9876543210'));
          expect(body, contains('name="booking_status"'));
          expect(body, contains('CHECKED_IN'));
          expect(body.contains('hotel_id'), isFalse);
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Room is already occupied',
            }),
            400,
            headers: {'content-type': 'application/json'},
          );
        }),
        initialRooms: [
          RoomModel(
            id: '14',
            roomNumber: '#101',
            floor: 'Floor 2',
            roomType: 'Family Room',
            pricePerNight: 4000,
            status: RoomStatus.available,
          ),
        ],
      );

      expect(
        () => repo.completeCheckIn(CheckInFormData(
          guestFullName: 'Niraj Vekariya',
          contactPhone: '+91 98765 43210',
          email: 'niraj.v@example.com',
          residentialAddress: '12 Lake Road, Pune',
          selectedRoomId: '14',
          selectedRoomNumber: '#101',
          roomType: 'Family Room',
          pricePerNight: 4000,
          advancePaid: 4480,
          checkInDate: DateTime(2026, 10, 14),
          checkOutDate: DateTime(2026, 10, 15),
        )),
        throwsA(predicate((error) => error.toString().contains('Room is already occupied'))),
      );
    });

    test('completeCheckIn uploads id photos and signature as images', () async {
      final dir = await Directory.systemTemp.createTemp('check-in-images');
      final photo = File('${dir.path}/aadhaar.jpg');
      await photo.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
      addTearDown(() => dir.delete(recursive: true));

      final repo = DashboardRepository(
        client: MockClient((request) async {
          final body = utf8.decode(request.bodyBytes, allowMalformed: true);
          expect(body, contains('name="images"'));
          expect(body, contains('image/jpeg'));
          expect(body, contains('filename="aadhaar.jpg"'));
          expect(body, contains('name="signatures"'));
          expect(body, contains('image/png'));
          expect(body, contains('filename="signature.png"'));
          expect(body.contains('application/octet-stream'), isFalse);
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Booking created successfully.',
              'data': {
                'id': 17,
                'booking_number': 'BK-20261014-E056A8',
                'primary_guest_name': 'Niraj Vekariya',
                'room': {'room_number': '101', 'room_type_name': 'Family Room'},
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final folio = await repo.completeCheckIn(CheckInFormData(
        guestFullName: 'Niraj Vekariya',
        contactPhone: '9876543210',
        selectedRoomId: '14',
        selectedRoomNumber: '#101',
        pricePerNight: 4000,
        idPhotos: [photo.path],
        isSignatureCaptured: true,
        signaturePoints: [const Offset(12, 20), const Offset(40, 28)],
        checkInDate: DateTime(2026, 10, 14),
        checkOutDate: DateTime(2026, 10, 15),
      ));

      expect(folio.bookingId, 'BK-20261014-E056A8');
    });

    test('completeCheckIn updates the seeded room list without throwing', () async {
      final repo = DashboardRepository(
        client: MockClient((request) async {
          if (request.method == 'POST' && request.url.path.endsWith('/bookings')) {
            return http.Response(postBookingApiResponse, 201, headers: {'content-type': 'application/json'});
          }
          return http.Response('{"success": false}', 404);
        }),
      );

      final folio = await repo.completeCheckIn(CheckInFormData(
        guestFullName: 'Niraj Vekariya',
        contactPhone: '9426886960',
        email: 'nirajvekariya2209@gmail.com',
        selectedRoomId: 'room-01',
        selectedRoomNumber: '#01',
        roomType: 'family room',
        pricePerNight: 5000,
        advancePaid: 0,
        checkInDate: DateTime(2026, 10, 14),
        checkOutDate: DateTime(2026, 10, 15),
      ));

      expect(folio.guestName, 'Niraj Vekariya');
      final rooms = await repo.getRooms();
      expect(rooms.firstWhere((room) => room.id == 'room-01').status, RoomStatus.occupied);
    });

    test('checkoutFolio posts /api/v1/bookings/{id}/check-out and removes the guest', () async {
      await repository.fetchAvailableRooms();
      final folios = await repository.fetchBookings();
      expect(folios.isNotEmpty, isTrue);

      final targetFolioId = folios.first.id;

      final result = await repository.checkoutFolio(
        targetFolioId,
        customPayload: {
          'paid_amount': 60,
          'payment_method': 'UPI',
          'notes': 'Collected remaining balance at the desk',
        },
      );

      expect(result['success'], isTrue);
      expect(result['message'], 'Checkout completed successfully. Room is now marked for cleaning.');

      final updatedFolios = await repository.getFolios();
      expect(updatedFolios.where((folio) => folio.id == targetFolioId), isEmpty);
    });

    test('DashboardBloc loads and emits live API data correctly', () async {
      final bloc = DashboardBloc(repository: repository);
      bloc.add(LoadDashboardDataEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<DashboardState>((s) => s.status == DashboardStatus.loading),
          predicate<DashboardState>((s) =>
              s.status == DashboardStatus.loaded &&
              s.stats.availableVacant == 4 &&
              s.stats.totalInHouseGuests == 1 &&
              s.stats.totalToday == 5000.0 &&
              s.allRooms.any((r) => r.roomNumber == '#01') &&
              s.folios.any((f) => f.guestName == 'Niraj Vekariya')),
        ]),
      );
    });

    test('RoomTypeModel parses room-types API JSON response correctly', () {
      const roomTypesJson = '''
      {
        "success": true,
        "count": 6,
        "data": [
          {
            "capacity": { "adults": 2, "children": 0 },
            "gstEnabled": true,
            "gstRate": 18,
            "cgstRate": 9,
            "sgstRate": 9,
            "taxInclusive": false,
            "_id": "6abe278048737b246de2b61e",
            "hotel": "6abce211513926b760aff542",
            "name": "Deluxe Room",
            "description": "",
            "basePrice": 0,
            "bedCount": 1,
            "bedType": "1 King Size Bed",
            "amenities": ["Free High-Speed WiFi", "Air Conditioner (AC)"],
            "images": [],
            "isActive": true,
            "isDeleted": false
          },
          {
            "capacity": { "adults": 2, "children": 0 },
            "gstEnabled": true,
            "gstRate": 18,
            "cgstRate": 9,
            "sgstRate": 9,
            "taxInclusive": false,
            "_id": "6abce335513926b760aff580",
            "hotel": "6abce211513926b760aff542",
            "name": "Family Room",
            "description": "",
            "basePrice": 0,
            "bedCount": 1,
            "bedType": "1 King Size Bed",
            "amenities": [],
            "images": [],
            "isActive": true,
            "isDeleted": false
          },
          {
            "capacity": { "adults": 2, "children": 0 },
            "gstEnabled": true,
            "gstRate": 18,
            "cgstRate": 9,
            "sgstRate": 9,
            "taxInclusive": false,
            "_id": "6abce304513926b760aff578",
            "hotel": "6abce211513926b760aff542",
            "name": "Couple Room",
            "description": "",
            "basePrice": 0,
            "bedCount": 1,
            "bedType": "1 King Size Bed",
            "amenities": [],
            "images": [],
            "isActive": true,
            "isDeleted": false
          }
        ]
      }
      ''';

      final decoded = jsonDecode(roomTypesJson) as Map<String, dynamic>;
      final list = (decoded['data'] as List)
          .map((e) => RoomTypeModel.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(list.length, 3);
      expect(list[0].id, '6abe278048737b246de2b61e');
      expect(list[0].name, 'Deluxe Room');
      expect(list[0].effectivePrice, 3000.0);
      expect(list[1].name, 'Family Room');
      expect(list[1].effectivePrice, 2000.0);
      expect(list[2].name, 'Couple Room');
      expect(list[2].effectivePrice, 5000.0);

      // Verify dynamic category grouping
      final dummyRooms = [
        RoomModel(
          id: 'r1',
          roomNumber: '#01',
          floor: 'Floor 1',
          roomType: 'Family Room',
          roomTypeId: '6abce335513926b760aff580',
          pricePerNight: 2000,
          status: RoomStatus.available,
          maxOccupancy: 2,
        ),
      ];

      final groups = RoomCategoryGroup.groupFromRoomTypesAndRooms(list, dummyRooms);
      expect(groups.length, 3);
      final familyGroup = groups.firstWhere((g) => g.categoryName == 'Family Room');
      expect(familyGroup.availableCount, 1);
      expect(familyGroup.totalCount, 1);
      expect(familyGroup.pricePerNight, 2000.0);
    });

    test('RoomTypeModel parses new railway room-types API response with integer id and hotel_id', () {
      const railwayJson = '''
      {
          "success": true,
          "message": "Room categories retrieved successfully.",
          "data": [
              {
                  "id": 2,
                  "hotel_id": 3,
                  "name": "Deluxe Room",
                  "description": "Deluxe Room",
                  "images": [],
                  "deleted_at": null,
                  "created_at": "2026-10-13T09:31:26.000Z",
                  "updated_at": "2026-10-13T09:31:26.000Z"
              }
          ]
      }
      ''';

      final decoded = jsonDecode(railwayJson) as Map<String, dynamic>;
      final list = (decoded['data'] as List)
          .map((e) => RoomTypeModel.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(list.length, 1);
      final item = list.first;
      expect(item.id, '2');
      expect(item.hotel, '3');
      expect(item.name, 'Deluxe Room');
      expect(item.description, 'Deluxe Room');
      expect(item.isActive, isTrue);
      expect(item.isDeleted, isFalse);
      expect(item.createdAt, '2026-10-13T09:31:26.000Z');
      expect(item.effectivePrice, 3000.0);
    });

    test('DashboardRepository.fetchRoomTypes requests /room-types without hotel_id', () async {
      String? requestedUrl;
      String? accept;

      final fakeClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        accept = request.headers['accept'];
        return http.Response(
          '''
          {
              "success": true,
              "message": "Room categories retrieved successfully.",
              "data": {
                  "room_categories": [
                      {
                          "id": 1,
                          "hotel_id": 1,
                          "name": "Family Room",
                          "description": "Family Room",
                          "images": [],
                          "deleted_at": null,
                          "room_status_counts": {
                              "available_count": 4,
                              "reserved_count": 0,
                              "occupied_count": 1,
                              "cleaning_count": 0,
                              "maintenance_count": 0,
                              "blocked_count": 0,
                              "total_room_count": 5
                          }
                      }
                  ],
                  "total": 1,
                  "page": 1,
                  "limit": 10,
                  "totalPages": 1
              }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = DashboardRepository(client: fakeClient);
      final types = await repo.fetchRoomTypes();

      expect(requestedUrl, endsWith('/api/v1/room-types'));
      expect(requestedUrl, isNot(contains('hotel_id')));
      expect(accept, 'application/json');
      expect(types.length, 1);
      expect(types.first.id, '1');
      expect(types.first.name, 'Family Room');
      expect(types.first.availableCount, 4);
      expect(types.first.occupiedCount, 1);
      expect(types.first.totalRoomCount, 5);
    });

    test('groupFromRoomTypesAndRooms only includes API room types and strictly excludes mock unmapped rooms', () {
      final apiTypes = [
        const RoomTypeModel(
          id: '2',
          hotel: '3',
          name: 'Deluxe Room',
          basePrice: 3000,
        ),
      ];

      final localMockRooms = [
        const RoomModel(
          id: 'room-01',
          roomNumber: '#01',
          floor: 'Floor 1',
          roomType: 'family room',
          pricePerNight: 5000,
          status: RoomStatus.available,
        ),
        const RoomModel(
          id: 'room-02',
          roomNumber: '#02',
          floor: 'Floor 1',
          roomType: 'couple room',
          pricePerNight: 2500,
          status: RoomStatus.available,
        ),
        const RoomModel(
          id: 'room-03',
          roomNumber: '#03',
          floor: 'Floor 1',
          roomType: 'Deluxe Room',
          pricePerNight: 3000,
          status: RoomStatus.available,
        ),
      ];

      final groups = RoomCategoryGroup.groupFromRoomTypesAndRooms(apiTypes, localMockRooms);

      // Must ONLY have 1 category: 'Deluxe Room', never 'family room' or 'couple room'
      expect(groups.length, 1);
      expect(groups.first.categoryName, 'Deluxe Room');
      expect(groups.first.rooms.length, 1);
      expect(groups.first.rooms.first.id, 'room-03');
    });

    test('HotelAdminRepository.fetchRoomTypes requests /room-types without hotel_id', () async {
      String? requestedUrl;

      final fakeClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(
          '''
          {
              "success": true,
              "message": "Room categories retrieved successfully.",
              "data": {
                  "room_categories": [
                      {
                          "id": 1,
                          "hotel_id": 1,
                          "name": "Family Room",
                          "description": "Family Room",
                          "images": [],
                          "room_status_counts": {
                              "available_count": 4,
                              "occupied_count": 1,
                              "total_room_count": 5
                          }
                      }
                  ]
              }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: fakeClient);
      final types = await repo.fetchRoomTypes();

      expect(requestedUrl, endsWith('/api/v1/room-types'));
      expect(requestedUrl, isNot(contains('hotel_id')));
      expect(types.length, 1);
      expect(types.first.name, 'Family Room');
      expect(types.first.totalRoomCount, 5);
    });

    test('HotelAdminRepository.createRoomType sends multipart request to /room-types with name and description', () async {
      String? requestedUrl;
      String? requestedMethod;
      String? contentType;
      String? bodyString;

      final fakeClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        requestedMethod = request.method;
        contentType = request.headers['content-type'];
        bodyString = request.body;

        return http.Response(
          '''
          {
              "success": true,
              "message": "Room category created successfully.",
              "data": {
                  "id": 4,
                  "hotel_id": 3,
                  "name": "Deluxe Room",
                  "description": "Deluxe Room",
                  "images": [],
                  "deleted_at": null,
                  "created_at": "2026-10-13T10:00:00.000Z",
                  "updated_at": "2026-10-13T10:00:00.000Z"
              }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: fakeClient);
      final result = await repo.createRoomType(
        name: 'Deluxe Room',
        description: 'Deluxe Room',
      );

      expect(requestedUrl, endsWith('/room-types'));
      expect(requestedUrl, isNot(contains('hotel_id')));
      expect(requestedMethod, 'POST');
      expect(contentType, contains('multipart/form-data'));
      expect(bodyString, contains('name="name"'));
      expect(bodyString, contains('Deluxe Room'));
      expect(bodyString, contains('name="description"'));
      expect(bodyString, isNot(contains('hotel_id')));
      expect(bodyString, isNot(contains('name="hotel_id"')));
      expect(result.message, 'Room category created successfully.');
      expect(result.roomType.id, '4');
      expect(result.roomType.name, 'Deluxe Room');
    });

    test('HotelAdminRepository.createRoomType throws backend error message on failure', () async {
      final fakeClient = MockClient((request) async {
        return http.Response(
          '''
          {
              "success": false,
              "message": "Room category with name 'Deluxe Room' already exists for this hotel.",
              "errors": []
          }
          ''',
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: fakeClient);

      expect(
        () => repo.createRoomType(name: 'Deluxe Room', description: 'Deluxe Room'),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains("Room category with name 'Deluxe Room' already exists for this hotel."))),
      );
    });

    test('HotelAdminRepository.updateRoomType sends multipart PUT request to /room-types/:id with name and description', () async {
      String? requestedUrl;
      String? requestedMethod;
      String? contentType;
      String? bodyString;

      final fakeClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        requestedMethod = request.method;
        contentType = request.headers['content-type'];
        bodyString = request.body;

        return http.Response(
          '''
          {
              "success": true,
              "message": "Room category updated successfully.",
              "data": {
                  "id": 10,
                  "hotel_id": 2,
                  "name": "Updated Executive Lakeview Suite",
                  "description": "Updated description with upgraded interior furnishings and espresso machine",
                  "images": [],
                  "deleted_at": null,
                  "created_at": "2026-10-13T10:43:03.000Z",
                  "updated_at": "2026-10-13T10:57:10.000Z"
              }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: fakeClient);
      final result = await repo.updateRoomType(
        '10',
        name: 'Updated Executive Lakeview Suite',
        description: 'Updated description with upgraded interior furnishings and espresso machine',
      );

      expect(requestedUrl, endsWith('/room-types/10'));
      expect(requestedMethod, 'PUT');
      expect(contentType, contains('multipart/form-data'));
      expect(bodyString, contains('Updated Executive Lakeview Suite'));
      expect(bodyString, contains('Updated description with upgraded interior furnishings'));
      expect(result.message, 'Room category updated successfully.');
      expect(result.roomType.id, '10');
      expect(result.roomType.name, 'Updated Executive Lakeview Suite');
    });

    test('HotelAdminRepository.updateRoomType throws backend error message on failure', () async {
      final fakeClient = MockClient((request) async {
        return http.Response(
          '''
          {
              "success": false,
              "message": "Room category not found.",
              "errors": []
          }
          ''',
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: fakeClient);

      expect(
        () => repo.updateRoomType('999', name: 'Nonexistent', description: 'None'),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Room category not found.'))),
      );
    });

    test('HotelAdminRepository.deleteRoomType sends DELETE request to /room-types/:id with application/json headers', () async {
      String? requestedUrl;
      String? requestedMethod;
      String? acceptHeader;
      String? contentTypeHeader;

      final fakeClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        requestedMethod = request.method;
        acceptHeader = request.headers['accept'];
        contentTypeHeader = request.headers['content-type'];

        return http.Response(
          '''
          {
              "success": true,
              "message": "Room category deleted successfully."
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: fakeClient);
      final msg = await repo.deleteRoomType('10');

      expect(requestedUrl, endsWith('/room-types/10'));
      expect(requestedMethod, 'DELETE');
      expect(acceptHeader, 'application/json');
      expect(contentTypeHeader, 'application/json');
      expect(msg, 'Room category deleted successfully.');
    });

    test('HotelAdminRepository.deleteRoomType throws backend error message on failure', () async {
      final fakeClient = MockClient((request) async {
        return http.Response(
          '''
          {
              "success": false,
              "message": "Room category not found or already deleted."
          }
          ''',
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: fakeClient);

      expect(
        () => repo.deleteRoomType('10'),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Room category not found or already deleted.'))),
      );
    });

    test('HotelAdminRepository.createRoom sends multipart POST request to /rooms with all required fields', () async {
      String? requestedUrl;
      String? requestedMethod;
      String? contentType;
      String? bodyString;

      final fakeClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        requestedMethod = request.method;
        contentType = request.headers['content-type'];
        bodyString = request.body;

        return http.Response(
          '''
          {
              "success": true,
              "message": "Room created successfully.",
              "data": {
                  "id": 42,
                  "hotel_id": 2,
                  "room_number": "Suite-692",
                  "room_type_id": 10,
                  "floor": "2",
                  "status": "AVAILABLE",
                  "seating_capacity": 3,
                  "bed_count": 1,
                  "bed_type": "1 Super King Bed",
                  "custom_price_per_night": 4500.0,
                  "notes": "Spacious corner room with private balcony and valley view.",
                  "amenities": "High-Speed Wi-Fi, Smart TV 55 inch, Mini Bar, Air Conditioning",
                  "cleaning_duration_minutes": 20,
                  "is_active": true
              }
          }
          ''',
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: fakeClient);
      final result = await repo.createRoom(
        roomNumber: 'Suite-692',
        roomTypeId: '10',
        floor: 2,
        beds: const [(bedType: 'Super King Bed', count: 1)],
        customPricePerNight: 4500.0,
        notes: 'Spacious corner room with private balcony and valley view.',
        amenities: ['High-Speed Wi-Fi', 'Smart TV 55 inch', 'Mini Bar', 'Air Conditioning'],
        cleaningDurationMinutes: 15,
        isActive: true,
      );

      expect(requestedUrl, endsWith('/rooms'));
      expect(requestedMethod, 'POST');
      expect(contentType, contains('multipart/form-data'));
      expect(bodyString, contains('name="beds"'));
      expect(bodyString, contains('Super King'));
      expect(bodyString, contains('"bed_count":1'));
      expect(bodyString, contains('name="amenities"'));
      expect(bodyString, contains('High-Speed Wi-Fi'));
      expect(bodyString, contains('name="cleaning_duration_minutes"'));
      expect(bodyString, contains('15'));
      expect(bodyString, contains('name="is_active"'));
      expect(bodyString, contains('Suite-692'));
      expect(bodyString, contains('room_type_id'));
      expect(bodyString, contains('4500'));
      expect(bodyString, contains('Spacious corner room'));
      expect(bodyString, isNot(contains('name="key_code"')));
      expect(bodyString, isNot(contains('name="status"')));
      expect(bodyString, isNot(contains('name="seating_capacity"')));
      expect(bodyString, isNot(contains('name="bed_count"')));
      expect(bodyString, isNot(contains('hotel_id')));
      expect(result.message, 'Room created successfully.');
      expect(result.room.roomNumber, '#Suite-692');
      expect(result.room.seatingCapacity, 3);
      expect(result.room.bedType, '1 Super King Bed');
      expect(result.room.pricePerNight, 4500.0);
    });

    test('HotelAdminRepository.fetchAdminRooms loads GET /rooms page and parses data.rooms', () async {
      final requestedUrls = <String>[];

      final fakeClient = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        expect(request.method, 'GET');
        expect(request.headers['accept'], 'application/json');
        expect(request.url.queryParameters.containsKey('hotel_id'), isFalse);

        return http.Response(
          '''
          {
            "success": true,
            "message": "Physical rooms retrieved successfully.",
            "data": {
              "rooms": [
                {
                  "id": 13,
                  "hotel_id": 2,
                  "hotel_name": "Niraj Resort",
                  "room_number": "101",
                  "room_type_id": 22,
                  "room_type_name": "Deluxe Room",
                  "floor": 2,
                  "status": "AVAILABLE",
                  "beds": [
                    {"id": 1, "bed_type": "1 King Size Bed", "bed_count": 1}
                  ],
                  "custom_price_per_night": 1000,
                  "notes": "",
                  "key_code": "key 101",
                  "amenities": ["High-Speed Wi-Fi", "Air Conditioning"],
                  "cleaning_started_at": null,
                  "cleaning_duration_minutes": 20,
                  "is_active": true,
                  "deleted_at": null,
                  "images": [],
                  "created_at": "2026-10-13T12:22:06.000Z",
                  "updated_at": "2026-10-13T12:22:06.000Z"
                }
              ],
              "total": 1,
              "page": 1,
              "limit": 10,
              "totalPages": 1
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: fakeClient);
      final rooms = await repo.fetchAdminRooms();

      expect(requestedUrls, hasLength(1));
      expect(requestedUrls.single, contains('/rooms?'));
      expect(requestedUrls.single, contains('page=1'));
      expect(requestedUrls.single, contains('limit=10'));
      expect(requestedUrls.single, contains('sort_order=asc'));
      expect(requestedUrls.single, isNot(contains('hotel_id')));
      expect(rooms, hasLength(1));
      expect(rooms.first.id, '13');
      expect(rooms.first.roomNumber, '#101');
      expect(rooms.first.roomType, 'Deluxe Room');
      expect(rooms.first.roomTypeId, '22');
      expect(rooms.first.floor, 'Floor 2');
      expect(rooms.first.status, RoomStatus.available);
      expect(rooms.first.pricePerNight, 1000);
      expect(rooms.first.bedCount, 1);
      expect(rooms.first.bedType, '1 King Size Bed');
      expect(rooms.first.bedInfoLabel, '1 King Size Bed');
      expect(rooms.first.keyCode, 'key 101');
      expect(rooms.first.seatingCapacity, 2);
      expect(rooms.first.cleaningDurationMinutes, 20);
      expect(rooms.first.amenities, contains('High-Speed Wi-Fi'));
      expect(rooms.first.isAvailable, isTrue);
    });

    test('HotelAdminRepository.fetchRoomsByStatus loads GET /rooms with status and sort_order', () async {
      final requestedUrls = <String>[];

      final fakeClient = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        expect(request.method, 'GET');
        expect(request.headers['accept'], 'application/json');
        expect(request.headers.containsKey('content-type'), isFalse);
        expect(request.url.queryParameters.containsKey('hotel_id'), isFalse);
        expect(request.url.queryParameters['status'], 'AVAILABLE');
        expect(request.url.queryParameters['sort_order'], 'asc');

        return http.Response(
          '''
          {
            "success": true,
            "data": {
              "rooms": [
                {
                  "id": 26,
                  "room_number": "101",
                  "room_type_name": "Family Room",
                  "floor": 1,
                  "status": "AVAILABLE",
                  "bed_type": "1 King Size Bed",
                  "custom_price_per_night": 1000
                }
              ],
              "total": 1,
              "page": 1,
              "limit": 10,
              "totalPages": 1
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: fakeClient);
      final rooms = await repo.fetchRoomsByStatus(status: 'AVAILABLE');

      expect(requestedUrls, hasLength(1));
      expect(requestedUrls.single, contains('page=1'));
      expect(requestedUrls.single, contains('limit=10'));
      expect(requestedUrls.single, contains('sort_order=asc'));
      expect(requestedUrls.single, contains('status=AVAILABLE'));
      expect(requestedUrls.single, isNot(contains('hotel_id')));
      expect(rooms, hasLength(1));
      expect(rooms.first.roomNumber, '#101');
      expect(rooms.first.roomType, 'Family Room');
      expect(rooms.first.pricePerNight, 1000);
    });

    test('HotelAdminRepository.updateRoom sends multipart PUT /rooms/:id with status, notes, and price', () async {
      String? requestedUrl;
      String? requestedMethod;
      String? contentType;
      String? bodyString;

      final fakeClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        requestedMethod = request.method;
        contentType = request.headers['content-type'];
        bodyString = request.body;

        return http.Response(
          '''
          {
            "success": true,
            "message": "Room updated successfully.",
            "data": {
              "id": 1,
              "hotel_id": 2,
              "room_number": "101",
              "room_type_id": 22,
              "room_type_name": "Deluxe Room",
              "floor": 2,
              "status": "MAINTENANCE",
              "custom_price_per_night": 4800,
              "notes": "AC maintenance scheduled with technician.",
              "amenities": [],
              "is_active": true,
              "deleted_at": null,
              "images": []
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: fakeClient);
      final result = await repo.updateRoom(
        '1',
        roomNumber: '101',
        roomTypeId: '22',
        floor: 2,
        status: 'MAINTENANCE',
        notes: 'AC maintenance scheduled with technician.',
        customPricePerNight: 4800,
        images: [
          http.MultipartFile.fromBytes('photo', [1, 2, 3], filename: 'room.jpg'),
        ],
      );

      expect(requestedUrl, endsWith('/rooms/1'));
      expect(requestedUrl, isNot(contains('hotel_id')));
      expect(requestedMethod, 'PUT');
      expect(contentType, contains('multipart/form-data'));
      expect(bodyString, contains('name="status"'));
      expect(bodyString, contains('MAINTENANCE'));
      expect(bodyString, contains('name="notes"'));
      expect(bodyString, contains('AC maintenance scheduled with technician.'));
      expect(bodyString, contains('name="custom_price_per_night"'));
      expect(bodyString, contains('4800.00'));
      expect(bodyString, contains('name="images"'));
      expect(bodyString, contains('filename="room.jpg"'));
      expect(bodyString, isNot(contains('hotel_id')));
      expect(bodyString, isNot(contains('gst')));
      expect(result.message, 'Room updated successfully.');
      expect(result.room.status, RoomStatus.maintenance);
      expect(result.room.pricePerNight, 4800);
    });

    test('HotelAdminRepository.deleteRoom sends DELETE /rooms/:id with JSON headers', () async {
      String? requestedUrl;
      String? requestedMethod;
      String? contentType;
      String? accept;

      final fakeClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        requestedMethod = request.method;
        contentType = request.headers['content-type'];
        accept = request.headers['accept'];

        return http.Response(
          '''
          {
            "success": true,
            "message": "Room deleted successfully."
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: fakeClient);
      final message = await repo.deleteRoom('1');

      expect(requestedUrl, endsWith('/rooms/1'));
      expect(requestedUrl, isNot(contains('/admin/rooms')));
      expect(requestedUrl, isNot(contains('hotel_id')));
      expect(requestedMethod, 'DELETE');
      expect(contentType, 'application/json');
      expect(accept, 'application/json');
      expect(message, 'Room deleted successfully.');
    });

    test('HotelAdminRepository.fetchAdminDashboard reads GET /api/v1/dashboard', () async {
      String? requestedUrl;
      String? requestedMethod;
      String? contentType;
      String? accept;
      String? body;

      final fakeClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        requestedMethod = request.method;
        contentType = request.headers['content-type'];
        accept = request.headers['accept'];
        body = request.body;
        return http.Response(
          '''
          {
            "success": true,
            "message": "Hotel admin dashboard retrieved successfully.",
            "data": {
              "hotel": {"id": 2, "name": "Niraj Resort", "currency": "INR", "tax_percentage": 18, "gst_enabled": true},
              "kpis": {
                "today_revenue": 20060,
                "month_revenue": 25960,
                "total_outstanding_due": 0,
                "occupancy_rate_percentage": 0,
                "total_physical_rooms": 5,
                "active_staff_count": 4
              },
              "today_pulse": {
                "actual_checked_in_today": 10,
                "expected_check_outs_today": 0,
                "actual_checked_out_today": 10,
                "current_in_house_guests": 0
              },
              "room_status_summary": {
                "AVAILABLE": 5, "RESERVED": 0, "OCCUPIED": 0, "CLEANING": 0, "MAINTENANCE": 0, "BLOCKED": 0
              },
              "revenue_by_payment_method": {
                "CASH": 14440, "ONLINE": 0, "CARD": 0, "UPI": 11520, "BANK_TRANSFER": 0
              },
              "weekly_revenue_graph": [
                {"date": "2026-10-14", "day": "Wednesday", "revenue": 5900},
                {"date": "2026-10-15", "day": "Thursday", "revenue": 23010},
                {"date": "2026-10-16", "day": "Friday", "revenue": 2784.8}
              ],
              "subscription_quota": {
                "plan_name": "Starter Boutique",
                "max_rooms_allowed": 15,
                "rooms_configured": 5,
                "remaining_room_slots": 10,
                "days_left": 28,
                "is_active": true
              }
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = HotelAdminRepository(client: fakeClient);
      final dashboard = await repo.fetchAdminDashboard();

      expect(requestedMethod, 'GET');
      expect(requestedUrl, endsWith('/api/v1/dashboard'));
      expect(requestedUrl, isNot(contains('hotel_id')));
      expect(contentType, 'application/json');
      expect(accept, 'application/json');
      expect(body, isEmpty);
      expect(dashboard.hotelName, 'Niraj Resort');
      expect(dashboard.todayRevenue, 20060);
      expect(dashboard.monthRevenue, 25960);
      expect(dashboard.outstandingDue, 0);
      expect(dashboard.occupancyRatePercentage, 0);
      expect(dashboard.totalPhysicalRooms, 5);
      expect(dashboard.activeStaffCount, 4);
      expect(dashboard.inHouseGuests, 0);
      expect(dashboard.availableRooms, 5);
      expect(dashboard.cash, 14440);
      expect(dashboard.upi, 11520);
      expect(dashboard.checkedInToday, 10);
      expect(dashboard.planName, 'Starter Boutique');
      expect(dashboard.gstEnabled, isTrue);
      expect(dashboard.weeklyRevenue, hasLength(3));
      expect(dashboard.weeklyRevenue.first.shortDay, 'Wed');
      expect(dashboard.weeklyRevenue.first.revenue, 5900);
      expect(dashboard.weeklyRevenue.last.day, 'Friday');
      expect(dashboard.weeklyRevenue.last.revenue, 2784.8);
    });

    test('fetchDashboardSummary requests the custom date dashboard summary', () async {
      Uri? requestedUri;
      String? requestedMethod;
      String? body;

      final repo = HotelAdminRepository(
        client: MockClient((request) async {
          requestedUri = request.url;
          requestedMethod = request.method;
          body = request.body;
          expect(request.headers['accept'], 'application/json');
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Dashboard summary retrieved successfully.',
              'data': {
                'period_start_date': '19-10-2026',
                'period_end_date': '19-10-2026',
                'total_collected_amount': 6600,
                'collection_by_payment_method': {
                  'cash_collected_amount': 6540,
                  'online_collected_amount': 0,
                  'card_collected_amount': 0,
                  'upi_collected_amount': 60,
                  'bank_transfer_collected_amount': 0,
                },
                'total_outstanding_amount': 540,
                'total_booking_count': 2,
                'total_guest_count': 6,
                'total_booking_amount': 7080,
                'total_discount_amount': 2000,
                'total_extra_charges_amount': 0,
                'total_late_checkout_charges_amount': 0,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final summary = await repo.fetchDashboardSummary(
        startDate: DateTime(2026, 10, 19),
        endDate: DateTime(2026, 10, 19),
      );

      expect(requestedMethod, 'GET');
      expect(requestedUri?.path, endsWith('/api/v1/dashboard/summary'));
      expect(requestedUri?.query, contains('start_date=2026-10-19'));
      expect(requestedUri?.query, contains('end_date=2026-10-19'));
      expect(requestedUri?.query, isNot(contains('hotel_id')));
      expect(body, isEmpty);
      expect(summary.totalCollectedAmount, 6600);
      expect(summary.cashCollectedAmount, 6540);
      expect(summary.upiCollectedAmount, 60);
      expect(summary.totalOutstandingAmount, 540);
      expect(summary.totalBookingCount, 2);
      expect(summary.totalGuestCount, 6);
      expect(summary.totalBookingAmount, 7080);
      expect(summary.totalDiscountAmount, 2000);
    });

    test('exportGstReport requests the custom date PDF export', () async {
      Uri? exportUri;
      final repo = DashboardRepository(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/reports/gst/export')) {
            exportUri = request.url;
            expect(request.method, 'GET');
            expect(request.url.query, contains('start_date=2026-10-01'));
            expect(request.url.query, contains('end_date=2026-10-31'));
            expect(request.url.query, contains('format=pdf'));
            expect(request.url.query, isNot(contains('hotel_id')));
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'GST report exported successfully.',
                'data': {
                  'url': 'https://hotelmanagementbackendnew-production.up.railway.app/uploads/pdfs/gst_report.pdf',
                  'file_name': 'gst_report.pdf',
                  'format': 'pdf',
                  'row_count': 2,
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('pdf-bytes', 200);
        }),
      );

      final file = await repo.exportGstReport(
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
        format: 'pdf',
      );

      expect(exportUri, isNotNull);
      expect(file.fileName, 'gst_report.pdf');
      expect(file.bytes, isNotEmpty);
    });
  });
}

