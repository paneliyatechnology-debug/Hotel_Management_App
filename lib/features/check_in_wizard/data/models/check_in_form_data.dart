import 'dart:ui';

import '../../../dashboard/data/models/guest_folio_model.dart';
import '../../../rooms/data/models/room_model.dart';

class AccompanyingGuest {
  String id;
  String name;
  String relationship; // 'Spouse', 'Child', 'Parent', 'Sibling', 'Relative', 'Friend', 'Other'
  String age;
  String idType; // 'Aadhaar Card', 'Passport', 'Driving License', 'Voter ID'
  String idNumber;
  bool isIdVerified;
  String? idPhotoUrl;
  String? get idFrontPhotoUrl => idPhotoUrl;
  set idFrontPhotoUrl(String? val) => idPhotoUrl = val;
  String? idBackPhotoUrl;
  List<Offset?> signaturePoints;
  bool isSignatureCaptured;

  AccompanyingGuest({
    String? id,
    this.name = '',
    this.relationship = 'Spouse',
    this.age = '',
    this.idType = 'Aadhaar Card',
    this.idNumber = '',
    this.isIdVerified = false,
    this.idPhotoUrl,
    this.idBackPhotoUrl,
    List<Offset?>? signaturePoints,
    this.isSignatureCaptured = false,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        signaturePoints = signaturePoints ?? [];

  AccompanyingGuest copy() {
    return AccompanyingGuest(
      id: id,
      name: name,
      relationship: relationship,
      age: age,
      idType: idType,
      idNumber: idNumber,
      isIdVerified: isIdVerified,
      idPhotoUrl: idPhotoUrl,
      idBackPhotoUrl: idBackPhotoUrl,
      signaturePoints: List.from(signaturePoints),
      isSignatureCaptured: isSignatureCaptured,
    );
  }
}

class GuestSignature {
  final String id;
  List<Offset?> points;
  String? photoPath;

  GuestSignature({
    String? id,
    List<Offset?>? points,
    this.photoPath,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        points = points ?? [];

  bool get isCaptured =>
      (photoPath != null && photoPath!.trim().isNotEmpty) || points.any((point) => point != null);

  GuestSignature copy() {
    return GuestSignature(
      id: id,
      points: List<Offset?>.from(points),
      photoPath: photoPath,
    );
  }
}

class CheckInFormData {
  // Step 1: Guest Identity & Regulatory ID
  String partyType; // 'Solo Guest', 'Couple (2 Guests)', 'Family / Group'
  String guestFullName;
  String idType; // 'Aadhaar Card', 'Passport', 'Driving License', 'Voter ID'
  String idNumber;
  String nationality;
  String? idFrontPhotoUrl;
  String? idBackPhotoUrl;
  List<String> idPhotos;
  bool isIdVerified;

  // Optional Second Guest Details (Step 1)
  String? secondGuestName;
  String? secondGuestPhone;

  // Attached / Accompanying Guests (Couple / Family)
  List<AccompanyingGuest> accompanyingGuests;

  // Step 2: Stay & Room Allocation
  String selectedRoomId;
  List<String> selectedRoomIds;
  String selectedRoomNumber;
  String selectedFloor;
  String roomType;
  double pricePerNight;
  bool gstEnabled;
  double gstRate;
  bool isRoomPreLocked;
  DateTime checkInDate;
  DateTime checkOutDate;
  int numberOfGuests;
  int extraBeds;
  int savedChildCount;

  // Step 3: Contact & Billing
  String contactPhone;
  String email;
  String residentialAddress;
  String city;
  String state;
  String pincode;
  String? gstNumber;
  String? specialRequests;

  // Step 4: Advance Folio & Payment
  String paymentMode; // 'UPI', 'Credit Card', 'Cash', 'POS Terminal'
  double advancePaid;
  double discountAmount;
  String transactionRef;

  // Step 5: Keycard & Allocation
  String assignedKeycardNumber;
  bool agreeTermsAndSignature;
  List<Offset?> signaturePoints;
  bool isSignatureCaptured;
  String? signaturePhotoPath;
  List<GuestSignature> extraSignatures;

  // Backend Integration Identifiers
  String? guestId;
  String? bookingNumber;
  String? receiptNumber;
  String? editingBookingId;

  CheckInFormData({
    this.partyType = 'Solo Guest',
    this.guestFullName = '',
    this.idType = 'Aadhaar Card',
    this.idNumber = '',
    this.nationality = 'Indian',
    this.idFrontPhotoUrl,
    this.idBackPhotoUrl,
    List<String>? idPhotos,
    this.isIdVerified = false,
    this.secondGuestName,
    this.secondGuestPhone,
    List<AccompanyingGuest>? accompanyingGuests,
    this.selectedRoomId = '',
    List<String>? selectedRoomIds,
    this.selectedRoomNumber = '',
    String? selectedFloor,
    this.roomType = '',
    this.pricePerNight = 0.0,
    this.gstEnabled = true,
    this.gstRate = 18,
    this.isRoomPreLocked = false,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    this.numberOfGuests = 1,
    this.extraBeds = 0,
    this.savedChildCount = 0,
    this.contactPhone = '',
    this.email = '',
    this.residentialAddress = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.gstNumber,
    this.specialRequests,
    this.paymentMode = 'UPI',
    this.advancePaid = 0.0,
    this.discountAmount = 0.0,
    this.transactionRef = '',
    this.assignedKeycardNumber = '',
    this.agreeTermsAndSignature = true,
    List<Offset?>? signaturePoints,
    this.isSignatureCaptured = false,
    this.signaturePhotoPath,
    List<GuestSignature>? extraSignatures,
    this.guestId,
    this.bookingNumber,
    this.receiptNumber,
    this.editingBookingId,
  })  : idPhotos = idPhotos ?? [
          if (idFrontPhotoUrl != null && idFrontPhotoUrl.isNotEmpty) idFrontPhotoUrl,
          if (idBackPhotoUrl != null && idBackPhotoUrl.isNotEmpty) idBackPhotoUrl,
        ],
        accompanyingGuests = accompanyingGuests ?? [],
        signaturePoints = signaturePoints ?? [],
        extraSignatures = extraSignatures ?? [],
        selectedRoomIds = _normalizeRoomIds(
          selectedRoomIds: selectedRoomIds,
          selectedRoomId: selectedRoomId,
        ),
        selectedFloor = selectedFloor ?? 'Floor 1',
        checkInDate = checkInDate ?? DateTime.now(),
        checkOutDate = checkOutDate ?? DateTime.now().add(const Duration(days: 1));

  int get selectedRoomCount => selectedRoomIds.isNotEmpty
      ? selectedRoomIds.length
      : (selectedRoomId.trim().isEmpty ? 0 : 1);

  String get roomsLabel {
    final label = selectedRoomNumber.trim();
    if (label.isNotEmpty) return label;
    if (selectedRoomIds.isNotEmpty) return selectedRoomIds.join(', ');
    return selectedRoomId;
  }

  int get totalNights {
    final diff = checkOutDate.difference(checkInDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get subtotal => (pricePerNight * totalNights) + (extraBeds * 500);
  double get taxableAmount {
    final amount = subtotal - discountAmount;
    return amount > 0 ? amount : 0;
  }

  double get gstTax => gstEnabled && gstRate > 0 ? taxableAmount * gstRate / 100 : 0;
  double get grandTotal => taxableAmount + gstTax;
  double get balanceDue => grandTotal - advancePaid;

  CheckInFormData copy() {
    return CheckInFormData(
      partyType: partyType,
      guestFullName: guestFullName,
      idType: idType,
      idNumber: idNumber,
      nationality: nationality,
      idFrontPhotoUrl: idFrontPhotoUrl,
      idBackPhotoUrl: idBackPhotoUrl,
      idPhotos: List<String>.from(idPhotos),
      isIdVerified: isIdVerified,
      secondGuestName: secondGuestName,
      secondGuestPhone: secondGuestPhone,
      accompanyingGuests: accompanyingGuests.map((g) => g.copy()).toList(),
      selectedRoomId: selectedRoomId,
      selectedRoomIds: List<String>.from(selectedRoomIds),
      selectedRoomNumber: selectedRoomNumber,
      selectedFloor: selectedFloor,
      roomType: roomType,
      pricePerNight: pricePerNight,
      gstEnabled: gstEnabled,
      gstRate: gstRate,
      isRoomPreLocked: isRoomPreLocked,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      numberOfGuests: numberOfGuests,
      extraBeds: extraBeds,
      savedChildCount: savedChildCount,
      contactPhone: contactPhone,
      email: email,
      residentialAddress: residentialAddress,
      city: city,
      state: state,
      pincode: pincode,
      gstNumber: gstNumber,
      specialRequests: specialRequests,
      paymentMode: paymentMode,
      advancePaid: advancePaid,
      discountAmount: discountAmount,
      transactionRef: transactionRef,
      assignedKeycardNumber: assignedKeycardNumber,
      agreeTermsAndSignature: agreeTermsAndSignature,
      signaturePoints: List<Offset?>.from(signaturePoints),
      isSignatureCaptured: isSignatureCaptured,
      signaturePhotoPath: signaturePhotoPath,
      extraSignatures: extraSignatures.map((signature) => signature.copy()).toList(),
      guestId: guestId,
      bookingNumber: bookingNumber,
      receiptNumber: receiptNumber,
      editingBookingId: editingBookingId,
    );
  }

  bool get isEditingBooking => (editingBookingId ?? '').trim().isNotEmpty;

  /// Fills the check-in wizard from a booking that is already in house.
  factory CheckInFormData.fromFolio(GuestFolioModel folio, RoomModel room) {
    final checkIn = DateTime(folio.checkInDate.year, folio.checkInDate.month, folio.checkInDate.day);
    final rawCheckOut = DateTime(folio.checkOutDate.year, folio.checkOutDate.month, folio.checkOutDate.day);
    final checkOut = rawCheckOut.isAfter(checkIn) ? rawCheckOut : checkIn.add(const Duration(days: 1));
    final nights = checkOut.difference(checkIn).inDays <= 0 ? 1 : checkOut.difference(checkIn).inDays;
    final nightly = folio.roomCharges > 0
        ? folio.roomCharges / nights
        : (folio.roomRatePerNight > 0 ? folio.roomRatePerNight : room.pricePerNight);
    final photos = folio.idImageUrls.map((url) => url.trim()).where((url) => url.isNotEmpty).toList();
    final signatures = folio.signatureUrls.map((url) => url.trim()).where((url) => url.isNotEmpty).toList();
    final adults = folio.adultCount ?? folio.numberOfGuests;
    final children = folio.childCount ?? 0;
    final notes = (folio.guestNotes ?? folio.specialRequests ?? '').trim();
    final bookingId = int.tryParse(folio.id.trim()) != null
        ? folio.id.trim()
        : (int.tryParse((folio.bookingId ?? '').trim()) != null ? folio.bookingId!.trim() : folio.id.trim());
    final apiRoomId = (folio.roomId ?? '').trim();
    final int extraBeds = folio.extraCharges <= 0
        ? (folio.extraBed ? 1 : 0)
        : (folio.extraCharges / 500).round().clamp(0, 20).toInt();

    // 1. Resolve Primary Guest Name
    var primaryName = (folio.guestName == 'Guest' ? '' : folio.guestName).trim();
    if (primaryName.isEmpty && folio.guests.isNotEmpty) {
      primaryName = folio.guests.first.name.trim();
    }

    // 2. Resolve Additional / Accompanying Guests from folio.guests and secondaryGuestName
    final otherGuestNames = <String>[];
    final secondary = (folio.secondaryGuestName ?? '').trim();
    if (secondary.isNotEmpty) {
      otherGuestNames.add(secondary);
    }
    for (final bg in folio.guests) {
      final name = bg.name.trim();
      if (name.isEmpty) continue;
      // Skip if it's the primary guest (displayOrder == 1 or matches primaryName)
      if (bg.displayOrder == 1 || (primaryName.isNotEmpty && name.toLowerCase() == primaryName.toLowerCase() && otherGuestNames.isEmpty)) {
        continue;
      }
      if (!otherGuestNames.contains(name)) {
        otherGuestNames.add(name);
      }
    }

    final String? secondGuest = otherGuestNames.isNotEmpty ? otherGuestNames.first : null;
    final accompanyingList = otherGuestNames.skip(1).map((n) => AccompanyingGuest(name: n)).toList();
    final totalGuests = (1 + otherGuestNames.length) > (adults + children)
        ? (1 + otherGuestNames.length)
        : (adults + children);

    final keycode = (folio.keycardNumber != null &&
            folio.keycardNumber!.trim().isNotEmpty &&
            folio.keycardNumber!.trim().toLowerCase() != 'null')
        ? folio.keycardNumber!.trim()
        : room.keyCode.trim();

    return CheckInFormData(
      partyType: totalGuests >= 3 ? 'Family / Group' : (totalGuests == 2 ? 'Couple (2 Guests)' : 'Solo Guest'),
      guestFullName: primaryName,
      idType: _wizardIdType(folio.idType),
      idNumber: folio.idNumber,
      nationality: folio.nationality.isEmpty ? 'Indian' : folio.nationality,
      idFrontPhotoUrl: photos.isNotEmpty ? photos.first : null,
      idBackPhotoUrl: photos.length > 1 ? photos[1] : null,
      idPhotos: photos,
      isIdVerified: folio.isGovtIdVerified || photos.isNotEmpty,
      secondGuestName: secondGuest,
      accompanyingGuests: accompanyingList,
      selectedRoomId: apiRoomId.isNotEmpty ? apiRoomId : room.id,
      selectedRoomIds: [if ((apiRoomId.isNotEmpty ? apiRoomId : room.id).trim().isNotEmpty) (apiRoomId.isNotEmpty ? apiRoomId : room.id)],
      selectedRoomNumber: room.roomNumber,
      selectedFloor: room.floor.isEmpty ? folio.floor : room.floor,
      roomType: room.roomType.isNotEmpty ? room.roomType : folio.roomType,
      pricePerNight: nightly,
      gstEnabled: folio.gstRate > 0 || room.gstEnabled,
      gstRate: folio.gstRate > 0 ? folio.gstRate : (room.gstEnabled ? room.gstRate : 0),
      isRoomPreLocked: true,
      checkInDate: checkIn,
      checkOutDate: checkOut,
      numberOfGuests: totalGuests < 1 ? 1 : totalGuests,
      extraBeds: extraBeds,
      savedChildCount: children < 0 ? 0 : children,
      contactPhone: folio.phone,
      email: folio.email,
      residentialAddress: folio.address ?? '',
      specialRequests: notes,
      gstNumber: folio.gstNumber,
      paymentMode: _wizardPaymentMode(folio.paymentMode),
      advancePaid: folio.advancePaid,
      discountAmount: folio.discount,
      transactionRef: notes,
      assignedKeycardNumber: keycode,
      agreeTermsAndSignature: true,
      isSignatureCaptured: signatures.isNotEmpty,
      signaturePhotoPath: signatures.isNotEmpty ? signatures.first : null,
      extraSignatures: [
        for (final url in signatures.skip(1)) GuestSignature(photoPath: url),
      ],
      guestId: folio.guestId,
      bookingNumber: folio.bookingId,
      receiptNumber: folio.receiptNumber,
      editingBookingId: bookingId,
    );
  }
}

List<String> _normalizeRoomIds({
  List<String>? selectedRoomIds,
  required String selectedRoomId,
}) {
  final ids = <String>[];
  void add(String raw) {
    final id = raw.trim();
    if (id.isEmpty || ids.contains(id)) return;
    ids.add(id);
  }

  if (selectedRoomIds != null) {
    for (final id in selectedRoomIds) {
      add(id);
    }
  }
  add(selectedRoomId);
  return ids;
}

String _wizardIdType(String raw) {
  final value = raw.toLowerCase();
  if (value.contains('passport')) return 'Passport';
  if (value.contains('driving') || value.contains('license') || value.contains('licence')) return 'Driving License';
  if (value.contains('voter')) return 'Voter ID';
  if (value.contains('aadhaar') || value.contains('aadhar')) return 'Aadhaar Card';
  const known = ['Aadhaar Card', 'Passport', 'Driving License', 'Voter ID'];
  return known.contains(raw) ? raw : 'Aadhaar Card';
}

String _wizardPaymentMode(String raw) {
  final value = raw.toUpperCase();
  if (value.contains('CASH')) return 'CASH';
  if (value.contains('CARD') || value.contains('CREDIT') || value.contains('DEBIT')) return 'CARD';
  if (value.contains('POS')) return 'POS';
  if (value.contains('NET') || value.contains('BANK')) return 'BANK_TRANSFER';
    if (value.contains('UPI')) return 'UPI';
  return 'UPI';
}
