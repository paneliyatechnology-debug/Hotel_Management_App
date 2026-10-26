import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/upload_image_compressor.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../data/models/booking_list_query.dart';
import '../../data/models/booking_pdf_file.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../../data/models/guest_folio_model.dart';
import '../../data/models/hotel_stats_model.dart';
import '../../data/models/room_live_update.dart';
import '../../../check_in_wizard/data/models/check_in_form_data.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/repositories/authenticated_http_client.dart';

import '../../../rooms/data/models/room_category_model.dart';

abstract class IDashboardRepository {
  Future<List<RoomModel>> getRooms();
  Future<List<RoomTypeModel>> getRoomTypes();
  Future<List<GuestFolioModel>> getFolios({
    String status = '',
    String search = '',
    int page = 1,
    int limit = 10,
    BookingListQuery? query,
  });
  Future<HotelStatsModel> getStats();
  Future<HotelStatsModel> fetchReceptionistDashboard();
  Future<List<RoomModel>> fetchAvailableRooms();
  Future<List<RoomTypeModel>> fetchRoomTypes({String? hotelId});
  Future<List<GuestFolioModel>> fetchBookings({
    String status = '',
    String search = '',
    String paymentStatus = '',
    String roomId = '',
    String bookingNumber = '',
    String primaryGuestName = '',
    String guestName = '',
    String mobileNumber = '',
    String checkInFrom = '',
    String checkInTo = '',
    String checkOutFrom = '',
    String checkOutTo = '',
    int page = 1,
    int limit = 10,
    BookingListQuery? query,
  });
  Future<void> updateRoomStatus(String roomId, RoomStatus newStatus);
  void acceptRemoteRoomStatuses();
  List<RoomModel> applyLiveRoomUpdate(RoomLiveUpdate update);
  Future<GuestFolioModel> completeCheckIn(CheckInFormData formData);
  Future<GuestFolioModel> updateBookingFromForm(CheckInFormData formData);
  Future<GuestFolioModel?> fetchBooking(String bookingId);
  ({List<RoomModel> rooms, List<GuestFolioModel> folios}) applyLiveBooking(Map<String, dynamic> json);
  Future<Map<String, dynamic>> checkoutFolio(String folioId, {Map<String, dynamic>? customPayload});
  Future<void> extendFolioStay(String folioId, DateTime newCheckoutDate);
  Future<void> addFolioPayment(String folioId, PaymentRecordModel payment);
  Future<void> addFolioCharge(String folioId, ChargeItemModel charge);
  Future<void> updateFolioKeycard(String folioId, String keycardStatus, String? keycardNumber);
}

class DashboardRepository implements IDashboardRepository {
  static const String baseUrl = ApiConstants.receptionistBaseUrl;
  static const String dashboardEndpoint = ApiConstants.receptionistDashboardUrl;
  static const String availableRoomsEndpoint = ApiConstants.receptionistAvailableRoomsUrl;
  static const String roomTypesEndpoint = ApiConstants.receptionistRoomTypesUrl;
  static const String bookingsEndpoint = ApiConstants.receptionistBookingsUrl;

  static DashboardRepository? _instance;
  final http.Client _client;
  final bool _isCustomClient;
  HotelStatsModel? _cachedStats;

  factory DashboardRepository({
    http.Client? client,
    AuthRepository? authRepository,
    List<RoomModel>? initialRooms,
    List<GuestFolioModel>? initialFolios,
    List<RoomTypeModel>? initialRoomTypes,
  }) {
    if (_instance == null || client != null || authRepository != null || initialRooms != null || initialFolios != null || initialRoomTypes != null) {
      _instance = DashboardRepository._internal(
        client: client,
        authRepository: authRepository,
        initialRooms: initialRooms,
        initialFolios: initialFolios,
        initialRoomTypes: initialRoomTypes,
      );
    }
    return _instance!;
  }

  DashboardRepository._internal({
    http.Client? client,
    AuthRepository? authRepository,
    List<RoomModel>? initialRooms,
    List<GuestFolioModel>? initialFolios,
    List<RoomTypeModel>? initialRoomTypes,
  })  : _isCustomClient = client != null,
        _rooms = initialRooms != null
            ? List<RoomModel>.from(initialRooms)
            : (_isTestEnv ? _buildInitialRooms() : <RoomModel>[]),
        _folios = initialFolios != null
            ? List<GuestFolioModel>.from(initialFolios)
            : (_isTestEnv ? _buildInitialFolios() : <GuestFolioModel>[]),
        _roomTypes = initialRoomTypes != null ? List.from(initialRoomTypes) : [],
        _client = client ??
            AuthenticatedHttpClient(
              authRepository: authRepository ?? AuthRepository(),
            );

  static bool get _isTestEnv {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  bool get _shouldSkipLiveNetwork {
    if (_isCustomClient) return false;
    return _isTestEnv;
  }

  List<RoomModel> _rooms = [];
  List<GuestFolioModel> _folios = [];
  List<RoomTypeModel> _roomTypes = [];
  BookingListQuery _guestListQuery = const BookingListQuery();
  final Set<String> _keepAvailableRoomIds = {};
  Future<GuestFolioModel>? _activeCheckIn;

  @override
  Future<HotelStatsModel> fetchReceptionistDashboard() async {
    if (_shouldSkipLiveNetwork) {
      return _cachedStats ?? _computeLocalStats();
    }
    try {
      final response = await _client
          .get(
            Uri.parse(dashboardEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final stats = HotelStatsModel.fromDashboardData(
            jsonResponse['data'] as Map<String, dynamic>,
          );
          _cachedStats = stats;
          return stats;
        }
      }
    } catch (_) {
      // In case of network errors or offline testing, fallback gracefully
    }
    return _cachedStats ?? _computeLocalStats();
  }

  @override
  Future<List<RoomModel>> fetchAvailableRooms() async {
    if (_shouldSkipLiveNetwork) {
      return List.unmodifiable(List<RoomModel>.from(_rooms));
    }
    try {
      final rooms = <RoomModel>[];
      var page = 1;
      var totalPages = 1;
      Map<String, dynamic>? hotelGst;
      while (page <= totalPages && page <= 50) {
        final uri = Uri.parse(ApiConstants.roomsUrl).replace(
          queryParameters: {
            'page': '$page',
            'limit': '10',
            'sort_by': 'floor',
            'sort_order': 'asc',
          },
        );
        final response = await _client
            .get(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode < 200 || response.statusCode >= 300) break;
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is! Map<String, dynamic> || jsonResponse['success'] != true) {
          break;
        }

        final data = jsonResponse['data'];
        final List<dynamic> list;
        if (data is List) {
          list = data;
          totalPages = page;
        } else if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          list = map['rooms'] as List<dynamic>? ?? const <dynamic>[];
          totalPages = (map['totalPages'] as num?)?.toInt() ??
              (map['total_pages'] as num?)?.toInt() ??
              page;
          hotelGst = map['hotel'] is Map ? Map<String, dynamic>.from(map['hotel'] as Map) : hotelGst;
        } else {
          break;
        }

        for (final item in list) {
          if (item is! Map) continue;
          final json = Map<String, dynamic>.from(item);
          if (json['deleted_at'] != null) continue;
          final apiRoom = RoomModel.fromJson(json).withHotelGst(hotelGst);
          final existingIndex = _rooms.indexWhere((room) =>
              room.id == apiRoom.id ||
              (room.roomNumber == apiRoom.roomNumber && room.floor == apiRoom.floor));
          final local = existingIndex == -1 ? null : _rooms[existingIndex];
          if (_isKeptAvailable(apiRoom) || (local != null && _isKeptAvailable(local))) {
            final availableRoom = apiRoom.copyWith(status: RoomStatus.available);
            _pinAvailable(availableRoom);
            if (local != null) _pinAvailable(local);
            rooms.add(availableRoom);
          } else {
            rooms.add(apiRoom);
          }
        }
        if (list.isEmpty) break;
        page++;
      }
      if (rooms.isNotEmpty) {
        _rooms = rooms;
      }
    } catch (_) {
      // Fallback to local rooms on network failure
    }
    await _syncOccupiedWithCheckedInBookings();
    return List.unmodifiable(List<RoomModel>.from(_rooms));
  }

  /// Pull CHECKED_IN bookings and clear stale OCCUPIED rooms that have no guest.
  /// Keeps the existing folio list for the Guests / In-House UI.
  Future<void> _syncOccupiedWithCheckedInBookings() async {
    if (_shouldSkipLiveNetwork) {
      _attachCheckedInGuests(clearStaleOccupied: true);
      return;
    }
    final retained = List<GuestFolioModel>.from(_folios);
    try {
      final uri = Uri.parse(ApiConstants.bookingsUrl).replace(
        queryParameters: const {
          'page': '1',
          'limit': '50',
          'booking_status': 'CHECKED_IN',
        },
      );
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final rows = _bookingRows(Map<String, dynamic>.from(decoded));
          final inHouse = <GuestFolioModel>[];
          final seen = <String>{};
          for (final row in rows) {
            if (row is! Map) continue;
            final folio = GuestFolioModel.fromJson(Map<String, dynamic>.from(row));
            if (folio.status != FolioStatus.inHouse) continue;
            if (folio.id.isEmpty || !seen.add(folio.id)) continue;
            inHouse.add(folio);
          }
          _folios = inHouse;
          _attachCheckedInGuests(clearStaleOccupied: true);
          final byId = <String, GuestFolioModel>{
            for (final folio in retained) folio.id: folio,
          };
          for (final folio in inHouse) {
            byId[folio.id] = folio;
          }
          _folios = byId.values.toList();
          return;
        }
      }
    } catch (_) {}
    _folios = retained;
    // Do not demote OCCUPIED when the CHECKED_IN list could not be loaded.
    _attachCheckedInGuests();
  }

  @override
  Future<List<RoomTypeModel>> fetchRoomTypes({String? hotelId}) async {
    if (_shouldSkipLiveNetwork) {
      return List.unmodifiable(_roomTypes);
    }
    try {
      final response = await _client
          .get(
            Uri.parse(ApiConstants.roomTypesUrl),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is Map<String, dynamic> && jsonResponse['success'] == true) {
          _roomTypes = RoomTypeModel.listFromResponse(jsonResponse);
          return List.unmodifiable(_roomTypes);
        }
      }
    } catch (_) {
      // Fallback to local room types on network error
    }
    return List.unmodifiable(_roomTypes);
  }

  @override
  Future<List<GuestFolioModel>> fetchBookings({
    String status = '',
    String search = '',
    String paymentStatus = '',
    String roomId = '',
    String bookingNumber = '',
    String primaryGuestName = '',
    String guestName = '',
    String mobileNumber = '',
    String checkInFrom = '',
    String checkInTo = '',
    String checkOutFrom = '',
    String checkOutTo = '',
    int page = 1,
    int limit = 10,
    BookingListQuery? query,
  }) async {
    final active = query ??
        BookingListQuery(
          bookingStatus: status,
          paymentStatus: paymentStatus,
          roomId: roomId,
          bookingNumber: bookingNumber,
          primaryGuestName: primaryGuestName,
          guestName: guestName,
          mobileNumber: mobileNumber,
          search: search,
          checkInFrom: checkInFrom,
          checkInTo: checkInTo,
          checkOutFrom: checkOutFrom,
          checkOutTo: checkOutTo,
          page: page,
          limit: limit,
        );
    _guestListQuery = active;
    if (_shouldSkipLiveNetwork) {
      return List.unmodifiable(List<GuestFolioModel>.from(_folios));
    }
    try {
      final pageNumber = active.page < 1 ? 1 : active.page;
      final uri = Uri.parse(ApiConstants.bookingsUrl).replace(
        queryParameters: active.toQueryParameters(pageNumber),
      );
      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_readApiError(response.body, response.statusCode));
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        _folios = <GuestFolioModel>[];
        return List.unmodifiable(_folios);
      }
      final jsonResponse = Map<String, dynamic>.from(decoded);
      final rows = _bookingRows(jsonResponse);
      final seen = <String>{};
      final collected = <GuestFolioModel>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final booking = Map<String, dynamic>.from(row);
        if (!_matchesRequestedBookingStatus(booking, active.bookingStatus)) continue;
        final folio = GuestFolioModel.fromJson(booking);
        if (folio.id.isEmpty || !seen.add(folio.id)) continue;
        collected.add(folio);
      }

      _folios = collected;
      final checkedInQuery = active.bookingStatus.trim().toUpperCase() == 'CHECKED_IN';
      _attachCheckedInGuests(clearStaleOccupied: checkedInQuery);
      return List.unmodifiable(List<GuestFolioModel>.from(_folios));
    } catch (_) {
      _folios = <GuestFolioModel>[];
      return List.unmodifiable(_folios);
    }
  }

  List<dynamic> _bookingRows(Map<String, dynamic> jsonResponse) {
    final data = jsonResponse['data'];
    if (data is List) return data;
    if (data is Map && data['bookings'] is List) {
      return data['bookings'] as List;
    }
    if (jsonResponse['bookings'] is List) {
      return jsonResponse['bookings'] as List;
    }
    return const [];
  }

  /// Keep Checkout CTAs aligned with In-House bookings.
  /// Room `OCCUPIED` from the rooms API / socket can lag behind check-out, so
  /// a room only stays occupied when a CHECKED_IN folio maps to it.
  ///
  /// [clearStaleOccupied] must only be true after a full CHECKED_IN booking fetch.
  void _attachCheckedInGuests({bool clearStaleOccupied = false}) {
    if (_rooms.isEmpty) return;
    final inHouse = _folios.where((folio) => folio.status == FolioStatus.inHouse).toList();
    final byRoomDigits = <String, GuestFolioModel>{};
    for (final folio in inHouse) {
      final digits = folio.assignedRoom.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) byRoomDigits.putIfAbsent(digits, () => folio);
    }

    final updated = List<RoomModel>.from(_rooms);
    var changed = false;
    for (var i = 0; i < updated.length; i++) {
      final room = updated[i];
      final roomDigits = room.roomNumber.replaceAll(RegExp(r'[^0-9]'), '');
      GuestFolioModel? match = roomDigits.isNotEmpty ? byRoomDigits[roomDigits] : null;
      if (match == null) {
        for (final folio in inHouse) {
          final folioId = room.currentGuestFolioId;
          if (folioId != null &&
              folioId.isNotEmpty &&
              (folio.id == folioId || folio.bookingId == folioId)) {
            match = folio;
            break;
          }
          if (room.id.isNotEmpty && folio.roomId != null && folio.roomId == room.id) {
            match = folio;
            break;
          }
        }
      }

      if (_isKeptAvailable(room)) {
        if (room.status != RoomStatus.available || room.currentGuestName != null) {
          updated[i] = room.copyWith(status: RoomStatus.available, clearGuest: true);
          changed = true;
        }
        continue;
      }

      if (match != null) {
        final name = match.guestName.trim();
        final next = room.copyWith(
          currentGuestName: name.isNotEmpty && name != 'Guest' ? name : room.currentGuestName,
          currentGuestFolioId: match.id,
          status: RoomStatus.occupied,
        );
        if (next.status != room.status ||
            next.currentGuestFolioId != room.currentGuestFolioId ||
            next.currentGuestName != room.currentGuestName) {
          updated[i] = next;
          changed = true;
        }
        continue;
      }

      // Keep rooms API OCCUPIED as-is so Edit / Checkout stay visible.
      // Guest name is filled when a matching In-House booking exists above.
    }
    if (changed) _rooms = updated;
  }

  bool _matchesRequestedBookingStatus(Map<String, dynamic> booking, String status) {
    final requested = status.trim().toUpperCase();
    if (requested.isEmpty) return true;
    final raw = (booking['booking_status'] ?? booking['status'] ?? '').toString().trim().toUpperCase();
    if (raw.isEmpty) return true;
    if (requested == 'CHECKED_IN') {
      return raw == 'CHECKED_IN' || raw == 'IN_HOUSE' || raw == 'INHOUSE';
    }
    return raw == requested;
  }

  HotelStatsModel _computeLocalStats() {
    int available = 0;
    int occupied = 0;
    int cleaning = 0;
    int maintenance = 0;

    for (final room in _rooms) {
      switch (room.status) {
        case RoomStatus.available:
          available++;
          break;
        case RoomStatus.occupied:
          occupied++;
          break;
        case RoomStatus.cleaning:
          cleaning++;
          break;
        case RoomStatus.maintenance:
          maintenance++;
          break;
      }
    }

    final inHouseGuests =
        _folios.where((f) => f.status == FolioStatus.inHouse).length;

    return HotelStatsModel(
      availableVacant: available,
      occupiedInHouse: occupied,
      housekeepingQueue: cleaning,
      maintenanceBlocked: maintenance,
      totalInHouseGuests: inHouseGuests,
    );
  }

  @override
  Future<List<RoomModel>> getRooms() async {
    return await fetchAvailableRooms();
  }

  @override
  Future<List<RoomTypeModel>> getRoomTypes() async {
    return await fetchRoomTypes();
  }

  @override
  Future<List<GuestFolioModel>> getFolios({
    String status = '',
    String search = '',
    int page = 1,
    int limit = 10,
    BookingListQuery? query,
  }) async {
    if (query != null) return fetchBookings(query: query);
    if (status.trim().isEmpty && search.trim().isEmpty && page == 1 && limit == 10) {
      return fetchBookings(query: _guestListQuery);
    }
    return fetchBookings(
      status: status,
      search: search,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<HotelStatsModel> getStats() async {
    return await fetchReceptionistDashboard();
  }

  /// The seeded room inventory is a constant list. Replacing an entry in place
  /// throws "Cannot modify an unmodifiable list", which is what Complete
  /// Check-In was showing. Always write through a growable copy.
  void _writeRoom(int index, RoomModel room) {
    final rooms = List<RoomModel>.from(_rooms);
    rooms[index] = room;
    _rooms = rooms;
  }

  @override
  void acceptRemoteRoomStatuses() {
    _keepAvailableRoomIds.clear();
  }

  @override
  List<RoomModel> applyLiveRoomUpdate(RoomLiveUpdate update) {
    acceptRemoteRoomStatuses();
    final patch = update.room;
    if (patch != null) {
      _rooms = patch.apply(List<RoomModel>.from(_rooms));
    }
    _attachCheckedInGuests();
    return List<RoomModel>.from(_rooms);
  }

  @override
  Future<void> updateRoomStatus(String roomId, RoomStatus newStatus) async {
    if (!_shouldSkipLiveNetwork) {
      final response = await _client
          .patch(
            Uri.parse('${ApiConstants.roomsUrl}/$roomId/status'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'status': _statusApiValue(newStatus)}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Failed to update room status (${response.statusCode})';
        try {
          final err = jsonDecode(response.body) as Map<String, dynamic>;
          message = (err['message'] ?? err['error'] ?? message).toString();
        } catch (_) {}
        throw Exception(message);
      }

      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'];
        if (data is Map<String, dynamic>) {
          final updated = RoomModel.fromJson(data).copyWith(status: newStatus);
          final index = _rooms.indexWhere((room) => room.id == roomId || room.id == updated.id);
          _rememberRequestedStatus(roomId, updated.id, newStatus);
          if (index != -1) {
            _writeRoom(index, updated);
            return;
          }
        }
      } catch (_) {}
    }

    final index = _rooms.indexWhere((r) => r.id == roomId);
    _rememberRequestedStatus(roomId, index == -1 ? null : _rooms[index].id, newStatus);
    if (index != -1) {
      _writeRoom(
        index,
        _rooms[index].copyWith(
          status: newStatus,
          currentGuestName: newStatus == RoomStatus.available ? null : _rooms[index].currentGuestName,
        ),
      );
    }
  }

  void _rememberRequestedStatus(String requestedId, String? responseId, RoomStatus status) {
    final index = _rooms.indexWhere((room) => room.id == requestedId || room.id == responseId);
    final room = index == -1 ? null : _rooms[index];
    if (status == RoomStatus.available) {
      _keepAvailableRoomIds.add(requestedId.trim());
      if (responseId != null && responseId.trim().isNotEmpty) {
        _keepAvailableRoomIds.add(responseId.trim());
      }
      if (room != null) _pinAvailable(room);
    } else if (room != null) {
      _releaseAvailablePin(room);
    } else {
      _keepAvailableRoomIds.remove(requestedId.trim());
      if (responseId != null) _keepAvailableRoomIds.remove(responseId.trim());
    }
  }

  bool _isKeptAvailable(RoomModel room) {
    final numberKey = _roomNumberKey(room.roomNumber);
    return _keepAvailableRoomIds.contains(room.id) ||
        _keepAvailableRoomIds.contains(_roomNumberKey(room.id)) ||
        (numberKey.isNotEmpty && _keepAvailableRoomIds.contains(numberKey));
  }

  void _pinAvailable(RoomModel room) {
    if (room.id.trim().isNotEmpty) _keepAvailableRoomIds.add(room.id.trim());
    final idKey = _roomNumberKey(room.id);
    final numberKey = _roomNumberKey(room.roomNumber);
    if (idKey.isNotEmpty) _keepAvailableRoomIds.add(idKey);
    if (numberKey.isNotEmpty) _keepAvailableRoomIds.add(numberKey);
  }

  void _releaseAvailablePin(RoomModel room) {
    _keepAvailableRoomIds.remove(room.id.trim());
    _keepAvailableRoomIds.remove(_roomNumberKey(room.id));
    _keepAvailableRoomIds.remove(_roomNumberKey(room.roomNumber));
  }

  String _roomNumberKey(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  String _statusApiValue(RoomStatus status) {
    switch (status) {
      case RoomStatus.occupied:
        return 'OCCUPIED';
      case RoomStatus.cleaning:
        return 'CLEANING';
      case RoomStatus.maintenance:
        return 'MAINTENANCE';
      case RoomStatus.available:
        return 'AVAILABLE';
    }
  }

  String _joinedAddress(CheckInFormData formData) {
    final parts = <String>[
      formData.residentialAddress.trim(),
      if (formData.city.trim().isNotEmpty) formData.city.trim(),
      if (formData.state.trim().isNotEmpty) formData.state.trim(),
      if (formData.pincode.trim().isNotEmpty) formData.pincode.trim(),
    ].where((part) => part.isNotEmpty);
    return parts.join(', ');
  }

  String _bookingMobile(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(digits.length - 10);
    }
    return digits;
  }

  String _plainAmount(num value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toString();
  }

  String _roomIdFormValue(String raw) {
    final ids = _roomIdIntsFromRaw(raw);
    if (ids.isEmpty) return '[]';
    return '[${ids.join(',')}]';
  }

  List<int> _roomIdIntsFromRaw(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const [];
    if (text.startsWith('[') && text.endsWith(']')) {
      final inner = text.substring(1, text.length - 1).trim();
      if (inner.isEmpty) return const [];
      return inner
          .split(',')
          .map((part) => int.tryParse(part.trim()))
          .whereType<int>()
          .toList();
    }
    final parsed = int.tryParse(text);
    if (parsed != null) return [parsed];
    return const [];
  }

  /// Bookings API expects `room_id` as `[1,47]` (numeric room ids).
  List<int> _bookingRoomIdInts(CheckInFormData formData, String resolvedRoomId) {
    final ids = <int>[];
    void addRaw(String raw) {
      for (final id in _roomIdIntsFromRaw(raw)) {
        if (!ids.contains(id)) ids.add(id);
      }
    }

    for (final raw in formData.selectedRoomIds) {
      addRaw(raw);
    }
    addRaw(formData.selectedRoomId);
    addRaw(resolvedRoomId);

    if (ids.isEmpty) {
      final numbers = formData.selectedRoomNumber
          .split(RegExp(r'[,+/]| and '))
          .map((part) => part.replaceAll(RegExp(r'[^0-9]'), '').trim())
          .where((part) => part.isNotEmpty);
      for (final wantedNumber in numbers) {
        for (final room in _rooms) {
          final roomNumber = room.roomNumber.replaceAll(RegExp(r'[^0-9]'), '');
          if (roomNumber == wantedNumber) {
            final parsed = int.tryParse(room.id);
            if (parsed != null && !ids.contains(parsed)) ids.add(parsed);
          }
        }
      }
    }
    return ids;
  }

  String _bookingRoomId(CheckInFormData formData, String resolvedRoomId) {
    final ids = _bookingRoomIdInts(formData, resolvedRoomId);
    if (ids.isEmpty) return '[]';
    return '[${ids.join(',')}]';
  }

  MediaType _imageMediaType(String path, List<int> header) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return MediaType('image', 'jpeg');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.svg')) return MediaType('image', 'svg+xml');
    if (lower.endsWith('.avif')) return MediaType('image', 'avif');
    if (header.length >= 3 && header[0] == 0xFF && header[1] == 0xD8) {
      return MediaType('image', 'jpeg');
    }
    if (header.length >= 8 &&
        header[0] == 0x89 &&
        header[1] == 0x50 &&
        header[2] == 0x4E &&
        header[3] == 0x47) {
      return MediaType('image', 'png');
    }
    if (header.length >= 3 && header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46) {
      return MediaType('image', 'gif');
    }
    return MediaType('image', 'jpeg');
  }

  String _imageFilename(String path, MediaType type) {
    final uri = Uri.tryParse(path);
    final rawName = uri != null && uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : path.split(RegExp(r'[/\\]')).last;
    final name = rawName.trim();
    if (name.contains('.')) return name;
    final extension = type.subtype == 'jpeg' ? 'jpg' : type.subtype;
    return 'id-photo.$extension';
  }

  String _checkInErrorText(Object error) {
    var text = error.toString();
    text = text.replaceFirst(RegExp(r'^(Exception|Error):\s*'), '');
    text = text.replaceFirst(RegExp(r'^Unsupported operation:\s*'), '');
    return text.trim().isEmpty ? 'Check-in failed' : text.trim();
  }

  String _readApiError(String body, int statusCode, {String fallback = 'Check-in failed'}) {
    if (statusCode == 413) {
      return 'ID photos are too large for upload. Use fewer photos or retake with the camera.';
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is List) {
          final lines = message.map((item) => item.toString()).where((item) => item.trim().isNotEmpty);
          final joined = lines.join('\n');
          if (joined.isNotEmpty) return joined;
        } else if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {}
    return '$fallback ($statusCode)';
  }

  Future<Uint8List> _readFileBytes(String path) async {
    return File(path).readAsBytes();
  }

  ({Uint8List bytes, MediaType contentType, String filename}) _preparedImageUpload({
    required Uint8List bytes,
    required String path,
    required String fallbackName,
  }) {
    final compressed = UploadImageCompressor.toUploadJpeg(bytes);
    if (compressed != null) {
      final base = _imageFilename(path, MediaType('image', 'jpeg'))
          .replaceAll(RegExp(r'\.[^.]+$'), '');
      final name = base.trim().isEmpty ? fallbackName : '$base.jpg';
      return (
        bytes: compressed,
        contentType: MediaType('image', 'jpeg'),
        filename: name.endsWith('.jpg') ? name : '$name.jpg',
      );
    }
    final header = bytes.take(16).toList();
    final contentType = _imageMediaType(path, header);
    return (
      bytes: bytes,
      contentType: contentType,
      filename: _imageFilename(path, contentType),
    );
  }

  String _bookingTimestamp(DateTime value, {required int defaultHour}) {
    final hasTime = value.hour != 0 || value.minute != 0 || value.second != 0;
    final utc = hasTime
        ? value.toUtc()
        : DateTime.utc(value.year, value.month, value.day, defaultHour);
    return utc.toIso8601String();
  }

  int _calendarNights(DateTime checkIn, DateTime checkOut) {
    final start = DateTime.utc(checkIn.toUtc().year, checkIn.toUtc().month, checkIn.toUtc().day);
    final end = DateTime.utc(checkOut.toUtc().year, checkOut.toUtc().month, checkOut.toUtc().day);
    final diff = end.difference(start).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double _gstRateForRoom(String resolvedRoomId, String selectedRoomId) {
    for (final room in _rooms) {
      if (room.id == resolvedRoomId || room.id == selectedRoomId) {
        if (!room.gstEnabled) return 0;
        return room.gstRate;
      }
    }
    return 18;
  }

  Future<List<int>?> _signaturePngBytes(List<Offset?> points) async {
    if (!points.any((point) => point != null)) return null;
    const width = 600.0;
    const height = 220.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    var drawing = false;
    for (final point in points) {
      if (point == null) {
        drawing = false;
        continue;
      }
      if (!drawing) {
        path.moveTo(point.dx, point.dy);
        drawing = true;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);
    final image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;
    return Uint8List.fromList(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
  }

  Future<void> _addSignatureFile(
    http.MultipartRequest request, {
    required String? photoPath,
    required List<Offset?> points,
    required String filename,
  }) async {
    final photo = photoPath?.trim() ?? '';
    if (photo.contains('://')) {
      if (await _addRemoteFile(request, photo, field: 'signatures')) return;
    } else if (photo.isNotEmpty) {
      try {
        final file = File(photo);
        if (await file.exists()) {
          final prepared = _preparedImageUpload(
            bytes: await _readFileBytes(photo),
            path: photo,
            fallbackName: 'signature.jpg',
          );
          request.files.add(http.MultipartFile.fromBytes(
            'signatures',
            prepared.bytes,
            filename: prepared.filename,
            contentType: prepared.contentType,
          ));
          return;
        }
      } catch (_) {}
    }
    final signatureBytes = await _signaturePngBytes(points);
    if (signatureBytes == null) return;
    request.files.add(http.MultipartFile.fromBytes(
      'signatures',
      signatureBytes,
      filename: filename,
      contentType: MediaType('image', 'png'),
    ));
  }

  Future<void> _addBookingImages(http.MultipartRequest request, CheckInFormData formData) async {
    // Prefer local captures first so we do not re-upload large CDN originals.
    final ordered = <String>[
      ...formData.idPhotos,
      if ((formData.idFrontPhotoUrl ?? '').trim().isNotEmpty) formData.idFrontPhotoUrl!.trim(),
      if ((formData.idBackPhotoUrl ?? '').trim().isNotEmpty) formData.idBackPhotoUrl!.trim(),
    ];
    final imagePaths = <String>[];
    final seen = <String>{};
    for (final path in ordered) {
      final trimmed = path.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      imagePaths.add(trimmed);
    }
    // Keep payload under typical nginx 1mb body limits.
    const maxImages = 6;
    for (final path in imagePaths.take(maxImages)) {
      await _addImagePart(request, path);
    }
  }

  Future<void> _addImagePart(http.MultipartRequest request, String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.contains('://')) {
      await _addRemoteFile(request, trimmed, field: 'images');
      return;
    }
    try {
      final file = File(trimmed);
      if (!await file.exists()) return;
      final prepared = _preparedImageUpload(
        bytes: await _readFileBytes(trimmed),
        path: trimmed,
        fallbackName: 'id-photo.jpg',
      );
      request.files.add(http.MultipartFile.fromBytes(
        'images',
        prepared.bytes,
        filename: prepared.filename,
        contentType: prepared.contentType,
      ));
    } catch (_) {}
  }

  Future<bool> _addRemoteFile(
    http.MultipartRequest request,
    String url, {
    required String field,
  }) async {
    try {
      final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300 || response.bodyBytes.isEmpty) {
        return false;
      }
      final prepared = _preparedImageUpload(
        bytes: response.bodyBytes,
        path: url,
        fallbackName: field == 'signatures' ? 'signature.jpg' : 'id-photo.jpg',
      );
      request.files.add(http.MultipartFile.fromBytes(
        field,
        prepared.bytes,
        filename: prepared.filename,
        contentType: prepared.contentType,
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  String _resolveRoomId(CheckInFormData formData) {
    final rawId = formData.selectedRoomId.trim();
    if (RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(rawId)) {
      return rawId;
    }
    final cleanNum = formData.selectedRoomNumber
        .replaceAll('#', '')
        .replaceAll('Room', '')
        .trim();
    for (final r in _rooms) {
      final rClean = r.roomNumber.replaceAll('#', '').replaceAll('Room', '').trim();
      final matchesNumber = rClean == cleanNum ||
          r.roomNumber == formData.selectedRoomNumber ||
          r.roomNumber == '#${formData.selectedRoomNumber}' ||
          'Room ${r.roomNumber}' == formData.selectedRoomNumber ||
          'Room #${r.roomNumber}' == formData.selectedRoomNumber;
      final matchesId = r.id == rawId;
      if ((matchesNumber || matchesId) && RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(r.id)) {
        return r.id;
      }
    }
    return rawId;
  }

  String _mapGovtIdType(String idType) {
    final upper = idType.trim().toUpperCase();
    if (upper.contains('AADHAAR') || upper.contains('ADHAAR')) return 'AADHAAR';
    if (upper.contains('PASSPORT')) return 'PASSPORT';
    if (upper.contains('DRIV') || upper.contains('DL')) return 'DRIVING_LICENSE';
    if (upper.contains('VOTER')) return 'VOTER_ID';
    return 'AADHAAR';
  }

  String _mapPaymentMethod(String paymentMode) {
    final upper = paymentMode.trim().toUpperCase();
    if (upper.contains('CASH')) return 'CASH';
    if (upper.contains('UPI')) return 'UPI';
    if (upper.contains('CARD') || upper.contains('CREDIT') || upper.contains('DEBIT')) return 'CARD';
    if (upper.contains('POS')) return 'POS';
    if (upper.contains('NET') || upper.contains('BANK')) return 'BANK_TRANSFER';
    return 'UPI';
  }

  @override
  Future<GuestFolioModel> completeCheckIn(CheckInFormData formData) {
    final inFlight = _activeCheckIn;
    if (inFlight != null) return inFlight;
    final run = _sendCheckIn(formData);
    late final Future<GuestFolioModel> tracked;
    tracked = run.whenComplete(() {
      if (identical(_activeCheckIn, tracked)) _activeCheckIn = null;
    });
    _activeCheckIn = tracked;
    return tracked;
  }

  Future<GuestFolioModel> _sendCheckIn(CheckInFormData formData) async {
    final targetRoomId = _resolveRoomId(formData);

    final checkInDateStr = _bookingTimestamp(formData.checkInDate, defaultHour: 14);
    final checkOutDateStr = _bookingTimestamp(formData.checkOutDate, defaultHour: 12);

    final childCount = formData.accompanyingGuests
        .where((guest) =>
            guest.name.trim().isNotEmpty && guest.relationship.toLowerCase().contains('child'))
        .length;
    final adults = formData.numberOfGuests > childCount
        ? formData.numberOfGuests - childCount
        : (formData.numberOfGuests > 0 ? formData.numberOfGuests : 1);
    final secondaryName = (formData.secondGuestName ?? '').trim().isNotEmpty
        ? formData.secondGuestName!.trim()
        : formData.accompanyingGuests
            .map((guest) => guest.name.trim())
            .firstWhere((name) => name.isNotEmpty, orElse: () => '');

    final allGuestNames = <String>[];
    if (formData.guestFullName.trim().isNotEmpty) {
      allGuestNames.add(formData.guestFullName.trim());
    }
    if ((formData.secondGuestName ?? '').trim().isNotEmpty) {
      final name = formData.secondGuestName!.trim();
      if (!allGuestNames.contains(name)) {
        allGuestNames.add(name);
      }
    }
    for (final guest in formData.accompanyingGuests) {
      final name = guest.name.trim();
      if (name.isNotEmpty && !allGuestNames.contains(name)) {
        allGuestNames.add(name);
      }
    }
    final guestsJson = jsonEncode(allGuestNames);

    final roomIdField = _bookingRoomId(formData, targetRoomId);
    final stayNights = _calendarNights(formData.checkInDate, formData.checkOutDate);
    final gstRate = _gstRateForRoom(targetRoomId, formData.selectedRoomId);
    final baseAmount = formData.pricePerNight * stayNights;

    if (!_shouldSkipLiveNetwork) {
      try {
        final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.bookingsUrl));
        request.headers['Accept'] = 'application/json';
        request.fields.addAll({
          'primary_guest_name': formData.guestFullName.trim(),
          'secondary_guest_name': secondaryName,
          'guests': guestsJson,
          'mobile_number': _bookingMobile(formData.contactPhone),
          'email': formData.email.trim(),
          'address': formData.residentialAddress.trim(),
          'room_id': roomIdField,
          'check_in_date': checkInDateStr,
          'check_out_date': checkOutDateStr,
          'adults': '$adults',
          'children': '$childCount',
          'base_amount': _plainAmount(baseAmount),
          'discount_amount': _plainAmount(formData.discountAmount),
          'extra_charges_total': _plainAmount(formData.extraBeds * 500),
          'gst_rate': _plainAmount(gstRate),
          'paid_amount': _plainAmount(formData.advancePaid),
          'payment_method': _mapPaymentMethod(formData.paymentMode),
          'notes': formData.transactionRef.trim().isNotEmpty
              ? formData.transactionRef.trim()
              : (formData.specialRequests ?? '').trim(),
          'booking_status': 'CHECKED_IN',
        });

        await _addBookingImages(request, formData);

        final signaturePhoto = formData.signaturePhotoPath;
        await _addSignatureFile(
          request,
          photoPath: signaturePhoto,
          points: formData.signaturePoints,
          filename: 'signature.png',
        );
        for (var index = 0; index < formData.extraSignatures.length; index++) {
          final extra = formData.extraSignatures[index];
          await _addSignatureFile(
            request,
            photoPath: extra.photoPath,
            points: extra.points,
            filename: 'signature-${index + 2}.png',
          );
        }

        final streamed = await _client.send(request).timeout(const Duration(seconds: 60));
        final response = await http.Response.fromStream(streamed);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
          final data = jsonResponse['data'] as Map<String, dynamic>? ?? {};
          final bookingJson = data['booking'] as Map<String, dynamic>? ?? data;
          final receiptNumber = data['receiptNumber']?.toString();

          final apiFolio = GuestFolioModel.fromJson(bookingJson);

          final enrichedFolio = apiFolio.copyWith(
            guestName: (apiFolio.guestName.isNotEmpty && apiFolio.guestName != 'Guest')
                ? apiFolio.guestName
                : (formData.guestFullName.isNotEmpty ? formData.guestFullName : 'Guest'),
            email: apiFolio.email.isNotEmpty ? apiFolio.email : formData.email,
            phone: apiFolio.phone.isNotEmpty ? apiFolio.phone : formData.contactPhone,
            idType: (apiFolio.idType.isNotEmpty && apiFolio.idType != 'Aadhaar Card')
                ? apiFolio.idType
                : formData.idType,
            idNumber: apiFolio.idNumber.isNotEmpty ? apiFolio.idNumber : formData.idNumber,
            isGovtIdVerified: formData.isIdVerified || apiFolio.isGovtIdVerified,
            assignedRoom: apiFolio.assignedRoom.isNotEmpty
                ? apiFolio.assignedRoom
                : 'Room ${formData.selectedRoomNumber}',
            roomType: apiFolio.roomType.isNotEmpty ? apiFolio.roomType : formData.roomType,
            keycardNumber: formData.assignedKeycardNumber.isNotEmpty
                ? formData.assignedKeycardNumber
                : apiFolio.keycardNumber,
            address: _joinedAddress(formData).isNotEmpty ? _joinedAddress(formData) : apiFolio.address,
            gstNumber: formData.gstNumber ?? apiFolio.gstNumber,
            receiptNumber: receiptNumber ?? apiFolio.receiptNumber,
            specialRequests: formData.specialRequests ?? apiFolio.specialRequests,
          );

          _folios.removeWhere((f) => f.id == enrichedFolio.id || f.bookingId == enrichedFolio.bookingId);
          _folios.insert(0, enrichedFolio);

          final roomIndex = _rooms.indexWhere((r) =>
              r.id == targetRoomId ||
              r.id == formData.selectedRoomId ||
              r.roomNumber == formData.selectedRoomNumber ||
              r.roomNumber == '#${formData.selectedRoomNumber}');
          if (roomIndex != -1) {
            _releaseAvailablePin(_rooms[roomIndex]);
            _writeRoom(
              roomIndex,
              _rooms[roomIndex].copyWith(
                status: RoomStatus.occupied,
                currentGuestName: enrichedFolio.guestName,
                currentGuestFolioId: enrichedFolio.id,
              ),
            );
          }

          return enrichedFolio;
        } else {
          throw Exception(_readApiError(response.body, response.statusCode));
        }
      } catch (e) {
        throw Exception(_checkInErrorText(e));
      }
    }

    final newFolioId = 'FOL-${1100 + _folios.length}';
    final newFolio = GuestFolioModel(
      id: newFolioId,
      guestName: formData.guestFullName.isNotEmpty ? formData.guestFullName : 'Guest',
      email: formData.email,
      phone: formData.contactPhone,
      assignedRoom: 'Room ${formData.selectedRoomNumber}',
      roomType: formData.roomType,
      checkInDate: formData.checkInDate,
      checkOutDate: formData.checkOutDate,
      status: FolioStatus.inHouse,
      idType: formData.idType,
      idNumber: formData.idNumber,
      isGovtIdVerified: formData.isIdVerified,
      roomRatePerNight: formData.pricePerNight,
      advancePaid: formData.advancePaid,
      totalAmount: formData.grandTotal > 0 ? formData.grandTotal : formData.pricePerNight * formData.totalNights,
      paymentMode: formData.paymentMode,
      keycardNumber: formData.assignedKeycardNumber,
      address: '${formData.residentialAddress}, ${formData.city}, ${formData.state} - ${formData.pincode}',
      gstNumber: formData.gstNumber,
    );

    _folios.insert(0, newFolio);

    // Update the room to occupied
    final roomIndex = _rooms.indexWhere((r) => r.id == formData.selectedRoomId || r.roomNumber == formData.selectedRoomNumber || r.roomNumber == '#${formData.selectedRoomNumber}');
    if (roomIndex != -1) {
      _releaseAvailablePin(_rooms[roomIndex]);
      _writeRoom(
        roomIndex,
        _rooms[roomIndex].copyWith(
          status: RoomStatus.occupied,
          currentGuestName: formData.guestFullName,
          currentGuestFolioId: newFolioId,
        ),
      );
    }

    return newFolio;
  }

  /// PUT /api/v1/bookings/{id}. No hotel_id. Auth comes from the signed-in session.
  Future<GuestFolioModel> updateBooking({
    required String bookingId,
    required String guestName,
    required String phone,
    required String email,
    required String address,
    required String roomId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int adults,
    required int children,
    required num baseAmount,
    required num discountAmount,
    required num extraCharges,
    required num gstRate,
    required num paidAmount,
    required String notes,
    String paymentMethod = 'UPI',
    String secondaryGuestName = '',
    String bookingStatus = 'CHECKED_IN',
  }) async {
    final id = bookingId.trim();
    if (id.isEmpty) throw Exception('Could not update this booking.');
    final payload = <String, dynamic>{
      'primary_guest_name': guestName.trim(),
      'secondary_guest_name': secondaryGuestName.trim(),
      'mobile_number': _bookingMobile(phone),
      'email': email.trim(),
      'address': address.trim(),
      'room_id': _roomIdIntsFromRaw(roomId).isNotEmpty
          ? _roomIdIntsFromRaw(roomId)
          : _roomIdIntsFromRaw(_roomIdFormValue(roomId)),
      'check_in_date': _bookingTimestamp(checkInDate, defaultHour: 14),
      'check_out_date': _bookingTimestamp(checkOutDate, defaultHour: 12),
      'adults': adults < 1 ? 1 : adults,
      'children': children < 0 ? 0 : children,
      'base_amount': _jsonAmount(baseAmount),
      'discount_amount': _jsonAmount(discountAmount),
      'extra_charges_total': _jsonAmount(extraCharges),
      'gst_rate': _jsonAmount(gstRate),
      'paid_amount': _jsonAmount(paidAmount),
      'payment_method': _mapPaymentMethod(paymentMethod),
      'notes': notes.trim(),
      'booking_status': bookingStatus,
    };
    final response = await _client
        .put(
          Uri.parse('${ApiConstants.bookingsUrl}/$id'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_readApiError(response.body, response.statusCode, fallback: 'Could not update this booking.'));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw Exception('Could not update this booking.');
    final data = decoded['data'];
    final bookingJson = data is Map
        ? (data['booking'] is Map ? Map<String, dynamic>.from(data['booking'] as Map) : Map<String, dynamic>.from(data))
        : payload;
    return GuestFolioModel.fromJson(bookingJson);
  }

  num _jsonAmount(num value) => value == value.roundToDouble() ? value.round() : value;

  @override
  Future<GuestFolioModel> updateBookingFromForm(CheckInFormData formData) async {
    final namedChildren = formData.accompanyingGuests
        .where((guest) => guest.name.trim().isNotEmpty && guest.relationship.toLowerCase().contains('child'))
        .length;
    final childCount = namedChildren > 0 ? namedChildren : formData.savedChildCount;
    final adults = formData.numberOfGuests > childCount
        ? formData.numberOfGuests - childCount
        : (formData.numberOfGuests > 0 ? formData.numberOfGuests : 1);
    final secondaryName = (formData.secondGuestName ?? '').trim().isNotEmpty
        ? formData.secondGuestName!.trim()
        : formData.accompanyingGuests
            .map((guest) => guest.name.trim())
            .firstWhere((name) => name.isNotEmpty, orElse: () => '');

    final allGuestNames = <String>[];
    if (formData.guestFullName.trim().isNotEmpty) {
      allGuestNames.add(formData.guestFullName.trim());
    }
    if ((formData.secondGuestName ?? '').trim().isNotEmpty) {
      final name = formData.secondGuestName!.trim();
      if (!allGuestNames.contains(name)) {
        allGuestNames.add(name);
      }
    }
    for (final guest in formData.accompanyingGuests) {
      final name = guest.name.trim();
      if (name.isNotEmpty && !allGuestNames.contains(name)) {
        allGuestNames.add(name);
      }
    }
    final guestsJson = jsonEncode(allGuestNames);

    final stayNights = _calendarNights(formData.checkInDate, formData.checkOutDate);
    final notes = formData.transactionRef.trim().isNotEmpty
        ? formData.transactionRef.trim()
        : (formData.specialRequests ?? '').trim();
    final id = (formData.editingBookingId ?? '').trim();
    if (id.isEmpty) throw Exception('Could not update this booking.');

    final request = http.MultipartRequest('PUT', Uri.parse('${ApiConstants.bookingsUrl}/$id'));
    request.headers['Accept'] = 'application/json';
    request.fields.addAll({
      'primary_guest_name': formData.guestFullName.trim(),
      'secondary_guest_name': secondaryName,
      'guests': guestsJson,
      'mobile_number': _bookingMobile(formData.contactPhone),
      'email': formData.email.trim(),
      'address': _joinedAddress(formData),
      'room_id': _bookingRoomId(formData, formData.selectedRoomId),
      'check_in_date': _bookingTimestamp(formData.checkInDate, defaultHour: 14),
      'check_out_date': _bookingTimestamp(formData.checkOutDate, defaultHour: 12),
      'adults': '${adults < 1 ? 1 : adults}',
      'children': '${childCount < 0 ? 0 : childCount}',
      'base_amount': _plainAmount(formData.pricePerNight * stayNights),
      'discount_amount': _plainAmount(formData.discountAmount),
      'extra_charges_total': _plainAmount(formData.extraBeds * 500),
      'gst_rate': _plainAmount(formData.gstRate),
      'paid_amount': _plainAmount(formData.advancePaid),
      'payment_method': _mapPaymentMethod(formData.paymentMode),
      'notes': notes,
      'booking_status': 'CHECKED_IN',
    });
    await _addBookingImages(request, formData);
    await _addSignatureFile(
      request,
      photoPath: formData.signaturePhotoPath,
      points: formData.signaturePoints,
      filename: 'signature.png',
    );
    for (var index = 0; index < formData.extraSignatures.length; index++) {
      final extra = formData.extraSignatures[index];
      await _addSignatureFile(
        request,
        photoPath: extra.photoPath,
        points: extra.points,
        filename: 'signature-${index + 2}.png',
      );
    }
    if (!request.files.any((file) => file.field == 'images')) {
      throw Exception('At least one image is required.');
    }

    final streamed = await _client.send(request).timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_readApiError(response.body, response.statusCode, fallback: 'Could not update this booking.'));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw Exception('Could not update this booking.');
    final data = decoded['data'];
    final bookingJson = data is Map
        ? (data['booking'] is Map ? Map<String, dynamic>.from(data['booking'] as Map) : Map<String, dynamic>.from(data))
        : <String, dynamic>{'id': id, 'primary_guest_name': formData.guestFullName};
    return GuestFolioModel.fromJson(bookingJson);
  }

  /// Applies a `booking:updated` payload to the in-memory rooms and folios.
  @override
  ({List<RoomModel> rooms, List<GuestFolioModel> folios}) applyLiveBooking(Map<String, dynamic> json) {
    acceptRemoteRoomStatuses();
    final folio = GuestFolioModel.fromJson(json);
    final deleted = json['deleted_at'] ?? json['deletedAt'];
    final removed = deleted != null && deleted.toString().trim().isNotEmpty && deleted.toString().toLowerCase() != 'null';
    _folios.removeWhere((item) => item.id == folio.id || (folio.bookingId != null && item.bookingId == folio.bookingId));
    if (removed || folio.status != FolioStatus.inHouse) {
      _clearLiveGuest(folio);
    } else {
      _folios.insert(0, folio);
      _clearLiveGuest(folio, keepMatchedRoom: true);
      _attachCheckedInGuests();
    }
    return (
      rooms: List<RoomModel>.from(_rooms),
      folios: List<GuestFolioModel>.from(_folios),
    );
  }

  void _clearLiveGuest(GuestFolioModel folio, {bool keepMatchedRoom = false}) {
    final roomId = (folio.roomId ?? '').trim();
    final digits = folio.assignedRoom.replaceAll(RegExp(r'[^0-9]'), '');
    final updated = <RoomModel>[];
    for (final room in _rooms) {
      final roomDigits = room.roomNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final sameRoom = (roomId.isNotEmpty && room.id == roomId) || (digits.isNotEmpty && roomDigits == digits);
      final sameGuest = room.currentGuestFolioId == folio.id ||
          (folio.bookingId != null && room.currentGuestFolioId == folio.bookingId);
      if (!sameRoom && !sameGuest) {
        updated.add(room);
        continue;
      }
      if (keepMatchedRoom && sameRoom) {
        updated.add(room);
        continue;
      }
      updated.add(room.copyWith(
        status: room.status == RoomStatus.occupied ? RoomStatus.cleaning : room.status,
        clearGuest: true,
      ));
    }
    _rooms = updated;
  }

  /// GET /api/v1/bookings/{id}. `data` is one booking object.
  @override
  Future<GuestFolioModel?> fetchBooking(String bookingId) async {
    if (_shouldSkipLiveNetwork) {
      final id = bookingId.trim();
      return _folios
          .where((f) => f.id == id || f.bookingId == id || f.effectiveBookingId == id)
          .firstOrNull;
    }
    final id = bookingId.trim();
    if (id.isEmpty) return null;
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.bookingsUrl}/$id'),
        headers: const {'Accept': 'application/json'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final data = decoded['data'];
      if (data is! Map) return null;
      return GuestFolioModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('DashboardRepository.fetchBooking error: $e');
      return null;
    }
  }

  /// GET /api/v1/bookings/{id}/pdf, then download the generated file.
  Future<BookingPdfFile> fetchBookingPdf(String bookingId) async {
    if (_shouldSkipLiveNetwork) {
      throw Exception('Could not generate the folio PDF.');
    }
    final id = bookingId.trim();
    if (id.isEmpty) {
      throw Exception('Could not generate the folio PDF.');
    }
    final response = await _client
        .get(
          Uri.parse('${ApiConstants.bookingsUrl}/$id/pdf'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_pdfErrorMessage(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Could not generate the folio PDF.');
    }
    final data = decoded['data'];
    if (data is! Map) {
      throw Exception('Could not generate the folio PDF.');
    }
    final url = (data['url'] ?? '').toString().trim();
    var fileName = (data['file_name'] ?? data['fileName'] ?? '').toString().trim();
    if (url.isEmpty) {
      throw Exception('Could not generate the folio PDF.');
    }
    if (fileName.isEmpty) fileName = 'guest-folio.pdf';
    final fileResponse = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (fileResponse.statusCode < 200 || fileResponse.statusCode >= 300 || fileResponse.bodyBytes.isEmpty) {
      throw Exception('Could not download the folio PDF.');
    }
    return BookingPdfFile(bytes: fileResponse.bodyBytes, fileName: fileName, url: url);
  }

  /// GET /api/v1/reports/gst/export?start_date=&end_date=&format=pdf|xlsx
  Future<BookingPdfFile> exportGstReport({
    required DateTime startDate,
    required DateTime endDate,
    required String format,
  }) async {
    if (_shouldSkipLiveNetwork) {
      throw Exception('Could not download the GST report.');
    }
    final fileFormat = format.trim().toLowerCase() == 'xlsx' ? 'xlsx' : 'pdf';
    final uri = Uri.parse(ApiConstants.gstReportExportUrl).replace(
      queryParameters: {
        'start_date': _reportDate(startDate),
        'end_date': _reportDate(endDate),
        'format': fileFormat,
      },
    );
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_readApiError(response.body, response.statusCode, fallback: 'Could not download the GST report'));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['success'] == false) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message == null || message.isEmpty ? 'Could not download the GST report.' : message);
    }
    final data = decoded['data'];
    if (data is! Map) {
      throw Exception('Could not download the GST report.');
    }
    final url = (data['url'] ?? '').toString().trim();
    var fileName = (data['file_name'] ?? data['fileName'] ?? '').toString().trim();
    if (url.isEmpty) {
      throw Exception('Could not download the GST report.');
    }
    if (fileName.isEmpty) fileName = 'gst-report.$fileFormat';
    final fileResponse = await _downloadReportFile(url);
    if (fileResponse.statusCode < 200 || fileResponse.statusCode >= 300 || fileResponse.bodyBytes.isEmpty) {
      throw Exception('Could not download the GST report.');
    }
    return BookingPdfFile(bytes: fileResponse.bodyBytes, fileName: fileName, url: url);
  }

  Future<http.Response> _downloadReportFile(String url) async {
    final uri = Uri.parse(url);
    try {
      final direct = await http.get(uri).timeout(const Duration(seconds: 30));
      if (direct.statusCode >= 200 && direct.statusCode < 300 && direct.bodyBytes.isNotEmpty) {
        return direct;
      }
    } catch (_) {}
    return _client.get(uri).timeout(const Duration(seconds: 30));
  }

  String _reportDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// GET /api/v1/dashboard/summary?start_date=&end_date= — same daily summary as admin.
  Future<DashboardSummary> fetchDashboardSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_shouldSkipLiveNetwork) {
      return const DashboardSummary();
    }
    final uri = Uri.parse(ApiConstants.dashboardSummaryUrl).replace(
      queryParameters: {
        'start_date': _reportDate(startDate),
        'end_date': _reportDate(endDate),
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

  /// Live booking bill from GET /api/v1/bookings/{id}. Used to fill checkout fields.
  Future<({
    double roomCharges,
    double discount,
    double extraCharges,
    double lateCharge,
    double lateHours,
    double taxable,
    double cgstRate,
    double sgstRate,
    double cgst,
    double sgst,
    double total,
    double paid,
    double due,
    String guestName,
    String phone,
    String bookingNumber,
    List<String> roomNumbers,
    String? notes,
  })?> fetchBookingSettlement(String bookingId) async {
    if (_shouldSkipLiveNetwork) {
      final id = bookingId.trim();
      final folio = _folios
          .where((f) => f.id == id || f.bookingId == id || f.effectiveBookingId == id)
          .firstOrNull;
      if (folio != null) {
        return (
          roomCharges: folio.roomCharges > 0 ? folio.roomCharges : folio.totalAmount,
          discount: folio.discount,
          extraCharges: folio.extraCharges,
          lateCharge: 0.0,
          lateHours: 0.0,
          taxable: folio.totalAmount,
          cgstRate: folio.gstRate > 0 ? folio.gstRate / 2 : 9.0,
          sgstRate: folio.gstRate > 0 ? folio.gstRate / 2 : 9.0,
          cgst: folio.cgstAmount,
          sgst: folio.sgstAmount,
          total: folio.totalAmount,
          paid: folio.advancePaid,
          due: folio.pendingAmount,
          guestName: folio.guestName,
          phone: folio.phone,
          bookingNumber: folio.bookingId ?? folio.id,
          roomNumbers: [folio.assignedRoom],
          notes: folio.guestNotes,
        );
      }
      return null;
    }
    final id = bookingId.trim();
    if (id.isEmpty) return null;
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.bookingsUrl}/$id'),
        headers: const {'Accept': 'application/json'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final data = decoded['data'];
      if (data is! Map) return null;
      double read(dynamic value) {
        if (value is num) return value.toDouble();
        return double.tryParse(value?.toString() ?? '') ?? 0;
      }

      final roomCharges = read(data['base_amount'] ?? data['baseAmount']);
      final discount = read(data['discount_amount'] ?? data['discountAmount']);
      final extraCharges = read(data['extra_charges_total'] ?? data['extraChargesTotal']);
      final lateCharge = read(data['late_checkout_charge'] ?? data['lateCheckoutCharge']);
      final lateHours = read(data['late_checkout_hours'] ?? data['lateCheckoutHours']);
      final taxable = data.containsKey('taxable_amount') || data.containsKey('taxableAmount')
          ? read(data['taxable_amount'] ?? data['taxableAmount'])
          : (roomCharges - discount + extraCharges + lateCharge).clamp(0, double.infinity).toDouble();
      final cgstRate = read(data['cgst_rate'] ?? data['cgstRate']).clamp(0, 100).toDouble();
      final sgstRate = read(data['sgst_rate'] ?? data['sgstRate']).clamp(0, 100).toDouble();
      final cgst = data.containsKey('cgst_amount') || data.containsKey('cgstAmount')
          ? read(data['cgst_amount'] ?? data['cgstAmount'])
          : taxable * (cgstRate > 0 ? cgstRate : 9) / 100;
      final sgst = data.containsKey('sgst_amount') || data.containsKey('sgstAmount')
          ? read(data['sgst_amount'] ?? data['sgstAmount'])
          : taxable * (sgstRate > 0 ? sgstRate : 9) / 100;
      final total = read(data['total_amount'] ?? data['totalAmount']);
      final paid = read(data['paid_amount'] ?? data['paidAmount']);
      final due = data.containsKey('due_amount') || data.containsKey('dueAmount')
          ? read(data['due_amount'] ?? data['dueAmount'])
          : (total - paid).clamp(0, double.infinity).toDouble();
      final notes = (data['notes'] ?? '').toString().trim();
      final roomNumbers = <String>[];
      final roomsRaw = data['rooms'];
      if (roomsRaw is List) {
        for (final item in roomsRaw) {
          if (item is! Map) continue;
          final number = (item['room_number'] ?? item['roomNumber'] ?? '').toString().trim();
          if (number.isEmpty) continue;
          final cleaned = number.replaceAll('#', '').replaceAll('Room', '').trim();
          if (cleaned.isNotEmpty && !roomNumbers.contains(cleaned)) {
            roomNumbers.add(cleaned);
          }
        }
      }
      return (
        roomCharges: roomCharges,
        discount: discount,
        extraCharges: extraCharges,
        lateCharge: lateCharge,
        lateHours: lateHours,
        taxable: taxable,
        cgstRate: cgstRate > 0 ? cgstRate : 9.0,
        sgstRate: sgstRate > 0 ? sgstRate : 9.0,
        cgst: cgst,
        sgst: sgst,
        total: total,
        paid: paid,
        due: due,
        guestName: (data['primary_guest_name'] ?? data['primaryGuestName'] ?? '').toString(),
        phone: (data['mobile_number'] ?? data['mobileNumber'] ?? '').toString(),
        bookingNumber: (data['booking_number'] ?? data['bookingNumber'] ?? '').toString(),
        roomNumbers: roomNumbers,
        notes: notes.isEmpty ? null : notes,
      );
    } catch (e) {
      debugPrint('DashboardRepository.fetchBookingSettlement error: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> checkoutFolio(
    String folioId, {
    Map<String, dynamic>? customPayload,
  }) async {
    final index = _folios.indexWhere((f) => f.id == folioId || f.bookingId == folioId);
    final folio = index != -1 ? _folios[index] : null;

    final targetBookingId = (folio?.id ?? folioId).trim();
    final checkoutUrl = '${ApiConstants.bookingsUrl}/$targetBookingId/check-out';
    final settlementAmount = folio != null && folio.pendingAmount > 0 ? folio.pendingAmount : 0.0;
    final payload = _checkoutPayload(
      folio: folio,
      settlementAmount: settlementAmount,
      customPayload: customPayload,
    );

    Map<String, dynamic> responseData = {
      "success": true,
      "message": "Checkout completed successfully. Room is now marked for cleaning.",
    };

    if (!_shouldSkipLiveNetwork) {
      final response = await _client
          .post(
            Uri.parse(checkoutUrl),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          responseData = decoded;
        } else if (decoded is Map) {
          responseData = Map<String, dynamic>.from(decoded);
        }
      } else {
        throw Exception(_readApiError(response.body, response.statusCode, fallback: 'Checkout failed'));
      }
    }

    if (index != -1) {
      final oldFolio = _folios[index];
      _folios[index] = oldFolio.copyWith(
        status: FolioStatus.departed,
        advancePaid: oldFolio.totalAmount,
      );

      final roomIndex = _rooms.indexWhere((r) =>
          'Room ${r.roomNumber}' == oldFolio.assignedRoom ||
          r.roomNumber == oldFolio.assignedRoom ||
          'Room #${r.roomNumber}' == oldFolio.assignedRoom ||
          '#${r.roomNumber}' == oldFolio.assignedRoom);
      if (roomIndex != -1) {
        _releaseAvailablePin(_rooms[roomIndex]);
        _writeRoom(
          roomIndex,
          _rooms[roomIndex].copyWith(
            status: RoomStatus.cleaning,
            currentGuestName: null,
            currentGuestFolioId: null,
          ),
        );
      }
    }

    return responseData;
  }

  Map<String, dynamic> _checkoutPayload({
    required GuestFolioModel? folio,
    required double settlementAmount,
    Map<String, dynamic>? customPayload,
  }) {
    final paidRaw = customPayload?['paid_amount'] ?? settlementAmount;
    final paidNumber = paidRaw is num ? paidRaw.toDouble() : settlementAmount;
    final paidAmount = _jsonAmount(paidNumber);
    final methodRaw = (customPayload?['payment_method'] ??
            (folio != null && folio.paymentMode.trim().isNotEmpty ? folio.paymentMode : 'CASH'))
        .toString()
        .trim()
        .toUpperCase();
    final paymentMethod = methodRaw.contains('CASH')
        ? 'CASH'
        : methodRaw.contains('CARD')
            ? 'CARD'
            : 'UPI';
    final notesRaw = (customPayload?['notes'] ?? '').toString().trim();
    final notes = notesRaw.isNotEmpty
        ? notesRaw
        : 'Checked out and settled via $paymentMethod';

    num readAmount(String key, {num fallback = 0}) {
      final raw = customPayload?[key];
      if (raw is num) return _jsonAmount(raw.toDouble());
      final parsed = double.tryParse(raw?.toString() ?? '');
      if (parsed != null) return _jsonAmount(parsed);
      return fallback;
    }

    return <String, dynamic>{
      'paid_amount': paidAmount,
      'extra_charges_total': readAmount('extra_charges_total'),
      'discount_amount': readAmount('discount_amount'),
      'late_checkout_charge': readAmount('late_checkout_charge'),
      'late_checkout_hours': readAmount('late_checkout_hours'),
      'notes': notes,
      'payment_method': paymentMethod,
    };
  }

  @override
  Future<void> extendFolioStay(String folioId, DateTime newCheckoutDate) async {
    final index = _folios.indexWhere((f) => f.id == folioId);
    if (index != -1) {
      final oldFolio = _folios[index];
      final addedNights = newCheckoutDate.difference(oldFolio.checkOutDate).inDays;
      final extraRoomCost = addedNights > 0 ? addedNights * oldFolio.roomRatePerNight : 0.0;
      final newTotal = oldFolio.totalAmount + extraRoomCost;
      final newRoomCharges = oldFolio.roomCharges + extraRoomCost;

      _folios[index] = oldFolio.copyWith(
        checkOutDate: newCheckoutDate,
        totalAmount: newTotal,
        roomCharges: newRoomCharges,
      );
    }
  }

  @override
  Future<void> addFolioPayment(String folioId, PaymentRecordModel payment) async {
    final index = _folios.indexWhere((f) => f.id == folioId);
    if (index != -1) {
      final oldFolio = _folios[index];
      final newAdvance = oldFolio.advancePaid + payment.amount;
      final updatedPayments = [payment, ...oldFolio.payments];

      _folios[index] = oldFolio.copyWith(
        advancePaid: newAdvance,
        payments: updatedPayments,
      );
    }
  }

  @override
  Future<void> addFolioCharge(String folioId, ChargeItemModel charge) async {
    final index = _folios.indexWhere((f) => f.id == folioId);
    if (index != -1) {
      final oldFolio = _folios[index];
      final newTotal = oldFolio.totalAmount + charge.amount;
      final newExtraCharges = oldFolio.extraCharges + charge.amount;
      final updatedServices = [charge, ...oldFolio.services];

      _folios[index] = oldFolio.copyWith(
        totalAmount: newTotal,
        extraCharges: newExtraCharges,
        services: updatedServices,
      );
    }
  }

  @override
  Future<void> updateFolioKeycard(String folioId, String keycardStatus, String? keycardNumber) async {
    final index = _folios.indexWhere((f) => f.id == folioId);
    if (index != -1) {
      final oldFolio = _folios[index];
      _folios[index] = oldFolio.copyWith(
        keycardStatus: keycardStatus,
        keycardNumber: keycardNumber ?? oldFolio.keycardNumber,
        keycardIssuedAt: DateTime.now(),
      );
    }
  }

  static List<RoomModel> _buildInitialRooms() => List<RoomModel>.from(const [
    RoomModel(
      id: 'room-01',
      roomNumber: '#01',
      floor: 'Floor 1',
      roomType: 'family room',
      pricePerNight: 5000,
      status: RoomStatus.available,
      maxOccupancy: 4,
      amenities: ['King Bed', 'Balcony View', 'Wi-Fi', 'Smart TV', 'En-suite Bath'],
    ),
    RoomModel(
      id: 'room-06',
      roomNumber: '#06',
      floor: 'Floor 1',
      roomType: 'family room',
      pricePerNight: 5000,
      status: RoomStatus.available,
      maxOccupancy: 4,
      amenities: ['King Bed', 'Balcony View', 'Wi-Fi', 'Smart TV', 'En-suite Bath'],
    ),
    RoomModel(
      id: 'room-11',
      roomNumber: '#11',
      floor: 'Floor 2',
      roomType: 'family room',
      pricePerNight: 5000,
      status: RoomStatus.available,
      maxOccupancy: 4,
      amenities: ['King Bed', 'Balcony View', 'Wi-Fi', 'Smart TV', 'En-suite Bath'],
    ),
    RoomModel(
      id: 'room-16',
      roomNumber: '#16',
      floor: 'Floor 3',
      roomType: 'family room',
      pricePerNight: 5000,
      status: RoomStatus.cleaning,
      maxOccupancy: 4,
      amenities: ['King Bed', 'Balcony View', 'Wi-Fi', 'Smart TV', 'En-suite Bath'],
    ),
    RoomModel(
      id: 'room-02',
      roomNumber: '#02',
      floor: 'Floor 1',
      roomType: 'couple room',
      pricePerNight: 2500,
      status: RoomStatus.available,
      maxOccupancy: 2,
      amenities: ['Queen Bed', 'Air Conditioning', 'Free Breakfast', 'Wi-Fi'],
    ),
    RoomModel(
      id: 'room-07',
      roomNumber: '#07',
      floor: 'Floor 1',
      roomType: 'couple room',
      pricePerNight: 2500,
      status: RoomStatus.available,
      maxOccupancy: 2,
      amenities: ['Queen Bed', 'Air Conditioning', 'Free Breakfast', 'Wi-Fi'],
    ),
    RoomModel(
      id: 'room-12',
      roomNumber: '#12',
      floor: 'Floor 2',
      roomType: 'couple room',
      pricePerNight: 2500,
      status: RoomStatus.occupied,
      currentGuestName: 'Ananya Sharma',
      currentGuestFolioId: 'FOL-1095',
      maxOccupancy: 2,
      amenities: ['Queen Bed', 'Air Conditioning', 'Free Breakfast', 'Wi-Fi'],
    ),
    RoomModel(
      id: 'room-03',
      roomNumber: '#03',
      floor: 'Floor 1',
      roomType: 'deluxe suite',
      pricePerNight: 7500,
      status: RoomStatus.occupied,
      currentGuestName: 'Vikram Mehta',
      currentGuestFolioId: 'FOL-1092',
      maxOccupancy: 3,
      amenities: ['Jacuzzi', 'Mini Bar', 'Sea View', 'High-Speed Wi-Fi'],
    ),
    RoomModel(
      id: 'room-08',
      roomNumber: '#08',
      floor: 'Floor 2',
      roomType: 'deluxe suite',
      pricePerNight: 7500,
      status: RoomStatus.available,
      maxOccupancy: 3,
      amenities: ['Jacuzzi', 'Mini Bar', 'Sea View', 'High-Speed Wi-Fi'],
    ),
    RoomModel(
      id: 'room-13',
      roomNumber: '#13',
      floor: 'Floor 2',
      roomType: 'deluxe suite',
      pricePerNight: 7500,
      status: RoomStatus.available,
      maxOccupancy: 3,
      amenities: ['Jacuzzi', 'Mini Bar', 'Sea View', 'High-Speed Wi-Fi'],
    ),
    RoomModel(
      id: 'room-04',
      roomNumber: '#04',
      floor: 'Floor 2',
      roomType: 'executive room',
      pricePerNight: 4200,
      status: RoomStatus.cleaning,
      maxOccupancy: 2,
      amenities: ['Work Desk', 'Ergonomic Chair', 'Wi-Fi', 'Coffee Machine'],
    ),
    RoomModel(
      id: 'room-09',
      roomNumber: '#09',
      floor: 'Floor 2',
      roomType: 'executive room',
      pricePerNight: 4200,
      status: RoomStatus.available,
      maxOccupancy: 2,
      amenities: ['Work Desk', 'Ergonomic Chair', 'Wi-Fi', 'Coffee Machine'],
    ),
    RoomModel(
      id: 'room-14',
      roomNumber: '#14',
      floor: 'Floor 3',
      roomType: 'executive room',
      pricePerNight: 4200,
      status: RoomStatus.available,
      maxOccupancy: 2,
      amenities: ['Work Desk', 'Ergonomic Chair', 'Wi-Fi', 'Coffee Machine'],
    ),
    RoomModel(
      id: 'room-05',
      roomNumber: '#05',
      floor: 'Floor 2',
      roomType: 'presidential suite',
      pricePerNight: 12000,
      status: RoomStatus.maintenance,
      maxOccupancy: 5,
      amenities: ['Private Lounge', 'Butler Service', 'Private Terrace'],
    ),
    RoomModel(
      id: 'room-10',
      roomNumber: '#10',
      floor: 'Floor 3',
      roomType: 'presidential suite',
      pricePerNight: 12000,
      status: RoomStatus.available,
      maxOccupancy: 5,
      amenities: ['Private Lounge', 'Butler Service', 'Private Terrace'],
    ),
  ]);

  static List<GuestFolioModel> _buildInitialFolios() => [
    GuestFolioModel(
      id: 'FOL-1088',
      guestName: 'Niraj Vekariya',
      email: 'nirajvekariya2209@gmail.com',
      phone: '08849218118',
      assignedRoom: 'Room #01',
      roomType: 'family room',
      checkInDate: DateTime(2026, 1, 19),
      checkOutDate: DateTime(2026, 1, 21),
      status: FolioStatus.departed,
      idType: 'Aadhaar Card',
      idNumber: 'XXXX-XXXX-4819',
      isGovtIdVerified: true,
      roomRatePerNight: 5000,
      advancePaid: 10000,
      totalAmount: 11200,
      paymentMode: 'UPI',
      keycardNumber: 'KC-101',
      address: 'Ahmedabad, Gujarat, India',
    ),
    GuestFolioModel(
      id: 'FOL-1092',
      guestName: 'Vikram Mehta',
      email: 'vikram.mehta@enterprise.in',
      phone: '09825166290',
      assignedRoom: 'Room #03',
      roomType: 'deluxe suite',
      checkInDate: DateTime.now().subtract(const Duration(hours: 18)),
      checkOutDate: DateTime.now().add(const Duration(days: 2)),
      status: FolioStatus.inHouse,
      idType: 'Passport',
      idNumber: 'P8923411',
      isGovtIdVerified: true,
      roomRatePerNight: 7500,
      advancePaid: 15000,
      totalAmount: 16800,
      paymentMode: 'Credit Card',
      keycardNumber: 'KC-103',
      address: 'Mumbai, Maharashtra, India',
    ),
  ];
}

String _pdfErrorMessage(http.Response response) {
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map) {
      final message = decoded['message']?.toString().trim() ?? '';
      if (message.isNotEmpty) return message;
    }
  } catch (_) {}
  return 'Could not generate the folio PDF.';
}

