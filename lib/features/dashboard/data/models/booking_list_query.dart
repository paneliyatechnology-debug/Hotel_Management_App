class BookingListQuery {
  final String bookingStatus;
  final String paymentStatus;
  final String roomId;
  final String bookingNumber;
  final String primaryGuestName;
  final String guestName;
  final String mobileNumber;
  final String search;
  final String checkInFrom;
  final String checkInTo;
  final String checkOutFrom;
  final String checkOutTo;
  final int page;
  final int limit;

  const BookingListQuery({
    this.bookingStatus = '',
    this.paymentStatus = '',
    this.roomId = '',
    this.bookingNumber = '',
    this.primaryGuestName = '',
    this.guestName = '',
    this.mobileNumber = '',
    this.search = '',
    this.checkInFrom = '',
    this.checkInTo = '',
    this.checkOutFrom = '',
    this.checkOutTo = '',
    this.page = 1,
    this.limit = 10,
  });

  bool get hasSheetFilters =>
      bookingStatus.trim().isNotEmpty ||
      paymentStatus.trim().isNotEmpty ||
      roomId.trim().isNotEmpty ||
      bookingNumber.trim().isNotEmpty ||
      primaryGuestName.trim().isNotEmpty ||
      guestName.trim().isNotEmpty ||
      mobileNumber.trim().isNotEmpty ||
      checkInFrom.trim().isNotEmpty ||
      checkInTo.trim().isNotEmpty ||
      checkOutFrom.trim().isNotEmpty ||
      checkOutTo.trim().isNotEmpty;

  Map<String, String> toQueryParameters(int page) {
    final params = <String, String>{
      'page': '$page',
      'limit': '${limit < 1 ? 10 : limit}',
    };
    void add(String key, String value) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) params[key] = trimmed;
    }

    add('booking_status', bookingStatus);
    add('payment_status', paymentStatus);
    add('room_id', roomId);
    add('booking_number', bookingNumber);
    add('primary_guest_name', primaryGuestName);
    add('guest_name', guestName);
    add('mobile_number', mobileNumber);
    add('search', search);
    add('check_in_from', checkInFrom);
    add('check_in_to', checkInTo);
    add('check_out_from', checkOutFrom);
    add('check_out_to', checkOutTo);
    return params;
  }

  BookingListQuery copyWith({
    String? bookingStatus,
    String? paymentStatus,
    String? roomId,
    String? bookingNumber,
    String? primaryGuestName,
    String? guestName,
    String? mobileNumber,
    String? search,
    String? checkInFrom,
    String? checkInTo,
    String? checkOutFrom,
    String? checkOutTo,
    int? page,
    int? limit,
  }) {
    return BookingListQuery(
      bookingStatus: bookingStatus ?? this.bookingStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      roomId: roomId ?? this.roomId,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      primaryGuestName: primaryGuestName ?? this.primaryGuestName,
      guestName: guestName ?? this.guestName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      search: search ?? this.search,
      checkInFrom: checkInFrom ?? this.checkInFrom,
      checkInTo: checkInTo ?? this.checkInTo,
      checkOutFrom: checkOutFrom ?? this.checkOutFrom,
      checkOutTo: checkOutTo ?? this.checkOutTo,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}
