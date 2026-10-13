class RoomTypeModel {
  final String id;
  final String hotel;
  final String name;
  final String description;
  final double basePrice;
  final int bedCount;
  final String bedType;
  final int adults;
  final int children;
  final bool gstEnabled;
  final double gstRate;
  final double cgstRate;
  final double sgstRate;
  final bool taxInclusive;
  final List<String> amenities;
  final List<String> images;
  final bool isActive;
  final bool isDeleted;
  final String? createdAt;
  final String? updatedAt;

  const RoomTypeModel({
    required this.id,
    required this.hotel,
    required this.name,
    this.description = '',
    required this.basePrice,
    this.bedCount = 1,
    this.bedType = '1 King Size Bed',
    this.adults = 2,
    this.children = 0,
    this.gstEnabled = true,
    this.gstRate = 18.0,
    this.cgstRate = 9.0,
    this.sgstRate = 9.0,
    this.taxInclusive = false,
    this.amenities = const [],
    this.images = const [],
    this.isActive = true,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) {
    int adults = 2;
    int children = 0;
    if (json['capacity'] is Map<String, dynamic>) {
      final cap = json['capacity'] as Map<String, dynamic>;
      adults = (cap['adults'] as num?)?.toInt() ?? 2;
      children = (cap['children'] as num?)?.toInt() ?? 0;
    }

    final rawAmenities = json['amenities'];
    final amenitiesList = <String>[];
    if (rawAmenities is List) {
      amenitiesList.addAll(rawAmenities.map((e) => e.toString()));
    }

    final rawImages = json['images'];
    final imagesList = <String>[];
    if (rawImages is List) {
      imagesList.addAll(rawImages.map((e) => e.toString()));
    }

    return RoomTypeModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      hotel: json['hotel']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Standard Room',
      description: json['description']?.toString() ?? '',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      bedCount: (json['bedCount'] as num?)?.toInt() ?? 1,
      bedType: json['bedType']?.toString() ?? '1 King Size Bed',
      adults: adults,
      children: children,
      gstEnabled: json['gstEnabled'] as bool? ?? true,
      gstRate: (json['gstRate'] as num?)?.toDouble() ?? 18.0,
      cgstRate: (json['cgstRate'] as num?)?.toDouble() ?? 9.0,
      sgstRate: (json['sgstRate'] as num?)?.toDouble() ?? 9.0,
      taxInclusive: json['taxInclusive'] as bool? ?? false,
      amenities: amenitiesList,
      images: imagesList,
      isActive: json['isActive'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'hotel': hotel,
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'bedCount': bedCount,
      'bedType': bedType,
      'capacity': {
        'adults': adults,
        'children': children,
      },
      'gstEnabled': gstEnabled,
      'gstRate': gstRate,
      'cgstRate': cgstRate,
      'sgstRate': sgstRate,
      'taxInclusive': taxInclusive,
      'amenities': amenities,
      'images': images,
      'isActive': isActive,
      'isDeleted': isDeleted,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  /// Default fallback rate resolution if basePrice is 0, matching the screenshot specifications
  double get effectivePrice {
    if (basePrice > 0) return basePrice;
    final lower = name.toLowerCase();
    if (lower.contains('family')) return 2000.0;
    if (lower.contains('couple')) return 5000.0;
    if (lower.contains('deluxe')) return 3000.0;
    if (lower.contains('standard')) return 2000.0;
    if (lower.contains('presidential') || lower.contains('vip')) return 8000.0;
    if (lower.contains('suite')) return 4500.0;
    return 3000.0;
  }
}
