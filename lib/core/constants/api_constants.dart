class ApiConstants {
  /// Railway host. API routes and the live socket both use this origin.
  static const String origin = 'https://api.myownpms.com';

  /// Base API URL for backend services
  static const String baseUrl = '$origin/api/v1';

  /// Live Socket.IO host — same as Postman `{{baseUrl}}`.
  static const String socketOrigin = 'https://api.myownpms.com';

  // ---------------------------------------------------------------------------
  // Authentication Endpoints
  // ---------------------------------------------------------------------------
  static const String authBaseUrl = '$baseUrl/auth';
  static const String loginUrl = '$authBaseUrl/login';
  static const String refreshTokenUrl = '$authBaseUrl/refresh-token';
  static const String forgotPasswordUrl = '$authBaseUrl/forgot-password';
  static const String meUrl = '$authBaseUrl/me';

  // ---------------------------------------------------------------------------
  // Hotel Admin Endpoints
  // ---------------------------------------------------------------------------
  static const String adminBaseUrl = '$baseUrl/admin';
  static const String adminDashboardUrl = '$adminBaseUrl/dashboard';
  static const String dashboardUrl = '$baseUrl/dashboard';
  static const String dashboardSummaryUrl = '$dashboardUrl/summary';
  static const String adminDailyCollectionsUrl = '$adminBaseUrl/daily-collections';
  static const String adminDailyCollectionsHandoverUrl = '$adminBaseUrl/daily-collections/handover';
  static const String adminReceptionistsUrl = '$adminBaseUrl/receptionists';
  static const String adminRoomsUrl = '$adminBaseUrl/rooms';
  static const String adminRoomTypesUrl = '$adminBaseUrl/room-types';
  static const String adminProfileUrl = '$adminBaseUrl/profile';
  static const String adminRevenueDetailsUrl = '$adminBaseUrl/revenue-details';
  static const String adminReportsUrl = '$adminBaseUrl/reports';
  static const String hotelTrialExtensionUrl = '$baseUrl/hotels/request-trial-extension';
  static const String hotelMeUrl = '$baseUrl/hotels/me';
  static const String subscriptionPlansUrl = '$baseUrl/subscription-plans';

  // ---------------------------------------------------------------------------
  // Front Desk / Receptionist Endpoints
  // ---------------------------------------------------------------------------
  static const String receptionistBaseUrl = '$baseUrl/receptionist';
  static const String receptionistDashboardUrl = '$receptionistBaseUrl/dashboard';
  static const String receptionistAvailableRoomsUrl = '$receptionistBaseUrl/rooms/available';
  static const String receptionistRoomTypesUrl = '$receptionistBaseUrl/room-types';
  static const String roomTypesUrl = '$baseUrl/room-types';
  static String roomTypesByHotelUrl(String hotelId) => '$roomTypesUrl?hotel_id=$hotelId';
  static const String roomsUrl = '$baseUrl/rooms';
  static const String usersUrl = '$baseUrl/users';
  static const String bookingsUrl = '$baseUrl/bookings';
  static const String gstReportExportUrl = '$baseUrl/reports/gst/export';
  static String roomsPageUrl({int page = 1, int limit = 10}) =>
      '$roomsUrl?page=$page&limit=$limit';
  static const String receptionistBookingsUrl = '$receptionistBaseUrl/bookings';

  // Helper method to build cookie headers
  static String buildCookieHeader({String? accessToken, String? refreshToken}) {
    final parts = <String>[];
    if (accessToken != null && accessToken.isNotEmpty) {
      parts.add('accessToken=$accessToken');
      parts.add('token=$accessToken');
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      parts.add('refreshToken=$refreshToken');
    }
    return parts.join('; ');
  }

  // Common JSON headers
  static Map<String, String> defaultHeaders({String? token, String? refreshToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final cookie = buildCookieHeader(accessToken: token, refreshToken: refreshToken);
    if (cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }
    return headers;
  }
}
