import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../dashboard/data/models/booking_list_query.dart';
import '../../data/models/guest_model.dart';
import '../../data/repositories/guests_repository.dart';
import 'guests_event.dart';
import 'guests_state.dart';

class GuestsBloc extends Bloc<GuestsEvent, GuestsState> {
  final IGuestsRepository repository;
  int _requestId = 0;

  GuestsBloc({required this.repository}) : super(const GuestsState()) {
    on<LoadGuestsEvent>(_onLoadGuests);
    on<RefreshGuestsEvent>(_onRefreshGuests);
    on<SearchGuestsEvent>(_onSearchGuests);
    on<ChangeStatusFilterEvent>(_onChangeStatusFilter);
    on<ChangeDateFilterEvent>(_onChangeDateFilter);
    on<ApplyAdvancedFiltersEvent>(_onApplyAdvancedFilters);
    on<ClearAllFiltersEvent>(_onClearAllFilters);
    on<LoadMoreGuestsEvent>(_onLoadMoreGuests);
    on<SelectGuestEvent>(_onSelectGuest);
  }

  Future<void> _onLoadGuests(LoadGuestsEvent event, Emitter<GuestsState> emit) async {
    await _reload(emit, showLoading: state.allGuests.isEmpty);
  }

  Future<void> _onRefreshGuests(RefreshGuestsEvent event, Emitter<GuestsState> emit) async {
    await _reload(emit, showLoading: false);
  }

  Future<void> _onSearchGuests(SearchGuestsEvent event, Emitter<GuestsState> emit) async {
    await _reload(emit, showLoading: false, next: state.copyWith(searchQuery: event.query));
  }

  Future<void> _onChangeStatusFilter(ChangeStatusFilterEvent event, Emitter<GuestsState> emit) async {
    await _reload(emit, showLoading: false, next: state.copyWith(statusFilter: event.statusFilter));
  }

  Future<void> _onChangeDateFilter(ChangeDateFilterEvent event, Emitter<GuestsState> emit) async {
    await _reload(
      emit,
      showLoading: false,
      next: state.copyWith(
        dateFilterOption: event.option,
        customDateRange: event.customRange,
        clearCustomDateRange: event.customRange == null && event.option != DateFilterOption.customRange,
      ),
    );
  }

  Future<void> _onApplyAdvancedFilters(ApplyAdvancedFiltersEvent event, Emitter<GuestsState> emit) async {
    await _reload(emit, showLoading: false, next: state.copyWith(advancedFilters: event.filters));
  }

  Future<void> _onClearAllFilters(ClearAllFiltersEvent event, Emitter<GuestsState> emit) async {
    await _reload(
      emit,
      showLoading: false,
      next: state.copyWith(
        searchQuery: '',
        statusFilter: 'All',
        dateFilterOption: DateFilterOption.allTime,
        clearCustomDateRange: true,
        advancedFilters: const AdvancedFiltersData(),
      ),
    );
  }

  Future<void> _onLoadMoreGuests(LoadMoreGuestsEvent event, Emitter<GuestsState> emit) async {
    if (!state.remoteResults || !state.hasMore || state.loadingMore || state.status == GuestsStatus.loading) {
      return;
    }
    final request = _requestId;
    emit(state.copyWith(loadingMore: true));
    try {
      final result = await repository.fetchGuestPage(_queryFor(state, page: state.page + 1));
      if (request != _requestId) return;
      final merged = _mergeGuests(state.allGuests, result.guests);
      emit(state.copyWith(
        status: GuestsStatus.loaded,
        allGuests: merged,
        filteredGuests: _applyLocalFilter(merged, state, fromNetwork: result.fromNetwork),
        page: result.page,
        listTotal: result.total,
        hasMore: result.hasMore,
        loadingMore: false,
        remoteResults: result.fromNetwork,
      ));
    } catch (_) {
      if (request != _requestId) return;
      emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> _reload(Emitter<GuestsState> emit, {required bool showLoading, GuestsState? next}) async {
    final request = ++_requestId;
    final current = next ?? state;
    if (showLoading) {
      emit(current.copyWith(status: GuestsStatus.loading, loadingMore: false));
    }
    try {
      final result = await repository.fetchGuestPage(_queryFor(current, page: 1));
      if (request != _requestId) return;
      final guests = result.guests;
      final visible = _applyLocalFilter(guests, current, fromNetwork: result.fromNetwork);
      emit(current.copyWith(
        status: GuestsStatus.loaded,
        allGuests: guests,
        filteredGuests: visible,
        page: result.page,
        listTotal: result.total,
        hasMore: result.hasMore,
        loadingMore: false,
        remoteResults: result.fromNetwork,
      ));
    } catch (_) {
      if (request != _requestId) return;
      emit(current.copyWith(status: GuestsStatus.loaded, loadingMore: false));
    }
  }

  BookingListQuery _queryFor(GuestsState current, {required int page}) {
    final advanced = current.advancedFilters;
    final range = _resolveDateRange(current.dateFilterOption, current.customDateRange);
    var checkInFrom = '';
    var checkInTo = '';
    var checkOutFrom = '';
    var checkOutTo = '';
    if (range != null) {
      checkInFrom = _ymd(range.start);
      checkInTo = _dayEnd(range.end);
    }
    if (advanced.checkInDate != null) {
      checkInFrom = _ymd(advanced.checkInDate!);
      checkInTo = _dayEnd(advanced.checkInDate!);
    }
    if (advanced.checkOutDate != null) {
      checkOutFrom = _ymd(advanced.checkOutDate!);
      checkOutTo = _dayEnd(advanced.checkOutDate!);
    }
    final room = advanced.roomNumber?.trim() ?? '';
    final typedSearch = current.searchQuery.trim();
    final roomIsId = RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(room);
    return BookingListQuery(
      bookingStatus: _bookingStatus(current),
      paymentStatus: advanced.paymentStatus?.trim() ?? '',
      roomId: roomIsId ? room : '',
      primaryGuestName: advanced.name?.trim() ?? '',
      mobileNumber: advanced.mobile?.trim() ?? '',
      search: typedSearch.isNotEmpty ? typedSearch : (roomIsId ? '' : room),
      checkInFrom: checkInFrom,
      checkInTo: checkInTo,
      checkOutFrom: checkOutFrom,
      checkOutTo: checkOutTo,
      page: page,
      limit: 10,
    );
  }

  String _bookingStatus(GuestsState current) {
    final advanced = current.advancedFilters.status;
    if (advanced == GuestStatus.inHouse) return 'CHECKED_IN';
    if (advanced == GuestStatus.checkedOut) return 'CHECKED_OUT';
    if (current.statusFilter == 'In-House') return 'CHECKED_IN';
    if (current.statusFilter == 'Checked-Out') return 'CHECKED_OUT';
    return '';
  }

  String _ymd(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _dayEnd(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-${day}T23:59:59.999Z';
  }

  List<GuestProfileModel> _mergeGuests(List<GuestProfileModel> current, List<GuestProfileModel> next) {
    final merged = List<GuestProfileModel>.from(current);
    final ids = merged.map((guest) => guest.id).toSet();
    for (final guest in next) {
      if (guest.id.isEmpty || !ids.add(guest.id)) continue;
      merged.add(guest);
    }
    return merged;
  }

  List<GuestProfileModel> _applyLocalFilter(
    List<GuestProfileModel> guests,
    GuestsState current, {
    bool fromNetwork = false,
  }) {
    if (fromNetwork) {
      return _filterGuests(
        allGuests: guests,
        query: current.searchQuery,
        statusFilter: current.statusFilter,
        dateOption: DateFilterOption.allTime,
        customRange: null,
        advanced: _sheetFiltersForLoadedPage(current.advancedFilters),
      );
    }
    return _filterGuests(
      allGuests: guests,
      query: current.searchQuery,
      statusFilter: current.statusFilter,
      dateOption: current.dateFilterOption,
      customRange: current.customDateRange,
      advanced: current.advancedFilters,
    );
  }

  AdvancedFiltersData _sheetFiltersForLoadedPage(AdvancedFiltersData advanced) {
    return AdvancedFiltersData(
      name: advanced.name,
      mobile: advanced.mobile,
      email: advanced.email,
      floor: advanced.floor,
      roomNumber: advanced.roomNumber,
      roomCategory: advanced.roomCategory,
      status: advanced.status,
      paymentStatus: advanced.paymentStatus,
    );
  }

  void _onSelectGuest(SelectGuestEvent event, Emitter<GuestsState> emit) {
    emit(state.copyWith(
      selectedGuest: event.guest,
      clearSelectedGuest: event.guest == null,
    ));
  }

  List<GuestProfileModel> _filterGuests({
    required List<GuestProfileModel> allGuests,
    required String query,
    required String statusFilter,
    required DateFilterOption dateOption,
    required DateTimeRange? customRange,
    required AdvancedFiltersData advanced,
  }) {
    final cleanQuery = query.trim().toLowerCase();

    return allGuests.where((guest) {
      // 1. Status Filter Tab: All, In-House, Checked-Out, Registered
      if (statusFilter == 'In-House' && guest.currentStatus != GuestStatus.inHouse) {
        return false;
      }
      if (statusFilter == 'Checked-Out' && guest.currentStatus != GuestStatus.checkedOut) {
        return false;
      }
      if (statusFilter == 'Registered' && guest.currentStatus != GuestStatus.registered) {
        return false;
      }

      // 2. Universal Search: Name, Mobile, Email, Room Number, Booking ID, ID Number
      if (cleanQuery.isNotEmpty) {
        final matchesName = guest.fullName.toLowerCase().contains(cleanQuery);
        final matchesMobile = guest.mobile.replaceAll(' ', '').contains(cleanQuery.replaceAll(' ', ''));
        final matchesEmail = guest.email.toLowerCase().contains(cleanQuery);

        // Check assigned room, last room number, or any historical stay room numbers
        final matchesRoom = guest.roomAssigned.toLowerCase().contains(cleanQuery) ||
            guest.lastRoomNumber.toLowerCase().contains(cleanQuery) ||
            guest.stayHistory.any((s) =>
                s.roomNumber.toLowerCase().contains(cleanQuery) ||
                s.roomNumber.replaceAll('#', '').toLowerCase().contains(cleanQuery.replaceAll('#', '')));

        // Check active booking number or any historical stay booking IDs
        final matchesBooking = guest.activeBookingNumber.toLowerCase().contains(cleanQuery) ||
            guest.stayHistory.any((s) =>
                s.bookingId.toLowerCase().contains(cleanQuery));

        // Check Govt ID number
        final matchesId = guest.kyc.idNumber.toLowerCase().contains(cleanQuery);

        if (!matchesName && !matchesMobile && !matchesEmail && !matchesRoom && !matchesBooking && !matchesId) {
          return false;
        }
      }

      // 3. Date Filter: Matches if any stay of the guest overlaps/falls within date range
      if (dateOption != DateFilterOption.allTime) {
        final range = _resolveDateRange(dateOption, customRange);
        if (range != null) {
          final matchesDate = guest.stayHistory.any((s) {
            // Check if stay falls within or overlaps with range
            return (s.checkInDate.isBefore(range.end) && s.checkOutDate.isAfter(range.start)) ||
                   (s.checkInDate.year == range.start.year && s.checkInDate.month == range.start.month && s.checkInDate.day == range.start.day);
          });
          if (!matchesDate) return false;
        }
      }

      // 4. Advanced Filters
      if (!advanced.isEmpty) {
        if (advanced.name != null && advanced.name!.trim().isNotEmpty) {
          if (!guest.fullName.toLowerCase().contains(advanced.name!.trim().toLowerCase())) return false;
        }
        if (advanced.mobile != null && advanced.mobile!.trim().isNotEmpty) {
          if (!guest.mobile.contains(advanced.mobile!.trim())) return false;
        }
        if (advanced.email != null && advanced.email!.trim().isNotEmpty) {
          if (!guest.email.toLowerCase().contains(advanced.email!.trim().toLowerCase())) return false;
        }
        if (advanced.floor != null && advanced.floor != 'All' && advanced.floor!.isNotEmpty) {
          final matchesFloor = guest.stayHistory.any((s) => s.floor.toLowerCase().contains(advanced.floor!.toLowerCase()));
          if (!matchesFloor) return false;
        }
        if (advanced.roomNumber != null && advanced.roomNumber!.trim().isNotEmpty) {
          final matchesRoom = guest.stayHistory.any((s) => s.roomNumber.contains(advanced.roomNumber!.trim()));
          if (!matchesRoom) return false;
        }
        if (advanced.roomCategory != null && advanced.roomCategory != 'All' && advanced.roomCategory!.isNotEmpty) {
          final matchesCat = guest.stayHistory.any((s) => s.roomCategory.toLowerCase().contains(advanced.roomCategory!.toLowerCase()));
          if (!matchesCat) return false;
        }
        if (advanced.status != null) {
          if (guest.currentStatus != advanced.status) return false;
        }
        if (advanced.paymentStatus != null && advanced.paymentStatus != 'All' && advanced.paymentStatus!.isNotEmpty) {
          final matchesPayment = guest.stayHistory.any((s) => s.paymentStatus.toLowerCase() == advanced.paymentStatus!.toLowerCase());
          if (!matchesPayment) return false;
        }
        if (advanced.checkInDate != null) {
          final matchesCheckIn = guest.stayHistory.any((s) =>
              s.checkInDate.year == advanced.checkInDate!.year &&
              s.checkInDate.month == advanced.checkInDate!.month &&
              s.checkInDate.day == advanced.checkInDate!.day);
          if (!matchesCheckIn) return false;
        }
        if (advanced.checkOutDate != null) {
          final matchesCheckOut = guest.stayHistory.any((s) =>
              s.checkOutDate.year == advanced.checkOutDate!.year &&
              s.checkOutDate.month == advanced.checkOutDate!.month &&
              s.checkOutDate.day == advanced.checkOutDate!.day);
          if (!matchesCheckOut) return false;
        }
      }

      return true;
    }).toList();
  }

  DateTimeRange? _resolveDateRange(DateFilterOption option, DateTimeRange? customRange) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (option) {
      case DateFilterOption.allTime:
        return null;
      case DateFilterOption.today:
        return DateTimeRange(start: todayStart, end: todayEnd);
      case DateFilterOption.yesterday:
        final yesterdayStart = todayStart.subtract(const Duration(days: 1));
        final yesterdayEnd = DateTime(yesterdayStart.year, yesterdayStart.month, yesterdayStart.day, 23, 59, 59);
        return DateTimeRange(start: yesterdayStart, end: yesterdayEnd);
      case DateFilterOption.thisWeek:
        final monday = todayStart.subtract(Duration(days: todayStart.weekday - 1));
        final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return DateTimeRange(start: monday, end: sunday);
      case DateFilterOption.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: monthStart, end: monthEnd);
      case DateFilterOption.thisYear:
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);
        return DateTimeRange(start: yearStart, end: yearEnd);
      case DateFilterOption.lastWeek:
        final lastMonday = todayStart.subtract(Duration(days: todayStart.weekday + 6));
        final lastSunday = lastMonday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return DateTimeRange(start: lastMonday, end: lastSunday);
      case DateFilterOption.lastMonth:
        final prevMonthStart = DateTime(now.year, now.month - 1, 1);
        final prevMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: prevMonthStart, end: prevMonthEnd);
      case DateFilterOption.lastYear:
        final prevYearStart = DateTime(now.year - 1, 1, 1);
        final prevYearEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        return DateTimeRange(start: prevYearStart, end: prevYearEnd);
      case DateFilterOption.customRange:
        return customRange;
    }
  }
}
