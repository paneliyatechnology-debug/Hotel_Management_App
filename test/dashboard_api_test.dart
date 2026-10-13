import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_own_pms_system/core/widgets/status_badge.dart';
import 'package:my_own_pms_system/features/dashboard/data/models/guest_folio_model.dart';
import 'package:my_own_pms_system/features/dashboard/data/models/hotel_stats_model.dart';
import 'package:my_own_pms_system/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:my_own_pms_system/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:my_own_pms_system/features/rooms/data/models/room_model.dart';
import 'package:my_own_pms_system/features/rooms/data/models/room_category_model.dart';
import 'package:my_own_pms_system/features/check_in_wizard/data/models/check_in_form_data.dart';

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
      expect(parsedRooms[0].bedInfoLabel, '1 Bed (1 King Size Bed)');
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
        } else if (request.url.path.contains('/rooms/available')) {
          return http.Response(availableRoomsApiResponse, 200, headers: {'content-type': 'application/json'});
        } else if (request.url.path.contains('/bookings')) {
          if (request.url.path.contains('/check-out')) {
            expect(request.method, 'POST');
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['dailyRoomRate'], 2160);
            expect(body['lateCheckoutType'], 'none');
            expect(body['paymentMethod'], 'CASH');
            isCheckedOut = true;
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Checkout complete for tushar. Room is now marked for CLEANING.',
                'data': {
                  'bookingNumber': 'BK-187636-463',
                  'totalAmount': 2160,
                  'totalPaid': 2160,
                  'dueRemaining': 0,
                  'roomStatus': 'CLEANING',
                  'receiptNumber': ''
                }
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'POST') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['isWalkIn'], true);
            expect(body['isInstantCheckIn'], true);
            expect(body['reusePreviousId'], true);
            expect(body['paymentMethod'], 'CASH');
            expect(body['fullName'], 'Niraj Vekariya');
            expect(body['mobileNumber'], '08849218118');
            expect(body['email'], 'nirajvekariya2209@gmail.com');
            expect(body['roomNumber'], '01');
            expect(body['advancePaymentAmount'], 2000);
            expect(body['govtIdType'], 'AADHAAR');
            return http.Response(postBookingApiResponse, 201, headers: {'content-type': 'application/json'});
          }
          if (isCheckedOut) {
            return http.Response(
              bookingsApiResponse.replaceAll(
                '"numberOfNights": 1',
                '"numberOfNights": 1, "status": "CHECKED_OUT", "actualCheckOut": "2026-09-27T12:00:00.000Z"',
              ),
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

    test('fetchBookings sets live bookings into repository folios', () async {
      final folios = await repository.fetchBookings();
      expect(folios.length, 1);
      expect(folios[0].guestName, 'Niraj Vekariya');
      expect(folios[0].bookingId, 'BK-058260-778');
      expect(folios[0].status, FolioStatus.inHouse);
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

    test('checkoutFolio calls /check-out endpoint with custom payload and marks room as cleaning', () async {
      await repository.fetchAvailableRooms();
      final folios = await repository.fetchBookings();
      expect(folios.isNotEmpty, isTrue);

      final targetFolioId = folios.first.id;

      final result = await repository.checkoutFolio(
        targetFolioId,
        customPayload: {
          'dailyRoomRate': 2160,
          'gracePeriodMinutes': 10,
          'hourlyRate': 180,
          'lateCheckoutFee': 0,
          'lateCheckoutHours': 0,
          'lateCheckoutMinutes': 0,
          'lateCheckoutType': 'none',
          'paymentMethod': 'CASH',
          'paymentReference': '',
          'settlementPaymentAmount': 0,
          'transactionId': '',
        },
      );

      expect(result['success'], isTrue);
      expect(result['message'], contains('CLEANING'));
      expect(result['data']['bookingNumber'], 'BK-187636-463');

      // Verify repo updated the folio to departed and room to cleaning
      final updatedFolios = await repository.getFolios();
      expect(updatedFolios.first.status, FolioStatus.departed);

      final updatedRooms = await repository.getRooms();
      final room01 = updatedRooms.firstWhere((r) => r.roomNumber == '#01');
      expect(room01.status, RoomStatus.cleaning);
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
  });
}

