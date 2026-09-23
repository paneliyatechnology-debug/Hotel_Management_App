import '../../../../core/widgets/status_badge.dart';

class GuestFolioModel {
  final String id;
  final String guestName;
  final String email;
  final String phone;
  final String assignedRoom;
  final String roomType;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final FolioStatus status;
  final String idType; // 'Aadhaar Card', 'Passport', 'Driving License', 'Voter ID'
  final String idNumber;
  final bool isGovtIdVerified;
  final double roomRatePerNight;
  final double advancePaid;
  final double totalAmount;
  final String paymentMode; // 'Cash', 'UPI', 'Credit Card', 'POS'
  final String? keycardNumber;
  final String? address;
  final String? gstNumber;

  const GuestFolioModel({
    required this.id,
    required this.guestName,
    required this.email,
    required this.phone,
    required this.assignedRoom,
    required this.roomType,
    required this.checkInDate,
    required this.checkOutDate,
    required this.status,
    required this.idType,
    required this.idNumber,
    this.isGovtIdVerified = true,
    required this.roomRatePerNight,
    required this.advancePaid,
    required this.totalAmount,
    this.paymentMode = 'UPI',
    this.keycardNumber,
    this.address,
    this.gstNumber,
  });

  GuestFolioModel copyWith({
    String? id,
    String? guestName,
    String? email,
    String? phone,
    String? assignedRoom,
    String? roomType,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    FolioStatus? status,
    String? idType,
    String? idNumber,
    bool? isGovtIdVerified,
    double? roomRatePerNight,
    double? advancePaid,
    double? totalAmount,
    String? paymentMode,
    String? keycardNumber,
    String? address,
    String? gstNumber,
  }) {
    return GuestFolioModel(
      id: id ?? this.id,
      guestName: guestName ?? this.guestName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      assignedRoom: assignedRoom ?? this.assignedRoom,
      roomType: roomType ?? this.roomType,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      status: status ?? this.status,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      isGovtIdVerified: isGovtIdVerified ?? this.isGovtIdVerified,
      roomRatePerNight: roomRatePerNight ?? this.roomRatePerNight,
      advancePaid: advancePaid ?? this.advancePaid,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      keycardNumber: keycardNumber ?? this.keycardNumber,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
    );
  }
}
