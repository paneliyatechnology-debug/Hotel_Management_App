import '../../../../core/widgets/status_badge.dart';

class RoomModel {
  final String id;
  final String roomNumber;
  final String floor;
  final String roomType; // e.g. 'Family Room', 'Couple Room', 'Deluxe Room'
  final double pricePerNight;
  final RoomStatus status;
  final String? currentGuestName;
  final String? currentGuestFolioId;
  final int maxOccupancy;
  final List<String> amenities;

  // Live API Telemetry & Metadata fields
  final String? roomTypeId;
  final String? hotelId;
  final double? customPricePerNight;
  final double? basePrice;
  final int bedCount;
  final String bedType;
  final int adultsCapacity;
  final int childrenCapacity;
  final int seatingCapacity;
  final int cleaningDurationMinutes;
  final bool gstEnabled;
  final double gstRate;
  final double cgstRate;
  final double sgstRate;
  final bool taxInclusive;
  final bool isAvailable;
  final bool isAvailableForDates;
  final String dateStatus;
  final String statusToday;
  final String actualDbStatus;
  final String overlapReason;
  final String notes;
  final List<String> images;
  final String roomTypeDescription;
  final String advanceBookingSummary;
  final List<dynamic> futureBookings;
  final String? requestedCheckInDate;
  final String? requestedCheckOutDate;
  final String keyCode;
  /// Physical rooms API: `current_booking_id` when status is OCCUPIED.
  final String? currentBookingId;
  final String hotelName;
  final DateTime? cleaningStartedAt;
  final bool isActive;

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
    this.roomTypeId,
    this.hotelId,
    this.customPricePerNight,
    this.basePrice,
    this.bedCount = 1,
    this.bedType = '1 King Size Bed',
    this.adultsCapacity = 2,
    this.childrenCapacity = 0,
    this.seatingCapacity = 2,
    this.cleaningDurationMinutes = 15,
    this.gstEnabled = true,
    this.gstRate = 18.0,
    this.cgstRate = 9.0,
    this.sgstRate = 9.0,
    this.taxInclusive = false,
    this.isAvailable = true,
    this.isAvailableForDates = true,
    this.dateStatus = 'AVAILABLE',
    this.statusToday = 'AVAILABLE',
    this.actualDbStatus = 'AVAILABLE',
    this.overlapReason = '',
    this.notes = '',
    this.images = const [],
    this.roomTypeDescription = '',
    this.advanceBookingSummary = '',
    this.futureBookings = const [],
    this.requestedCheckInDate,
    this.requestedCheckOutDate,
    this.keyCode = '',
    this.currentBookingId,
    this.hotelName = '',
    this.cleaningStartedAt,
    this.isActive = true,
  });

  /// Formats clean room number without `#` or prefix
  String get cleanRoomNumber =>
      roomNumber.replaceAll('#', '').replaceAll('Room', '').trim();

  /// User friendly capacity label: 'Max 2 Guests (+ 1 Kids)' or 'Max 2 Guests'
  String get capacityLabel =>
      'Max $adultsCapacity Guests${childrenCapacity > 0 ? " (+ $childrenCapacity Kids)" : ""}';

  /// User friendly bed info from the rooms `beds` list.
  String get bedInfoLabel {
    final label = bedType.trim();
    if (label.isEmpty) return bedCount > 0 ? '$bedCount Bed' : '';
    return label;
  }

  /// Whether GST tax applies
  bool get hasGst => gstEnabled && gstRate > 0;

  /// Rooms list puts GST on `data.hotel`, not on each room.
  RoomModel withHotelGst(Map<String, dynamic>? hotel) {
    if (hotel == null) return this;
    final rawEnabled = hotel['gst_enabled'] ?? hotel['gstEnabled'];
    final rawRate = hotel['tax_percentage'] ?? hotel['taxPercentage'];
    if (rawEnabled == null && rawRate == null) return this;
    final enabled = rawEnabled == true;
    final rate = rawRate is num ? rawRate.toDouble() : double.tryParse(rawRate?.toString() ?? '') ?? 0;
    if (!enabled || rate <= 0) {
      return copyWith(gstEnabled: false, gstRate: 0, cgstRate: 0, sgstRate: 0);
    }
    return copyWith(
      gstEnabled: true,
      gstRate: rate,
      cgstRate: rate / 2,
      sgstRate: rate / 2,
    );
  }

  RoomModel copyWith({
    String? id,
    String? roomNumber,
    String? floor,
    String? roomType,
    double? pricePerNight,
    RoomStatus? status,
    String? currentGuestName,
    String? currentGuestFolioId,
    bool clearGuest = false,
    int? maxOccupancy,
    List<String>? amenities,
    String? roomTypeId,
    String? hotelId,
    double? customPricePerNight,
    double? basePrice,
    int? bedCount,
    String? bedType,
    int? adultsCapacity,
    int? childrenCapacity,
    int? seatingCapacity,
    int? cleaningDurationMinutes,
    bool? gstEnabled,
    double? gstRate,
    double? cgstRate,
    double? sgstRate,
    bool? taxInclusive,
    bool? isAvailable,
    bool? isAvailableForDates,
    String? dateStatus,
    String? statusToday,
    String? actualDbStatus,
    String? overlapReason,
    String? notes,
    List<String>? images,
    String? roomTypeDescription,
    String? advanceBookingSummary,
    List<dynamic>? futureBookings,
    String? requestedCheckInDate,
    String? requestedCheckOutDate,
    String? keyCode,
    String? currentBookingId,
    bool clearCurrentBookingId = false,
    String? hotelName,
    DateTime? cleaningStartedAt,
    bool clearCleaningStartedAt = false,
    bool? isActive,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      floor: floor ?? this.floor,
      roomType: roomType ?? this.roomType,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      status: status ?? this.status,
      currentGuestName: clearGuest ? null : (currentGuestName ?? this.currentGuestName),
      currentGuestFolioId: clearGuest ? null : (currentGuestFolioId ?? this.currentGuestFolioId),
      maxOccupancy: maxOccupancy ?? this.maxOccupancy,
      amenities: amenities ?? this.amenities,
      roomTypeId: roomTypeId ?? this.roomTypeId,
      hotelId: hotelId ?? this.hotelId,
      customPricePerNight: customPricePerNight ?? this.customPricePerNight,
      basePrice: basePrice ?? this.basePrice,
      bedCount: bedCount ?? this.bedCount,
      bedType: bedType ?? this.bedType,
      adultsCapacity: adultsCapacity ?? this.adultsCapacity,
      childrenCapacity: childrenCapacity ?? this.childrenCapacity,
      seatingCapacity: seatingCapacity ?? this.seatingCapacity,
      cleaningDurationMinutes: cleaningDurationMinutes ?? this.cleaningDurationMinutes,
      gstEnabled: gstEnabled ?? this.gstEnabled,
      gstRate: gstRate ?? this.gstRate,
      cgstRate: cgstRate ?? this.cgstRate,
      sgstRate: sgstRate ?? this.sgstRate,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      isAvailable: isAvailable ?? this.isAvailable,
      isAvailableForDates: isAvailableForDates ?? this.isAvailableForDates,
      dateStatus: dateStatus ?? this.dateStatus,
      statusToday: statusToday ?? this.statusToday,
      actualDbStatus: actualDbStatus ?? this.actualDbStatus,
      overlapReason: overlapReason ?? this.overlapReason,
      notes: notes ?? this.notes,
      images: images ?? this.images,
      roomTypeDescription: roomTypeDescription ?? this.roomTypeDescription,
      advanceBookingSummary: advanceBookingSummary ?? this.advanceBookingSummary,
      futureBookings: futureBookings ?? this.futureBookings,
      requestedCheckInDate: requestedCheckInDate ?? this.requestedCheckInDate,
      requestedCheckOutDate: requestedCheckOutDate ?? this.requestedCheckOutDate,
      keyCode: keyCode ?? this.keyCode,
      currentBookingId: clearCurrentBookingId
          ? null
          : (currentBookingId ?? this.currentBookingId),
      hotelName: hotelName ?? this.hotelName,
      cleaningStartedAt: clearCleaningStartedAt
          ? null
          : (cleaningStartedAt ?? this.cleaningStartedAt),
      isActive: isActive ?? this.isActive,
    );
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final roomTypeData = json['roomType'];
    String typeName = 'Standard Room';
    String? typeId;
    double? basePrice;
    int adults = 2;
    int children = 0;
    int typeBedCount = 1;
    String typeBedType = '1 King Size Bed';
    List<String> roomAmenities = [];
    List<String> typeImages = [];
    String typeDescription = '';
    bool typeGstEnabled = true;
    double typeGstRate = 18.0;
    double typeCgstRate = 9.0;
    double typeSgstRate = 9.0;
    bool typeTaxInclusive = false;

    if (roomTypeData is Map<String, dynamic>) {
      typeId = roomTypeData['_id']?.toString() ?? roomTypeData['id']?.toString();
      typeName = roomTypeData['name']?.toString() ?? 'Standard Room';
      basePrice = (roomTypeData['basePrice'] as num?)?.toDouble() ??
          (roomTypeData['base_price'] as num?)?.toDouble();
      typeBedCount = (roomTypeData['bedCount'] as num?)?.toInt() ??
          (roomTypeData['bed_count'] as num?)?.toInt() ??
          1;
      typeBedType = roomTypeData['bedType']?.toString() ??
          roomTypeData['bed_type']?.toString() ??
          '1 King Size Bed';
      typeDescription = roomTypeData['description']?.toString() ?? '';
      typeGstEnabled = roomTypeData['gstEnabled'] as bool? ??
          roomTypeData['gst_enabled'] as bool? ??
          true;
      typeGstRate = (roomTypeData['gstRate'] as num?)?.toDouble() ??
          (roomTypeData['gst_rate'] as num?)?.toDouble() ??
          18.0;
      typeCgstRate = (roomTypeData['cgstRate'] as num?)?.toDouble() ?? 9.0;
      typeSgstRate = (roomTypeData['sgstRate'] as num?)?.toDouble() ?? 9.0;
      typeTaxInclusive = roomTypeData['taxInclusive'] as bool? ?? false;

      if (roomTypeData['capacity'] is Map) {
        final cap = Map<String, dynamic>.from(roomTypeData['capacity'] as Map);
        adults = (cap['adults'] as num?)?.toInt() ?? 2;
        children = (cap['children'] as num?)?.toInt() ?? 0;
      }
      if (roomTypeData['amenities'] is List) {
        roomAmenities.addAll((roomTypeData['amenities'] as List).map((e) => e.toString()));
      }
      if (roomTypeData['images'] is List) {
        typeImages.addAll((roomTypeData['images'] as List).map((e) => e.toString()));
      }
    } else if (roomTypeData is String && roomTypeData.isNotEmpty) {
      typeName = roomTypeData;
    }

    // Physical rooms API: flat room_type_name / room_type_id
    final flatTypeName = json['room_type_name']?.toString() ?? json['roomTypeName']?.toString();
    if (flatTypeName != null && flatTypeName.trim().isNotEmpty) {
      typeName = flatTypeName.trim();
    }
    typeId ??= json['room_type_id']?.toString() ?? json['roomTypeId']?.toString();

    // Room-level amenities (List or comma-separated String)
    if (json['amenities'] is String && (json['amenities'] as String).trim().isNotEmpty) {
      roomAmenities = (json['amenities'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['amenities'] is List && (json['amenities'] as List).isNotEmpty) {
      roomAmenities = (json['amenities'] as List).map((e) => e.toString()).toList();
    }

    if (typeImages.isEmpty && json['images'] is List) {
      for (final item in json['images'] as List) {
        if (item is String && item.trim().isNotEmpty) {
          typeImages.add(item.trim());
        } else if (item is Map) {
          final url = (item['url'] ?? item['image_url'] ?? item['path'] ?? '').toString().trim();
          if (url.isNotEmpty) typeImages.add(url);
        }
      }
    }

    // Price: custom_price_per_night takes precedence
    final rawCustomPrice = json['custom_price_per_night'] ?? json['customPricePerNight'];
    final customPrice = (rawCustomPrice is num)
        ? rawCustomPrice.toDouble()
        : double.tryParse(rawCustomPrice?.toString() ?? '');
    double resolvedPrice;
    if (customPrice != null && customPrice > 0) {
      resolvedPrice = customPrice;
    } else if (basePrice != null && basePrice > 0) {
      resolvedPrice = basePrice;
    } else if (customPrice != null) {
      resolvedPrice = customPrice;
    } else if (basePrice != null) {
      resolvedPrice = basePrice;
    } else {
      resolvedPrice = 4000.0;
    }

    // beds: [{ id, bed_type, bed_count }, ...]
    var bedCount = typeBedCount;
    var bedType = typeBedType;
    final bedsLabel = _bedsLabel(json['beds']);
    if (bedsLabel != null) {
      bedCount = bedsLabel.count;
      bedType = bedsLabel.label;
    } else {
      final rawBedCount = json['bed_count'] ?? json['bedCount'];
      bedCount = (rawBedCount is num)
          ? rawBedCount.toInt()
          : (int.tryParse(rawBedCount?.toString() ?? '') ?? typeBedCount);
      bedType = json['bed_type']?.toString() ?? json['bedType']?.toString() ?? typeBedType;
    }

    final rawSeating = json['seating_capacity'] ?? json['seatingCapacity'];
    final seating = (rawSeating is num)
        ? rawSeating.toInt()
        : (int.tryParse(rawSeating?.toString() ?? '') ?? (adults + children));

    // status: AVAILABLE | OCCUPIED | CLEANING | MAINTENANCE
    final rawStatus = (json['status'] ?? 'AVAILABLE').toString().trim().toUpperCase();
    final parsedStatus = switch (rawStatus) {
      'OCCUPIED' || 'BOOKED' => RoomStatus.occupied,
      'CLEANING' => RoomStatus.cleaning,
      'MAINTENANCE' || 'BLOCKED' => RoomStatus.maintenance,
      _ => RoomStatus.available,
    };
    final roomIsAvailable = parsedStatus == RoomStatus.available;

    final rawRoomNum = (json['room_number'] ?? json['roomNumber'] ?? '').toString().trim();
    final formattedRoomNum = rawRoomNum.isEmpty
        ? ''
        : (rawRoomNum.startsWith('#') ? rawRoomNum : '#$rawRoomNum');
    final rawFloor = (json['floor'] ?? '1').toString().trim();
    final floorStr =
        rawFloor.toLowerCase().contains('floor') ? rawFloor : 'Floor $rawFloor';

    final guest = _readGuestName(json);
    final bookingIdRaw = json['current_booking_id'] ?? json['currentBookingId'];
    final bookingId = bookingIdRaw == null || '$bookingIdRaw'.trim().isEmpty || '$bookingIdRaw' == 'null'
        ? null
        : '$bookingIdRaw'.trim();

    String? inDate;
    String? outDate;
    if (json['requestedStayPeriod'] is Map) {
      final period = Map<String, dynamic>.from(json['requestedStayPeriod'] as Map);
      inDate = period['checkInDate']?.toString();
      outDate = period['checkOutDate']?.toString();
    }

    final calculatedCapacity = (adults + children) > 0 ? (adults + children) : 2;
    final hotelIdRaw = json['hotel_id'] ?? (json['hotel'] is Map ? (json['hotel'] as Map)['id'] : json['hotel']);
    final hotelName = (json['hotel_name'] ??
            json['hotelName'] ??
            (json['hotel'] is Map ? (json['hotel'] as Map)['name'] : null) ??
            '')
        .toString()
        .trim();
    final isActive = json['is_active'] == true ||
        json['isActive'] == true ||
        (json['is_active'] == null && json['isActive'] == null && json['deleted_at'] == null);
    final cleaningStarted = _readDateTime(
      json['cleaning_started_at'] ?? json['cleaningStartedAt'],
    );

    // is_active = room record enabled; availability comes from status
    final explicitAvailable = json['isAvailable'] ?? json['is_available'];
    final resolvedAvailable = explicitAvailable is bool ? explicitAvailable : roomIsAvailable;
    final explicitAvailableForDates = json['isAvailableForDates'] ?? json['is_available_for_dates'];
    final resolvedAvailableForDates =
        explicitAvailableForDates is bool ? explicitAvailableForDates : roomIsAvailable;

    return RoomModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? formattedRoomNum,
      roomNumber: formattedRoomNum,
      floor: floorStr,
      roomType: typeName,
      pricePerNight: resolvedPrice,
      status: parsedStatus,
      currentGuestName:
          (guest != null && guest.trim().isNotEmpty) ? guest.trim() : null,
      currentGuestFolioId: bookingId,
      maxOccupancy: calculatedCapacity,
      amenities: roomAmenities.isNotEmpty
          ? roomAmenities
          : const ['Wi-Fi', 'AC', 'TV', 'En-suite Bath'],
      roomTypeId: typeId,
      hotelId: hotelIdRaw?.toString(),
      customPricePerNight: customPrice,
      basePrice: basePrice,
      bedCount: bedCount,
      bedType: bedType,
      adultsCapacity: adults,
      childrenCapacity: children,
      seatingCapacity: seating,
      cleaningDurationMinutes:
          _readInt(json['cleaning_duration_minutes'] ?? json['cleaningDurationMinutes']) ?? 15,
      gstEnabled: json['gstEnabled'] as bool? ?? json['gst_enabled'] as bool? ?? typeGstEnabled,
      gstRate: (json['gstRate'] as num?)?.toDouble() ??
          (json['gst_rate'] as num?)?.toDouble() ??
          typeGstRate,
      cgstRate: (json['cgstRate'] as num?)?.toDouble() ?? typeCgstRate,
      sgstRate: (json['sgstRate'] as num?)?.toDouble() ?? typeSgstRate,
      taxInclusive: json['taxInclusive'] as bool? ?? typeTaxInclusive,
      isAvailable: resolvedAvailable,
      isAvailableForDates: resolvedAvailableForDates,
      dateStatus: json['dateStatus']?.toString() ?? rawStatus,
      statusToday: json['statusToday']?.toString() ?? rawStatus,
      actualDbStatus: json['actualDbStatus']?.toString() ?? rawStatus,
      overlapReason: json['overlapReason']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      images: typeImages,
      roomTypeDescription: typeDescription,
      advanceBookingSummary: json['advanceBookingSummary']?.toString() ?? '',
      futureBookings: (json['futureBookings'] as List<dynamic>?) ?? const [],
      requestedCheckInDate: inDate,
      requestedCheckOutDate: outDate,
      keyCode: (json['key_code'] ?? json['keyCode'] ?? '').toString().trim(),
      currentBookingId: bookingId,
      hotelName: hotelName,
      cleaningStartedAt: cleaningStarted,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_number': cleanRoomNumber,
      'floor': floor,
      'room_type_id': roomTypeId,
      'room_type_name': roomType,
      'hotel_id': hotelId,
      'hotel_name': hotelName,
      'custom_price_per_night': customPricePerNight ?? pricePerNight,
      'status': status.name.toUpperCase(),
      'current_booking_id': currentBookingId,
      'guestName': currentGuestName,
      'seating_capacity': seatingCapacity,
      'bed_count': bedCount,
      'bed_type': bedType,
      'cleaning_duration_minutes': cleaningDurationMinutes,
      'cleaning_started_at': cleaningStartedAt?.toIso8601String(),
      'gstEnabled': gstEnabled,
      'gstRate': gstRate,
      'cgstRate': cgstRate,
      'sgstRate': sgstRate,
      'taxInclusive': taxInclusive,
      'is_active': isActive,
      'isAvailable': isAvailable,
      'dateStatus': dateStatus,
      'notes': notes,
      'key_code': keyCode,
      'amenities': amenities,
      'images': images,
    };
  }
}

String? _readGuestName(Map<String, dynamic> json) {
  for (final key in const [
    'guestName',
    'guest_name',
    'primary_guest_name',
    'primaryGuestName',
    'current_guest_name',
    'currentGuestName',
  ]) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  final booking = json['booking'] ?? json['current_booking'] ?? json['active_booking'];
  if (booking is Map) {
    for (final key in const [
      'primary_guest_name',
      'primaryGuestName',
      'guest_name',
      'guestName',
    ]) {
      final value = booking[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
  }
  return null;
}

int? _readInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _readDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final raw = value.toString().trim();
  if (raw.isEmpty || raw.toLowerCase() == 'null') return null;
  return DateTime.tryParse(raw);
}

({int count, String label})? _bedsLabel(dynamic raw) {
  if (raw is! List || raw.isEmpty) return null;
  final parts = <String>[];
  var total = 0;
  for (final item in raw) {
    if (item is! Map) continue;
    final count = (item['bed_count'] as num?)?.toInt() ??
        (item['bedCount'] as num?)?.toInt() ??
        int.tryParse('${item['bed_count'] ?? item['bedCount'] ?? ''}') ??
        1;
    final line = _bedLine(count, '${item['bed_type'] ?? item['bedType'] ?? ''}');
    if (line.isEmpty) continue;
    total += count < 1 ? 1 : count;
    parts.add(line);
  }
  if (parts.isEmpty) return null;
  return (count: total, label: parts.join(', '));
}

String _bedLine(int count, String rawType) {
  final type = rawType.trim();
  if (type.isEmpty) return '';
  if (RegExp(r'^\d+\s+').hasMatch(type)) return type;
  final safeCount = count < 1 ? 1 : count;
  return '$safeCount ${_displayBedType(type)}';
}

String _displayBedType(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'king':
      return 'King Size Bed';
    case 'queen':
      return 'Queen Size Bed';
    case 'single':
      return 'Single Bed';
    case 'double':
      return 'Double Bed';
    case 'super king':
      return 'Super King Bed';
    case 'extra mattress':
      return 'Extra Mattress';
    default:
      return raw.trim();
  }
}
