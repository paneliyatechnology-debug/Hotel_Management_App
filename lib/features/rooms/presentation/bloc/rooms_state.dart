import '../../data/models/room_model.dart';

enum RoomsBlocStatus { initial, loading, loaded, error }

class RoomsState {
  final RoomsBlocStatus status;
  final List<RoomModel> allRooms;
  final List<RoomModel> filteredRooms;
  final String searchQuery;
  final String selectedFloor;
  final String selectedStatus;
  final String? errorMessage;

  const RoomsState({
    this.status = RoomsBlocStatus.initial,
    this.allRooms = const [],
    this.filteredRooms = const [],
    this.searchQuery = '',
    this.selectedFloor = 'All Floors',
    this.selectedStatus = 'All Status',
    this.errorMessage,
  });

  RoomsState copyWith({
    RoomsBlocStatus? status,
    List<RoomModel>? allRooms,
    List<RoomModel>? filteredRooms,
    String? searchQuery,
    String? selectedFloor,
    String? selectedStatus,
    String? errorMessage,
  }) {
    return RoomsState(
      status: status ?? this.status,
      allRooms: allRooms ?? this.allRooms,
      filteredRooms: filteredRooms ?? this.filteredRooms,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFloor: selectedFloor ?? this.selectedFloor,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
