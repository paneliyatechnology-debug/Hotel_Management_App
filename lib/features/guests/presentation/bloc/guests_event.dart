import 'package:flutter/material.dart';
import '../../data/models/guest_model.dart';

enum DateFilterOption {
  allTime,
  today,
  yesterday,
  thisWeek,
  thisMonth,
  thisYear,
  lastWeek,
  lastMonth,
  lastYear,
  customRange;

  static const DateFilterOption all = DateFilterOption.allTime;
  static const DateFilterOption custom = DateFilterOption.customRange;
}

extension DateFilterOptionX on DateFilterOption {
  String get label {
    switch (this) {
      case DateFilterOption.allTime:
        return 'All Time';
      case DateFilterOption.today:
        return 'Today';
      case DateFilterOption.yesterday:
        return 'Yesterday';
      case DateFilterOption.thisWeek:
        return 'This Week';
      case DateFilterOption.thisMonth:
        return 'This Month';
      case DateFilterOption.thisYear:
        return 'This Year';
      case DateFilterOption.lastWeek:
        return 'Last Week';
      case DateFilterOption.lastMonth:
        return 'Last Month';
      case DateFilterOption.lastYear:
        return 'Last Year';
      case DateFilterOption.customRange:
        return 'Custom Range';
    }
  }
}

class AdvancedFiltersData {
  final String? name;
  final String? mobile;
  final String? email;
  final String? floor;
  final String? roomNumber;
  final String? roomCategory;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final GuestStatus? status;
  final String? paymentStatus; // 'Paid', 'Partially Paid', 'Pending'

  const AdvancedFiltersData({
    this.name,
    this.mobile,
    this.email,
    this.floor,
    this.roomNumber,
    this.roomCategory,
    this.checkInDate,
    this.checkOutDate,
    this.status,
    this.paymentStatus,
  });

  int get activeCount {
    int count = 0;
    if (name != null && name!.trim().isNotEmpty) count++;
    if (mobile != null && mobile!.trim().isNotEmpty) count++;
    if (email != null && email!.trim().isNotEmpty) count++;
    if (floor != null && floor!.trim().isNotEmpty && floor != 'All') count++;
    if (roomNumber != null && roomNumber!.trim().isNotEmpty) count++;
    if (roomCategory != null && roomCategory!.trim().isNotEmpty && roomCategory != 'All') count++;
    if (checkInDate != null) count++;
    if (checkOutDate != null) count++;
    if (status != null) count++;
    if (paymentStatus != null && paymentStatus!.trim().isNotEmpty && paymentStatus != 'All') count++;
    return count;
  }

  bool get isEmpty => activeCount == 0;
}

abstract class GuestsEvent {
  const GuestsEvent();
}

class LoadGuestsEvent extends GuestsEvent {
  final String status;
  final String search;
  final int page;
  final int limit;

  const LoadGuestsEvent({
    this.status = 'CHECKED_OUT',
    this.search = '',
    this.page = 1,
    this.limit = 20,
  });
}

class RefreshGuestsEvent extends GuestsEvent {
  final String status;
  final String search;
  final int page;
  final int limit;

  const RefreshGuestsEvent({
    this.status = 'CHECKED_OUT',
    this.search = '',
    this.page = 1,
    this.limit = 20,
  });
}

class SearchGuestsEvent extends GuestsEvent {
  final String query;
  const SearchGuestsEvent(this.query);
}

class ChangeStatusFilterEvent extends GuestsEvent {
  final String statusFilter; // 'All', 'In-House', 'Checked-Out'
  const ChangeStatusFilterEvent(this.statusFilter);
}

class ChangeDateFilterEvent extends GuestsEvent {
  final DateFilterOption option;
  final DateTimeRange? customRange;
  const ChangeDateFilterEvent({required this.option, this.customRange});
}

class ApplyAdvancedFiltersEvent extends GuestsEvent {
  final AdvancedFiltersData filters;
  const ApplyAdvancedFiltersEvent(this.filters);
}

class ClearAllFiltersEvent extends GuestsEvent {
  const ClearAllFiltersEvent();
}

class SelectGuestEvent extends GuestsEvent {
  final GuestProfileModel? guest;
  const SelectGuestEvent(this.guest);
}
