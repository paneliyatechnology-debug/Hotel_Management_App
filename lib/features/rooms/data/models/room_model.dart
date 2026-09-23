import '../../../../core/widgets/status_badge.dart';

class RoomModel {
  final String id;
  final String roomNumber;
  final String floor;
  final String roomType; // e.g. 'family room', 'couple room', 'deluxe suite'
  final double pricePerNight;
  final RoomStatus status;
  final String? currentGuestName;
  final String? currentGuestFolioId;
  final int maxOccupancy;
  final List<String> amenities;

  const RoomModel({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.roomType,
    required this.pricePerNight,
    required this.status,
    this.currentGuestName,
    this.currentGuestFolioId,
    this.maxOccupancy = 2,
    this.amenities = const ['Wi-Fi', 'AC', 'TV', 'En-suite Bath'],
  });

  RoomModel copyWith({
    String? id,
    String? roomNumber,
    String? floor,
    String? roomType,
    double? pricePerNight,
    RoomStatus? status,
    String? currentGuestName,
    String? currentGuestFolioId,
    int? maxOccupancy,
    List<String>? amenities,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      floor: floor ?? this.floor,
      roomType: roomType ?? this.roomType,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      status: status ?? this.status,
      currentGuestName: currentGuestName ?? this.currentGuestName,
      currentGuestFolioId: currentGuestFolioId ?? this.currentGuestFolioId,
      maxOccupancy: maxOccupancy ?? this.maxOccupancy,
      amenities: amenities ?? this.amenities,
    );
  }
}
