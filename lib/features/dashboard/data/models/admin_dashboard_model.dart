class WeeklyRevenuePoint {
  final String date;
  final String day;
  final double revenue;

  const WeeklyRevenuePoint({
    this.date = '',
    this.day = '',
    this.revenue = 0,
  });

  String get shortDay {
    final text = day.trim();
    if (text.isEmpty) return '';
    return text.length <= 3 ? text : text.substring(0, 3);
  }
}

class AdminDashboardSnapshot {
  final String hotelName;
  final String currency;
  final double taxPercentage;
  final bool gstEnabled;
  final double todayRevenue;
  final double monthRevenue;
  final double outstandingDue;
  final int occupancyRatePercentage;
  final int totalPhysicalRooms;
  final int activeStaffCount;
  final int checkedInToday;
  final int expectedCheckOutsToday;
  final int checkedOutToday;
  final int inHouseGuests;
  final int availableRooms;
  final int reservedRooms;
  final int occupiedRooms;
  final int cleaningRooms;
  final int maintenanceRooms;
  final int blockedRooms;
  final double cash;
  final double online;
  final double card;
  final double upi;
  final double bankTransfer;
  final List<WeeklyRevenuePoint> weeklyRevenue;
  final String planName;
  final int maxRoomsAllowed;
  final int roomsConfigured;
  final int remainingRoomSlots;
  final int daysLeft;
  final bool planActive;

  const AdminDashboardSnapshot({
    this.hotelName = '',
    this.currency = 'INR',
    this.taxPercentage = 0,
    this.gstEnabled = false,
    this.todayRevenue = 0,
    this.monthRevenue = 0,
    this.outstandingDue = 0,
    this.occupancyRatePercentage = 0,
    this.totalPhysicalRooms = 0,
    this.activeStaffCount = 0,
    this.checkedInToday = 0,
    this.expectedCheckOutsToday = 0,
    this.checkedOutToday = 0,
    this.inHouseGuests = 0,
    this.availableRooms = 0,
    this.reservedRooms = 0,
    this.occupiedRooms = 0,
    this.cleaningRooms = 0,
    this.maintenanceRooms = 0,
    this.blockedRooms = 0,
    this.cash = 0,
    this.online = 0,
    this.card = 0,
    this.upi = 0,
    this.bankTransfer = 0,
    this.weeklyRevenue = const [],
    this.planName = '',
    this.maxRoomsAllowed = 0,
    this.roomsConfigured = 0,
    this.remainingRoomSlots = 0,
    this.daysLeft = 0,
    this.planActive = false,
  });

  factory AdminDashboardSnapshot.fromJson(Map<String, dynamic> data) {
    final source = _map(data['dashboard']).isNotEmpty ? _map(data['dashboard']) : data;
    final hotel = _map(source['hotel']);
    final kpis = _map(source['kpis']);
    final pulse = _map(source['today_pulse'] ?? source['todayPulse']);
    final rooms = _map(source['room_status_summary'] ?? source['roomStatusSummary']);
    final payments = _map(source['revenue_by_payment_method'] ?? source['revenueByPaymentMethod']);
    final plan = _map(source['subscription_quota'] ?? source['subscriptionQuota']);

    return AdminDashboardSnapshot(
      hotelName: (hotel['name'] ?? '').toString(),
      currency: (hotel['currency'] ?? 'INR').toString(),
      taxPercentage: _num(hotel['tax_percentage'] ?? hotel['taxPercentage']),
      gstEnabled: hotel['gst_enabled'] == true || hotel['gstEnabled'] == true,
      todayRevenue: _num(kpis['today_revenue'] ?? kpis['todayRevenue']),
      monthRevenue: _num(kpis['month_revenue'] ?? kpis['monthRevenue']),
      outstandingDue: _num(kpis['total_outstanding_due'] ?? kpis['totalOutstandingDue']),
      occupancyRatePercentage: _num(kpis['occupancy_rate_percentage'] ?? kpis['occupancyRatePercentage']).round(),
      totalPhysicalRooms: _num(kpis['total_physical_rooms'] ?? kpis['totalPhysicalRooms']).round(),
      activeStaffCount: _num(kpis['active_staff_count'] ?? kpis['activeStaffCount']).round(),
      checkedInToday: _num(pulse['actual_checked_in_today'] ?? pulse['actualCheckedInToday']).round(),
      expectedCheckOutsToday: _num(pulse['expected_check_outs_today'] ?? pulse['expectedCheckOutsToday']).round(),
      checkedOutToday: _num(pulse['actual_checked_out_today'] ?? pulse['actualCheckedOutToday']).round(),
      inHouseGuests: _num(pulse['current_in_house_guests'] ?? pulse['currentInHouseGuests']).round(),
      availableRooms: _num(rooms['AVAILABLE'] ?? rooms['available_count'] ?? rooms['availableCount']).round(),
      reservedRooms: _num(rooms['RESERVED'] ?? rooms['reserved_count'] ?? rooms['reservedCount']).round(),
      occupiedRooms: _num(rooms['OCCUPIED'] ?? rooms['occupied_count'] ?? rooms['occupiedCount']).round(),
      cleaningRooms: _num(rooms['CLEANING'] ?? rooms['cleaning_count'] ?? rooms['cleaningCount']).round(),
      maintenanceRooms: _num(rooms['MAINTENANCE'] ?? rooms['maintenance_count'] ?? rooms['maintenanceCount']).round(),
      blockedRooms: _num(rooms['BLOCKED'] ?? rooms['blocked_count'] ?? rooms['blockedCount']).round(),
      cash: _num(payments['CASH']),
      online: _num(payments['ONLINE']),
      card: _num(payments['CARD']),
      upi: _num(payments['UPI']),
      bankTransfer: _num(payments['BANK_TRANSFER']),
      weeklyRevenue: _weekly(source['weekly_revenue_graph'] ?? source['weeklyRevenueGraph']),
      planName: (plan['plan_name'] ?? '').toString(),
      maxRoomsAllowed: _num(plan['max_rooms_allowed']).round(),
      roomsConfigured: _num(plan['rooms_configured']).round(),
      remainingRoomSlots: _num(plan['remaining_room_slots']).round(),
      daysLeft: _num(plan['days_left']).round(),
      planActive: plan['is_active'] == true,
    );
  }

  AdminDashboardSnapshot withRoomCounts({
    int? availableRooms,
    int? reservedRooms,
    int? occupiedRooms,
    int? cleaningRooms,
    int? maintenanceRooms,
    int? blockedRooms,
    int? inHouseGuests,
  }) {
    return AdminDashboardSnapshot(
      hotelName: hotelName,
      currency: currency,
      taxPercentage: taxPercentage,
      gstEnabled: gstEnabled,
      todayRevenue: todayRevenue,
      monthRevenue: monthRevenue,
      outstandingDue: outstandingDue,
      occupancyRatePercentage: occupancyRatePercentage,
      totalPhysicalRooms: totalPhysicalRooms,
      activeStaffCount: activeStaffCount,
      checkedInToday: checkedInToday,
      expectedCheckOutsToday: expectedCheckOutsToday,
      checkedOutToday: checkedOutToday,
      inHouseGuests: inHouseGuests ?? this.inHouseGuests,
      availableRooms: availableRooms ?? this.availableRooms,
      reservedRooms: reservedRooms ?? this.reservedRooms,
      occupiedRooms: occupiedRooms ?? this.occupiedRooms,
      cleaningRooms: cleaningRooms ?? this.cleaningRooms,
      maintenanceRooms: maintenanceRooms ?? this.maintenanceRooms,
      blockedRooms: blockedRooms ?? this.blockedRooms,
      cash: cash,
      online: online,
      card: card,
      upi: upi,
      bankTransfer: bankTransfer,
      weeklyRevenue: weeklyRevenue,
      planName: planName,
      maxRoomsAllowed: maxRoomsAllowed,
      roomsConfigured: roomsConfigured,
      remainingRoomSlots: remainingRoomSlots,
      daysLeft: daysLeft,
      planActive: planActive,
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static List<WeeklyRevenuePoint> _weekly(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return WeeklyRevenuePoint(
        date: (map['date'] ?? '').toString(),
        day: (map['day'] ?? '').toString(),
        revenue: _num(map['revenue']),
      );
    }).toList();
  }

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
