import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/repositories/authenticated_http_client.dart';
import '../../../rooms/data/models/room_category_model.dart';
import '../../../rooms/data/models/room_model.dart';
import '../models/admin_models.dart';

class HotelAdminRepository {
  static const String baseUrl = 'https://hotelmanagementbackend-dev.up.railway.app/api/v1';

  final http.Client _client;
  final AuthRepository _authRepository;

  AuthRepository get authRepository => _authRepository;

  static HotelAdminRepository? _instance;

  factory HotelAdminRepository({
    http.Client? client,
    AuthRepository? authRepository,
  }) {
    if (_instance == null || client != null || authRepository != null) {
      _instance = HotelAdminRepository._internal(
        client: client,
        authRepository: authRepository,
      );
    }
    return _instance!;
  }

  HotelAdminRepository._internal({
    http.Client? client,
    AuthRepository? authRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _client = client ??
            AuthenticatedHttpClient(
              authRepository: authRepository ?? AuthRepository(),
            );

  // 1. Dashboard Overview
  Future<Map<String, dynamic>> fetchAdminDashboard() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['data'] as Map<String, dynamic>? ?? json;
    }
    throw Exception('Failed to load admin dashboard (status: ${response.statusCode})');
  }

  // 2. Daily Collections Telemetry & Transactions
  Future<Map<String, dynamic>> fetchDailyCollections({
    String? paymentMethod,
    String? query,
    int page = 1,
    int limit = 50,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/daily-collections').replace(
      queryParameters: {
        if (paymentMethod != null && paymentMethod != 'ALL') 'paymentMethod': paymentMethod,
        if (query != null && query.isNotEmpty) 'query': query,
        'handoverPage': '$page',
        'handoverLimit': '$limit',
      },
    );

    final response = await _client.get(uri, headers: {'Content-Type': 'application/json'});
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? json;
      final telemetry = DailyCollectionsTelemetry.fromJson(data['telemetry'] as Map<String, dynamic>?);
      final rawTransactions = data['transactions'] as List<dynamic>? ?? [];
      final transactions = rawTransactions
          .map((e) => AdminPaymentTransaction.fromJson(e as Map<String, dynamic>))
          .toList();

      return {
        'telemetry': telemetry,
        'transactions': transactions,
        'raw': data,
      };
    }
    throw Exception('Failed to load daily collections (status: ${response.statusCode})');
  }

  // 3. Settle Cash Drawer / Handover to Vault
  Future<Map<String, dynamic>> settleHandover({String notes = ''}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/admin/daily-collections/handover'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'notes': notes}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to settle cash drawer');
  }

  // 4. Staff Management (Receptionists)
  Future<List<StaffMemberModel>> fetchStaffMembers() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/admin/receptionists'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['data'] as List<dynamic>? ?? [];
      return list.map((e) => StaffMemberModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load staff members (status: ${response.statusCode})');
  }

  Future<({StaffMemberModel staff, String message})> createStaffMember({
    required String name,
    required String email,
    required String phone,
    String role = 'RECEPTIONIST',
    String shift = 'Morning (07:00 - 15:00)',
  }) async {
    var cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length > 10 && cleanPhone.startsWith('91')) {
      cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/admin/receptionists'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': cleanPhone,
        'role': role,
        'shift': shift,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final staff = StaffMemberModel.fromJson(json['data'] as Map<String, dynamic>);
      final message = json['message'] as String? ?? 'Staff member onboarded successfully.';
      return (staff: staff, message: message);
    }
    String message = 'Failed to create staff member';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = err['message'] as String? ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<({StaffMemberModel staff, String message})> updateStaffMember(
    String id, {
    required String name,
    required String email,
    required String phone,
    String? role,
    String? shift,
  }) async {
    var cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length > 10 && cleanPhone.startsWith('91')) {
      cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
    }
    final response = await _client.put(
      Uri.parse('$baseUrl/admin/receptionists/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': cleanPhone,
        if (role != null) 'role': role,
        if (shift != null) 'shift': shift,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final staff = StaffMemberModel.fromJson(json['data'] as Map<String, dynamic>);
      final message = json['message'] as String? ?? 'Staff details updated successfully.';
      return (staff: staff, message: message);
    }
    String message = 'Failed to update staff member';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = err['message'] as String? ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<String> updateStaffStatus(String id, String status) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/admin/receptionists/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['message'] as String? ?? 'Staff member status updated to $status.';
      } catch (_) {
        return 'Staff member status updated to $status.';
      }
    }

    String message = 'Failed to update staff status (${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = err['message'] as String? ?? message;
    } catch (_) {
      // body is not JSON — use default message
    }
    throw Exception(message);
  }

  Future<String> deleteStaffMember(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/admin/receptionists/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['message'] as String? ?? 'Staff member removed successfully.';
      } catch (_) {
        return 'Staff member removed successfully.';
      }
    }
    String message = 'Failed to delete staff member';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = err['message'] as String? ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  // 5. Rooms Management
  Future<List<RoomModel>> fetchAdminRooms() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/admin/rooms'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['data'] as List<dynamic>? ?? [];
      return list.map((e) => RoomModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load admin rooms (status: ${response.statusCode})');
  }

  Future<({List<RoomModel> rooms, String message})> createRoomsBatch({
    required List<String> roomNumbers,
    required String roomTypeId,
    int floor = 1,
    int seatingCapacity = 2,
    int bedCount = 1,
    String bedType = '1 King Size Bed',
    double? customPricePerNight,
    String status = 'AVAILABLE',
    String notes = '',
    List<String> amenities = const [],
    bool gstEnabled = true,
    double gstRate = 0,
    double cgstRate = 0,
    double sgstRate = 0,
    bool taxInclusive = false,
  }) async {
    final createdRooms = <RoomModel>[];
    String lastMessage = 'Successfully created ${roomNumbers.length} room(s).';
    for (final number in roomNumbers) {
      final body = {
        'roomNumber': number.trim(),
        'roomType': roomTypeId,
        'floor': floor,
        'seatingCapacity': seatingCapacity,
        'bedCount': bedCount,
        'bedType': bedType,
        if (customPricePerNight != null && customPricePerNight > 0)
          'customPricePerNight': customPricePerNight,
        'status': status,
        'notes': notes,
        'amenities': amenities,
        'gstEnabled': gstEnabled,
        'gstRate': gstRate,
        'cgstRate': cgstRate,
        'sgstRate': sgstRate,
        'taxInclusive': taxInclusive,
      };

      final response = await _client.post(
        Uri.parse('$baseUrl/admin/rooms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['message'] != null) {
          lastMessage = json['message'] as String;
        }
        if (json['data'] != null) {
          createdRooms.add(RoomModel.fromJson(json['data'] as Map<String, dynamic>));
        }
      } else {
        String msg = 'Failed to create room $number (${response.statusCode})';
        try {
          final err = jsonDecode(response.body) as Map<String, dynamic>;
          msg = err['message'] as String? ?? msg;
        } catch (_) {}
        throw Exception(msg);
      }
    }
    return (rooms: createdRooms, message: lastMessage);
  }

  Future<({RoomModel room, String message})> updateRoom(
    String id, {
    required String roomNumber,
    required String roomTypeId,
    int floor = 1,
    int seatingCapacity = 2,
    int bedCount = 1,
    String bedType = '1 King Size Bed',
    double? customPricePerNight,
    String status = 'AVAILABLE',
    String notes = '',
    List<String> amenities = const [],
    bool gstEnabled = true,
    double gstRate = 0,
    double cgstRate = 0,
    double sgstRate = 0,
    bool taxInclusive = false,
  }) async {
    final body = {
      'roomNumber': roomNumber.trim(),
      'roomType': roomTypeId,
      'floor': floor,
      'seatingCapacity': seatingCapacity,
      'bedCount': bedCount,
      'bedType': bedType,
      if (customPricePerNight != null) 'customPricePerNight': customPricePerNight,
      'status': status,
      'notes': notes,
      'amenities': amenities,
      'gstEnabled': gstEnabled,
      'gstRate': gstRate,
      'cgstRate': cgstRate,
      'sgstRate': sgstRate,
      'taxInclusive': taxInclusive,
    };

    final response = await _client.put(
      Uri.parse('$baseUrl/admin/rooms/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final room = RoomModel.fromJson(json['data'] as Map<String, dynamic>);
      final message = json['message'] as String? ?? 'Room updated successfully.';
      return (room: room, message: message);
    }
    String message = 'Failed to update room (${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = err['message'] as String? ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<String> updateRoomStatus(String roomId, String status) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/admin/rooms/$roomId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['message'] as String? ?? 'Room status updated to $status.';
      } catch (_) {
        return 'Room status updated to $status.';
      }
    }
    String message = 'Failed to update room status (${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = err['message'] as String? ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<String> deleteRoom(String roomId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/admin/rooms/$roomId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['message'] as String? ?? 'Room deleted successfully.';
      } catch (_) {
        return 'Room deleted successfully.';
      }
    }
    String message = 'Failed to delete room (${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = err['message'] as String? ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  // 6. Room Categories (Room Types & Tariffs)
  Future<List<RoomTypeModel>> fetchRoomTypes() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/admin/room-types'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['data'] as List<dynamic>? ?? [];
      return list.map((e) => RoomTypeModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load room types (status: ${response.statusCode})');
  }

  Future<({RoomTypeModel roomType, String message})> createRoomType({
    required String name,
    required double basePrice,
    int adults = 2,
    int children = 0,
    int bedCount = 1,
    String bedType = '1 King Size Bed',
    String description = '',
    List<String> amenities = const [],
    bool gstEnabled = true,
    double gstRate = 0,
    double cgstRate = 0,
    double sgstRate = 0,
    bool taxInclusive = false,
  }) async {
    final body = {
      'name': name.trim(),
      'description': description.trim(),
      'basePrice': basePrice,
      'capacity': {'adults': adults, 'children': children},
      'bedCount': bedCount,
      'bedType': bedType,
      'amenities': amenities,
      'gstEnabled': gstEnabled,
      'gstRate': gstRate,
      'cgstRate': cgstRate,
      'sgstRate': sgstRate,
      'taxInclusive': taxInclusive,
    };

    final response = await _client.post(
      Uri.parse('$baseUrl/admin/room-types'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final roomType = RoomTypeModel.fromJson(json['data'] as Map<String, dynamic>);
      final message = json['message'] as String? ?? 'Room category created successfully.';
      return (roomType: roomType, message: message);
    }
    String message = 'Failed to create room category (${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = err['message'] as String? ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<({RoomTypeModel roomType, String message})> updateRoomType(
    String id, {
    required String name,
    required double basePrice,
    int adults = 2,
    int children = 0,
    int bedCount = 1,
    String bedType = '1 King Size Bed',
    String description = '',
    List<String> amenities = const [],
    bool gstEnabled = true,
    double gstRate = 0,
    double cgstRate = 0,
    double sgstRate = 0,
    bool taxInclusive = false,
  }) async {
    final body = {
      'name': name.trim(),
      'description': description.trim(),
      'basePrice': basePrice,
      'capacity': {'adults': adults, 'children': children},
      'bedCount': bedCount,
      'bedType': bedType,
      'amenities': amenities,
      'gstEnabled': gstEnabled,
      'gstRate': gstRate,
      'cgstRate': cgstRate,
      'sgstRate': sgstRate,
      'taxInclusive': taxInclusive,
    };

    final response = await _client.put(
      Uri.parse('$baseUrl/admin/room-types/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final roomType = RoomTypeModel.fromJson(json['data'] as Map<String, dynamic>);
      final message = json['message'] as String? ?? 'Room category updated successfully.';
      return (roomType: roomType, message: message);
    }
    String message = 'Failed to update room category (${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = err['message'] as String? ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<String> deleteRoomType(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/admin/room-types/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['message'] as String? ?? 'Room category deleted successfully.';
      } catch (_) {
        return 'Room category deleted successfully.';
      }
    }
    String message = 'Failed to delete room category (${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = err['message'] as String? ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  // 7. Profile & Settings
  Future<Map<String, dynamic>> fetchHotelProfile() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/admin/profile'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['data'] as Map<String, dynamic>? ?? json;
    }
    throw Exception('Failed to load hotel profile (status: ${response.statusCode})');
  }

  Future<void> updateHotelSettings({
    required String checkInTime,
    required String checkOutTime,
    String timezone = 'Asia/Kolkata',
    String upiId = '',
    String beneficiaryName = '',
    String bankName = '',
    String accountNumber = '',
    String ifscCode = '',
    bool gstEnabled = true,
    int defaultGstRate = 18,
    String gstin = '',
    bool taxInclusive = false,
  }) async {
    final body = {
      'settings': {
        'checkInTime': checkInTime,
        'checkOutTime': checkOutTime,
        'timezone': timezone,
        'upiId': upiId,
        'gstEnabled': gstEnabled,
        'defaultGstRate': defaultGstRate,
        'defaultCgstRate': defaultGstRate ~/ 2,
        'defaultSgstRate': defaultGstRate ~/ 2,
        'gstin': gstin,
        'taxInclusive': taxInclusive,
        'bankDetails': {
          'beneficiaryName': beneficiaryName,
          'bankName': bankName,
          'accountNumber': accountNumber,
          'ifscCode': ifscCode,
        },
      },
    };

    final response = await _client.put(
      Uri.parse('$baseUrl/admin/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to update settings');
    }
  }

  // 8. Trial Extension Request
  Future<Map<String, dynamic>> requestTrialExtension({
    required int requestedDays,
    required String reason,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/hotels/request-trial-extension'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requestedDays': requestedDays,
        'reason': reason,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Failed to submit trial extension request');
  }

  // 9. Revenue Details & Reports
  Future<RevenueDetailsData> fetchRevenueDetails({
    String? startDate,
    String? endDate,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/revenue-details').replace(
      queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );

    final response = await _client.get(uri, headers: {'Content-Type': 'application/json'});
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return RevenueDetailsData.fromJson(json);
    }
    throw Exception('Failed to load revenue details (status: ${response.statusCode})');
  }

  Future<Map<String, dynamic>> fetchReports() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/admin/reports'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['data'] as Map<String, dynamic>? ?? json;
    }
    throw Exception('Failed to load reports (status: ${response.statusCode})');
  }
}
