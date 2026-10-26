class HotelStatsModel {
  final int availableVacant;
  final int occupiedInHouse;
  final int housekeepingQueue;
  final int maintenanceBlocked;
  final int totalInHouseGuests;
  final double todayCash;
  final double todayUpi;
  final double todayOnline;
  final double totalToday;
  final int checkedInToday;
  final double monthRevenue;
  final double outstandingDue;
  final double weeklyRevenue;
  final int occupancyRatePercentage;
  final int totalPhysicalRooms;
  final int activeStaffCount;
  final bool fromAdminApi;
  final List<dynamic> todayArrivals;
  final List<dynamic> todayDepartures;

  const HotelStatsModel({
    required this.availableVacant,
    required this.occupiedInHouse,
    required this.housekeepingQueue,
    required this.maintenanceBlocked,
    required this.totalInHouseGuests,
    this.todayCash = 0.0,
    this.todayUpi = 0.0,
    this.todayOnline = 0.0,
    this.totalToday = 0.0,
    this.checkedInToday = 0,
    this.monthRevenue = 0.0,
    this.outstandingDue = 0.0,
    this.weeklyRevenue = 0.0,
    this.occupancyRatePercentage = -1,
    this.totalPhysicalRooms = 0,
    this.activeStaffCount = 0,
    this.fromAdminApi = false,
    this.todayArrivals = const [],
    this.todayDepartures = const [],
  });

  factory HotelStatsModel.fromDashboardData(Map<String, dynamic> data) {
    final rooms = data['rooms'] as Map<String, dynamic>? ?? {};
    final collections = data['collections'] as Map<String, dynamic>? ?? {};

    final available = (rooms['available'] as num?)?.toInt() ?? 0;
    final cleaning = (rooms['cleaning'] as num?)?.toInt() ?? 0;
    final currentGuests = (rooms['currentGuests'] as num?)?.toInt() ?? 0;
    final occupied = (rooms['occupied'] as num?)?.toInt() ??
        (rooms['booked'] as num?)?.toInt() ??
        0;
    final maintenance = (rooms['maintenance'] as num?)?.toInt() ??
        (rooms['blocked'] as num?)?.toInt() ??
        0;

    return HotelStatsModel(
      availableVacant: available,
      occupiedInHouse: occupied,
      housekeepingQueue: cleaning,
      maintenanceBlocked: maintenance,
      totalInHouseGuests: currentGuests,
      todayCash: (collections['todayCash'] as num?)?.toDouble() ?? 0.0,
      todayOnline: (collections['todayOnline'] as num?)?.toDouble() ?? 0.0,
      totalToday: (collections['totalToday'] as num?)?.toDouble() ?? 0.0,
      todayArrivals: (data['todayArrivals'] as List<dynamic>?) ?? const [],
      todayDepartures: (data['todayDepartures'] as List<dynamic>?) ?? const [],
    );
  }

  factory HotelStatsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return HotelStatsModel.fromDashboardData(data);
  }

  HotelStatsModel copyWith({
    int? availableVacant,
    int? occupiedInHouse,
    int? housekeepingQueue,
    int? maintenanceBlocked,
    int? totalInHouseGuests,
    double? todayCash,
    double? todayUpi,
    double? todayOnline,
    double? totalToday,
    int? checkedInToday,
    double? monthRevenue,
    double? outstandingDue,
    double? weeklyRevenue,
    int? occupancyRatePercentage,
    int? totalPhysicalRooms,
    int? activeStaffCount,
    bool? fromAdminApi,
    List<dynamic>? todayArrivals,
    List<dynamic>? todayDepartures,
  }) {
    return HotelStatsModel(
      availableVacant: availableVacant ?? this.availableVacant,
      occupiedInHouse: occupiedInHouse ?? this.occupiedInHouse,
      housekeepingQueue: housekeepingQueue ?? this.housekeepingQueue,
      maintenanceBlocked: maintenanceBlocked ?? this.maintenanceBlocked,
      totalInHouseGuests: totalInHouseGuests ?? this.totalInHouseGuests,
      todayCash: todayCash ?? this.todayCash,
      todayUpi: todayUpi ?? this.todayUpi,
      todayOnline: todayOnline ?? this.todayOnline,
      totalToday: totalToday ?? this.totalToday,
      checkedInToday: checkedInToday ?? this.checkedInToday,
      monthRevenue: monthRevenue ?? this.monthRevenue,
      outstandingDue: outstandingDue ?? this.outstandingDue,
      weeklyRevenue: weeklyRevenue ?? this.weeklyRevenue,
      occupancyRatePercentage: occupancyRatePercentage ?? this.occupancyRatePercentage,
      totalPhysicalRooms: totalPhysicalRooms ?? this.totalPhysicalRooms,
      activeStaffCount: activeStaffCount ?? this.activeStaffCount,
      fromAdminApi: fromAdminApi ?? this.fromAdminApi,
      todayArrivals: todayArrivals ?? this.todayArrivals,
      todayDepartures: todayDepartures ?? this.todayDepartures,
    );
  }
}
