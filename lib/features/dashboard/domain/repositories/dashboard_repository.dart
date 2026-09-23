import 'dart:async';
import '../../../../core/widgets/status_badge.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../data/models/guest_folio_model.dart';
import '../../data/models/hotel_stats_model.dart';
import '../../../check_in_wizard/data/models/check_in_form_data.dart';

abstract class IDashboardRepository {
  Future<List<RoomModel>> getRooms();
  Future<List<GuestFolioModel>> getFolios();
  Future<HotelStatsModel> getStats();
  Future<void> updateRoomStatus(String roomId, RoomStatus newStatus);
  Future<GuestFolioModel> completeCheckIn(CheckInFormData formData);
  Future<void> checkoutFolio(String folioId);
}

class DashboardRepository implements IDashboardRepository {
  static final DashboardRepository _instance = DashboardRepository._internal();
  factory DashboardRepository() => _instance;
  DashboardRepository._internal();

  final List<RoomModel> _rooms = [
    // Family Rooms
    const RoomModel(
      id: 'room-01',
      roomNumber: '#01',
      floor: 'Floor 1',
      roomType: 'family room',
      pricePerNight: 5000,
      status: RoomStatus.available,
      maxOccupancy: 4,
      amenities: ['King Bed', 'Balcony View', 'Wi-Fi', 'Smart TV', 'En-suite Bath'],
    ),
    const RoomModel(
      id: 'room-06',
      roomNumber: '#06',
      floor: 'Floor 1',
      roomType: 'family room',
      pricePerNight: 5000,
      status: RoomStatus.available,
      maxOccupancy: 4,
      amenities: ['King Bed', 'Balcony View', 'Wi-Fi', 'Smart TV', 'En-suite Bath'],
    ),
    const RoomModel(
      id: 'room-11',
      roomNumber: '#11',
      floor: 'Floor 2',
      roomType: 'family room',
      pricePerNight: 5000,
      status: RoomStatus.available,
      maxOccupancy: 4,
      amenities: ['King Bed', 'Balcony View', 'Wi-Fi', 'Smart TV', 'En-suite Bath'],
    ),
    const RoomModel(
      id: 'room-16',
      roomNumber: '#16',
      floor: 'Floor 3',
      roomType: 'family room',
      pricePerNight: 5000,
      status: RoomStatus.cleaning,
      maxOccupancy: 4,
      amenities: ['King Bed', 'Balcony View', 'Wi-Fi', 'Smart TV', 'En-suite Bath'],
    ),

    // Couple Rooms
    const RoomModel(
      id: 'room-02',
      roomNumber: '#02',
      floor: 'Floor 1',
      roomType: 'couple room',
      pricePerNight: 2500,
      status: RoomStatus.available,
      maxOccupancy: 2,
      amenities: ['Queen Bed', 'Air Conditioning', 'Free Breakfast', 'Wi-Fi'],
    ),
    const RoomModel(
      id: 'room-07',
      roomNumber: '#07',
      floor: 'Floor 1',
      roomType: 'couple room',
      pricePerNight: 2500,
      status: RoomStatus.available,
      maxOccupancy: 2,
      amenities: ['Queen Bed', 'Air Conditioning', 'Free Breakfast', 'Wi-Fi'],
    ),
    const RoomModel(
      id: 'room-12',
      roomNumber: '#12',
      floor: 'Floor 2',
      roomType: 'couple room',
      pricePerNight: 2500,
      status: RoomStatus.occupied,
      currentGuestName: 'Ananya Sharma',
      currentGuestFolioId: 'FOL-1095',
      maxOccupancy: 2,
      amenities: ['Queen Bed', 'Air Conditioning', 'Free Breakfast', 'Wi-Fi'],
    ),

    // Deluxe Suites
    const RoomModel(
      id: 'room-03',
      roomNumber: '#03',
      floor: 'Floor 1',
      roomType: 'deluxe suite',
      pricePerNight: 7500,
      status: RoomStatus.occupied,
      currentGuestName: 'Vikram Mehta',
      currentGuestFolioId: 'FOL-1092',
      maxOccupancy: 3,
      amenities: ['Jacuzzi', 'Mini Bar', 'Sea View', 'High-Speed Wi-Fi'],
    ),
    const RoomModel(
      id: 'room-08',
      roomNumber: '#08',
      floor: 'Floor 2',
      roomType: 'deluxe suite',
      pricePerNight: 7500,
      status: RoomStatus.available,
      maxOccupancy: 3,
      amenities: ['Jacuzzi', 'Mini Bar', 'Sea View', 'High-Speed Wi-Fi'],
    ),
    const RoomModel(
      id: 'room-13',
      roomNumber: '#13',
      floor: 'Floor 2',
      roomType: 'deluxe suite',
      pricePerNight: 7500,
      status: RoomStatus.available,
      maxOccupancy: 3,
      amenities: ['Jacuzzi', 'Mini Bar', 'Sea View', 'High-Speed Wi-Fi'],
    ),

    // Executive Rooms
    const RoomModel(
      id: 'room-04',
      roomNumber: '#04',
      floor: 'Floor 2',
      roomType: 'executive room',
      pricePerNight: 4200,
      status: RoomStatus.cleaning,
      maxOccupancy: 2,
      amenities: ['Work Desk', 'Ergonomic Chair', 'Wi-Fi', 'Coffee Machine'],
    ),
    const RoomModel(
      id: 'room-09',
      roomNumber: '#09',
      floor: 'Floor 2',
      roomType: 'executive room',
      pricePerNight: 4200,
      status: RoomStatus.available,
      maxOccupancy: 2,
      amenities: ['Work Desk', 'Ergonomic Chair', 'Wi-Fi', 'Coffee Machine'],
    ),
    const RoomModel(
      id: 'room-14',
      roomNumber: '#14',
      floor: 'Floor 3',
      roomType: 'executive room',
      pricePerNight: 4200,
      status: RoomStatus.available,
      maxOccupancy: 2,
      amenities: ['Work Desk', 'Ergonomic Chair', 'Wi-Fi', 'Coffee Machine'],
    ),

    // Presidential Suites
    const RoomModel(
      id: 'room-05',
      roomNumber: '#05',
      floor: 'Floor 2',
      roomType: 'presidential suite',
      pricePerNight: 12000,
      status: RoomStatus.maintenance,
      maxOccupancy: 5,
      amenities: ['Private Lounge', 'Butler Service', 'Private Terrace'],
    ),
    const RoomModel(
      id: 'room-10',
      roomNumber: '#10',
      floor: 'Floor 3',
      roomType: 'presidential suite',
      pricePerNight: 12000,
      status: RoomStatus.available,
      maxOccupancy: 5,
      amenities: ['Private Lounge', 'Butler Service', 'Private Terrace'],
    ),
  ];

  final List<GuestFolioModel> _folios = [
    GuestFolioModel(
      id: 'FOL-1088',
      guestName: 'Niraj Vekariya',
      email: 'nirajvekariya2209@gmail.com',
      phone: '08849218118',
      assignedRoom: 'Room #01',
      roomType: 'family room',
      checkInDate: DateTime(2026, 1, 19),
      checkOutDate: DateTime(2026, 1, 21),
      status: FolioStatus.departed,
      idType: 'Aadhaar Card',
      idNumber: 'XXXX-XXXX-4819',
      isGovtIdVerified: true,
      roomRatePerNight: 5000,
      advancePaid: 10000,
      totalAmount: 11200,
      paymentMode: 'UPI',
      keycardNumber: 'KC-101',
      address: 'Ahmedabad, Gujarat, India',
    ),
    GuestFolioModel(
      id: 'FOL-1092',
      guestName: 'Vikram Mehta',
      email: 'vikram.mehta@enterprise.in',
      phone: '09825166290',
      assignedRoom: 'Room #03',
      roomType: 'deluxe suite',
      checkInDate: DateTime.now().subtract(const Duration(hours: 18)),
      checkOutDate: DateTime.now().add(const Duration(days: 2)),
      status: FolioStatus.inHouse,
      idType: 'Passport',
      idNumber: 'P8923411',
      isGovtIdVerified: true,
      roomRatePerNight: 7500,
      advancePaid: 15000,
      totalAmount: 16800,
      paymentMode: 'Credit Card',
      keycardNumber: 'KC-103',
      address: 'Mumbai, Maharashtra, India',
    ),
  ];

  @override
  Future<List<RoomModel>> getRooms() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.unmodifiable(_rooms);
  }

  @override
  Future<List<GuestFolioModel>> getFolios() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.unmodifiable(_folios);
  }

  @override
  Future<HotelStatsModel> getStats() async {
    int available = 0;
    int occupied = 0;
    int cleaning = 0;
    int maintenance = 0;

    for (final room in _rooms) {
      switch (room.status) {
        case RoomStatus.available:
          available++;
          break;
        case RoomStatus.occupied:
          occupied++;
          break;
        case RoomStatus.cleaning:
          cleaning++;
          break;
        case RoomStatus.maintenance:
          maintenance++;
          break;
      }
    }

    final inHouseGuests = _folios.where((f) => f.status == FolioStatus.inHouse).length;

    return HotelStatsModel(
      availableVacant: available,
      occupiedInHouse: occupied,
      housekeepingQueue: cleaning,
      maintenanceBlocked: maintenance,
      totalInHouseGuests: inHouseGuests,
    );
  }

  @override
  Future<void> updateRoomStatus(String roomId, RoomStatus newStatus) async {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      _rooms[index] = _rooms[index].copyWith(
        status: newStatus,
        currentGuestName: newStatus == RoomStatus.available ? null : _rooms[index].currentGuestName,
      );
    }
  }

  @override
  Future<GuestFolioModel> completeCheckIn(CheckInFormData formData) async {
    final newFolioId = 'FOL-${1100 + _folios.length}';
    final newFolio = GuestFolioModel(
      id: newFolioId,
      guestName: formData.guestFullName,
      email: formData.email,
      phone: formData.contactPhone,
      assignedRoom: 'Room ${formData.selectedRoomNumber}',
      roomType: formData.roomType,
      checkInDate: formData.checkInDate,
      checkOutDate: formData.checkOutDate,
      status: FolioStatus.inHouse,
      idType: formData.idType,
      idNumber: formData.idNumber,
      isGovtIdVerified: formData.isIdVerified,
      roomRatePerNight: formData.pricePerNight,
      advancePaid: formData.advancePaid,
      totalAmount: formData.grandTotal,
      paymentMode: formData.paymentMode,
      keycardNumber: formData.assignedKeycardNumber,
      address: '${formData.residentialAddress}, ${formData.city}, ${formData.state} - ${formData.pincode}',
      gstNumber: formData.gstNumber,
    );

    _folios.insert(0, newFolio);

    // Update the room to occupied
    final roomIndex = _rooms.indexWhere((r) => r.id == formData.selectedRoomId || r.roomNumber == formData.selectedRoomNumber);
    if (roomIndex != -1) {
      _rooms[roomIndex] = _rooms[roomIndex].copyWith(
        status: RoomStatus.occupied,
        currentGuestName: formData.guestFullName,
        currentGuestFolioId: newFolioId,
      );
    }

    return newFolio;
  }

  @override
  Future<void> checkoutFolio(String folioId) async {
    final index = _folios.indexWhere((f) => f.id == folioId);
    if (index != -1) {
      final oldFolio = _folios[index];
      _folios[index] = oldFolio.copyWith(status: FolioStatus.departed);

      // Change corresponding room to cleaning
      final roomIndex = _rooms.indexWhere((r) => 'Room ${r.roomNumber}' == oldFolio.assignedRoom || r.roomNumber == oldFolio.assignedRoom);
      if (roomIndex != -1) {
        _rooms[roomIndex] = _rooms[roomIndex].copyWith(
          status: RoomStatus.cleaning,
          currentGuestName: null,
          currentGuestFolioId: null,
        );
      }
    }
  }
}
