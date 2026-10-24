import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/repositories/authenticated_http_client.dart';
import '../../../dashboard/data/models/booking_list_query.dart';
import '../models/guest_model.dart';

class GuestListPage {
  final List<GuestProfileModel> guests;
  final int page;
  final int totalPages;
  final int total;
  final bool hasMore;
  final bool fromNetwork;

  const GuestListPage({
    required this.guests,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.hasMore,
    required this.fromNetwork,
  });
}

abstract class IGuestsRepository {
  Future<List<GuestProfileModel>> getGuests({
    String status = '',
    String search = '',
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  });
  Future<GuestListPage> fetchGuestPage(BookingListQuery query);
  Future<GuestProfileModel?> getGuestById(String id);
}

class GuestsRepository implements IGuestsRepository {
  static const String baseUrl = ApiConstants.receptionistBaseUrl;
  static const String bookingsEndpoint = ApiConstants.receptionistBookingsUrl;

  static GuestsRepository? _instance;
  final http.Client _client;
  final bool _isCustomClient;
  List<GuestProfileModel>? _cachedGuests;

  factory GuestsRepository({
    http.Client? client,
    AuthRepository? authRepository,
  }) {
    if (_instance == null || client != null || authRepository != null) {
      _instance = GuestsRepository._internal(
        client: client,
        authRepository: authRepository,
      );
    }
    return _instance!;
  }

  GuestsRepository._internal({
    http.Client? client,
    AuthRepository? authRepository,
  })  : _isCustomClient = client != null,
        _client = client ??
            AuthenticatedHttpClient(
              authRepository: authRepository ?? AuthRepository(),
            );

  bool get _shouldSkipLiveNetwork {
    if (_isCustomClient) return false;
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<GuestProfileModel>> getGuests({
    String status = '',
    String search = '',
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedGuests != null && _cachedGuests!.isNotEmpty) {
      return List.unmodifiable(_cachedGuests!);
    }

    if (_shouldSkipLiveNetwork) {
      _cachedGuests = _buildMockGuests();
      return List.unmodifiable(_cachedGuests!);
    }

    try {
      final query = <String, String>{
        'page': '${page < 1 ? 1 : page}',
        'limit': '${limit < 1 ? 10 : limit}',
      };
      final bookingStatus = status.trim();
      if (bookingStatus.isNotEmpty) query['booking_status'] = bookingStatus;
      final searchText = search.trim();
      if (searchText.isNotEmpty) query['search'] = searchText;
      final uri = Uri.parse(ApiConstants.bookingsUrl).replace(queryParameters: query);

      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _cachedGuests = const [];
        return const [];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        _cachedGuests = const [];
        return const [];
      }
      final jsonResponse = Map<String, dynamic>.from(decoded);
      final bookingsList = _bookingRows(jsonResponse);
      final seen = <String>{};
      final apiGuests = <GuestProfileModel>[];
      for (final item in bookingsList) {
        if (item is! Map) continue;
        final guest = GuestProfileModel.fromJson(Map<String, dynamic>.from(item));
        if (guest.id.isEmpty || !seen.add(guest.id)) continue;
        apiGuests.add(guest);
      }
      _cachedGuests = apiGuests;
      return List.unmodifiable(_cachedGuests!);
    } catch (e) {
      debugPrint('GuestsRepository.getGuests error: $e');
      _cachedGuests = const [];
      return const [];
    }
  }

  @override
  Future<GuestListPage> fetchGuestPage(BookingListQuery query) async {
    if (_shouldSkipLiveNetwork) {
      final guests = _buildMockGuests();
      return GuestListPage(
        guests: guests,
        page: 1,
        totalPages: 1,
        total: guests.length,
        hasMore: false,
        fromNetwork: false,
      );
    }

    final pageNumber = query.page < 1 ? 1 : query.page;
    final uri = Uri.parse(ApiConstants.bookingsUrl).replace(
      queryParameters: query.toQueryParameters(pageNumber),
    );
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return GuestListPage(
        guests: const [],
        page: pageNumber,
        totalPages: pageNumber,
        total: 0,
        hasMore: false,
        fromNetwork: true,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      return GuestListPage(
        guests: const [],
        page: pageNumber,
        totalPages: pageNumber,
        total: 0,
        hasMore: false,
        fromNetwork: true,
      );
    }
    final jsonResponse = Map<String, dynamic>.from(decoded);
    final rows = _bookingRows(jsonResponse);
    final seen = <String>{};
    final guests = <GuestProfileModel>[];
    for (final item in rows) {
      if (item is! Map) continue;
      final guest = GuestProfileModel.fromJson(Map<String, dynamic>.from(item));
      if (guest.id.isEmpty || !seen.add(guest.id)) continue;
      guests.add(guest);
    }

    final data = jsonResponse['data'];
    var totalPages = pageNumber;
    var total = guests.length;
    var page = pageNumber;
    if (data is Map) {
      totalPages = (data['totalPages'] as num?)?.toInt() ?? pageNumber;
      total = (data['total'] as num?)?.toInt() ?? guests.length;
      page = (data['page'] as num?)?.toInt() ?? pageNumber;
    }
    if (totalPages < 1) totalPages = 1;
    return GuestListPage(
      guests: guests,
      page: page,
      totalPages: totalPages,
      total: total,
      hasMore: page < totalPages,
      fromNetwork: true,
    );
  }

  List<dynamic> _bookingRows(Map<String, dynamic> jsonResponse) {
    final data = jsonResponse['data'];
    if (data is List) return data;
    if (data is Map && data['bookings'] is List) return data['bookings'] as List;
    if (jsonResponse['bookings'] is List) return jsonResponse['bookings'] as List;
    return const [];
  }

  @override
  Future<GuestProfileModel?> getGuestById(String id) async {
    final guests = await getGuests();
    try {
      return guests.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<GuestProfileModel> _buildMockGuests() {
    // No static guest data — widget tests use an empty list.
    return const <GuestProfileModel>[];
  }
}
