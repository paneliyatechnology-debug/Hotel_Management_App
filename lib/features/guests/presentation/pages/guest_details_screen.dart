import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../dashboard/data/models/guest_folio_model.dart';
import '../../../folios/presentation/widgets/guest_folio_details_view.dart';
import '../../data/models/guest_model.dart';

class GuestDetailsScreen extends StatelessWidget {
  final GuestProfileModel guest;
  final bool isEmbedded;

  const GuestDetailsScreen({
    super.key,
    required this.guest,
    this.isEmbedded = false,
  });

  GuestFolioModel get _folio => guest.toFolio();

  String _appBarTitle(GuestFolioModel folio) {
    final name = folio.guestName.trim();
    final rawRoom = folio.assignedRoom.replaceAll(RegExp(r'^(Room\s*#?|#)'), '').trim();
    final room = rawRoom.isNotEmpty ? 'Room #$rawRoom' : '';
    if (name.isNotEmpty && room.isNotEmpty) return '$name • $room';
    if (name.isNotEmpty) return name;
    if (room.isNotEmpty) return room;
    return 'Guest Details';
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      surfaceTintColor: Colors.white,
      centerTitle: false,
      leading: const BackButton(color: Color(0xFF0F172A)),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE2E8F0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folio = _folio;
    final body = GuestFolioDetailsView(
      folio: folio,
      isDialog: false,
      onClose: () => Navigator.of(context).maybePop(),
    );
    final appBar = _buildAppBar(context, _appBarTitle(folio));

    if (isEmbedded) {
      return ColoredBox(
        color: const Color(0xFFF8FAFC),
        child: Column(
          children: [
            Material(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: SizedBox(height: kToolbarHeight + 1, child: appBar),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: appBar,
      body: body,
    );
  }
}

extension GuestProfileFolio on GuestProfileModel {
  GuestFolioModel toFolio() {
    final stay = currentStay ?? (stayHistory.isNotEmpty ? stayHistory.first : null);
    final room = stay?.roomNumber ?? lastRoomNumber;
    final images = <String>[
      if (kyc.documentFrontUrl != null && kyc.documentFrontUrl!.startsWith('http')) kyc.documentFrontUrl!,
      if (kyc.documentBackUrl != null && kyc.documentBackUrl!.startsWith('http')) kyc.documentBackUrl!,
    ];
    final addressLine = [
      address,
      city,
      state,
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return GuestFolioModel(
      id: bookingRecordId.isNotEmpty ? bookingRecordId : id,
      guestName: fullName,
      email: email,
      phone: mobile,
      assignedRoom: room,
      roomType: stay?.roomCategory ?? lastRoomCategory,
      checkInDate: stay?.checkInDate ?? lastCheckInDate,
      checkOutDate: stay?.checkOutDate ?? lastCheckOutDate,
      status: _folioStatus,
      idType: kyc.idType,
      idNumber: kyc.idNumber == 'Pending ID' ? '' : kyc.idNumber,
      isGovtIdVerified: kyc.isVerified,
      roomRatePerNight: stay?.roomCharges ?? 0,
      advancePaid: stay?.paidAmount ?? paidAmount,
      totalAmount: stay?.totalAmount ?? totalAmount,
      paymentMode: stay?.paymentMethod ?? 'UPI',
      address: addressLine,
      bookingId: stay?.bookingId ?? activeBookingNumber,
      floor: stay?.floor ?? 'Floor 1',
      numberOfGuests: stay?.numberOfGuests ?? 1,
      gender: gender,
      dateOfBirth: dateOfBirth,
      nationality: nationality,
      roomCharges: stay?.roomCharges ?? totalAmount,
      extraCharges: stay?.extraCharges ?? 0,
      discount: stay?.discount ?? 0,
      tax: stay?.tax ?? 0,
      createdByName: stay?.checkedInBy,
      idImageUrls: images,
      bookingStatus: rawStatus.isNotEmpty ? rawStatus : 'Confirmed',
    );
  }

  FolioStatus get _folioStatus {
    switch (currentStatus) {
      case GuestStatus.inHouse:
        return FolioStatus.inHouse;
      case GuestStatus.cancelled:
        return FolioStatus.cancelled;
      case GuestStatus.checkedOut:
        return FolioStatus.departed;
      case GuestStatus.registered:
        return FolioStatus.confirmed;
    }
  }
}
