import '../../data/models/guest_folio_model.dart';
import '../../data/models/hotel_stats_model.dart';
import '../../../rooms/data/models/room_model.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState {
  final DashboardStatus status;
  final HotelStatsModel stats;
  final List<RoomModel> allRooms;
  final List<RoomModel> filteredRooms;
  final List<GuestFolioModel> folios;
  final String searchQuery;
  final String selectedFloor;
  final String selectedStatus;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.stats = const HotelStatsModel(
      availableVacant: 2,
      occupiedInHouse: 0,
      housekeepingQueue: 0,
      maintenanceBlocked: 0,
      totalInHouseGuests: 1,
    ),
    this.allRooms = const [],
    this.filteredRooms = const [],
    this.folios = const [],
    this.searchQuery = '',
    this.selectedFloor = 'All Floors',
    this.selectedStatus = 'All Status (2)',
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    HotelStatsModel? stats,
    List<RoomModel>? allRooms,
    List<RoomModel>? filteredRooms,
    List<GuestFolioModel>? folios,
    String? searchQuery,
    String? selectedFloor,
    String? selectedStatus,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      allRooms: allRooms ?? this.allRooms,
      filteredRooms: filteredRooms ?? this.filteredRooms,
      folios: folios ?? this.folios,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFloor: selectedFloor ?? this.selectedFloor,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
