import '../../../../core/widgets/status_badge.dart';

abstract class DashboardEvent {}

class LoadDashboardDataEvent extends DashboardEvent {}

class RefreshDashboardDataEvent extends DashboardEvent {}

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
  CheckoutGuestEvent(this.folioId);
}
