class HotelStatsModel {
  final int availableVacant;
  final int occupiedInHouse;
  final int housekeepingQueue;
  final int maintenanceBlocked;
  final int totalInHouseGuests;

  const HotelStatsModel({
    required this.availableVacant,
    required this.occupiedInHouse,
    required this.housekeepingQueue,
    required this.maintenanceBlocked,
    required this.totalInHouseGuests,
  });

  HotelStatsModel copyWith({
    int? availableVacant,
    int? occupiedInHouse,
    int? housekeepingQueue,
    int? maintenanceBlocked,
    int? totalInHouseGuests,
  }) {
    return HotelStatsModel(
      availableVacant: availableVacant ?? this.availableVacant,
      occupiedInHouse: occupiedInHouse ?? this.occupiedInHouse,
      housekeepingQueue: housekeepingQueue ?? this.housekeepingQueue,
      maintenanceBlocked: maintenanceBlocked ?? this.maintenanceBlocked,
      totalInHouseGuests: totalInHouseGuests ?? this.totalInHouseGuests,
    );
  }
}
