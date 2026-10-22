import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_own_pms_system/features/guests/data/models/guest_model.dart';
import 'package:my_own_pms_system/features/guests/data/repositories/guests_repository.dart';
import 'package:my_own_pms_system/features/guests/presentation/bloc/guests_bloc.dart';
import 'package:my_own_pms_system/features/guests/presentation/bloc/guests_event.dart';
import 'package:my_own_pms_system/features/guests/presentation/bloc/guests_state.dart';

const String sampleGuestsApiResponse = r'''{
    "success": true,
    "total": 4,
    "count": 4,
    "page": 1,
    "totalPages": 1,
    "data": [
        {
            "idProof": {
                "idType": "AADHAAR",
                "idNumber": "5421-9876-1234",
                "frontImage": "",
                "backImage": "",
                "verificationStatus": "VERIFIED",
                "verifiedBy": "6abce421513926b760aff5b2",
                "verifiedAt": "2026-10-06T05:25:48.495Z",
                "verificationNotes": ""
            },
            "_id": "6ac4865cb79de1286fbf406f",
            "hotel": "6abce211513926b760aff542",
            "fullName": "Niraj Vekariya",
            "mobileNumber": "+91 98765 43210",
            "email": "niraj.v@example.com",
            "gender": "Male",
            "nationality": "Indian",
            "address": "",
            "city": "",
            "state": "",
            "country": "India",
            "emergencyContact": "",
            "signature": "",
            "totalVisits": 1,
            "totalSpent": 0,
            "isDeleted": false,
            "createdAt": "2026-10-06T05:25:48.497Z",
            "updatedAt": "2026-10-06T05:25:48.497Z",
            "__v": 0,
            "name": "Niraj Vekariya",
            "phone": "+91 98765 43210",
            "status": "REGISTERED",
            "roomAssigned": "Not Assigned",
            "roomNumber": "Not Assigned",
            "roomNumbers": [],
            "roomIds": [],
            "checkInDate": "N/A",
            "checkOutDate": "N/A",
            "checkInDateRaw": null,
            "checkOutDateRaw": null,
            "checkInTime": "14:00",
            "checkOutTime": "12:00",
            "actualCheckIn": null,
            "actualCheckOut": null,
            "activeBookingNumber": "N/A",
            "paymentStatus": "PENDING",
            "balanceAmount": 0,
            "dueAmount": 0,
            "advanceAmount": 0,
            "paidAmount": 0,
            "totalAmount": 0,
            "accompanyingGuests": [],
            "idType": "AADHAAR",
            "idNumber": "5421-9876-1234",
            "govtIdType": "AADHAAR",
            "govtIdNumber": "5421-9876-1234",
            "idVerified": true
        },
        {
            "idProof": {
                "idType": "AADHAAR",
                "idNumber": "5654 3234 5666",
                "frontImage": "",
                "backImage": "",
                "verificationStatus": "VERIFIED",
                "verifiedBy": "6abce421513926b760aff5b2",
                "verifiedAt": "2026-10-02T06:31:00.793Z",
                "verificationNotes": ""
            },
            "_id": "6abf4fa4c912efe800d407cb",
            "hotel": "6abce211513926b760aff542",
            "fullName": "Keyur Sangani",
            "mobileNumber": "dfcdccccccccccccccc",
            "email": "jatin.patel@gmail.com",
            "gender": "Male",
            "nationality": "Indian",
            "address": "",
            "city": "",
            "state": "",
            "country": "India",
            "emergencyContact": "",
            "signature": "",
            "totalVisits": 1,
            "totalSpent": 0,
            "isDeleted": false,
            "createdAt": "2026-10-02T06:31:00.794Z",
            "updatedAt": "2026-10-02T06:31:31.567Z",
            "__v": 0,
            "name": "Keyur Sangani",
            "phone": "dfcdccccccccccccccc",
            "status": "CHECKED_OUT",
            "roomAssigned": "01",
            "roomNumber": "01",
            "roomNumbers": [
                "01"
            ],
            "roomIds": [
                "6abe27bb48737b246de2b75e"
            ],
            "checkInDate": "2/10/2026",
            "checkOutDate": "2/10/2026",
            "checkInDateRaw": "2026-10-02T12:01:00.000Z",
            "checkOutDateRaw": "2026-10-03T12:00:00.000Z",
            "checkInTime": "12:01",
            "checkOutTime": "06:46",
            "actualCheckIn": "2026-10-02T06:31:31.571Z",
            "actualCheckOut": "2026-10-02T06:46:20.771Z",
            "activeBookingNumber": "BK-691571-125",
            "paymentStatus": "PAID",
            "balanceAmount": 0,
            "dueAmount": 0,
            "advanceAmount": 3500,
            "paidAmount": 3500,
            "totalAmount": 3500,
            "accompanyingGuests": [],
            "idType": "AADHAAR",
            "idNumber": "5654 3234 5666",
            "govtIdType": "AADHAAR",
            "govtIdNumber": "5654 3234 5666",
            "idVerified": true
        },
        {
            "idProof": {
                "idType": "AADHAAR",
                "idNumber": "4251 6545 4135",
                "frontImage": "",
                "backImage": "",
                "verificationStatus": "VERIFIED",
                "verifiedBy": "6abce421513926b760aff5b2",
                "verifiedAt": "2026-10-02T04:12:56.934Z",
                "verificationNotes": ""
            },
            "_id": "6abf2f48c912efe800d3fe07",
            "hotel": "6abce211513926b760aff542",
            "fullName": "niraj vekariya",
            "mobileNumber": "09426886960",
            "email": "tushartpayevs@gmail.com",
            "gender": "Male",
            "nationality": "Indian",
            "address": "",
            "city": "",
            "state": "",
            "country": "India",
            "emergencyContact": "",
            "signature": "",
            "totalVisits": 1,
            "totalSpent": 0,
            "isDeleted": false,
            "createdAt": "2026-10-02T04:12:56.935Z",
            "updatedAt": "2026-10-02T04:12:56.935Z",
            "__v": 0,
            "name": "niraj vekariya",
            "phone": "09426886960",
            "status": "CHECKED_OUT",
            "roomAssigned": "02",
            "roomNumber": "02",
            "roomNumbers": [
                "02"
            ],
            "roomIds": [
                "6abe284948737b246de2b8da"
            ],
            "checkInDate": "2/10/2026",
            "checkOutDate": "2/10/2026",
            "checkInDateRaw": "2026-10-02T09:42:00.000Z",
            "checkOutDateRaw": "2026-10-03T12:00:00.000Z",
            "checkInTime": "09:42",
            "checkOutTime": "06:46",
            "actualCheckIn": "2026-10-02T04:12:56.938Z",
            "actualCheckOut": "2026-10-02T06:46:09.523Z",
            "activeBookingNumber": "BK-376938-209",
            "paymentStatus": "PAID",
            "balanceAmount": 0,
            "dueAmount": 0,
            "advanceAmount": 2000,
            "paidAmount": 2000,
            "totalAmount": 1000,
            "accompanyingGuests": [],
            "idType": "AADHAAR",
            "idNumber": "4251 6545 4135",
            "govtIdType": "AADHAAR",
            "govtIdNumber": "4251 6545 4135",
            "idVerified": true
        },
        {
            "idProof": {
                "idType": "AADHAAR",
                "idNumber": "8075 4434 0112",
                "frontImage": "",
                "backImage": "",
                "verificationStatus": "VERIFIED",
                "verifiedBy": "6abce421513926b760aff5b2",
                "verifiedAt": "2026-10-01T13:49:13.316Z",
                "verificationNotes": ""
            },
            "_id": "6abe64d9c912efe800d3fbf7",
            "hotel": "6abce211513926b760aff542",
            "fullName": "tushar paneliya",
            "mobileNumber": "8849218118",
            "email": "tpatel5241@gmail.com",
            "gender": "Male",
            "nationality": "Indian",
            "address": "",
            "city": "",
            "state": "",
            "country": "India",
            "emergencyContact": "",
            "signature": "",
            "totalVisits": 1,
            "totalSpent": 0,
            "isDeleted": false,
            "createdAt": "2026-10-01T13:49:13.318Z",
            "updatedAt": "2026-10-01T13:49:13.318Z",
            "__v": 0,
            "name": "tushar paneliya",
            "phone": "8849218118",
            "status": "CHECKED_OUT",
            "roomAssigned": "01",
            "roomNumber": "01",
            "roomNumbers": [
                "01"
            ],
            "roomIds": [
                "6abe27bb48737b246de2b75e"
            ],
            "checkInDate": "1/10/2026",
            "checkOutDate": "2/10/2026",
            "checkInDateRaw": "2026-10-01T19:19:00.000Z",
            "checkOutDateRaw": "2026-10-02T12:00:00.000Z",
            "checkInTime": "19:19",
            "checkOutTime": "04:13",
            "actualCheckIn": "2026-10-01T13:49:13.324Z",
            "actualCheckOut": "2026-10-02T04:13:18.315Z",
            "activeBookingNumber": "BK-553324-802",
            "paymentStatus": "PAID",
            "balanceAmount": 0,
            "dueAmount": 0,
            "advanceAmount": 5000,
            "paidAmount": 5000,
            "totalAmount": 5000,
            "accompanyingGuests": [],
            "idType": "AADHAAR",
            "idNumber": "8075 4434 0112",
            "govtIdType": "AADHAAR",
            "govtIdNumber": "8075 4434 0112",
            "idVerified": true
        }
    ]
}''';

void main() {
  group('Guests API Response Parsing Tests', () {
    test('Parses full GuestsApiResponse correctly from backend JSON', () {
      final jsonMap = jsonDecode(sampleGuestsApiResponse) as Map<String, dynamic>;
      final response = GuestsApiResponse.fromJson(jsonMap);

      expect(response.success, isTrue);
      expect(response.total, equals(4));
      expect(response.count, equals(4));
      expect(response.page, equals(1));
      expect(response.totalPages, equals(1));
      expect(response.data.length, equals(4));

      // 1. Guest 1: Niraj Vekariya (Registered)
      final guest1 = response.data[0];
      expect(guest1.id, equals('6ac4865cb79de1286fbf406f'));
      expect(guest1.fullName, equals('Niraj Vekariya'));
      expect(guest1.mobile, equals('+91 98765 43210'));
      expect(guest1.email, equals('niraj.v@example.com'));
      expect(guest1.currentStatus, equals(GuestStatus.registered));
      expect(guest1.roomAssigned, equals('Not Assigned'));
      expect(guest1.kyc.idType, equals('Aadhaar Card'));
      expect(guest1.kyc.idNumber, equals('5421-9876-1234'));
      expect(guest1.kyc.isVerified, isTrue);
      expect(guest1.paymentStatus, equals('PENDING'));

      // 2. Guest 2: Keyur Sangani (Checked-Out, Room 01)
      final guest2 = response.data[1];
      expect(guest2.id, equals('6abf4fa4c912efe800d407cb'));
      expect(guest2.fullName, equals('Keyur Sangani'));
      expect(guest2.currentStatus, equals(GuestStatus.checkedOut));
      expect(guest2.roomAssigned, equals('01'));
      expect(guest2.activeBookingNumber, equals('BK-691571-125'));
      expect(guest2.paidAmount, equals(3500.0));
      expect(guest2.totalAmount, equals(3500.0));
      expect(guest2.paymentStatus, equals('PAID'));

      // 3. Guest 3: niraj vekariya (Checked-Out, Room 02)
      final guest3 = response.data[2];
      expect(guest3.id, equals('6abf2f48c912efe800d3fe07'));
      expect(guest3.fullName, equals('niraj vekariya'));
      expect(guest3.roomAssigned, equals('02'));
      expect(guest3.activeBookingNumber, equals('BK-376938-209'));
      expect(guest3.currentStatus, equals(GuestStatus.checkedOut));

      // 4. Guest 4: tushar paneliya (Checked-Out, Room 01)
      final guest4 = response.data[3];
      expect(guest4.id, equals('6abe64d9c912efe800d3fbf7'));
      expect(guest4.fullName, equals('tushar paneliya'));
      expect(guest4.roomAssigned, equals('01'));
      expect(guest4.activeBookingNumber, equals('BK-553324-802'));
      expect(guest4.paidAmount, equals(5000.0));
    });

    test('GuestsRepository calls API endpoint and returns parsed models with custom Client', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/bookings'));
        expect(request.url.queryParameters['page'], equals('1'));
        expect(request.url.queryParameters['limit'], equals('10'));
        expect(request.url.queryParameters.containsKey('status'), isFalse);
        expect(request.url.queryParameters.containsKey('booking_status'), isFalse);
        expect(request.url.queryParameters.containsKey('hotel_id'), isFalse);
        expect(request.method, equals('GET'));
        return http.Response(sampleGuestsApiResponse, 200, headers: {'content-type': 'application/json'});
      });

      final repo = GuestsRepository(client: mockClient);
      final guests = await repo.getGuests(forceRefresh: true);

      expect(guests.length, equals(4));
      expect(guests.first.fullName, equals('Niraj Vekariya'));
      expect(guests.first.currentStatus, equals(GuestStatus.registered));
      expect(guests[1].fullName, equals('Keyur Sangani'));
      expect(guests[1].roomAssigned, equals('01'));
    });

    test('GuestProfileModel parses live booking JSON (Jash Korat) accurately', () {
      const liveBookingJson = r'''{
        "guestsCount": { "adults": 1, "children": 0 },
        "_id": "6ac634929f68d352d6cf530e",
        "bookingNumber": "BK-482512-167",
        "guest": {
          "_id": "6ac5e78eaedfa42ab283fbe4",
          "name": "Jash Korat",
          "fullName": "Jash Korat",
          "phone": "1234567899",
          "mobileNumber": "1234567899",
          "email": "jasminkorat04@gmail.com",
          "gender": "Male",
          "idProof": {
            "idType": "AADHAAR",
            "idNumber": "1111 1111 1111",
            "verificationStatus": "VERIFIED"
          }
        },
        "room": {
          "_id": "6ac4b53f444a0645ee9253c8",
          "roomNumber": "202",
          "floor": 1,
          "status": "OCCUPIED"
        },
        "roomNumber": "202",
        "roomType": {
          "_id": "6ac4b3e3444a0645ee925369",
          "name": "Executive Ocean View Suite 2",
          "basePrice": 4500
        },
        "checkInDate": "2026-10-07",
        "checkOutDate": "2026-10-08",
        "totalAmount": 4860,
        "paidAmount": 211,
        "dueAmount": 4649,
        "paymentStatus": "PENDING",
        "status": "CHECKED_IN"
      }''';

      final decoded = jsonDecode(liveBookingJson) as Map<String, dynamic>;
      final guest = GuestProfileModel.fromJson(decoded);

      expect(guest.fullName, 'Jash Korat');
      expect(guest.mobile, '1234567899');
      expect(guest.email, 'jasminkorat04@gmail.com');
      expect(guest.roomAssigned, '202');
      expect(guest.activeBookingNumber, 'BK-482512-167');
      expect(guest.totalAmount, 4860.0);
      expect(guest.paidAmount, 211.0);
      expect(guest.balanceAmount, 4649.0);
      expect(guest.currentStatus, GuestStatus.inHouse);
      expect(guest.kyc.idType, 'Aadhaar Card');
      expect(guest.kyc.idNumber, '1111 1111 1111');
      expect(guest.kyc.isVerified, isTrue);
    });

    test('GuestsBloc loads guests from API repository and filters properly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(sampleGuestsApiResponse, 200, headers: {'content-type': 'application/json'});
      });

      final repo = GuestsRepository(client: mockClient);
      final bloc = GuestsBloc(repository: repo);

      bloc.add(const LoadGuestsEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<GuestsState>((s) => s.status == GuestsStatus.loading),
          predicate<GuestsState>((s) {
            return s.status == GuestsStatus.loaded &&
                s.allGuests.length == 4 &&
                s.registeredCount == 1 &&
                s.checkedOutCount == 3;
          }),
        ]),
      );

      // Search by name 'Keyur'
      bloc.add(const SearchGuestsEvent('Keyur'));
      await expectLater(
        bloc.stream,
        emits(predicate<GuestsState>((s) =>
            s.filteredGuests.length == 1 &&
            s.filteredGuests.first.fullName == 'Keyur Sangani')),
      );

      // Filter by Registered status (Keyur is Checked-Out, so should be empty)
      bloc.add(const ChangeStatusFilterEvent('Registered'));
      await expectLater(
        bloc.stream,
        emits(predicate<GuestsState>((s) => s.filteredGuests.isEmpty)),
      );

      // Clear search query, Registered status still active
      bloc.add(const SearchGuestsEvent(''));
      await expectLater(
        bloc.stream,
        emits(predicate<GuestsState>((s) =>
            s.filteredGuests.length == 1 &&
            s.filteredGuests.first.fullName == 'Niraj Vekariya' &&
            s.filteredGuests.first.currentStatus == GuestStatus.registered)),
      );

      // Switch back to All status
      bloc.add(const ChangeStatusFilterEvent('All'));
      await expectLater(
        bloc.stream,
        emits(predicate<GuestsState>((s) => s.filteredGuests.length == 4)),
      );

      await bloc.close();
    });
  });
}
