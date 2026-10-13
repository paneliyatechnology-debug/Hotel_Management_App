class HotelSupportContact {
  final String phone;
  final String email;
  final String whatsapp;

  const HotelSupportContact({
    this.phone = '',
    this.email = '',
    this.whatsapp = '',
  });

  factory HotelSupportContact.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HotelSupportContact();
    return HotelSupportContact(
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'email': email,
        'whatsapp': whatsapp,
      };
}

class HotelSubscription {
  final String plan;
  final String status;
  final String trialStartDate;
  final String trialEndDate;
  final bool autoRenew;
  final int daysLeft;
  final int totalDays;
  final int elapsedDays;
  final int elapsedPercentage;
  final bool isTrialActive;
  final bool isSubActive;
  final bool isExpired;

  const HotelSubscription({
    this.plan = '',
    this.status = '',
    this.trialStartDate = '',
    this.trialEndDate = '',
    this.autoRenew = false,
    this.daysLeft = 0,
    this.totalDays = 0,
    this.elapsedDays = 0,
    this.elapsedPercentage = 0,
    this.isTrialActive = false,
    this.isSubActive = false,
    this.isExpired = false,
  });

  factory HotelSubscription.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HotelSubscription();
    return HotelSubscription(
      plan: json['plan'] as String? ?? '',
      status: json['status'] as String? ?? '',
      trialStartDate: json['trialStartDate'] as String? ?? '',
      trialEndDate: json['trialEndDate'] as String? ?? '',
      autoRenew: json['autoRenew'] as bool? ?? false,
      daysLeft: (json['daysLeft'] as num?)?.toInt() ?? 0,
      totalDays: (json['totalDays'] as num?)?.toInt() ?? 0,
      elapsedDays: (json['elapsedDays'] as num?)?.toInt() ?? 0,
      elapsedPercentage: (json['elapsedPercentage'] as num?)?.toInt() ?? 0,
      isTrialActive: json['isTrialActive'] as bool? ?? false,
      isSubActive: json['isSubActive'] as bool? ?? false,
      isExpired: json['isExpired'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'plan': plan,
        'status': status,
        'trialStartDate': trialStartDate,
        'trialEndDate': trialEndDate,
        'autoRenew': autoRenew,
        'daysLeft': daysLeft,
        'totalDays': totalDays,
        'elapsedDays': elapsedDays,
        'elapsedPercentage': elapsedPercentage,
        'isTrialActive': isTrialActive,
        'isSubActive': isSubActive,
        'isExpired': isExpired,
      };
}

class HotelSettings {
  final String checkInTime;
  final String checkOutTime;
  final String timezone;
  final String currency;
  final double taxPercentage;
  final String upiId;
  final bool gstEnabled;
  final int defaultGstRate;
  final int defaultCgstRate;
  final int defaultSgstRate;
  final bool taxInclusive;
  final int lateCheckoutGraceMinutes;
  final List<String> amenities;
  final List<String> policies;

  const HotelSettings({
    this.checkInTime = '14:00',
    this.checkOutTime = '12:00',
    this.timezone = 'Asia/Kolkata',
    this.currency = 'INR',
    this.taxPercentage = 0.0,
    this.upiId = '',
    this.gstEnabled = true,
    this.defaultGstRate = 18,
    this.defaultCgstRate = 9,
    this.defaultSgstRate = 9,
    this.taxInclusive = false,
    this.lateCheckoutGraceMinutes = 10,
    this.amenities = const [],
    this.policies = const [],
  });

  String get policyScheduleLabel =>
      'Check-In: $checkInTime | Check-Out: $checkOutTime';

  factory HotelSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HotelSettings();
    return HotelSettings(
      checkInTime: json['checkInTime'] as String? ?? '14:00',
      checkOutTime: json['checkOutTime'] as String? ?? '12:00',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      currency: json['currency'] as String? ?? 'INR',
      taxPercentage: (json['taxPercentage'] as num?)?.toDouble() ?? 0.0,
      upiId: json['upiId'] as String? ?? '',
      gstEnabled: json['gstEnabled'] as bool? ?? true,
      defaultGstRate: (json['defaultGstRate'] as num?)?.toInt() ?? 18,
      defaultCgstRate: (json['defaultCgstRate'] as num?)?.toInt() ?? 9,
      defaultSgstRate: (json['defaultSgstRate'] as num?)?.toInt() ?? 9,
      taxInclusive: json['taxInclusive'] as bool? ?? false,
      lateCheckoutGraceMinutes:
          (json['lateCheckoutGraceMinutes'] as num?)?.toInt() ?? 10,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      policies: (json['policies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'checkInTime': checkInTime,
        'checkOutTime': checkOutTime,
        'timezone': timezone,
        'currency': currency,
        'taxPercentage': taxPercentage,
        'upiId': upiId,
        'gstEnabled': gstEnabled,
        'defaultGstRate': defaultGstRate,
        'defaultCgstRate': defaultCgstRate,
        'defaultSgstRate': defaultSgstRate,
        'taxInclusive': taxInclusive,
        'lateCheckoutGraceMinutes': lateCheckoutGraceMinutes,
        'amenities': amenities,
        'policies': policies,
      };
}

class HotelInfoModel {
  final String id;
  final String name;
  final String slug;
  final String status;
  final String statusReason;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String hotelType;
  final String website;
  final String logo;
  final HotelSubscription subscription;
  final HotelSettings settings;
  final HotelSupportContact supportContact;

  const HotelInfoModel({
    this.id = '',
    this.name = '',
    this.slug = '',
    this.status = '',
    this.statusReason = '',
    this.ownerName = '',
    this.ownerEmail = '',
    this.ownerPhone = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.pincode = '',
    this.hotelType = '',
    this.website = '',
    this.logo = '',
    this.subscription = const HotelSubscription(),
    this.settings = const HotelSettings(),
    this.supportContact = const HotelSupportContact(),
  });

  String get formattedAddress {
    if (address.isNotEmpty) return address;
    final parts = [city, state, country].where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Property Location Not Set';
  }

  factory HotelInfoModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HotelInfoModel();
    return HotelInfoModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusReason: json['statusReason'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      ownerEmail: json['ownerEmail'] as String? ?? '',
      ownerPhone: json['ownerPhone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      hotelType: json['hotelType'] as String? ?? '',
      website: json['website'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      subscription: HotelSubscription.fromJson(
          json['subscription'] as Map<String, dynamic>?),
      settings:
          HotelSettings.fromJson(json['settings'] as Map<String, dynamic>?),
      supportContact: HotelSupportContact.fromJson(
          json['supportContact'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'slug': slug,
        'status': status,
        'statusReason': statusReason,
        'ownerName': ownerName,
        'ownerEmail': ownerEmail,
        'ownerPhone': ownerPhone,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
        'hotelType': hotelType,
        'website': website,
        'logo': logo,
        'subscription': subscription.toJson(),
        'settings': settings.toJson(),
        'supportContact': supportContact.toJson(),
      };
}

class AuthUserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String employeeId;
  final String status;
  final String lastLoginAt;
  final bool mustChangePassword;
  final HotelInfoModel hotel;

  const AuthUserModel({
    this.id = '',
    this.name = '',
    this.email = '',
    this.phone = '',
    this.role = '',
    this.employeeId = '',
    this.status = 'ACTIVE',
    this.lastLoginAt = '',
    this.mustChangePassword = false,
    this.hotel = const HotelInfoModel(),
  });

  factory AuthUserModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AuthUserModel();
    return AuthUserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      lastLoginAt: json['lastLoginAt'] as String? ?? '',
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      hotel: HotelInfoModel.fromJson(json['hotel'] as Map<String, dynamic>?),
    );
  }

  bool get isReceptionist => role.trim().toUpperCase() == 'RECEPTIONIST';
  bool get isHotelAdmin => !isReceptionist;
  String get effectiveRole => isReceptionist ? 'RECEPTIONIST' : 'HOTEL_ADMIN';
  bool get isActiveShift => status.trim().toUpperCase() == 'ACTIVE';

  String get initialLetter {
    final clean = name.trim();
    return clean.isNotEmpty ? clean[0].toUpperCase() : 'T';
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'employeeId': employeeId,
        'status': status,
        'lastLoginAt': lastLoginAt,
        'mustChangePassword': mustChangePassword,
        'hotel': hotel.toJson(),
      };
}
