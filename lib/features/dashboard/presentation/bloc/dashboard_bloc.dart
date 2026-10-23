import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../data/models/booking_list_query.dart';
import '../../data/models/hotel_stats_model.dart';
import '../../data/models/room_live_update.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../rooms/data/models/room_type_model.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final IDashboardRepository repository;
  BookingListQuery _guestQuery = const BookingListQuery();

  DashboardBloc({required this.repository}) : super(const DashboardState()) {
    on<LoadDashboardDataEvent>(_onLoadDashboardData);
    on<RefreshDashboardDataEvent>(_onRefreshDashboardData);
    on<FilterRoomsEvent>(_onFilterRooms);
    on<ChangeRoomStatusDashboardEvent>(_onChangeRoomStatus);
    on<CheckoutGuestEvent>(_onCheckoutGuest);
    on<ExtendFolioStayEvent>(_onExtendFolioStay);
    on<AddFolioPaymentEvent>(_onAddFolioPayment);
    on<AddFolioChargeEvent>(_onAddFolioCharge);
    on<UpdateFolioKeycardEvent>(_onUpdateFolioKeycard);
    on<LoadBookingsEvent>(_onLoadBookings);
    on<LiveRoomSyncEvent>(_onLiveRoomSync);
    on<QuietRefreshLiveRoomsEvent>(_onQuietRefreshLiveRooms);
    on<ApplyLiveBookingEvent>(_onApplyLiveBooking);
    on<ApplyCategoryCountsEvent>(_onApplyCategoryCounts);
    on<ApplyLiveDashboardEvent>(_onApplyLiveDashboard);
  }

  Future<void> _onLoadBookings(
    LoadBookingsEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (event.showLoading && state.folios.isEmpty) {
      emit(state.copyWith(status: DashboardStatus.loading));
    }
    try {
      final query = event.query ?? _guestQuery;
      _guestQuery = query;
      final folios = await repository.fetchBookings(query: query);
      final rooms = await repository.getRooms();
      emit(state.copyWith(
        status: DashboardStatus.loaded,
        folios: folios,
        allRooms: rooms,
        filteredRooms: _applyFilters(rooms, state.searchQuery, state.selectedFloor, state.selectedStatus),
        clearSuccess: true,
      ));
    } catch (_) {
      emit(state.copyWith(status: DashboardStatus.loaded, clearSuccess: true));
    }
  }


  Future<void> _onExtendFolioStay(
    ExtendFolioStayEvent event,
    Emitter<DashboardState> emit,
  ) async {
    await repository.extendFolioStay(event.folioId, event.newCheckoutDate);
    add(RefreshDashboardDataEvent());
  }

  Future<void> _onAddFolioPayment(
    AddFolioPaymentEvent event,
    Emitter<DashboardState> emit,
  ) async {
    await repository.addFolioPayment(event.folioId, event.payment);
    add(RefreshDashboardDataEvent());
  }

  Future<void> _onAddFolioCharge(
    AddFolioChargeEvent event,
    Emitter<DashboardState> emit,
  ) async {
    await repository.addFolioCharge(event.folioId, event.charge);
    add(RefreshDashboardDataEvent());
  }

  Future<void> _onUpdateFolioKeycard(
    UpdateFolioKeycardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    await repository.updateFolioKeycard(
      event.folioId,
      event.keycardStatus,
      event.keycardNumber,
    );
    add(RefreshDashboardDataEvent());
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardDataEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.status != DashboardStatus.loaded) {
      emit(state.copyWith(status: DashboardStatus.loading));
    }
    try {
      final folios = await repository.getFolios();
      final rooms = await repository.getRooms();
      final roomTypes = await repository.getRoomTypes();
      final stats = await repository.getStats();

      final filtered = _applyFilters(rooms, state.searchQuery, state.selectedFloor, state.selectedStatus);

      emit(state.copyWith(
        status: DashboardStatus.loaded,
        allRooms: rooms,
        filteredRooms: filtered,
        roomTypes: roomTypes,
        folios: folios,
        stats: stats,
        clearSuccess: true,
      ));
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: cleanMsg,
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onRefreshDashboardData(
    RefreshDashboardDataEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final folios = await repository.getFolios();
      final rooms = await repository.getRooms();
      final stats = await repository.getStats();
      var roomTypes = state.roomTypes;
      try {
        roomTypes = await repository.getRoomTypes();
      } catch (_) {
        // Keep cached categories if /room-types is slow or fails mid-refresh.
      }

      final filtered = _applyFilters(rooms, state.searchQuery, state.selectedFloor, state.selectedStatus);

      emit(state.copyWith(
        status: DashboardStatus.loaded,
        allRooms: rooms,
        filteredRooms: filtered,
        roomTypes: roomTypes,
        folios: folios,
        stats: stats,
        // Silent refresh — do not toast on every category / pull-to-refresh.
        clearSuccess: true,
      ));
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: cleanMsg,
        clearSuccess: true,
      ));
    }
  }

  void _onLiveRoomSync(
    LiveRoomSyncEvent event,
    Emitter<DashboardState> emit,
  ) {
    final patch = event.update.room;
    final previous = patch == null
        ? null
        : state.allRooms.cast<RoomModel?>().firstWhere(
              (room) => room != null && patch.matches(room),
              orElse: () => null,
            );
    final rooms = repository.applyLiveRoomUpdate(event.update);
    final counts = event.update.breakdown;
    var stats = state.stats;
    if (counts != null) {
      stats = stats.copyWith(
        availableVacant: counts.available ?? stats.availableVacant,
        occupiedInHouse: counts.occupied ?? stats.occupiedInHouse,
        housekeepingQueue: counts.cleaning ?? stats.housekeepingQueue,
        maintenanceBlocked: counts.maintenanceBlocked ?? stats.maintenanceBlocked,
        totalInHouseGuests: counts.guests ?? stats.totalInHouseGuests,
      );
    } else if (patch != null && !patch.removed && previous != null && previous.status != patch.status) {
      stats = stats.copyWith(
        availableVacant: _shiftCount(stats.availableVacant, RoomStatus.available, previous.status, patch.status),
        occupiedInHouse: _shiftCount(stats.occupiedInHouse, RoomStatus.occupied, previous.status, patch.status),
        housekeepingQueue: _shiftCount(stats.housekeepingQueue, RoomStatus.cleaning, previous.status, patch.status),
        maintenanceBlocked: _shiftCount(stats.maintenanceBlocked, RoomStatus.maintenance, previous.status, patch.status),
      );
    }
    emit(state.copyWith(
      status: state.status == DashboardStatus.initial ? DashboardStatus.loaded : state.status,
      allRooms: rooms,
      filteredRooms: _applyFilters(rooms, state.searchQuery, state.selectedFloor, state.selectedStatus),
      stats: stats,
    ));
  }

  Future<void> _onQuietRefreshLiveRooms(
    QuietRefreshLiveRoomsEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      repository.acceptRemoteRoomStatuses();
      final folios = await repository.getFolios();
      final rooms = await repository.getRooms();
      final stats = await repository.getStats();
      // Do not re-fetch room-types here — live ticks were hammering /room-types
      // and stacking snackbars. Categories stay on the last loaded list.
      emit(state.copyWith(
        status: DashboardStatus.loaded,
        allRooms: rooms,
        filteredRooms: _applyFilters(rooms, state.searchQuery, state.selectedFloor, state.selectedStatus),
        folios: folios,
        stats: stats,
        clearSuccess: true,
      ));
    } catch (_) {
      // Keep the rooms already on screen if the refresh fails.
    }
  }

  void _onApplyLiveBooking(
    ApplyLiveBookingEvent event,
    Emitter<DashboardState> emit,
  ) {
    final booking = socketObject(event.data);
    if (booking == null) return;
    final inner = booking['primary_guest_name'] == null && booking['booking_status'] == null && booking['data'] is Map
        ? Map<String, dynamic>.from(booking['data'] as Map)
        : booking;
    final applied = repository.applyLiveBooking(inner);
    emit(state.copyWith(
      status: state.status == DashboardStatus.initial ? DashboardStatus.loaded : state.status,
      allRooms: applied.rooms,
      filteredRooms: _applyFilters(applied.rooms, state.searchQuery, state.selectedFloor, state.selectedStatus),
      folios: applied.folios,
    ));
  }

  void _onApplyCategoryCounts(
    ApplyCategoryCountsEvent event,
    Emitter<DashboardState> emit,
  ) {
    final payload = socketObject(event.data);
    if (payload == null) return;
    final raw = payload['room_categories'] ?? payload['roomCategories'];
    var roomTypes = state.roomTypes;
    if (raw is List) {
      final countsById = <String, RoomTypeModel>{};
      for (final item in raw) {
        if (item is! Map) continue;
        final parsed = RoomTypeModel.fromJson(Map<String, dynamic>.from(item));
        if (parsed.id.isEmpty) continue;
        countsById[parsed.id] = parsed;
      }
      if (countsById.isNotEmpty) {
        if (roomTypes.isEmpty) {
          roomTypes = countsById.values.toList();
        } else {
          roomTypes = [
            for (final type in roomTypes)
              countsById[type.id] == null ? type : type.withStatusCounts(countsById[type.id]!),
          ];
        }
      }
    }
    final summary = payload['room_status_summary'] ?? payload['roomStatusSummary'];
    var stats = state.stats;
    if (summary is Map) {
      final breakdown = RoomBreakdown.tryParse(Map<String, dynamic>.from(summary));
      if (breakdown != null) {
        stats = stats.copyWith(
          availableVacant: breakdown.available ?? stats.availableVacant,
          occupiedInHouse: breakdown.occupied ?? stats.occupiedInHouse,
          housekeepingQueue: breakdown.cleaning ?? stats.housekeepingQueue,
          maintenanceBlocked: breakdown.maintenanceBlocked ?? stats.maintenanceBlocked,
          totalInHouseGuests: breakdown.guests ?? stats.totalInHouseGuests,
        );
      }
    }
    emit(state.copyWith(roomTypes: roomTypes, stats: stats));
  }

  void _onApplyLiveDashboard(
    ApplyLiveDashboardEvent event,
    Emitter<DashboardState> emit,
  ) {
    final payload = socketObject(event.data);
    if (payload == null) return;
    final data = payload['data'] is Map ? Map<String, dynamic>.from(payload['data'] as Map) : payload;
    emit(state.copyWith(stats: _statsFromDashboardSocket(data, state.stats)));
  }

  HotelStatsModel _statsFromDashboardSocket(Map<String, dynamic> data, HotelStatsModel current) {
    final rooms = data['room_status_summary'] ?? data['roomStatusSummary'];
    final roomMap = rooms is Map ? Map<String, dynamic>.from(rooms) : const <String, dynamic>{};
    final shift = data['shift_collections_today'] ?? data['shiftCollectionsToday'];
    final shiftMap = shift is Map ? Map<String, dynamic>.from(shift) : const <String, dynamic>{};
    final kpis = data['kpis'] is Map ? Map<String, dynamic>.from(data['kpis'] as Map) : const <String, dynamic>{};
    final pulse = data['today_pulse'] ?? data['todayPulse'];
    final pulseMap = pulse is Map ? Map<String, dynamic>.from(pulse) : const <String, dynamic>{};
    int? count(dynamic value) => value is num ? value.round() : int.tryParse(value?.toString() ?? '');
    double? amount(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
    final cash = amount(shiftMap['cash_collected'] ?? shiftMap['cashCollected']);
    final upi = amount(shiftMap['upi_collected'] ?? shiftMap['upiCollected']);
    final card = amount(shiftMap['card_collected'] ?? shiftMap['cardCollected']);
    final online = amount(shiftMap['online_collected'] ?? shiftMap['onlineCollected']);
    final totalShift = amount(shiftMap['total_shift_collected'] ?? shiftMap['totalShiftCollected']);
    final maintenance = count(roomMap['MAINTENANCE']);
    final blocked = count(roomMap['BLOCKED']);
    final maintenanceBlocked = maintenance == null && blocked == null ? null : (maintenance ?? 0) + (blocked ?? 0);
    final shiftOther = online == null && card == null ? null : (online ?? 0) + (card ?? 0);
    return current.copyWith(
      availableVacant: count(roomMap['AVAILABLE']) ?? current.availableVacant,
      occupiedInHouse: count(roomMap['OCCUPIED']) ?? current.occupiedInHouse,
      housekeepingQueue: count(roomMap['CLEANING']) ?? current.housekeepingQueue,
      maintenanceBlocked: maintenanceBlocked ?? current.maintenanceBlocked,
      totalInHouseGuests: count(pulseMap['current_in_house_guests'] ?? pulseMap['currentInHouseGuests']) ?? current.totalInHouseGuests,
      todayCash: cash ?? current.todayCash,
      todayUpi: upi ?? current.todayUpi,
      todayOnline: shiftOther ?? current.todayOnline,
      totalToday: totalShift ?? amount(kpis['today_revenue'] ?? kpis['todayRevenue']) ?? current.totalToday,
      checkedInToday: count(pulseMap['actual_checked_in_today'] ?? pulseMap['actualCheckedInToday']) ?? current.checkedInToday,
      monthRevenue: amount(kpis['month_revenue'] ?? kpis['monthRevenue']) ?? current.monthRevenue,
      outstandingDue: amount(kpis['total_outstanding_due'] ?? kpis['totalOutstandingDue']) ?? current.outstandingDue,
      occupancyRatePercentage: count(kpis['occupancy_rate_percentage'] ?? kpis['occupancyRatePercentage']) ?? current.occupancyRatePercentage,
      totalPhysicalRooms: count(kpis['total_physical_rooms'] ?? kpis['totalPhysicalRooms']) ?? current.totalPhysicalRooms,
      activeStaffCount: count(kpis['active_staff_count'] ?? kpis['activeStaffCount']) ?? current.activeStaffCount,
    );
  }

  int _shiftCount(int value, RoomStatus slot, RoomStatus from, RoomStatus to) {
    var next = value;
    if (slot == from) next -= 1;
    if (slot == to) next += 1;
    return next < 0 ? 0 : next;
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
    try {
      await repository.updateRoomStatus(event.roomId, event.newStatus);
      add(RefreshDashboardDataEvent());
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onCheckoutGuest(
    CheckoutGuestEvent event,
    Emitter<DashboardState> emit,
  ) async {
    await repository.checkoutFolio(event.folioId, customPayload: event.customPayload);
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
