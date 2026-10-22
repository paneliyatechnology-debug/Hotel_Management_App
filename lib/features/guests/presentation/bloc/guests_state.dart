import 'package:flutter/material.dart';
import '../../data/models/guest_model.dart';
import 'guests_event.dart';

enum GuestsStatus { initial, loading, loaded, error }

class GuestsState {
  final GuestsStatus status;
  final List<GuestProfileModel> allGuests;
  final List<GuestProfileModel> filteredGuests;
  final String searchQuery;
  final String statusFilter; // 'All', 'In-House', 'Checked-Out'
  final DateFilterOption dateFilterOption;
  final DateTimeRange? customDateRange;
  final AdvancedFiltersData advancedFilters;
  final GuestProfileModel? selectedGuest;
  final String? errorMessage;
  final int page;
  final int listTotal;
  final bool hasMore;
  final bool loadingMore;
  final bool remoteResults;

  const GuestsState({
    this.status = GuestsStatus.initial,
    this.allGuests = const [],
    this.filteredGuests = const [],
    this.searchQuery = '',
    this.statusFilter = 'All',
    this.dateFilterOption = DateFilterOption.allTime,
    this.customDateRange,
    this.advancedFilters = const AdvancedFiltersData(),
    this.selectedGuest,
    this.errorMessage,
    this.page = 1,
    this.listTotal = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.remoteResults = false,
  });

  int get allCount => listTotal > allGuests.length ? listTotal : allGuests.length;
  int get totalCount => allGuests.length;
  int get inHouseCount => allGuests.where((g) => g.currentStatus == GuestStatus.inHouse).length;
  int get checkedOutCount => allGuests.where((g) => g.currentStatus == GuestStatus.checkedOut).length;
  int get registeredCount => allGuests.where((g) => g.currentStatus == GuestStatus.registered).length;

  int get activeFilterCount => totalActiveFiltersCount;
  int get totalActiveFiltersCount {
    int count = advancedFilters.activeCount;
    if (dateFilterOption != DateFilterOption.allTime) count++;
    return count;
  }

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      statusFilter != 'All' ||
      dateFilterOption != DateFilterOption.allTime ||
      !advancedFilters.isEmpty;

  bool get hasAnyFiltersActive => hasActiveFilters;

  String get dateFilterLabel {
    if (dateFilterOption == DateFilterOption.customRange && customDateRange != null) {
      final start = '${customDateRange!.start.day} ${_monthName(customDateRange!.start.month)}';
      final end = '${customDateRange!.end.day} ${_monthName(customDateRange!.end.month)}';
      return '$start – $end';
    }
    if (dateFilterOption == DateFilterOption.allTime) {
      return 'Date';
    }
    return dateFilterOption.label;
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  GuestsState copyWith({
    GuestsStatus? status,
    List<GuestProfileModel>? allGuests,
    List<GuestProfileModel>? filteredGuests,
    String? searchQuery,
    String? statusFilter,
    DateFilterOption? dateFilterOption,
    DateTimeRange? customDateRange,
    AdvancedFiltersData? advancedFilters,
    GuestProfileModel? selectedGuest,
    bool clearSelectedGuest = false,
    bool clearCustomDateRange = false,
    String? errorMessage,
    int? page,
    int? listTotal,
    bool? hasMore,
    bool? loadingMore,
    bool? remoteResults,
  }) {
    return GuestsState(
      status: status ?? this.status,
      allGuests: allGuests ?? this.allGuests,
      filteredGuests: filteredGuests ?? this.filteredGuests,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      dateFilterOption: dateFilterOption ?? this.dateFilterOption,
      customDateRange: clearCustomDateRange ? null : (customDateRange ?? this.customDateRange),
      advancedFilters: advancedFilters ?? this.advancedFilters,
      selectedGuest: clearSelectedGuest ? null : (selectedGuest ?? this.selectedGuest),
      errorMessage: errorMessage ?? this.errorMessage,
      page: page ?? this.page,
      listTotal: listTotal ?? this.listTotal,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      remoteResults: remoteResults ?? this.remoteResults,
    );
  }
}
