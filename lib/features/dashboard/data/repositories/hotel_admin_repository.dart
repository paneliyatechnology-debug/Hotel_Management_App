import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../auth/data/models/auth_user_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/repositories/authenticated_http_client.dart';
import '../../../rooms/data/models/room_category_model.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../../../core/widgets/status_badge.dart';
import '../models/admin_dashboard_model.dart';
import '../models/dashboard_summary_model.dart';
import '../models/admin_models.dart';
import '../models/hotel_me_model.dart';
import '../models/subscription_plan_model.dart';

class HotelAdminRepository {
  static const String baseUrl = ApiConstants.baseUrl;

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

  /// GET /api/v1/dashboard. No body and no hotel_id.
  Future<AdminDashboardSnapshot> fetchAdminDashboard() async {
    final response = await _client.get(
      Uri.parse(ApiConstants.dashboardUrl),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) {
        final data = json['data'];
        if (data is Map<String, dynamic>) {
          return AdminDashboardSnapshot.fromJson(data);
        }
        if (data is Map) {
          return AdminDashboardSnapshot.fromJson(Map<String, dynamic>.from(data));
        }
      }
    }
    throw Exception('Failed to load admin dashboard (status: ${response.statusCode})');
  }

  /// GET /api/v1/dashboard/summary?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD.
  /// No body and no hotel_id.
  Future<DashboardSummary> fetchDashboardSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uri = Uri.parse(ApiConstants.dashboardSummaryUrl).replace(
      queryParameters: {
        'start_date': _summaryDate(startDate),
        'end_date': _summaryDate(endDate),
      },
    );
    final response = await _client.get(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) json = decoded;
      if (decoded is Map) json ??= Map<String, dynamic>.from(decoded);
    } catch (_) {}
    if (response.statusCode < 200 || response.statusCode >= 300 || json?['success'] == false) {
      final message = json?['message']?.toString().trim();
      throw Exception(message == null || message.isEmpty ? 'Could not load the date summary.' : message);
    }
    final data = json?['data'];
    if (data is Map<String, dynamic>) return DashboardSummary.fromJson(data);
    if (data is Map) return DashboardSummary.fromJson(Map<String, dynamic>.from(data));
    throw Exception('Could not load the date summary.');
  }

  String _summaryDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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
  /// GET /api/v1/users?role=RECEPTIONIST&is_active=true&sort_by=created_at&sort_order=desc&page=&limit=
  /// Reads data.users. hotel_id is not sent.
  Future<List<StaffMemberModel>> fetchStaffMembers({int limit = 10}) async {
    final staff = <StaffMemberModel>[];
    var page = 1;
    var totalPages = 1;

    while (page <= totalPages && page <= 50) {
      final uri = Uri.parse(ApiConstants.usersUrl).replace(
        queryParameters: {
          'role': 'RECEPTIONIST',
          'is_active': 'true',
          'sort_by': 'created_at',
          'sort_order': 'desc',
          'page': '$page',
          'limit': '$limit',
        },
      );
      final response = await _client.get(uri, headers: await _roomJsonHeaders());

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Failed to load staff members (status: ${response.statusCode})';
        try {
          final err = jsonDecode(response.body) as Map<String, dynamic>;
          message = (err['message'] ?? err['error'] ?? message).toString();
        } catch (_) {}
        throw Exception(message);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      final List<dynamic> list;
      if (data is List) {
        list = data;
        totalPages = page;
      } else if (data is Map<String, dynamic>) {
        list = data['users'] as List<dynamic>? ?? data['receptionists'] as List<dynamic>? ?? [];
        totalPages = (data['total_pages'] as num?)?.toInt() ??
            (data['totalPages'] as num?)?.toInt() ??
            page;
      } else {
        list = const [];
        totalPages = page;
      }

      for (final item in list) {
        if (item is Map<String, dynamic>) {
          staff.add(StaffMemberModel.fromJson(item));
        }
      }

      if (list.isEmpty) break;
      page++;
    }

    return staff;
  }

  /// POST /api/v1/users
  /// Body: name, email, phone (+91…), role, is_active, must_change_password.
  /// hotel_id is taken from the access token when that claim is present.
  Future<({StaffMemberModel staff, String message})> createStaffMember({
    required String name,
    required String email,
    required String phone,
    String role = 'RECEPTIONIST',
    bool isActive = true,
    bool mustChangePassword = true,
  }) async {
    final headers = await _roomJsonHeaders();
    final hotelId = _hotelIdFromJwt(headers['Authorization']?.replaceFirst('Bearer ', ''));
    final response = await _client.post(
      Uri.parse(ApiConstants.usersUrl),
      headers: headers,
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'phone': _formatStaffPhone(phone),
        'role': role,
        if (hotelId != null) 'hotel_id': hotelId,
        'is_active': isActive,
        'must_change_password': mustChangePassword,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      final staff = StaffMemberModel.fromJson(
        data is Map<String, dynamic> ? data : <String, dynamic>{},
      );
      final message = json['message'] as String? ?? 'User created successfully.';
      return (staff: staff, message: message);
    }
    String message = 'Failed to create staff member';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = (err['message'] ?? err['error'] ?? message).toString();
    } catch (_) {}
    throw Exception(message);
  }

  String _formatStaffPhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(digits.length - 10);
    }
    if (digits.length == 10) return '+91$digits';
    return phone.trim();
  }

  int? _hotelIdFromJwt(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = jsonDecode(utf8.decode(base64Decode(payload)));
      if (decoded is! Map<String, dynamic>) return null;
      final hotelId = decoded['hotel_id'];
      if (hotelId is num && hotelId > 0) return hotelId.toInt();
      final parsed = int.tryParse('${hotelId ?? ''}');
      if (parsed != null && parsed > 0) return parsed;
    } catch (_) {}
    return null;
  }

  /// PUT /api/v1/users/:id
  /// Body is only name, phone (+91…), and is_active.
  Future<({StaffMemberModel staff, String message})> updateStaffMember(
    String id, {
    required String name,
    required String phone,
    required bool isActive,
  }) async {
    final response = await _client.put(
      Uri.parse('${ApiConstants.usersUrl}/$id'),
      headers: await _roomJsonHeaders(),
      body: jsonEncode({
        'name': name.trim(),
        'phone': _formatStaffPhone(phone),
        'is_active': isActive,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      final staff = data is Map<String, dynamic>
          ? StaffMemberModel.fromJson(data)
          : StaffMemberModel(
              id: id,
              name: name.trim(),
              email: '',
              phone: _formatStaffPhone(phone),
              status: isActive ? 'ACTIVE' : 'INACTIVE',
            );
      final message = json['message'] as String? ?? 'Staff details updated successfully.';
      return (staff: staff, message: message);
    }
    String message = 'Failed to update staff member';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = (err['message'] ?? err['error'] ?? message).toString();
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

  /// DELETE /api/v1/users/:id with JSON headers. No request body and no hotel_id.
  Future<String> deleteStaffMember(String id) async {
    final response = await _client.delete(
      Uri.parse('${ApiConstants.usersUrl}/$id'),
      headers: await _roomJsonHeaders(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['message'] as String? ?? 'Staff member removed successfully.';
      } catch (_) {
        return 'Staff member removed successfully.';
      }
    }
    String message = 'Failed to delete staff member (${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = (err['message'] ?? err['error'] ?? message).toString();
    } catch (_) {}
    throw Exception(message);
  }

  // 5. Rooms Management
  /// GET /api/v1/rooms?page=&limit=&sort_order=asc
  /// Reads data.rooms. hotel_id is not sent; the API reads it from the access token.
  Future<List<RoomModel>> fetchAdminRooms({int limit = 10}) async {
    final rooms = <RoomModel>[];
    var page = 1;
    var totalPages = 1;
    Map<String, dynamic>? hotelGst;

    while (page <= totalPages && page <= 50) {
      final uri = Uri.parse(ApiConstants.roomsUrl).replace(
        queryParameters: {
          'page': '$page',
          'limit': '$limit',
          'sort_order': 'asc',
        },
      );
      final response = await _client.get(uri, headers: await _roomJsonHeaders());

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Failed to load rooms (status: ${response.statusCode})';
        try {
          final err = jsonDecode(response.body) as Map<String, dynamic>;
          message = (err['message'] ?? err['error'] ?? message).toString();
        } catch (_) {}
        throw Exception(message);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      final List<dynamic> list;
      if (data is List) {
        list = data;
        totalPages = page;
      } else if (data is Map<String, dynamic>) {
        list = data['rooms'] as List<dynamic>? ?? [];
        totalPages = (data['totalPages'] as num?)?.toInt() ?? page;
        if (data['hotel'] is Map) {
          hotelGst = Map<String, dynamic>.from(data['hotel'] as Map);
        }
      } else {
        list = const [];
        totalPages = page;
      }

      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        if (item['deleted_at'] != null) continue;
        rooms.add(RoomModel.fromJson(item).withHotelGst(hotelGst));
      }

      if (list.isEmpty) break;
      page++;
    }

    return rooms;
  }

  /// GET /api/v1/rooms?page=&limit=&sort_order=asc&status=
  /// Status is AVAILABLE, OCCUPIED, CLEANING, or MAINTENANCE. hotel_id is not sent.
  Future<List<RoomModel>> fetchRoomsByStatus({
    required String status,
    int limit = 10,
  }) async {
    final rooms = <RoomModel>[];
    var page = 1;
    var totalPages = 1;
    Map<String, dynamic>? hotelGst;

    while (page <= totalPages && page <= 50) {
      final uri = Uri.parse(ApiConstants.roomsUrl).replace(
        queryParameters: {
          'page': '$page',
          'limit': '$limit',
          'sort_order': 'asc',
          'status': status,
        },
      );
      final response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Failed to load rooms (status: ${response.statusCode})';
        try {
          final err = jsonDecode(response.body) as Map<String, dynamic>;
          message = (err['message'] ?? err['error'] ?? message).toString();
        } catch (_) {}
        throw Exception(message);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      final List<dynamic> list;
      if (data is List) {
        list = data;
        totalPages = page;
      } else if (data is Map<String, dynamic>) {
        list = data['rooms'] as List<dynamic>? ?? [];
        totalPages = (data['totalPages'] as num?)?.toInt() ??
            (data['total_pages'] as num?)?.toInt() ??
            page;
        if (data['hotel'] is Map) {
          hotelGst = Map<String, dynamic>.from(data['hotel'] as Map);
        }
      } else {
        list = const [];
        totalPages = page;
      }

      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        if (item['deleted_at'] != null) continue;
        rooms.add(RoomModel.fromJson(item).withHotelGst(hotelGst));
      }

      if (list.isEmpty) break;
      page++;
    }

    return rooms;
  }

  Future<Map<String, String>> _roomJsonHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await _accessTokenWithHotelClaim();
    final refreshToken = await _authRepository.getSavedRefreshToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      final parts = <String>[
        'accessToken=$token',
        if (refreshToken != null && refreshToken.isNotEmpty) 'refreshToken=$refreshToken',
      ];
      headers['Cookie'] = parts.join('; ');
    }
    return headers;
  }

  /// Creates a single room via POST /rooms (multipart/form-data).
  /// Matches the live payload: room_number, room_type_id, floor, beds, price, notes, amenities, cleaning_duration_minutes, is_active.
  Future<({RoomModel room, String message})> createRoom({
    required String roomNumber,
    required String roomTypeId,
    required int floor,
    required List<({String bedType, int count})> beds,
    double? customPricePerNight,
    String notes = '',
    List<String> amenities = const [],
    int cleaningDurationMinutes = 15,
    bool isActive = true,
    List<http.MultipartFile>? files,
  }) async {
    final uri = Uri.parse('$baseUrl/rooms');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';

    final token = await _authRepository.getValidAccessToken() ??
        await _authRepository.getSavedToken();
    final refreshToken = await _authRepository.getSavedRefreshToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
      final parts = <String>[
        'accessToken=$token',
        'token=$token',
        if (refreshToken != null && refreshToken.isNotEmpty)
          'refreshToken=$refreshToken',
      ];
      request.headers['Cookie'] = parts.join('; ');
    }

    request.fields['room_number'] = roomNumber.trim();
    request.fields['room_type_id'] = roomTypeId.trim();
    request.fields['floor'] = floor.toString();
    request.fields['beds'] = jsonEncode([
      for (final bed in beds)
        {
          'bed_type': _apiBedType(bed.bedType),
          'bed_count': bed.count < 1 ? 1 : bed.count,
        },
    ]);
    if (customPricePerNight != null && customPricePerNight > 0) {
      request.fields['custom_price_per_night'] = _formAmount(customPricePerNight);
    }
    request.fields['notes'] = notes.trim();
    request.fields['amenities'] = jsonEncode(amenities);
    request.fields['cleaning_duration_minutes'] = cleaningDurationMinutes.toString();
    request.fields['is_active'] = isActive.toString();

    if (files != null && files.isNotEmpty) {
      request.files.addAll(files);
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      final RoomModel room;
      if (data is Map<String, dynamic>) {
        room = RoomModel.fromJson(data);
      } else {
        room = RoomModel(
          id: '',
          roomNumber: roomNumber.trim(),
          floor: '$floor',
          roomType: '',
          roomTypeId: roomTypeId,
          pricePerNight: customPricePerNight ?? 0.0,
          customPricePerNight: customPricePerNight,
          seatingCapacity: 2,
          bedCount: beds.fold<int>(0, (sum, bed) => sum + (bed.count < 1 ? 1 : bed.count)),
          bedType: beds.map((bed) => '${bed.count < 1 ? 1 : bed.count} ${_apiBedType(bed.bedType)}').join(', '),
          notes: notes,
          amenities: amenities,
          status: RoomStatus.available,
        );
      }
      return (
        room: room,
        message: json['message'] as String? ?? 'Room created successfully.',
      );
    }

    String message = 'Failed to create room (${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      if (err['message'] != null && err['message'].toString().isNotEmpty) {
        message = err['message'].toString();
      } else if (err['error'] != null && err['error'].toString().isNotEmpty) {
        message = err['error'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  Future<({List<RoomModel> rooms, String message})> createRoomsBatch({
    required List<String> roomNumbers,
    required String roomTypeId,
    required List<({String bedType, int count})> beds,
    int floor = 1,
    double? customPricePerNight,
    String notes = '',
    List<String> amenities = const [],
    int cleaningDurationMinutes = 15,
    bool isActive = true,
  }) async {
    final createdRooms = <RoomModel>[];
    String lastMessage = 'Successfully created ${roomNumbers.length} room(s).';
    for (final number in roomNumbers) {
      final res = await createRoom(
        roomNumber: number,
        roomTypeId: roomTypeId,
        floor: floor,
        beds: beds,
        customPricePerNight: customPricePerNight,
        notes: notes,
        amenities: amenities,
        cleaningDurationMinutes: cleaningDurationMinutes,
        isActive: isActive,
      );
      createdRooms.add(res.room);
      lastMessage = res.message;
    }
    return (rooms: createdRooms, message: lastMessage);
  }

  String _apiBedType(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.contains('mattress') || value.contains('extra')) return 'Extra Mattress';
    if (value.contains('super') && value.contains('king')) return 'Super King';
    if (value.contains('king')) return 'King';
    if (value.contains('queen')) return 'Queen';
    if (value.contains('single')) return 'Single';
    if (value.contains('double')) return 'Double';
    return raw.trim();
  }

  String _formAmount(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toString();
  }

  /// PUT /api/v1/rooms/:id as multipart/form-data.
  /// Sends status, notes, custom_price_per_night, and optional images.
  /// hotel_id is not sent.
  Future<({RoomModel room, String message})> updateRoom(
    String id, {
    required String roomNumber,
    required String roomTypeId,
    int floor = 1,
    List<({String bedType, int count})> beds = const [],
    double? customPricePerNight,
    String status = 'AVAILABLE',
    String notes = '',
    List<String> amenities = const [],
    bool gstEnabled = true,
    double gstRate = 0,
    double cgstRate = 0,
    double sgstRate = 0,
    bool taxInclusive = false,
    List<String> imagePaths = const [],
    List<http.MultipartFile>? images,
  }) async {
    final fields = <String, String>{
      'status': status.trim(),
      'notes': notes.trim(),
    };
    if (customPricePerNight != null) {
      fields['custom_price_per_night'] = customPricePerNight.toStringAsFixed(2);
    }
    final cleanNumber = roomNumber.replaceAll('#', '').trim();
    if (cleanNumber.isNotEmpty) {
      fields['room_number'] = cleanNumber;
    }
    if (roomTypeId.trim().isNotEmpty) {
      fields['room_type_id'] = roomTypeId.trim();
    }
    fields['floor'] = '$floor';
    if (beds.isNotEmpty) {
      fields['beds'] = jsonEncode([
        for (final bed in beds)
          {
            'bed_type': _apiBedType(bed.bedType),
            'bed_count': bed.count < 1 ? 1 : bed.count,
          },
      ]);
    }
    fields['amenities'] = jsonEncode(amenities);

    final files = <http.MultipartFile>[
      for (final path in imagePaths)
        if (path.trim().isNotEmpty) await http.MultipartFile.fromPath('images', path),
      if (images != null)
        for (final file in images)
          http.MultipartFile(
            'images',
            file.finalize(),
            file.length,
            filename: file.filename,
            contentType: file.contentType,
          ),
    ];

    return _putRoom(id, fields: fields, files: files, fallback: RoomModel(
      id: id,
      roomNumber: cleanNumber,
      floor: 'Floor $floor',
      roomType: '',
      roomTypeId: roomTypeId,
      pricePerNight: customPricePerNight ?? 0,
      customPricePerNight: customPricePerNight,
      status: _roomStatusFromName(status),
      notes: notes,
      amenities: amenities,
      seatingCapacity: 2,
      bedCount: beds.fold<int>(0, (sum, bed) => sum + (bed.count < 1 ? 1 : bed.count)),
      bedType: beds.map((bed) => '${bed.count < 1 ? 1 : bed.count} ${_apiBedType(bed.bedType)}').join(', '),
    ));
  }

  /// PATCH /api/v1/rooms/{id}/status with JSON { "status": "CLEANING" }.
  /// Allowed values: AVAILABLE, RESERVED, OCCUPIED, CLEANING, MAINTENANCE, BLOCKED.
  Future<String> updateRoomStatus(String roomId, String status) async {
    final response = await _client.patch(
      Uri.parse('${ApiConstants.roomsUrl}/$roomId/status'),
      headers: await _roomJsonHeaders(),
      body: jsonEncode({'status': _apiRoomStatus(status)}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['message']?.toString() ?? 'Room status updated successfully.';
      } catch (_) {
        return 'Room status updated successfully.';
      }
    }

    String message = 'Failed to update room status (${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = (err['message'] ?? err['error'] ?? message).toString();
    } catch (_) {}
    throw Exception(message);
  }

  String _apiRoomStatus(String status) {
    switch (status.trim().toUpperCase()) {
      case 'OCCUPIED':
      case 'BOOKED':
        return 'OCCUPIED';
      case 'RESERVED':
        return 'RESERVED';
      case 'CLEANING':
        return 'CLEANING';
      case 'MAINTENANCE':
      case 'REPAIR':
        return 'MAINTENANCE';
      case 'BLOCKED':
        return 'BLOCKED';
      default:
        return 'AVAILABLE';
    }
  }

  Future<({RoomModel room, String message})> _putRoom(
    String id, {
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
    required RoomModel fallback,
  }) async {
    final request = http.MultipartRequest('PUT', Uri.parse('${ApiConstants.roomsUrl}/$id'));
    await _applyRoomMultipartAuth(request);
    request.fields.addAll(fields);
    request.files.addAll(files);

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'];
        final room = data is Map<String, dynamic> ? RoomModel.fromJson(data) : fallback;
        final message = json['message'] as String? ?? 'Room updated successfully.';
        return (room: room, message: message);
      } catch (_) {
        return (room: fallback, message: 'Room updated successfully.');
      }
    }

    String message = 'Failed to update room (${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      if (err['message'] != null && err['message'].toString().isNotEmpty) {
        message = err['message'].toString();
      } else if (err['error'] != null && err['error'].toString().isNotEmpty) {
        message = err['error'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  Future<void> _applyRoomMultipartAuth(http.BaseRequest request) async {
    request.headers['Accept'] = 'application/json';
    final token = await _accessTokenWithHotelClaim();
    final refreshToken = await _authRepository.getSavedRefreshToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
      final parts = <String>[
        'accessToken=$token',
        if (refreshToken != null && refreshToken.isNotEmpty) 'refreshToken=$refreshToken',
      ];
      request.headers['Cookie'] = parts.join('; ');
    }
  }

  RoomStatus _roomStatusFromName(String status) {
    switch (status.trim().toUpperCase()) {
      case 'OCCUPIED':
      case 'BOOKED':
        return RoomStatus.occupied;
      case 'CLEANING':
        return RoomStatus.cleaning;
      case 'MAINTENANCE':
      case 'BLOCKED':
        return RoomStatus.maintenance;
      default:
        return RoomStatus.available;
    }
  }

  /// DELETE /api/v1/rooms/:id with JSON headers. No request body and no hotel_id.
  Future<String> deleteRoom(String roomId) async {
    final response = await _client.delete(
      Uri.parse('${ApiConstants.roomsUrl}/$roomId'),
      headers: await _roomJsonHeaders(),
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
      if (err['message'] != null && err['message'].toString().isNotEmpty) {
        message = err['message'].toString();
      } else if (err['error'] != null && err['error'].toString().isNotEmpty) {
        message = err['error'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  // 6. Room Categories (Room Types & Tariffs)
  /// GET /api/v1/room-types. Accept only. hotel_id is not sent.
  Future<List<RoomTypeModel>> fetchRoomTypes({String? hotelId}) async {
    final response = await _client.get(
      Uri.parse(ApiConstants.roomTypesUrl),
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic> && json['success'] == true) {
        return RoomTypeModel.listFromResponse(json);
      }
    }
    String message = 'Failed to load room types (status: ${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      message = (err['message'] ?? err['error'] ?? message).toString();
    } catch (_) {}
    throw Exception(message);
  }

  /// POST /api/v1/room-types as multipart/form-data.
  /// Body fields are only `name` and `description`. hotel_id is not sent;
  /// the API reads it from the access-token cookie.
  Future<({RoomTypeModel roomType, String message})> createRoomType({
    required String name,
    String description = '',
  }) async {
    final uri = Uri.parse(ApiConstants.roomTypesUrl);
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';

    final token = await _accessTokenWithHotelClaim();
    final refreshToken = await _authRepository.getSavedRefreshToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
      final parts = <String>[
        'accessToken=$token',
        if (refreshToken != null && refreshToken.isNotEmpty)
          'refreshToken=$refreshToken',
      ];
      request.headers['Cookie'] = parts.join('; ');
    }

    request.fields['name'] = name.trim();
    request.fields['description'] = description.trim();

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      final RoomTypeModel roomType;
      if (data is Map<String, dynamic>) {
        roomType = RoomTypeModel.fromJson(data);
      } else {
        roomType = RoomTypeModel(
          id: '',
          hotel: '',
          name: name.trim(),
          description: description.trim(),
          basePrice: 0,
        );
      }
      final message = json['message'] as String? ?? 'Room category created successfully.';
      return (roomType: roomType, message: message);
    }
    String message = 'Failed to create room category (${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      if (err['message'] != null && err['message'].toString().isNotEmpty) {
        message = err['message'].toString();
      } else if (err['error'] != null && err['error'].toString().isNotEmpty) {
        message = err['error'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  /// Uses the saved access token when its JWT already contains hotel_id.
  /// Otherwise refreshes once so the cookie token can carry that claim.
  /// The claim is never copied into the request body.
  Future<String?> _accessTokenWithHotelClaim() async {
    final current = await _authRepository.getValidAccessToken() ??
        await _authRepository.getSavedToken();
    if (current == null || current.isEmpty) return current;
    if (_jwtHasHotelId(current)) return current;
    try {
      final refreshed = await _authRepository.refreshToken();
      final next = refreshed.accessToken;
      if (next != null && next.isNotEmpty) return next;
    } catch (_) {}
    return current;
  }

  bool _jwtHasHotelId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return false;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = jsonDecode(utf8.decode(base64Decode(payload)));
      if (decoded is! Map<String, dynamic>) return false;
      final hotelId = decoded['hotel_id'];
      if (hotelId is num) return hotelId > 0;
      final parsed = int.tryParse('${hotelId ?? ''}');
      return parsed != null && parsed > 0;
    } catch (_) {
      return false;
    }
  }

  Future<({RoomTypeModel roomType, String message})> updateRoomType(
    String id, {
    required String name,
    double basePrice = 0.0,
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
    List<http.MultipartFile>? files,
  }) async {
    final uri = Uri.parse('$baseUrl/room-types/$id');
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Accept'] = 'application/json';

    final token = await _authRepository.getValidAccessToken() ??
        await _authRepository.getSavedToken();
    final refreshToken = await _authRepository.getSavedRefreshToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
      final parts = <String>[
        'accessToken=$token',
        'token=$token',
        if (refreshToken != null && refreshToken.isNotEmpty)
          'refreshToken=$refreshToken',
      ];
      request.headers['Cookie'] = parts.join('; ');
    }

    request.fields['name'] = name.trim();
    request.fields['description'] = description.trim();
    if (files != null && files.isNotEmpty) {
      request.files.addAll(files);
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      final RoomTypeModel roomType;
      if (data is Map<String, dynamic>) {
        roomType = RoomTypeModel.fromJson(data);
      } else {
        roomType = RoomTypeModel(
          id: id,
          hotel: '',
          name: name.trim(),
          description: description.trim(),
          basePrice: basePrice,
          adults: adults,
          children: children,
          bedCount: bedCount,
          bedType: bedType,
          amenities: amenities,
        );
      }
      final message = json['message'] as String? ?? 'Room category updated successfully.';
      return (roomType: roomType, message: message);
    }
    String message = 'Failed to update room category (${response.statusCode})';
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      if (err['message'] != null && err['message'].toString().isNotEmpty) {
        message = err['message'].toString();
      } else if (err['error'] != null && err['error'].toString().isNotEmpty) {
        message = err['error'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  Future<String> deleteRoomType(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/room-types/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
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
      if (err['message'] != null && err['message'].toString().isNotEmpty) {
        message = err['message'].toString();
      } else if (err['error'] != null && err['error'].toString().isNotEmpty) {
        message = err['error'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  /// GET /api/v1/subscription-plans?billingCycle=MONTHLY&isActive=true&page=1&limit=10
  Future<SubscriptionPlanList> fetchSubscriptionPlans() async {
    final uri = Uri.parse(ApiConstants.subscriptionPlansUrl).replace(
      queryParameters: const {
        'billingCycle': 'MONTHLY',
        'isActive': 'true',
        'page': '1',
        'limit': '10',
      },
    );
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load subscription plans (${response.statusCode})');
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw Exception('Failed to load subscription plans');
    }
    final data = json['data'];
    final dataMap = data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{};
    final rawPlans = dataMap['plans'];
    if (rawPlans is! List) {
      return const SubscriptionPlanList(plans: [], isTrialUsed: true);
    }
    final plans = rawPlans
        .whereType<Map>()
        .map((item) => SubscriptionPlan.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    plans.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final trialUsed = dataMap.containsKey('is_trial_used') || dataMap.containsKey('isTrialUsed')
        ? dataMap['is_trial_used'] == true || dataMap['isTrialUsed'] == true
        : plans.any((plan) => plan.isTrialUsed == true);
    return SubscriptionPlanList(plans: plans, isTrialUsed: trialUsed);
  }

  /// POST /api/v1/subscription-plans/:id/purchase. No body and no hotel_id.
  Future<SubscriptionPurchase> purchaseSubscriptionPlan(int planId) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.subscriptionPlansUrl}/$planId/purchase'),
      headers: const {'Accept': 'application/json'},
    );
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300 || json?['success'] == false) {
      final message = (json?['message'] ?? json?['error'] ?? 'Failed to purchase plan (${response.statusCode})').toString();
      throw Exception(message);
    }

    final data = json?['data'];
    if (data is! Map) {
      throw Exception((json?['message'] ?? 'Failed to purchase plan').toString());
    }
    return SubscriptionPurchase.fromJson(Map<String, dynamic>.from(data));
  }

  /// GET /api/v1/auth/me. Hotel profile is data.hotel.
  Future<AuthUserModel> fetchCurrentUser() async {
    final response = await _client.get(
      Uri.parse(ApiConstants.meUrl),
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load hotel profile (${response.statusCode})');
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic> || json['data'] is! Map) {
      throw Exception('Failed to load hotel profile');
    }
    final data = Map<String, dynamic>.from(json['data'] as Map);
    final userMap = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : data;
    return AuthUserModel.fromJson(userMap);
  }

  /// GET /api/v1/auth/me. Reads data.hotel, including settings and bank fields.
  Future<MyHotelProfile> fetchMyHotelProfile() async {
    final response = await _client.get(
      Uri.parse(ApiConstants.meUrl),
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load hotel profile (${response.statusCode})');
    }
    return MyHotelProfile.fromResponse(jsonDecode(response.body));
  }

  /// GET /api/v1/hotels/me
  Future<HotelMeProfile> fetchHotelMe() async {
    final response = await _client.get(
      Uri.parse(ApiConstants.hotelMeUrl),
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load hotel settings (${response.statusCode})');
    }
    final json = jsonDecode(response.body);
    return HotelMeProfile.fromJson(hotelMeMap(json));
  }

  /// PUT /api/v1/hotels/me as multipart/form-data. Mobile number is not sent.
  Future<String> updateHotelMe(HotelMeProfile profile, {String? logoPath}) async {
    final request = http.MultipartRequest('PUT', Uri.parse(ApiConstants.hotelMeUrl));
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(profile.toFormFields());
    if (logoPath != null && logoPath.trim().isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('logo', logoPath));
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final json = _tryJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = json?['message'] ?? json?['error'] ?? 'Failed to update hotel settings';
      throw Exception(message.toString());
    }
    return (json?['message'] ?? 'Hotel settings updated').toString();
  }

  Map<String, dynamic>? _tryJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
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
