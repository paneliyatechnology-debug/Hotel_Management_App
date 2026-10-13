import 'package:flutter/material.dart';
import '../../../../core/widgets/status_badge.dart';

class PaymentRecordModel {
  final String id;
  final DateTime date;
  final double amount;
  final String paymentMethod; // 'UPI', 'Cash', 'Credit Card', 'POS', 'Net Banking'
  final String reference;
  final String status; // 'Successful', 'Pending', 'Refunded'

  const PaymentRecordModel({
    required this.id,
    required this.date,
    required this.amount,
    required this.paymentMethod,
    required this.reference,
    this.status = 'Successful',
  });
}

class ChargeItemModel {
  final String id;
  final String serviceName; // 'Room Service', 'Laundry', 'Minibar', 'Restaurant', 'Extra Bed'
  final DateTime date;
  final double amount;
  final String status; // 'Posted', 'Pending'

  const ChargeItemModel({
    required this.id,
    required this.serviceName,
    required this.date,
    required this.amount,
    this.status = 'Posted',
  });
}

class StayActivityModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;

  const StayActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
  });
}

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

  // 2026 Enhanced PMS Attributes
  final String? bookingId;
  final String? receiptNumber;
  final String? guestId;
  final String bookingSource; // 'Direct / Walk-In', 'MakeMyTrip', 'Booking.com', 'Corporate'
  final String bookingStatus; // 'Confirmed', 'Completed', 'Cancelled'
  final String floor;
  final int numberOfGuests;
  final String gender;
  final DateTime? dateOfBirth;
  final String nationality;
  final String keycardStatus; // 'Active', 'Not Issued', 'Issue Reported', 'Lost', 'Inactive'
  final DateTime? keycardIssuedAt;
  final String? vipStatus;
  final String? specialRequests;
  final String? mealPlan; // 'EP (Room Only)', 'CP (Breakfast Included)', 'MAP (Half Board)'
  final String? guestNotes;
  final bool extraBed;

  // Folio Itemized Breakdown
  final double roomCharges;
  final double extraCharges;
  final double foodCharges;
  final double laundryCharges;
  final double otherServiceCharges;
  final double discount;
  final double tax;

  // Payments, Services, and Activity
  final List<PaymentRecordModel> payments;
  final List<ChargeItemModel> services;
  final List<StayActivityModel> activityTimeline;

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
    this.bookingId,
    this.receiptNumber,
    this.guestId,
    this.bookingSource = 'Direct / Walk-In',
    this.bookingStatus = 'Confirmed',
    this.floor = 'Floor 1',
    this.numberOfGuests = 2,
    this.gender = 'Male',
    this.dateOfBirth,
    this.nationality = 'Indian',
    this.keycardStatus = 'Active',
    this.keycardIssuedAt,
    this.vipStatus,
    this.specialRequests,
    this.mealPlan = 'CP (Breakfast Included)',
    this.guestNotes,
    this.extraBed = false,
    this.roomCharges = 0,
    this.extraCharges = 0,
    this.foodCharges = 0,
    this.laundryCharges = 0,
    this.otherServiceCharges = 0,
    this.discount = 0,
    this.tax = 0,
    this.payments = const [],
    this.services = const [],
    this.activityTimeline = const [],
  });

  // Effective Financial Calculations
  double get pendingAmount {
    final diff = totalAmount - advancePaid;
    return diff > 0 ? diff : 0;
  }

  double get paidAmount => advancePaid;

  String get paymentStatusLabel {
    if (pendingAmount <= 0) return 'PAID';
    if (paidAmount > 0) return 'PARTIALLY PAID';
    return 'PENDING';
  }

  // Stay Calculations
  int get totalNights {
    final diff = checkOutDate.difference(checkInDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  int get nightsCompleted {
    final now = DateTime.now();
    final completed = now.difference(checkInDate).inDays;
    if (completed < 0) return 0;
    if (completed > totalNights) return totalNights;
    return completed;
  }

  int get nightsRemaining {
    final rem = totalNights - nightsCompleted;
    return rem < 0 ? 0 : rem;
  }

  bool get isCheckoutToday {
    final now = DateTime.now();
    return checkOutDate.year == now.year &&
        checkOutDate.month == now.month &&
        checkOutDate.day == now.day;
  }

  bool get isCheckoutTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return checkOutDate.year == tomorrow.year &&
        checkOutDate.month == tomorrow.month &&
        checkOutDate.day == tomorrow.day;
  }

  bool get isOverdueCheckout {
    final now = DateTime.now();
    return status == FolioStatus.inHouse &&
        checkOutDate.isBefore(now) &&
        !isCheckoutToday;
  }

  bool get hasPendingPayment => pendingAmount > 0;

  bool get hasKeycardIssue =>
      keycardStatus == 'Issue Reported' ||
      keycardStatus == 'Lost' ||
      keycardStatus == 'Not Issued';

  String get effectiveBookingId {
    if (bookingId != null && bookingId!.isNotEmpty) {
      return bookingId!;
    }
    if (id.startsWith('BK-')) {
      return id;
    }
    return 'BK-${id.replaceAll('FOL-', '')}';
  }

  String get maskedIdNumber {
    if (idNumber.length > 4) {
      return '•••• •••• ${idNumber.substring(idNumber.length - 4)}';
    }
    return idNumber;
  }

  String get initial {
    if (guestName.trim().isEmpty) return 'G';
    final parts = guestName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return guestName[0].toUpperCase();
  }

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
    String? bookingId,
    String? receiptNumber,
    String? guestId,
    String? bookingSource,
    String? bookingStatus,
    String? floor,
    int? numberOfGuests,
    String? gender,
    DateTime? dateOfBirth,
    String? nationality,
    String? keycardStatus,
    DateTime? keycardIssuedAt,
    String? vipStatus,
    String? specialRequests,
    String? mealPlan,
    String? guestNotes,
    bool? extraBed,
    double? roomCharges,
    double? extraCharges,
    double? foodCharges,
    double? laundryCharges,
    double? otherServiceCharges,
    double? discount,
    double? tax,
    List<PaymentRecordModel>? payments,
    List<ChargeItemModel>? services,
    List<StayActivityModel>? activityTimeline,
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
      bookingId: bookingId ?? this.bookingId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      guestId: guestId ?? this.guestId,
      bookingSource: bookingSource ?? this.bookingSource,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      floor: floor ?? this.floor,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      keycardStatus: keycardStatus ?? this.keycardStatus,
      keycardIssuedAt: keycardIssuedAt ?? this.keycardIssuedAt,
      vipStatus: vipStatus ?? this.vipStatus,
      specialRequests: specialRequests ?? this.specialRequests,
      mealPlan: mealPlan ?? this.mealPlan,
      guestNotes: guestNotes ?? this.guestNotes,
      extraBed: extraBed ?? this.extraBed,
      roomCharges: roomCharges ?? this.roomCharges,
      extraCharges: extraCharges ?? this.extraCharges,
      foodCharges: foodCharges ?? this.foodCharges,
      laundryCharges: laundryCharges ?? this.laundryCharges,
      otherServiceCharges: otherServiceCharges ?? this.otherServiceCharges,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      payments: payments ?? this.payments,
      services: services ?? this.services,
      activityTimeline: activityTimeline ?? this.activityTimeline,
    );
  }

  factory GuestFolioModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> guestData = {};
    String? gId;
    if (json['guest'] is Map<String, dynamic>) {
      guestData = json['guest'] as Map<String, dynamic>;
      gId = guestData['_id']?.toString();
    } else if (json['guest'] is String) {
      gId = json['guest'] as String;
    } else if (json['guestId'] != null) {
      gId = json['guestId']?.toString();
    }

    Map<String, dynamic> roomData = {};
    if (json['room'] is Map<String, dynamic>) {
      roomData = json['room'] as Map<String, dynamic>;
    }
    final roomTypeData = json['roomType'];

    String typeName = 'Standard Room';
    double rate = 4000;
    if (roomTypeData is Map<String, dynamic>) {
      typeName = roomTypeData['name']?.toString() ?? 'Standard Room';
      rate = (roomTypeData['basePrice'] as num?)?.toDouble() ?? 4000;
    } else if (roomTypeData is String && roomTypeData.isNotEmpty) {
      typeName = roomTypeData;
    }

    final roomNum = json['roomNumber']?.toString() ??
        roomData['roomNumber']?.toString() ??
        (json['roomNumbers'] is List && (json['roomNumbers'] as List).isNotEmpty
            ? (json['roomNumbers'] as List).first.toString()
            : '01');

    final assignedRoom = roomNum.startsWith('Room')
        ? roomNum
        : (roomNum.startsWith('#') ? 'Room $roomNum' : 'Room #$roomNum');

    final guestName = guestData['fullName']?.toString() ??
        guestData['name']?.toString() ??
        json['guestName']?.toString() ??
        'Guest';

    final email = guestData['email']?.toString() ?? json['email']?.toString() ?? '';
    final phone = guestData['phone']?.toString() ??
        guestData['mobileNumber']?.toString() ??
        json['phone']?.toString() ??
        '';

    final govtIdType = (guestData['idProof'] is Map
            ? guestData['idProof']['idType']?.toString()
            : null) ??
        guestData['govtIdType']?.toString() ??
        guestData['idType']?.toString() ??
        'Aadhaar Card';
    final govtIdNumber = (guestData['idProof'] is Map
            ? guestData['idProof']['idNumber']?.toString()
            : null) ??
        guestData['govtIdNumber']?.toString() ??
        guestData['idNumber']?.toString() ??
        '';

    final checkInStr = json['checkInDate']?.toString();
    final checkOutStr = json['checkOutDate']?.toString();
    final checkIn = checkInStr != null
        ? DateTime.tryParse(checkInStr) ?? DateTime.now()
        : DateTime.now();
    final checkOut = checkOutStr != null
        ? DateTime.tryParse(checkOutStr) ??
            DateTime.now().add(const Duration(days: 1))
        : DateTime.now().add(const Duration(days: 1));

    final nights = (json['numberOfNights'] as num?)?.toInt() ?? 1;
    final total = (json['totalAmount'] as num?)?.toDouble() ??
        (json['baseAmount'] as num?)?.toDouble() ??
        (json['total'] as num?)?.toDouble() ??
        (rate * nights);
    final advance = (json['paidAmount'] as num?)?.toDouble() ??
        (json['advancePaid'] as num?)?.toDouble() ??
        (json['advancePayment'] as num?)?.toDouble() ??
        (json['advance'] as num?)?.toDouble() ??
        total;

    final bookingNum = json['bookingNumber']?.toString() ??
        (json['_id'] != null ? 'BK-${json['_id'].toString().substring(0, json['_id'].toString().length > 6 ? 6 : json['_id'].toString().length)}' : 'BK-1001');

    final rawStatus = json['status']?.toString().toUpperCase() ?? '';
    FolioStatus status = FolioStatus.inHouse;
    if (rawStatus == 'DEPARTED' ||
        rawStatus == 'CHECKED_OUT' ||
        rawStatus == 'CHECKEDOUT' ||
        rawStatus == 'COMPLETED' ||
        json['actualCheckOut'] != null) {
      status = FolioStatus.departed;
    } else if (rawStatus == 'CANCELLED') {
      status = FolioStatus.cancelled;
    } else if (rawStatus == 'RESERVED' || rawStatus == 'PENDING') {
      status = FolioStatus.confirmed;
    } else {
      status = FolioStatus.inHouse;
    }

    final floorNum = roomData['floor']?.toString() ?? '1';
    final floorStr = floorNum.toLowerCase().contains('floor')
        ? floorNum
        : 'Floor $floorNum';

    int guestCount = 1;
    if (json['guestsCount'] is Map) {
      final gc = json['guestsCount'] as Map<String, dynamic>;
      guestCount = ((gc['adults'] as num?)?.toInt() ?? 1) +
          ((gc['children'] as num?)?.toInt() ?? 0);
    } else if (json['adults'] != null) {
      guestCount = ((json['adults'] as num?)?.toInt() ?? 1) +
          ((json['children'] as num?)?.toInt() ?? 0);
    }

    final receiptNum = json['receiptNumber']?.toString();
    final paymentMethod = json['paymentMethod']?.toString() ??
        json['paymentMode']?.toString() ??
        'UPI';

    return GuestFolioModel(
      id: json['_id']?.toString() ?? bookingNum,
      bookingId: bookingNum,
      receiptNumber: receiptNum,
      guestId: gId,
      guestName: guestName,
      email: email,
      phone: phone,
      assignedRoom: assignedRoom,
      roomType: typeName,
      checkInDate: checkIn,
      checkOutDate: checkOut,
      status: status,
      idType: govtIdType,
      idNumber: govtIdNumber,
      isGovtIdVerified: govtIdNumber.isNotEmpty,
      roomRatePerNight: rate,
      advancePaid: advance,
      totalAmount: total,
      paymentMode: paymentMethod,
      keycardNumber: json['keycardNumber']?.toString() ?? 'KC-$roomNum',
      floor: floorStr,
      numberOfGuests: guestCount,
      gender: guestData['gender']?.toString() ?? json['gender']?.toString() ?? 'Male',
      nationality: guestData['nationality']?.toString() ?? json['nationality']?.toString() ?? 'Indian',
      address: guestData['address']?.toString() ?? json['address']?.toString() ?? '',
      bookingSource: json['bookingSource']?.toString() ?? 'Direct / Walk-In',
      bookingStatus: json['bookingStatus']?.toString() ?? 'Confirmed',
    );
  }
}
