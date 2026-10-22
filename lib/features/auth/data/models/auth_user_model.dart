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
    final tax = json['tax_percentage'] ?? json['taxPercentage'];
    return HotelSettings(
      checkInTime: (json['check_in_time'] ?? json['checkInTime'] ?? '14:00').toString(),
      checkOutTime: (json['check_out_time'] ?? json['checkOutTime'] ?? '12:00').toString(),
      timezone: (json['timezone'] ?? 'Asia/Kolkata').toString(),
      currency: (json['currency'] ?? 'INR').toString(),
      taxPercentage: tax is num ? tax.toDouble() : double.tryParse('$tax') ?? 0.0,
      upiId: (json['upi_id'] ?? json['upiId'] ?? '').toString(),
      gstEnabled: _settingsBool(json['gst_enabled'] ?? json['gstEnabled'], fallback: true),
      defaultGstRate: (json['defaultGstRate'] as num?)?.toInt() ?? (tax is num ? tax.toInt() : 18),
      defaultCgstRate: (json['defaultCgstRate'] as num?)?.toInt() ?? 9,
      defaultSgstRate: (json['defaultSgstRate'] as num?)?.toInt() ?? 9,
      taxInclusive: _settingsBool(json['taxInclusive'] ?? json['tax_inclusive'], fallback: false),
      lateCheckoutGraceMinutes: _settingsInt(json['late_checkout_grace_minutes'] ?? json['lateCheckoutGraceMinutes'], fallback: 10),
      amenities: _settingsList(json['amenities']),
      policies: _settingsList(json['policies']),
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

bool _settingsBool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
  }
  return fallback;
}

List<String> _settingsList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList();
  }
  return const [];
}

int _settingsInt(dynamic value, {required int fallback}) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
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
  final String gstNumber;
  final String panNumber;
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
    this.gstNumber = '',
    this.panNumber = '',
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
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['hotel_name'] ?? json['hotelName'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      statusReason: (json['statusReason'] ?? '').toString(),
      ownerName: (json['ownerName'] ?? '').toString(),
      ownerEmail: (json['ownerEmail'] ?? '').toString(),
      ownerPhone: (json['ownerPhone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      pincode: (json['pincode'] ?? '').toString(),
      hotelType: (json['hotelType'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      logo: (json['logo'] ?? '').toString(),
      gstNumber: (json['gst_number'] ?? json['gstNumber'] ?? json['gstin'] ?? '').toString(),
      panNumber: (json['pan_number'] ?? json['panNumber'] ?? '').toString(),
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
        'gst_number': gstNumber,
        'pan_number': panNumber,
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
    final rawHotel = json['hotel'];
    Map<String, dynamic> hotelMap = {};
    if (rawHotel is Map<String, dynamic>) {
      hotelMap = Map<String, dynamic>.from(rawHotel);
    }
    final hotelId = (hotelMap['_id'] ??
            hotelMap['id'] ??
            json['hotel_id'] ??
            json['hotelId'] ??
            json['id'] ??
            '')
        .toString();
    if ((hotelMap['id'] == null && hotelMap['_id'] == null) ||
        (hotelMap['id']?.toString().isEmpty ?? true)) {
      hotelMap['id'] = hotelId;
    }

    return AuthUserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      employeeId: (json['employeeId'] ?? '').toString(),
      status: (json['status'] ?? 'ACTIVE').toString(),
      lastLoginAt: (json['last_login_at'] ?? json['lastLoginAt'] ?? '').toString(),
      mustChangePassword: json['must_change_password'] == true || json['mustChangePassword'] == true,
      hotel: HotelInfoModel.fromJson(hotelMap),
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
