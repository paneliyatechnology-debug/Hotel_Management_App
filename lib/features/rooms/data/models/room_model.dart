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
  });

  /// Formats clean room number without `#` or prefix
  String get cleanRoomNumber =>
      roomNumber.replaceAll('#', '').replaceAll('Room', '').trim();

  /// User friendly capacity label: 'Max 2 Guests (+ 1 Kids)' or 'Max 2 Guests'
  String get capacityLabel =>
      'Max $adultsCapacity Guests${childrenCapacity > 0 ? " (+ $childrenCapacity Kids)" : ""}';

  /// User friendly bed info label: '1 Bed (1 King Size Bed)'
  String get bedInfoLabel => '$bedCount Bed ($bedType)';

  /// Whether GST tax applies
  bool get hasGst => gstEnabled && gstRate > 0;

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
      basePrice = (roomTypeData['basePrice'] as num?)?.toDouble();
      typeBedCount = (roomTypeData['bedCount'] as num?)?.toInt() ?? 1;
      typeBedType = roomTypeData['bedType']?.toString() ?? '1 King Size Bed';
      typeDescription = roomTypeData['description']?.toString() ?? '';
      typeGstEnabled = roomTypeData['gstEnabled'] as bool? ?? true;
      typeGstRate = (roomTypeData['gstRate'] as num?)?.toDouble() ?? 18.0;
      typeCgstRate = (roomTypeData['cgstRate'] as num?)?.toDouble() ?? 9.0;
      typeSgstRate = (roomTypeData['sgstRate'] as num?)?.toDouble() ?? 9.0;
      typeTaxInclusive = roomTypeData['taxInclusive'] as bool? ?? false;

      if (roomTypeData['capacity'] is Map) {
        final cap = roomTypeData['capacity'] as Map<String, dynamic>;
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

    // Room-level amenities override or supplement
    if (json['amenities'] is List && (json['amenities'] as List).isNotEmpty) {
      roomAmenities = (json['amenities'] as List).map((e) => e.toString()).toList();
    }

    // Price resolution: customPricePerNight takes precedence over roomType.basePrice
    final customPrice = (json['customPricePerNight'] as num?)?.toDouble();
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

    // Bed configuration
    final bedCount = (json['bedCount'] as num?)?.toInt() ?? typeBedCount;
    final bedType = json['bedType']?.toString() ?? typeBedType;

    // Seating capacity
    final seating = (json['seatingCapacity'] as num?)?.toInt() ?? (adults + children);

    // Status parsing
    final rawStatus = json['status']?.toString().toUpperCase() ?? 'AVAILABLE';
    RoomStatus parsedStatus = RoomStatus.available;
    if (rawStatus == 'OCCUPIED' || rawStatus == 'BOOKED') {
      parsedStatus = RoomStatus.occupied;
    } else if (rawStatus == 'CLEANING') {
      parsedStatus = RoomStatus.cleaning;
    } else if (rawStatus == 'MAINTENANCE' || rawStatus == 'BLOCKED') {
      parsedStatus = RoomStatus.maintenance;
    }

    final rawRoomNum = json['roomNumber']?.toString() ?? '';
    final formattedRoomNum =
        rawRoomNum.startsWith('#') ? rawRoomNum : '#$rawRoomNum';
    final rawFloor = json['floor']?.toString() ?? '1';
    final floorStr =
        rawFloor.toLowerCase().contains('floor') ? rawFloor : 'Floor $rawFloor';

    final guest = json['guestName']?.toString();

    // Stay dates if provided
    String? inDate;
    String? outDate;
    if (json['requestedStayPeriod'] is Map) {
      final period = json['requestedStayPeriod'] as Map<String, dynamic>;
      inDate = period['checkInDate']?.toString();
      outDate = period['checkOutDate']?.toString();
    }

    final calculatedCapacity = (adults + children) > 0 ? (adults + children) : 2;

    return RoomModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? formattedRoomNum,
      roomNumber: formattedRoomNum,
      floor: floorStr,
      roomType: typeName,
      pricePerNight: resolvedPrice,
      status: parsedStatus,
      currentGuestName:
          (guest != null && guest.trim().isNotEmpty) ? guest.trim() : null,
      maxOccupancy: calculatedCapacity,
      amenities: roomAmenities.isNotEmpty
          ? roomAmenities
          : const ['Wi-Fi', 'AC', 'TV', 'En-suite Bath'],
      roomTypeId: typeId,
      hotelId: json['hotel']?.toString(),
      customPricePerNight: customPrice,
      basePrice: basePrice,
      bedCount: bedCount,
      bedType: bedType,
      adultsCapacity: adults,
      childrenCapacity: children,
      seatingCapacity: seating,
      cleaningDurationMinutes: (json['cleaningDurationMinutes'] as num?)?.toInt() ?? 15,
      gstEnabled: json['gstEnabled'] as bool? ?? typeGstEnabled,
      gstRate: (json['gstRate'] as num?)?.toDouble() ?? typeGstRate,
      cgstRate: (json['cgstRate'] as num?)?.toDouble() ?? typeCgstRate,
      sgstRate: (json['sgstRate'] as num?)?.toDouble() ?? typeSgstRate,
      taxInclusive: json['taxInclusive'] as bool? ?? typeTaxInclusive,
      isAvailable: json['isAvailable'] == true,
      isAvailableForDates: json['isAvailableForDates'] == true,
      dateStatus: json['dateStatus']?.toString() ?? 'AVAILABLE',
      statusToday: json['statusToday']?.toString() ?? 'AVAILABLE',
      actualDbStatus: json['actualDbStatus']?.toString() ?? 'AVAILABLE',
      overlapReason: json['overlapReason']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      images: typeImages,
      roomTypeDescription: typeDescription,
      advanceBookingSummary: json['advanceBookingSummary']?.toString() ?? '',
      futureBookings: (json['futureBookings'] as List<dynamic>?) ?? const [],
      requestedCheckInDate: inDate,
      requestedCheckOutDate: outDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomNumber': cleanRoomNumber,
      'floor': floor,
      'roomType': {
        '_id': roomTypeId,
        'name': roomType,
        'basePrice': basePrice,
        'bedCount': bedCount,
        'bedType': bedType,
        'capacity': {
          'adults': adultsCapacity,
          'children': childrenCapacity,
        },
        'amenities': amenities,
        'images': images,
        'description': roomTypeDescription,
      },
      'pricePerNight': pricePerNight,
      'customPricePerNight': customPricePerNight,
      'status': status.name.toUpperCase(),
      'guestName': currentGuestName,
      'seatingCapacity': seatingCapacity,
      'bedCount': bedCount,
      'bedType': bedType,
      'cleaningDurationMinutes': cleaningDurationMinutes,
      'gstEnabled': gstEnabled,
      'gstRate': gstRate,
      'cgstRate': cgstRate,
      'sgstRate': sgstRate,
      'taxInclusive': taxInclusive,
      'isAvailable': isAvailable,
      'dateStatus': dateStatus,
      'notes': notes,
    };
  }
}
