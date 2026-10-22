import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final folio = _folio;
    final isDeparted = folio.status == FolioStatus.departed || folio.status == FolioStatus.cancelled;
    final isPaid = folio.pendingAmount <= 0;
    final statusLabel = switch (folio.status) {
      FolioStatus.inHouse => 'IN-HOUSE',
      FolioStatus.departed => 'DEPARTED',
      FolioStatus.cancelled => 'CANCELLED',
      FolioStatus.confirmed => 'REGISTERED',
    };
    final rawRoom = folio.assignedRoom.replaceAll(RegExp(r'^(Room\s*#?|#)'), '').trim();
    final displayRoom = rawRoom.isNotEmpty ? 'Room #$rawRoom' : 'Room';

    if (isEmbedded) {
      return Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Text(
                'Guest Details',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: GuestFolioDetailsView(
                folio: folio,
                isDialog: false,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guest Details',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            Text(
              '${folio.guestName} • $displayRoom',
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: isDeparted ? const Color(0xFFE0F2FE) : const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDeparted ? const Color(0xFFBAE6FD) : const Color(0xFF86EFAC),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDeparted ? const Color(0xFF0369A1) : const Color(0xFF15803D),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isDeparted ? const Color(0xFF0369A1) : const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPaid ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                width: 0.8,
              ),
            ),
            child: Text(
              folio.paymentStatusLabel,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: isPaid ? const Color(0xFF15803D) : const Color(0xFFB45309),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: GuestFolioDetailsView(
        folio: folio,
        isDialog: false,
      ),
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
