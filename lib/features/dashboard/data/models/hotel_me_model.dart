import 'dart:convert';

class HotelMeProfile {
  final String name;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String gstNumber;
  final String panNumber;
  final String bankName;
  final String bankAccountHolder;
  final String bankAccountNumber;
  final String bankIfscCode;
  final String bankBranch;
  final String hotelType;
  final String website;
  final String checkInTime;
  final String checkOutTime;
  final String timezone;
  final String currency;
  final String taxPercentage;
  final bool gstEnabled;
  final String upiId;
  final String lateCheckoutGraceMinutes;
  final List<String> amenities;
  final List<String> policies;
  final String logoUrl;

  const HotelMeProfile({
    this.name = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.country = 'India',
    this.pincode = '',
    this.gstNumber = '',
    this.panNumber = '',
    this.bankName = '',
    this.bankAccountHolder = '',
    this.bankAccountNumber = '',
    this.bankIfscCode = '',
    this.bankBranch = '',
    this.hotelType = '',
    this.website = '',
    this.checkInTime = '14:00',
    this.checkOutTime = '12:00',
    this.timezone = 'Asia/Kolkata',
    this.currency = 'INR',
    this.taxPercentage = '18',
    this.gstEnabled = true,
    this.upiId = '',
    this.lateCheckoutGraceMinutes = '10',
    this.amenities = const [],
    this.policies = const [],
    this.logoUrl = '',
  });

  factory HotelMeProfile.fromJson(Map<String, dynamic> json) {
    final settings = _asMap(json['settings']);
    final bank = _asMap(json['bank_details'] ?? json['bankDetails'] ?? json['bank']);
    return HotelMeProfile(
      name: _text(json, settings, const ['name']),
      address: _text(json, settings, const ['address']),
      city: _text(json, settings, const ['city']),
      state: _text(json, settings, const ['state']),
      country: _text(json, settings, const ['country']).isEmpty ? 'India' : _text(json, settings, const ['country']),
      pincode: _text(json, settings, const ['pincode', 'pin_code', 'postal_code']),
      gstNumber: _text(json, settings, const ['gst_number', 'gstNumber', 'gstin']),
      panNumber: _text(json, settings, const ['pan_number', 'panNumber']),
      bankName: _text(json, bank, const ['bank_name', 'bankName']),
      bankAccountHolder: _text(json, bank, const ['bank_account_holder', 'bankAccountHolder', 'beneficiaryName', 'account_holder']),
      bankAccountNumber: _text(json, bank, const ['bank_account_number', 'bankAccountNumber', 'accountNumber', 'account_number']),
      bankIfscCode: _text(json, bank, const ['bank_ifsc_code', 'bankIfscCode', 'ifscCode', 'ifsc']),
      bankBranch: _text(json, bank, const ['bank_branch', 'bankBranch', 'branch']),
      hotelType: _text(json, settings, const ['hotel_type', 'hotelType']),
      website: _text(json, settings, const ['website']),
      checkInTime: _text(json, settings, const ['check_in_time', 'checkInTime']).isEmpty
          ? '14:00'
          : _text(json, settings, const ['check_in_time', 'checkInTime']),
      checkOutTime: _text(json, settings, const ['check_out_time', 'checkOutTime']).isEmpty
          ? '12:00'
          : _text(json, settings, const ['check_out_time', 'checkOutTime']),
      timezone: _text(json, settings, const ['timezone']).isEmpty ? 'Asia/Kolkata' : _text(json, settings, const ['timezone']),
      currency: _text(json, settings, const ['currency']).isEmpty ? 'INR' : _text(json, settings, const ['currency']),
      taxPercentage: _text(json, settings, const ['tax_percentage', 'taxPercentage', 'defaultGstRate']).isEmpty
          ? '18'
          : _text(json, settings, const ['tax_percentage', 'taxPercentage', 'defaultGstRate']),
      gstEnabled: _bool(json['gst_enabled'] ?? json['gstEnabled'] ?? settings['gst_enabled'] ?? settings['gstEnabled'], fallback: true),
      upiId: _text(json, settings, const ['upi_id', 'upiId']),
      lateCheckoutGraceMinutes: _text(json, settings, const ['late_checkout_grace_minutes', 'lateCheckoutGraceMinutes']).isEmpty
          ? '10'
          : _text(json, settings, const ['late_checkout_grace_minutes', 'lateCheckoutGraceMinutes']),
      amenities: _list(json['amenities'] ?? settings['amenities']),
      policies: _list(json['policies'] ?? settings['policies']),
      logoUrl: _text(json, settings, const ['logo', 'logo_url', 'logoUrl']),
    );
  }

  Map<String, String> toFormFields() {
    return {
      'name': name.trim(),
      'address': address.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'country': country.trim(),
      'pincode': pincode.trim(),
      'gst_number': gstNumber.trim(),
      'pan_number': panNumber.trim(),
      'bank_name': bankName.trim(),
      'bank_account_holder': bankAccountHolder.trim(),
      'bank_account_number': bankAccountNumber.trim(),
      'bank_ifsc_code': bankIfscCode.trim(),
      'bank_branch': bankBranch.trim(),
      'hotel_type': hotelType.trim(),
      'website': website.trim(),
      'check_in_time': checkInTime.trim(),
      'check_out_time': checkOutTime.trim(),
      'timezone': timezone.trim(),
      'currency': currency.trim(),
      'tax_percentage': taxPercentage.trim(),
      'gst_enabled': gstEnabled ? 'true' : 'false',
      'upi_id': upiId.trim(),
      'late_checkout_grace_minutes': lateCheckoutGraceMinutes.trim(),
      'amenities': jsonEncode(amenities),
      'policies': jsonEncode(policies),
    };
  }
}

Map<String, dynamic> hotelMeMap(dynamic json) {
  if (json is! Map) return {};
  final root = Map<String, dynamic>.from(json);
  final data = root['data'];
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final hotel = map['hotel'];
    if (hotel is Map) return Map<String, dynamic>.from(hotel);
    return map;
  }
  final hotel = root['hotel'];
  if (hotel is Map) return Map<String, dynamic>.from(hotel);
  return root;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

String _text(Map<String, dynamic> primary, Map<String, dynamic> extra, List<String> keys) {
  for (final key in keys) {
    final value = primary[key] ?? extra[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

bool _bool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
  }
  return fallback;
}

List<String> _list(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    final text = value.trim();
    if (text.startsWith('[')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) {
          return decoded.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
        }
      } catch (_) {}
    }
    return text.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  }
  return const [];
}

class MyHotelProfile {
  final HotelMeProfile hotel;
  final String phone;
  final String email;
  final String ownerName;

  const MyHotelProfile({
    this.hotel = const HotelMeProfile(),
    this.phone = '',
    this.email = '',
    this.ownerName = '',
  });

  factory MyHotelProfile.fromResponse(dynamic json) {
    final root = json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};
    final data = root['data'] is Map ? Map<String, dynamic>.from(root['data'] as Map) : root;
    final user = data['user'] is Map ? Map<String, dynamic>.from(data['user'] as Map) : data;
    final hotel = user['hotel'] is Map ? Map<String, dynamic>.from(user['hotel'] as Map) : <String, dynamic>{};
    final owner = hotel['owner'] is Map ? Map<String, dynamic>.from(hotel['owner'] as Map) : <String, dynamic>{};
    return MyHotelProfile(
      hotel: HotelMeProfile.fromJson(hotel),
      phone: (user['phone'] ?? owner['phone'] ?? '').toString(),
      email: (user['email'] ?? owner['email'] ?? '').toString(),
      ownerName: (owner['name'] ?? user['name'] ?? '').toString(),
    );
  }
}
