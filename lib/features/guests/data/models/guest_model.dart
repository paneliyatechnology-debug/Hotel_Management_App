import 'package:flutter/foundation.dart';

enum GuestStatus {
  inHouse,
  checkedOut,
  cancelled,
  registered,
}

extension GuestStatusX on GuestStatus {
  String get label {
    switch (this) {
      case GuestStatus.inHouse:
        return 'IN-HOUSE';
      case GuestStatus.checkedOut:
        return 'CHECKED-OUT';
      case GuestStatus.cancelled:
        return 'CANCELLED';
      case GuestStatus.registered:
        return 'REGISTERED';
    }
  }
}

class KycDetailsModel {
  final String idType; // 'Aadhaar Card', 'Passport', 'Driving Licence', 'Voter ID', 'Other'
  final String idNumber;
  final bool isVerified;
  final String? documentFrontUrl;
  final String? documentBackUrl;
  final String nationality;

  const KycDetailsModel({
    required this.idType,
    required this.idNumber,
    this.isVerified = true,
    this.documentFrontUrl,
    this.documentBackUrl,
    this.nationality = 'Indian',
  });

  String get maskedIdNumber {
    if (idNumber.length > 4) {
      return '•••• •••• ${idNumber.substring(idNumber.length - 4)}';
    }
    return idNumber;
  }

  String? get frontDocumentPath => documentFrontUrl;
  String? get backDocumentPath => documentBackUrl;

  factory KycDetailsModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['idType'] ?? 'AADHAAR').toString().toUpperCase();
    String formattedType;
    if (rawType.contains('AADHAAR')) {
      formattedType = 'Aadhaar Card';
    } else if (rawType.contains('PASSPORT')) {
      formattedType = 'Passport';
    } else if (rawType.contains('DRIVING') || rawType.contains('DL')) {
      formattedType = 'Driving Licence';
    } else if (rawType.contains('VOTER')) {
      formattedType = 'Voter ID';
    } else {
      formattedType = json['idType']?.toString().isNotEmpty == true
          ? json['idType'].toString()
          : 'Government ID';
    }

    final isVerified = json['verificationStatus']?.toString().toUpperCase() == 'VERIFIED' ||
        json['idVerified'] == true;

    return KycDetailsModel(
      idType: formattedType,
      idNumber: (json['idNumber'] ?? '').toString(),
      isVerified: isVerified,
      documentFrontUrl: json['frontImage']?.toString(),
      documentBackUrl: json['backImage']?.toString(),
      nationality: (json['nationality'] ?? 'Indian').toString(),
    );
  }
}

class HistoricalStayModel {
  final String stayId;
  final String bookingId;
  final DateTime bookingDate;
  final String bookingSource; // 'Direct / Walk-In', 'MakeMyTrip', 'Booking.com', 'Corporate'
  final String bookingStatus; // 'Confirmed', 'Completed', 'Cancelled'
  final String roomNumber;
  final String floor;
  final String roomCategory;
  final DateTime checkInDate;
  final String checkInTime;
  final DateTime checkOutDate;
  final String checkOutTime;
  final int numberOfGuests;
  final GuestStatus status;

  // Billing
  final double roomCharges;
  final double extraCharges;
  final double discount;
  final double tax;
  final double totalAmount;

  // Payment
  final double paidAmount;
  final double pendingAmount;
  final String paymentMethod; // 'UPI', 'Credit Card', 'Cash', 'Net Banking'
  final String paymentStatus; // 'Paid', 'Partially Paid', 'Pending'

  // Activity Audit
  final String checkedInBy;
  final String? checkedOutBy;
  final DateTime activityTimestamp;

  const HistoricalStayModel({
    required this.stayId,
    required this.bookingId,
    required this.bookingDate,
    required this.bookingSource,
    required this.bookingStatus,
    required this.roomNumber,
    required this.floor,
    required this.roomCategory,
    required this.checkInDate,
    required this.checkInTime,
    required this.checkOutDate,
    required this.checkOutTime,
    required this.numberOfGuests,
    required this.status,
    required this.roomCharges,
    this.extraCharges = 0,
    this.discount = 0,
    required this.tax,
    required this.totalAmount,
    required this.paidAmount,
    this.pendingAmount = 0,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.checkedInBy,
    this.checkedOutBy,
    required this.activityTimestamp,
  });

  int get stayNights {
    final diff = checkOutDate.difference(checkInDate).inDays;
    return diff <= 0 ? 1 : diff;
  }
}

@immutable
class GuestProfileModel {
  final String id;
  final String fullName;
  final String mobile;
  final String email;
  final String gender;
  final DateTime dateOfBirth;
  final String address;
  final String city;
  final String state;
  final String nationality;
  final KycDetailsModel kyc;
  final HistoricalStayModel? currentStay;
  final List<HistoricalStayModel> stayHistory;
  final GuestStatus currentStatus;
  final int totalLifetimeStays;
  final double totalLifetimeSpent;

  // Backend API specific fields
  final String rawStatus;
  final String roomAssigned;
  final String activeBookingNumber;
  final String paymentStatus;
  final double balanceAmount;
  final double paidAmount;
  final double totalAmount;
  final double advanceAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String bookingRecordId;

  const GuestProfileModel({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.gender,
    required this.dateOfBirth,
    required this.address,
    required this.city,
    required this.state,
    this.nationality = 'Indian',
    required this.kyc,
    this.currentStay,
    required this.stayHistory,
    required this.currentStatus,
    required this.totalLifetimeStays,
    required this.totalLifetimeSpent,
    this.rawStatus = '',
    this.roomAssigned = '',
    this.activeBookingNumber = '',
    this.paymentStatus = 'PENDING',
    this.balanceAmount = 0.0,
    this.paidAmount = 0.0,
    this.totalAmount = 0.0,
    this.advanceAmount = 0.0,
    this.createdAt,
    this.updatedAt,
    this.bookingRecordId = '',
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'G';
  }

  String get name => fullName;
  KycDetailsModel get kycDetails => kyc;
  GuestStatus get status => currentStatus;
  int get stayCount => totalLifetimeStays;

  String get lastRoomNumber {
    if (roomAssigned.isNotEmpty &&
        roomAssigned != 'Not Assigned' &&
        roomAssigned != 'N/A') {
      return roomAssigned;
    }
    if (currentStay != null) return currentStay!.roomNumber;
    if (stayHistory.isNotEmpty) return stayHistory.first.roomNumber;
    return roomAssigned.isNotEmpty ? roomAssigned : '101';
  }

  String get lastRoomCategory =>
      currentStay?.roomCategory ??
      (stayHistory.isNotEmpty
          ? stayHistory.first.roomCategory
          : 'Standard Room');

  DateTime get lastCheckInDate =>
      currentStay?.checkInDate ??
      (stayHistory.isNotEmpty
          ? stayHistory.first.checkInDate
          : createdAt ?? DateTime.now());

  DateTime get lastCheckOutDate =>
      currentStay?.checkOutDate ??
      (stayHistory.isNotEmpty
          ? stayHistory.first.checkOutDate
          : createdAt?.add(const Duration(days: 1)) ?? DateTime.now());

  factory GuestProfileModel.fromJson(Map<String, dynamic> json) {
    // 1. Check for nested guest Map from booking API
    final guestData = json['guest'] is Map<String, dynamic>
        ? json['guest'] as Map<String, dynamic>
        : (json['guest'] is Map ? Map<String, dynamic>.from(json['guest'] as Map) : null);

    // 2. Status parsing
    final rawStatus = (json['booking_status'] ?? json['status'] ?? '').toString().toUpperCase().trim();
    GuestStatus status;
    if (rawStatus == 'IN_HOUSE' ||
        rawStatus == 'IN-HOUSE' ||
        rawStatus == 'CHECKED_IN' ||
        rawStatus == 'OCCUPIED') {
      status = GuestStatus.inHouse;
    } else if (rawStatus == 'CHECKED_OUT' ||
        rawStatus == 'CHECKED-OUT' ||
        rawStatus == 'COMPLETED') {
      status = GuestStatus.checkedOut;
    } else if (rawStatus == 'CANCELLED' || rawStatus == 'CANCELED') {
      status = GuestStatus.cancelled;
    } else if (rawStatus == 'REGISTERED') {
      status = GuestStatus.registered;
    } else {
      status = GuestStatus.registered;
    }

    // 3. KYC parsing
    final idProofMap = guestData?['idProof'] is Map
        ? Map<String, dynamic>.from(guestData!['idProof'] as Map)
        : (json['idProof'] is Map ? Map<String, dynamic>.from(json['idProof'] as Map) : null);

    final rawIdType = (idProofMap?['idType'] ??
            guestData?['govtIdType'] ??
            guestData?['idType'] ??
            json['govtIdType'] ??
            json['idType'] ??
            'AADHAAR')
        .toString();
    final idNumber = (idProofMap?['idNumber'] ??
            guestData?['govtIdNumber'] ??
            guestData?['idNumber'] ??
            json['govtIdNumber'] ??
            json['idNumber'] ??
            '')
        .toString();
    final isVerified = (idProofMap?['verificationStatus']
                ?.toString()
                .toUpperCase() ==
            'VERIFIED') ||
        (json['idVerified'] == true);

    String formattedIdType;
    final upperIdType = rawIdType.toUpperCase();
    if (upperIdType.contains('AADHAAR')) {
      formattedIdType = 'Aadhaar Card';
    } else if (upperIdType.contains('PASSPORT')) {
      formattedIdType = 'Passport';
    } else if (upperIdType.contains('DRIVING') || upperIdType.contains('DL')) {
      formattedIdType = 'Driving Licence';
    } else if (upperIdType.contains('VOTER')) {
      formattedIdType = 'Voter ID';
    } else {
      formattedIdType = rawIdType.isNotEmpty ? rawIdType : 'Government ID';
    }

    final kyc = KycDetailsModel(
      idType: formattedIdType,
      idNumber: idNumber.isNotEmpty ? idNumber : 'Pending ID',
      isVerified: isVerified,
      documentFrontUrl: (idProofMap?['frontImage'] ?? guestData?['frontImage'] ?? json['frontImage'] ?? '').toString().isNotEmpty
          ? (idProofMap?['frontImage'] ?? guestData?['frontImage'] ?? json['frontImage']).toString()
          : null,
      documentBackUrl: (idProofMap?['backImage'] ?? guestData?['backImage'] ?? json['backImage'] ?? '').toString().isNotEmpty
          ? (idProofMap?['backImage'] ?? guestData?['backImage'] ?? json['backImage']).toString()
          : null,
      nationality:
          (guestData?['nationality'] ?? guestData?['country'] ?? json['nationality'] ?? json['country'] ?? 'Indian').toString(),
    );

    // 4. Room & Room Category
    final roomData = json['room'] is Map
        ? Map<String, dynamic>.from(json['room'] as Map)
        : (json['rooms'] is List && (json['rooms'] as List).isNotEmpty && (json['rooms'] as List).first is Map
            ? Map<String, dynamic>.from((json['rooms'] as List).first as Map)
            : null);
    final roomTypeData = json['roomType'];

    final roomAssigned = (json['roomNumber'] ??
            roomData?['roomNumber'] ??
            roomData?['room_number'] ??
            (json['roomNumbers'] is List && (json['roomNumbers'] as List).isNotEmpty
                ? (json['roomNumbers'] as List).first.toString()
                : null) ??
            json['roomAssigned'] ??
            'Not Assigned')
        .toString();

    final roomCategoryName = (roomTypeData is Map
            ? roomTypeData['name']
            : null) ??
        roomData?['room_type_name'] ??
        json['roomCategory'] ??
        (roomTypeData is String && roomTypeData.isNotEmpty ? roomTypeData : 'Standard Room');

    final floorStr = (roomData?['floor'] != null
        ? 'Floor ${roomData!['floor']}'
        : (json['floor'] ?? 'Floor 1')).toString();

    // 5. Timestamps & Dates
    final createdAtRaw = json['createdAt']?.toString();
    final updatedAtRaw = json['updatedAt']?.toString();
    final createdAt =
        createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;
    final updatedAt =
        updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw) : null;

    final checkInRaw = json['check_in_date']?.toString() ?? json['checkInDate']?.toString() ?? json['checkInDateRaw']?.toString();
    final checkOutRaw = json['check_out_date']?.toString() ?? json['checkOutDate']?.toString() ?? json['checkOutDateRaw']?.toString();
    final actualCheckInRaw = json['actualCheckIn']?.toString();
    final actualCheckOutRaw = json['actualCheckOut']?.toString();

    DateTime checkInDate = (checkInRaw != null
            ? DateTime.tryParse(checkInRaw)
            : null) ??
        (actualCheckInRaw != null
            ? DateTime.tryParse(actualCheckInRaw)
            : null) ??
        createdAt ??
        DateTime.now();

    DateTime checkOutDate = (checkOutRaw != null
            ? DateTime.tryParse(checkOutRaw)
            : null) ??
        (actualCheckOutRaw != null
            ? DateTime.tryParse(actualCheckOutRaw)
            : null) ??
        checkInDate.add(const Duration(days: 1));

    final bookingNumber = (json['booking_number'] ?? json['bookingNumber'] ?? json['activeBookingNumber'] ?? 'N/A').toString();

    final totalAmount = (json['totalAmount'] as num?)?.toDouble() ??
        (json['baseAmount'] as num?)?.toDouble() ??
        0.0;
    final paidAmount = (json['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final balanceAmount = (json['dueAmount'] as num?)?.toDouble() ??
        (json['balanceAmount'] as num?)?.toDouble() ??
        0.0;
    final advanceAmount =
        (json['advanceAmount'] as num?)?.toDouble() ?? 0.0;
    final paymentStatus =
        (json['paymentStatus'] ?? 'PENDING').toString().toUpperCase();

    final accompanyingCount = json['accompanyingGuests'] is List
        ? (json['accompanyingGuests'] as List).length
        : 0;

    final hasStayDetails = roomAssigned != 'Not Assigned' ||
        bookingNumber != 'N/A' ||
        status != GuestStatus.registered;

    HistoricalStayModel? stayModel;
    if (hasStayDetails) {
      stayModel = HistoricalStayModel(
        stayId: 'STAY-${json['_id'] ?? DateTime.now().millisecondsSinceEpoch}',
        bookingId: bookingNumber != 'N/A' && bookingNumber.isNotEmpty
            ? bookingNumber
            : 'BK-${(json['_id']?.toString() ?? '100000').substring(0, 6)}',
        bookingDate: createdAt ?? DateTime.now(),
        bookingSource: (json['bookingSource'] ?? 'Direct / Walk-In').toString(),
        bookingStatus: rawStatus.isNotEmpty ? rawStatus : 'Confirmed',
        roomNumber: roomAssigned != 'Not Assigned' ? roomAssigned : '101',
        floor: floorStr,
        roomCategory: roomCategoryName.toString(),
        checkInDate: checkInDate,
        checkInTime: (json['checkInTime'] ?? '14:00').toString(),
        checkOutDate: checkOutDate,
        checkOutTime: (json['checkOutTime'] ?? '12:00').toString(),
        numberOfGuests: (json['guestsCount'] is Map
            ? (((json['guestsCount']['adults'] as num?)?.toInt() ?? 1) +
                ((json['guestsCount']['children'] as num?)?.toInt() ?? 0))
            : accompanyingCount + 1),
        status: status == GuestStatus.registered
            ? GuestStatus.checkedOut
            : status,
        roomCharges: totalAmount > 0 ? totalAmount : paidAmount,
        tax: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
        totalAmount: totalAmount > 0 ? totalAmount : paidAmount,
        paidAmount: paidAmount,
        pendingAmount: balanceAmount,
        paymentMethod: (json['paymentMethod'] ?? 'UPI').toString(),
        paymentStatus: paymentStatus,
        checkedInBy: 'Front Desk',
        checkedOutBy: actualCheckOutRaw != null ? 'Front Desk' : null,
        activityTimestamp: updatedAt ?? createdAt ?? DateTime.now(),
      );
    }

    final stayHistory = <HistoricalStayModel>[];
    if (stayModel != null) {
      stayHistory.add(stayModel);
    }

    final totalLifetimeStays = (json['totalVisits'] as num?)?.toInt() ??
        (stayHistory.isNotEmpty ? stayHistory.length : 1);
    final totalSpent = (json['totalSpent'] as num?)?.toDouble() ??
        (totalAmount > 0 ? totalAmount : paidAmount);

    final guestId = (guestData?['_id'] ?? json['guestId'] ?? json['_id'] ?? json['id'] ?? '').toString();
    final fullName = (guestData?['fullName'] ??
            guestData?['name'] ??
            json['primary_guest_name'] ??
            json['fullName'] ??
            json['name'] ??
            'Guest')
        .toString()
        .trim();
    final mobile = (guestData?['mobileNumber'] ??
            guestData?['phone'] ??
            json['mobile_number'] ??
            json['mobileNumber'] ??
            json['phone'] ??
            '')
        .toString()
        .trim();
    final email = (guestData?['email'] ?? json['email'] ?? '').toString().trim();
    final gender = (guestData?['gender'] ?? json['gender'] ?? 'Not Specified').toString();
    final address = (guestData?['address'] ?? json['address'] ?? '').toString();
    final city = (guestData?['city'] ?? json['city'] ?? '').toString();
    final state = (guestData?['state'] ?? json['state'] ?? '').toString();
    final guestNationality = (guestData?['nationality'] ?? guestData?['country'] ?? json['nationality'] ?? json['country'] ?? 'Indian').toString();

    return GuestProfileModel(
      id: guestId,
      fullName: fullName,
      mobile: mobile,
      email: email,
      gender: gender,
      dateOfBirth: DateTime(1995, 1, 1),
      address: address,
      city: city,
      state: state,
      nationality: guestNationality,
      kyc: kyc,
      currentStay: status == GuestStatus.inHouse ? stayModel : null,
      stayHistory: stayHistory,
      currentStatus: status,
      totalLifetimeStays: totalLifetimeStays,
      totalLifetimeSpent: totalSpent,
      rawStatus: rawStatus,
      roomAssigned: roomAssigned,
      activeBookingNumber: bookingNumber,
      paymentStatus: paymentStatus,
      balanceAmount: balanceAmount,
      paidAmount: paidAmount,
      totalAmount: totalAmount,
      advanceAmount: advanceAmount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      bookingRecordId: (json['id'] ?? json['_id'] ?? guestId).toString(),
    );
  }
}

/// Helper model for parsing the full guests API response
class GuestsApiResponse {
  final bool success;
  final int total;
  final int count;
  final int page;
  final int totalPages;
  final List<GuestProfileModel> data;

  const GuestsApiResponse({
    required this.success,
    required this.total,
    required this.count,
    required this.page,
    required this.totalPages,
    required this.data,
  });

  factory GuestsApiResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List? ?? [];
    return GuestsApiResponse(
      success: json['success'] == true,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      count: (json['count'] as num?)?.toInt() ?? list.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      data: list
          .map((item) =>
              GuestProfileModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
