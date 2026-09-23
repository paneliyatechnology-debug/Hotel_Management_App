import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final IDashboardRepository repository;

  DashboardBloc({required this.repository}) : super(const DashboardState()) {
    on<LoadDashboardDataEvent>(_onLoadDashboardData);
    on<RefreshDashboardDataEvent>(_onRefreshDashboardData);
    on<FilterRoomsEvent>(_onFilterRooms);
    on<ChangeRoomStatusDashboardEvent>(_onChangeRoomStatus);
    on<CheckoutGuestEvent>(_onCheckoutGuest);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardDataEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final rooms = await repository.getRooms();
      final folios = await repository.getFolios();
      final stats = await repository.getStats();

      final filtered = _applyFilters(rooms, state.searchQuery, state.selectedFloor, state.selectedStatus);

      emit(state.copyWith(
        status: DashboardStatus.loaded,
        allRooms: rooms,
        filteredRooms: filtered,
        folios: folios,
        stats: stats,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshDashboardData(
    RefreshDashboardDataEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final rooms = await repository.getRooms();
      final folios = await repository.getFolios();
      final stats = await repository.getStats();

      final filtered = _applyFilters(rooms, state.searchQuery, state.selectedFloor, state.selectedStatus);

      emit(state.copyWith(
        status: DashboardStatus.loaded,
        allRooms: rooms,
        filteredRooms: filtered,
        folios: folios,
        stats: stats,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onFilterRooms(
    FilterRoomsEvent event,
    Emitter<DashboardState> emit,
  ) {
    final filtered = _applyFilters(state.allRooms, event.searchQuery, event.floor, event.status);
    emit(state.copyWith(
      searchQuery: event.searchQuery,
      selectedFloor: event.floor,
      selectedStatus: event.status,
      filteredRooms: filtered,
    ));
  }

  Future<void> _onChangeRoomStatus(
    ChangeRoomStatusDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    await repository.updateRoomStatus(event.roomId, event.newStatus);
    add(RefreshDashboardDataEvent());
  }

  Future<void> _onCheckoutGuest(
    CheckoutGuestEvent event,
    Emitter<DashboardState> emit,
  ) async {
    await repository.checkoutFolio(event.folioId);
    add(RefreshDashboardDataEvent());
  }

  List<RoomModel> _applyFilters(List<RoomModel> rooms, String searchQuery, String selectedFloor, String selectedStatus) {
    return rooms.where((room) {
      // Query filter
      final q = searchQuery.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          room.roomNumber.toLowerCase().contains(q) ||
          room.roomType.toLowerCase().contains(q) ||
          (room.currentGuestName != null && room.currentGuestName!.toLowerCase().contains(q));

      // Floor filter
      final matchesFloor = selectedFloor == 'All Floors' || room.floor == selectedFloor;

      // Status filter
      bool matchesStatus = true;
      if (selectedStatus != 'All Status (2)' && selectedStatus != 'All Status') {
        if (selectedStatus.contains('Available')) {
          matchesStatus = room.status == RoomStatus.available;
        } else if (selectedStatus.contains('Occupied')) {
          matchesStatus = room.status == RoomStatus.occupied;
        } else if (selectedStatus.contains('Cleaning')) {
          matchesStatus = room.status == RoomStatus.cleaning;
        } else if (selectedStatus.contains('Maintenance')) {
          matchesStatus = room.status == RoomStatus.maintenance;
        }
      }

      return matchesQuery && matchesFloor && matchesStatus;
    }).toList();
  }
}
