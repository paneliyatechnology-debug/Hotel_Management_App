import 'dart:ui';

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
  String selectedRoomNumber;
  String selectedFloor;
  String roomType;
  double pricePerNight;
  bool isRoomPreLocked;
  DateTime checkInDate;
  DateTime checkOutDate;
  int numberOfGuests;
  int extraBeds;

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

  // Backend Integration Identifiers
  String? guestId;
  String? bookingNumber;
  String? receiptNumber;

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
    this.selectedRoomNumber = '',
    String? selectedFloor,
    this.roomType = '',
    this.pricePerNight = 0.0,
    this.isRoomPreLocked = false,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    this.numberOfGuests = 1,
    this.extraBeds = 0,
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
    this.assignedKeycardNumber = 'KC-101',
    this.agreeTermsAndSignature = true,
    List<Offset?>? signaturePoints,
    this.isSignatureCaptured = false,
    this.guestId,
    this.bookingNumber,
    this.receiptNumber,
  })  : idPhotos = idPhotos ?? [
          if (idFrontPhotoUrl != null && idFrontPhotoUrl.isNotEmpty) idFrontPhotoUrl,
          if (idBackPhotoUrl != null && idBackPhotoUrl.isNotEmpty) idBackPhotoUrl,
        ],
        accompanyingGuests = accompanyingGuests ?? [],
        signaturePoints = signaturePoints ?? [],
        selectedFloor = selectedFloor ?? 'Floor 1',
        checkInDate = checkInDate ?? DateTime.now(),
        checkOutDate = checkOutDate ?? DateTime.now().add(const Duration(days: 1));

  int get totalNights {
    final diff = checkOutDate.difference(checkInDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get subtotal => (pricePerNight * totalNights) + (extraBeds * 500);
  double get gstTax => subtotal * 0.12; // 12% GST
  double get grandTotal => subtotal + gstTax - discountAmount;
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
      selectedRoomNumber: selectedRoomNumber,
      selectedFloor: selectedFloor,
      roomType: roomType,
      pricePerNight: pricePerNight,
      isRoomPreLocked: isRoomPreLocked,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      numberOfGuests: numberOfGuests,
      extraBeds: extraBeds,
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
      guestId: guestId,
      bookingNumber: bookingNumber,
      receiptNumber: receiptNumber,
    );
  }
}
