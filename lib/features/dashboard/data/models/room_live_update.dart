import 'dart:convert';

import '../../../../core/widgets/status_badge.dart';
import '../../../rooms/data/models/room_model.dart';

class RoomPatch {
  final String? id;
  final String? roomNumber;
  final String? floor;
  final RoomStatus status;
  final String rawStatus;
  final bool removed;
  final Map<String, dynamic>? raw;

  const RoomPatch({
    required this.id,
    required this.roomNumber,
    this.floor,
    required this.status,
    required this.rawStatus,
    this.removed = false,
    this.raw,
  });

  String get cacheKey {
    switch (status) {
      case RoomStatus.available:
        return 'AVAILABLE';
      case RoomStatus.occupied:
        return 'OCCUPIED';
      case RoomStatus.cleaning:
        return 'CLEANING';
      case RoomStatus.maintenance:
        return 'MAINTENANCE';
    }
  }

  bool matches(RoomModel room) {
    if (id != null && id!.isNotEmpty && room.id == id) return true;
    final wanted = _roomKey(roomNumber);
    if (wanted.isEmpty) return false;
    return _roomKey(room.roomNumber) == wanted || _roomKey(room.id) == wanted;
  }

  List<RoomModel> apply(List<RoomModel> rooms) {
    var changed = false;
    var matched = false;
    final next = <RoomModel>[];
    for (final room in rooms) {
      if (!matches(room)) {
        next.add(room);
        continue;
      }
      matched = true;
      changed = true;
      if (removed) continue;
      final floorLabel = _floorLabel(floor);
      next.add(room.copyWith(
        status: status,
        floor: floorLabel,
        statusToday: rawStatus,
        actualDbStatus: rawStatus,
        dateStatus: rawStatus,
        isAvailable: status == RoomStatus.available,
        clearGuest: status == RoomStatus.available,
      ));
    }
    if (!matched && !removed) {
      final created = toRoomModel();
      if (created != null) {
        next.insert(0, created);
        changed = true;
      }
    }
    return changed ? next : rooms;
  }

  RoomModel? toRoomModel() {
    if (removed) return null;
    final number = (roomNumber ?? '').trim();
    final roomId = (id ?? '').trim();
    if (number.isEmpty && roomId.isEmpty) return null;
    if (raw != null) {
      try {
        return RoomModel.fromJson(raw!).copyWith(
          status: status,
          statusToday: rawStatus,
          actualDbStatus: rawStatus,
          dateStatus: rawStatus,
          isAvailable: status == RoomStatus.available,
        );
      } catch (_) {}
    }
    final floorLabel = _floorLabel(floor) ?? 'Floor 1';
    return RoomModel(
      id: roomId.isEmpty ? number : roomId,
      roomNumber: number.isEmpty ? roomId : number,
      floor: floorLabel,
      roomType: 'Room',
      pricePerNight: 0,
      status: status,
      statusToday: rawStatus,
      actualDbStatus: rawStatus,
      dateStatus: rawStatus,
      isAvailable: status == RoomStatus.available,
    );
  }

  static RoomPatch? tryParse(Map<String, dynamic> json) {
    final id = _text(json, const ['id', 'room_id', 'roomId', '_id']);
    final roomNumber = _text(json, const [
      'room_number',
      'roomNumber',
      'number',
      'room_no',
      'roomNo',
    ]);
    if ((id == null || id.isEmpty) && (roomNumber == null || roomNumber.isEmpty)) {
      return null;
    }
    final floor = _text(json, const ['floor']);
    final deleted = json['deleted_at'] ?? json['deletedAt'];
    final removed = json['is_active'] == false ||
        json['isActive'] == false ||
        (deleted != null && deleted.toString().trim().isNotEmpty && deleted.toString().toLowerCase() != 'null');
    if (removed) {
      return RoomPatch(
        id: id,
        roomNumber: roomNumber,
        floor: floor,
        status: RoomStatus.available,
        rawStatus: 'DELETED',
        removed: true,
        raw: json,
      );
    }
    final rawStatus = _text(json, const [
      'status',
      'room_status',
      'roomStatus',
      'new_status',
      'newStatus',
    ]);
    final status = rawStatus == null ? null : roomStatusFromName(rawStatus);
    if (rawStatus == null || status == null) return null;
    return RoomPatch(
      id: id,
      roomNumber: roomNumber,
      floor: floor,
      status: status,
      rawStatus: rawStatus.toUpperCase(),
      raw: json,
    );
  }
}

class RoomBreakdown {
  final int? available;
  final int? occupied;
  final int? reserved;
  final int? cleaning;
  final int? maintenance;
  final int? blocked;
  final int? guests;

  const RoomBreakdown({
    this.available,
    this.occupied,
    this.reserved,
    this.cleaning,
    this.maintenance,
    this.blocked,
    this.guests,
  });

  int? get maintenanceBlocked {
    if (maintenance == null && blocked == null) return null;
    return (maintenance ?? 0) + (blocked ?? 0);
  }

  bool get hasCounts =>
      available != null ||
      occupied != null ||
      reserved != null ||
      cleaning != null ||
      maintenance != null ||
      blocked != null ||
      guests != null;

  static RoomBreakdown? tryParse(Map<String, dynamic> json) {
    final breakdown = RoomBreakdown(
      available: _count(json, const [
        'AVAILABLE',
        'available',
        'available_count',
        'availableCount',
        'vacant',
        'VACANT',
      ]),
      occupied: _count(json, const [
        'OCCUPIED',
        'occupied',
        'occupied_count',
        'occupiedCount',
        'BOOKED',
        'booked',
      ]),
      reserved: _count(json, const [
        'RESERVED',
        'reserved',
        'reserved_count',
        'reservedCount',
      ]),
      cleaning: _count(json, const [
        'CLEANING',
        'cleaning',
        'cleaning_count',
        'cleaningCount',
        'HOUSEKEEPING',
        'housekeeping',
      ]),
      maintenance: _count(json, const [
        'MAINTENANCE',
        'maintenance',
        'maintenance_count',
        'maintenanceCount',
      ]),
      blocked: _count(json, const [
        'BLOCKED',
        'blocked',
        'blocked_count',
        'blockedCount',
      ]),
      guests: _count(json, const [
        'currentGuests',
        'current_in_house_guests',
        'currentInHouseGuests',
        'in_house_guests',
        'inHouseGuests',
      ]),
    );
    return breakdown.hasCounts ? breakdown : null;
  }
}

class RoomLiveUpdate {
  final RoomPatch? room;
  final RoomBreakdown? breakdown;

  const RoomLiveUpdate({this.room, this.breakdown});

  bool get isEmpty => room == null && breakdown == null;
}

RoomStatus? roomStatusFromName(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'AVAILABLE':
    case 'VACANT':
      return RoomStatus.available;
    case 'OCCUPIED':
    case 'BOOKED':
    case 'RESERVED':
      return RoomStatus.occupied;
    case 'CLEANING':
    case 'HOUSEKEEPING':
      return RoomStatus.cleaning;
    case 'MAINTENANCE':
    case 'BLOCKED':
      return RoomStatus.maintenance;
    default:
      return null;
  }
}

List<RoomLiveUpdate> parseRoomLivePayload(dynamic data) {
  final maps = _maps(data);
  RoomBreakdown? breakdown;
  final rooms = <RoomPatch>[];
  for (final map in maps) {
    breakdown ??= RoomBreakdown.tryParse(map);
    final room = RoomPatch.tryParse(map);
    if (room != null && !rooms.any((item) => item.id == room.id && item.roomNumber == room.roomNumber && item.status == room.status)) {
      rooms.add(room);
    }
  }
  if (rooms.isEmpty) {
    if (breakdown == null) return const [];
    return [RoomLiveUpdate(breakdown: breakdown)];
  }
  return [
    for (var index = 0; index < rooms.length; index++)
      RoomLiveUpdate(room: rooms[index], breakdown: index == 0 ? breakdown : null),
  ];
}

Map<String, dynamic>? socketObject(dynamic data) {
  final maps = _maps(data);
  if (maps.isEmpty) return null;
  return maps.first;
}

List<Map<String, dynamic>> _maps(dynamic data) {
  if (data is String) {
    try {
      return _maps(jsonDecode(data));
    } catch (_) {
      return const [];
    }
  }
  if (data is List) {
    return data.expand(_maps).toList();
  }
  final root = _map(data);
  if (root == null) return const [];
  final maps = <Map<String, dynamic>>[root];
  for (final key in const [
    'data',
    'room',
    'payload',
    'rooms',
    'room_status_breakdown',
    'roomStatusBreakdown',
    'room_status_summary',
    'roomStatusSummary',
    'breakdown',
    'summary',
  ]) {
    final value = root[key];
    if (value is Map) {
      maps.add(Map<String, dynamic>.from(value));
    } else if (value is List) {
      maps.addAll(value.map(_map).whereType<Map<String, dynamic>>());
    }
  }
  return maps;
}

Map<String, dynamic>? _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _text(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return null;
}

int? _count(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.round();
  }
  return null;
}

String _roomKey(String? value) {
  var text = (value ?? '').trim().toLowerCase();
  text = text.replaceAll('#', '');
  text = text.replaceAll('room', '');
  return text.trim();
}

String? _floorLabel(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  if (text.toLowerCase().startsWith('floor')) return text;
  return 'Floor $text';
}
