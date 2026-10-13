import '../../../../core/widgets/status_badge.dart';
import '../../data/models/guest_folio_model.dart';

abstract class DashboardEvent {}

class LoadDashboardDataEvent extends DashboardEvent {}

class RefreshDashboardDataEvent extends DashboardEvent {}

class LoadBookingsEvent extends DashboardEvent {
  final bool showLoading;
  final String status;
  final String search;
  final int page;
  final int limit;

  LoadBookingsEvent({
    this.showLoading = false,
    this.status = 'CHECKED_IN',
    this.search = '',
    this.page = 1,
    this.limit = 20,
  });
}


class FilterRoomsEvent extends DashboardEvent {
  final String searchQuery;
  final String floor;
  final String status;

  FilterRoomsEvent({
    required this.searchQuery,
    required this.floor,
    required this.status,
  });
}

class ChangeRoomStatusDashboardEvent extends DashboardEvent {
  final String roomId;
  final RoomStatus newStatus;

  ChangeRoomStatusDashboardEvent({
    required this.roomId,
    required this.newStatus,
  });
}

class CheckoutGuestEvent extends DashboardEvent {
  final String folioId;
  final Map<String, dynamic>? customPayload;
  CheckoutGuestEvent(this.folioId, {this.customPayload});
}

class ExtendFolioStayEvent extends DashboardEvent {
  final String folioId;
  final DateTime newCheckoutDate;
  ExtendFolioStayEvent({required this.folioId, required this.newCheckoutDate});
}

class AddFolioPaymentEvent extends DashboardEvent {
  final String folioId;
  final PaymentRecordModel payment;
  AddFolioPaymentEvent({required this.folioId, required this.payment});
}

class AddFolioChargeEvent extends DashboardEvent {
  final String folioId;
  final ChargeItemModel charge;
  AddFolioChargeEvent({required this.folioId, required this.charge});
}

class UpdateFolioKeycardEvent extends DashboardEvent {
  final String folioId;
  final String keycardStatus;
  final String? keycardNumber;
  UpdateFolioKeycardEvent({
    required this.folioId,
    required this.keycardStatus,
    this.keycardNumber,
  });
}
