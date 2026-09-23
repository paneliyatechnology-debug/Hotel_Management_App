import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../data/models/room_model.dart';
import '../../../../core/widgets/status_badge.dart';
import 'rooms_event.dart';
import 'rooms_state.dart';

class RoomsBloc extends Bloc<RoomsEvent, RoomsState> {
  final IDashboardRepository repository;

  RoomsBloc({required this.repository}) : super(const RoomsState()) {
    on<LoadRoomsEvent>(_onLoadRooms);
    on<FilterRoomsListEvent>(_onFilterRoomsList);
    on<UpdateRoomStatusEvent>(_onUpdateRoomStatus);
  }

  Future<void> _onLoadRooms(
    LoadRoomsEvent event,
    Emitter<RoomsState> emit,
  ) async {
    emit(state.copyWith(status: RoomsBlocStatus.loading));
    try {
      final rooms = await repository.getRooms();
      final filtered = _applyFilters(rooms, state.searchQuery, state.selectedFloor, state.selectedStatus);
      emit(state.copyWith(
        status: RoomsBlocStatus.loaded,
        allRooms: rooms,
        filteredRooms: filtered,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RoomsBlocStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onFilterRoomsList(
    FilterRoomsListEvent event,
    Emitter<RoomsState> emit,
  ) {
    final filtered = _applyFilters(state.allRooms, event.query, event.floor, event.status);
    emit(state.copyWith(
      searchQuery: event.query,
      selectedFloor: event.floor,
      selectedStatus: event.status,
      filteredRooms: filtered,
    ));
  }

  Future<void> _onUpdateRoomStatus(
    UpdateRoomStatusEvent event,
    Emitter<RoomsState> emit,
  ) async {
    await repository.updateRoomStatus(event.roomId, event.newStatus);
    final rooms = await repository.getRooms();
    final filtered = _applyFilters(rooms, state.searchQuery, state.selectedFloor, state.selectedStatus);
    emit(state.copyWith(
      allRooms: rooms,
      filteredRooms: filtered,
    ));
  }

  List<RoomModel> _applyFilters(List<RoomModel> rooms, String query, String floor, String status) {
    return rooms.where((room) {
      final q = query.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          room.roomNumber.toLowerCase().contains(q) ||
          room.roomType.toLowerCase().contains(q) ||
          (room.currentGuestName != null && room.currentGuestName!.toLowerCase().contains(q));

      final matchesFloor = floor == 'All Floors' || room.floor == floor;

      bool matchesStatus = true;
      if (status != 'All Status (2)' && status != 'All Status') {
        if (status.contains('Available')) {
          matchesStatus = room.status == RoomStatus.available;
        } else if (status.contains('Occupied')) {
          matchesStatus = room.status == RoomStatus.occupied;
        } else if (status.contains('Cleaning')) {
          matchesStatus = room.status == RoomStatus.cleaning;
        } else if (status.contains('Maintenance')) {
          matchesStatus = room.status == RoomStatus.maintenance;
        }
      }

      return matchesQuery && matchesFloor && matchesStatus;
    }).toList();
  }
}
