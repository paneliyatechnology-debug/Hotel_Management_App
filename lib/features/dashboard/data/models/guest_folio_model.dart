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

class BookingGuestModel {
  final int id;
  final String name;
  final int displayOrder;

  const BookingGuestModel({
    required this.id,
    required this.name,
    this.displayOrder = 1,
  });

  factory BookingGuestModel.fromJson(Map<String, dynamic> json) {
    return BookingGuestModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? json['guest_name'] ?? json['fullName'] ?? '').toString().trim(),
      displayOrder: (json['display_order'] as num?)?.toInt() ?? (json['displayOrder'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'display_order': displayOrder,
  };
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
  final int? adultCount;
  final int? childCount;
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
  final String? secondaryGuestName;
  final String? createdByName;
  final List<String> idImageUrls;
  final List<String> signatureUrls;
  final DateTime? actualCheckIn;
  final DateTime? actualCheckOut;
  final double gstRate;
  final double cgstAmount;
  final double sgstAmount;
  final String? roomId;
  final List<BookingGuestModel> guests;

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
    this.paymentMode = '',
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
    this.adultCount,
    this.childCount,
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
    this.secondaryGuestName,
    this.createdByName,
    this.idImageUrls = const [],
    this.signatureUrls = const [],
    this.actualCheckIn,
    this.actualCheckOut,
    this.gstRate = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.roomId,
    this.guests = const [],
  });

  // Effective Financial Calculations
  bool get hasPayment => payments.isNotEmpty || advancePaid > 0;

  double get pendingAmount {
    final diff = totalAmount - advancePaid;
    return diff > 0 ? diff : 0;
  }

  double get paidAmount => advancePaid;

  String get paymentStatusLabel {
    if (paidAmount <= 0) return 'PENDING';
    if (pendingAmount <= 0) return 'PAID';
    return 'PARTIALLY PAID';
  }

  // Stay Calculations
  int get totalNights {
    final start = DateTime(checkInDate.year, checkInDate.month, checkInDate.day);
    final end = DateTime(checkOutDate.year, checkOutDate.month, checkOutDate.day);
    final diff = end.difference(start).inDays;
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
    int? adultCount,
    int? childCount,
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
    String? secondaryGuestName,
    String? createdByName,
    List<String>? idImageUrls,
    List<String>? signatureUrls,
    DateTime? actualCheckIn,
    DateTime? actualCheckOut,
    double? gstRate,
    double? cgstAmount,
    double? sgstAmount,
    String? roomId,
    List<BookingGuestModel>? guests,
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
      adultCount: adultCount ?? this.adultCount,
      childCount: childCount ?? this.childCount,
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
      secondaryGuestName: secondaryGuestName ?? this.secondaryGuestName,
      createdByName: createdByName ?? this.createdByName,
      idImageUrls: idImageUrls ?? this.idImageUrls,
      signatureUrls: signatureUrls ?? this.signatureUrls,
      actualCheckIn: actualCheckIn ?? this.actualCheckIn,
      actualCheckOut: actualCheckOut ?? this.actualCheckOut,
      gstRate: gstRate ?? this.gstRate,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      roomId: roomId ?? this.roomId,
      guests: guests ?? this.guests,
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
    if (json['room'] is Map) {
      roomData = Map<String, dynamic>.from(json['room'] as Map);
    } else if (json['rooms'] is List && (json['rooms'] as List).isNotEmpty) {
      final firstRoom = (json['rooms'] as List).first;
      if (firstRoom is Map) {
        roomData = Map<String, dynamic>.from(firstRoom);
      }
    }
    final roomTypeData = json['roomType'];

    String typeName = 'Standard Room';
    var rateFromCatalog = false;
    double rate = 4000;
    if (roomTypeData is Map) {
      final roomType = Map<String, dynamic>.from(roomTypeData);
      typeName = roomType['name']?.toString() ?? 'Standard Room';
      if (roomType['basePrice'] is num) {
        rate = (roomType['basePrice'] as num).toDouble();
        rateFromCatalog = true;
      }
    } else if (roomTypeData is String && roomTypeData.isNotEmpty) {
      typeName = roomTypeData;
    } else if (roomData['room_type_name'] != null) {
      typeName = roomData['room_type_name'].toString();
    }

    final roomNum = json['roomNumber']?.toString() ??
        roomData['roomNumber']?.toString() ??
        roomData['room_number']?.toString() ??
        (json['roomNumbers'] is List && (json['roomNumbers'] as List).isNotEmpty
            ? (json['roomNumbers'] as List).first.toString()
            : '01');

    final assignedRoom = roomNum.startsWith('Room')
        ? roomNum
        : (roomNum.startsWith('#') ? 'Room $roomNum' : 'Room #$roomNum');

    String firstNonEmpty(List<dynamic> candidates, [String fallback = '']) {
      for (final c in candidates) {
        if (c != null) {
          final s = c.toString().trim();
          if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
        }
      }
      return fallback;
    }

    final guestName = firstNonEmpty([
      guestData['fullName'],
      guestData['name'],
      guestData['guest_name'],
      json['primary_guest_name'],
      json['primaryGuestName'],
      json['guestName'],
      json['guest_name'],
    ], 'Guest');

    final email = firstNonEmpty([
      guestData['email'],
      json['email'],
    ]);

    final phone = firstNonEmpty([
      guestData['phone'],
      guestData['mobileNumber'],
      guestData['mobile_number'],
      json['mobile_number'],
      json['mobileNumber'],
      json['phone'],
    ]);

    final govtIdType = (guestData['idProof'] is Map
            ? guestData['idProof']['idType']?.toString()
            : null) ??
        guestData['govtIdType']?.toString() ??
        guestData['idType']?.toString() ??
        json['id_type']?.toString() ??
        '';
    final govtIdNumber = (guestData['idProof'] is Map
            ? guestData['idProof']['idNumber']?.toString()
            : null) ??
        guestData['govtIdNumber']?.toString() ??
        guestData['idNumber']?.toString() ??
        '';

    final checkInStr = (json['check_in_date'] ?? json['checkInDate'])?.toString();
    final checkOutStr = (json['check_out_date'] ?? json['checkOutDate'])?.toString();
    final checkIn = checkInStr != null
        ? DateTime.tryParse(checkInStr) ?? DateTime.now()
        : DateTime.now();
    final checkOut = checkOutStr != null
        ? DateTime.tryParse(checkOutStr) ??
            DateTime.now().add(const Duration(days: 1))
        : DateTime.now().add(const Duration(days: 1));

    final nights = (json['nights'] as num?)?.toInt() ??
        (json['number_of_nights'] as num?)?.toInt() ??
        (json['numberOfNights'] as num?)?.toInt() ??
        1;
    if (!rateFromCatalog && json['base_amount'] is num && nights > 0) {
      rate = (json['base_amount'] as num).toDouble() / nights;
    }
    final total = (json['total_amount'] as num?)?.toDouble() ??
        (json['totalAmount'] as num?)?.toDouble() ??
        (json['base_amount'] as num?)?.toDouble() ??
        (json['baseAmount'] as num?)?.toDouble() ??
        (json['total'] as num?)?.toDouble() ??
        (rate * nights);

    final bookingNum = json['booking_number']?.toString() ??
        json['bookingNumber']?.toString() ??
        (json['_id'] != null ? 'BK-${json['_id'].toString().substring(0, json['_id'].toString().length > 6 ? 6 : json['_id'].toString().length)}' : 'BK-1001');

    final rawStatus = (json['booking_status'] ?? json['status'] ?? '').toString().toUpperCase();
    final actualOut = json['actual_check_out'] ?? json['actualCheckOut'];
    final hasActualCheckout = actualOut != null && actualOut.toString().trim().isNotEmpty;
    FolioStatus status = FolioStatus.inHouse;
    if (rawStatus == 'DEPARTED' ||
        rawStatus == 'CHECKED_OUT' ||
        rawStatus == 'CHECKEDOUT' ||
        rawStatus == 'COMPLETED' ||
        hasActualCheckout) {
      status = FolioStatus.departed;
    } else if (rawStatus == 'CANCELLED') {
      status = FolioStatus.cancelled;
    } else if (rawStatus == 'RESERVED' || rawStatus == 'PENDING' || rawStatus == 'CONFIRMED') {
      status = FolioStatus.confirmed;
    } else {
      status = FolioStatus.inHouse;
    }

    final floorNum = roomData['floor']?.toString() ?? '1';
    final floorStr = floorNum.toLowerCase().contains('floor')
        ? floorNum
        : 'Floor $floorNum';

    int? adultCount;
    int? childCount;
    int guestCount = 1;
    if (json['guestsCount'] is Map) {
      final gc = Map<String, dynamic>.from(json['guestsCount'] as Map);
      adultCount = (gc['adults'] as num?)?.toInt() ?? 1;
      childCount = (gc['children'] as num?)?.toInt() ?? 0;
      guestCount = adultCount + childCount;
    } else if (json['adults'] != null || json['children'] != null) {
      adultCount = (json['adults'] as num?)?.toInt() ?? 1;
      childCount = (json['children'] as num?)?.toInt() ?? 0;
      guestCount = adultCount + childCount;
    }

    final receiptNum = json['receiptNumber']?.toString();
    final payments = _paymentHistory(json['payment_history'] ?? json['paymentHistory'], checkIn);
    final rawPaymentMethod = json['payment_method']?.toString() ??
        json['paymentMethod']?.toString() ??
        json['paymentMode']?.toString();
    final paymentMethod = (rawPaymentMethod != null &&
            rawPaymentMethod.trim().isNotEmpty &&
            rawPaymentMethod.trim() != 'null')
        ? rawPaymentMethod.trim()
        : (payments.isNotEmpty ? payments.first.paymentMethod : '');

    final rawDue = (json['due_amount'] as num?)?.toDouble() ??
        (json['dueAmount'] as num?)?.toDouble();
    final rawPaid = (json['paid_amount'] as num?)?.toDouble() ??
        (json['paidAmount'] as num?)?.toDouble() ??
        (json['advancePaid'] as num?)?.toDouble() ??
        (json['advancePayment'] as num?)?.toDouble() ??
        (json['advance'] as num?)?.toDouble();

    final double advance;
    if (rawPaid != null) {
      advance = rawPaid;
    } else if (rawDue != null) {
      advance = (total - rawDue).clamp(0.0, total);
    } else if (payments.isNotEmpty) {
      advance = payments.fold<double>(0.0, (sum, p) => sum + p.amount);
    } else {
      advance = 0.0;
    }
    final tax = _amount(json['tax_amount'] ?? json['gst_amount'] ?? json['taxAmount'] ?? json['tax']);
    final discount = _amount(json['discount_amount'] ?? json['discountAmount'] ?? json['discount']);
    final roomCharges = _amount(json['base_amount'] ?? json['baseAmount'] ?? json['roomCharges']);
    final notes = json['notes']?.toString();
    final secondaryGuest = json['secondary_guest_name']?.toString() ?? json['secondaryGuestName']?.toString();
    final roomId = _bookingRoomId(json['room_id'] ?? json['roomId'], roomData['id']);
    String? createdByName;
    if (json['creator'] is Map) {
      createdByName = Map<String, dynamic>.from(json['creator'] as Map)['name']?.toString();
    }

    final rawGuests = json['guests'];
    final guestsList = <BookingGuestModel>[];
    if (rawGuests is List) {
      for (final item in rawGuests) {
        if (item is Map<String, dynamic>) {
          guestsList.add(BookingGuestModel.fromJson(item));
        } else if (item is Map) {
          guestsList.add(BookingGuestModel.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String && item.trim().isNotEmpty) {
          guestsList.add(BookingGuestModel(id: 0, name: item.trim(), displayOrder: guestsList.length + 1));
        }
      }
      guestsList.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }

    return GuestFolioModel(
      id: (json['_id'] ?? json['id'] ?? bookingNum).toString(),
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
      keycardNumber: json['keycard_number']?.toString() ?? json['keycardNumber']?.toString() ?? 'KC-$roomNum',
      floor: floorStr,
      numberOfGuests: guestCount,
      adultCount: adultCount,
      childCount: childCount,
      gender: guestData['gender']?.toString() ?? json['gender']?.toString() ?? '',
      nationality: guestData['nationality']?.toString() ?? json['nationality']?.toString() ?? 'Indian',
      address: guestData['address']?.toString() ?? json['address']?.toString() ?? '',
      bookingSource: json['bookingSource']?.toString() ?? 'Direct / Walk-In',
      bookingStatus: json['booking_status']?.toString() ?? json['bookingStatus']?.toString() ?? 'Confirmed',
      guestNotes: (notes != null && notes.trim().isNotEmpty) ? notes.trim() : null,
      secondaryGuestName: (secondaryGuest != null && secondaryGuest.trim().isNotEmpty) ? secondaryGuest.trim() : null,
      createdByName: (createdByName != null && createdByName.trim().isNotEmpty) ? createdByName.trim() : null,
      roomCharges: roomCharges,
      discount: discount,
      tax: tax,
      payments: payments,
      extraCharges: _amount(json['extra_charges_total'] ?? json['extraCharges']),
      idImageUrls: _mediaUrls(json['images']),
      signatureUrls: _mediaUrls(json['signatures']),
      actualCheckIn: DateTime.tryParse((json['actual_check_in'] ?? json['actualCheckIn'] ?? '').toString()),
      actualCheckOut: DateTime.tryParse((json['actual_check_out'] ?? json['actualCheckOut'] ?? '').toString()),
      gstRate: _amount(json['gst_rate'] ?? json['gstRate']),
      cgstAmount: _amount(json['cgst_amount'] ?? json['cgstAmount']),
      sgstAmount: _amount(json['sgst_amount'] ?? json['sgstAmount']),
      roomId: roomId,
      guests: guestsList,
    );
  }
}

String? _bookingRoomId(dynamic raw, dynamic fallback) {
  if (raw is List && raw.isNotEmpty) {
    final first = raw.first?.toString().trim() ?? '';
    if (first.isNotEmpty) return first;
  }
  final direct = raw?.toString().trim() ?? '';
  if (direct.isNotEmpty && direct != 'null' && !direct.startsWith('[')) return direct;
  final fromRoom = fallback?.toString().trim() ?? '';
  if (fromRoom.isNotEmpty && fromRoom != 'null') return fromRoom;
  return null;
}

double _amount(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _mediaUrls(dynamic raw) {
  if (raw is! List) return const [];
  final urls = <String>[];
  for (final item in raw) {
    if (item is String && item.trim().isNotEmpty) {
      urls.add(item.trim());
    } else if (item is Map) {
      final url = item['url'] ?? item['image_url'] ?? item['path'];
      if (url != null && url.toString().trim().isNotEmpty) {
        urls.add(url.toString().trim());
      }
    }
  }
  return urls;
}

List<PaymentRecordModel> _paymentHistory(dynamic raw, DateTime fallbackDate) {
  if (raw is! List) return const [];
  final records = <PaymentRecordModel>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final when = DateTime.tryParse(
          (map['received_at'] ?? map['created_at'] ?? map['paid_at'] ?? map['date'] ?? '').toString(),
        ) ??
        fallbackDate;
    final receivedBy = map['received_by'];
    final receiverName = receivedBy is Map
        ? (receivedBy['name'] ?? '').toString()
        : (receivedBy ?? '').toString();
    final source = (map['source'] ?? '').toString();
    final reference = [source, receiverName].where((part) => part.trim().isNotEmpty).join(' · ');
    records.add(
      PaymentRecordModel(
        id: (map['id'] ?? records.length + 1).toString(),
        date: when,
        amount: _amount(map['amount']),
        paymentMethod: (map['payment_method'] ?? map['paymentMethod'] ?? 'UPI').toString(),
        reference: reference,
        status: (map['status'] ?? 'PAID').toString(),
      ),
    );
  }
  return records;
}
