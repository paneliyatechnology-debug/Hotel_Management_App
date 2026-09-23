import '../../../../core/widgets/status_badge.dart';

abstract class RoomsEvent {}

class LoadRoomsEvent extends RoomsEvent {}

class FilterRoomsListEvent extends RoomsEvent {
  final String query;
  final String floor;
  final String status;

  FilterRoomsListEvent({
    required this.query,
    required this.floor,
    required this.status,
  });
}

class UpdateRoomStatusEvent extends RoomsEvent {
  final String roomId;
  final RoomStatus newStatus;

  UpdateRoomStatusEvent({
    required this.roomId,
    required this.newStatus,
  });
}
