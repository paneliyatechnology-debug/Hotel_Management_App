import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/guest_model.dart';

class GuestCard extends StatelessWidget {
  final GuestProfileModel guest;
  final VoidCallback onTap;

  const GuestCard({
    super.key,
    required this.guest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final mostRecentStay = guest.currentStay ?? (guest.stayHistory.isNotEmpty ? guest.stayHistory.first : null);
    final isInHouse = guest.status == GuestStatus.inHouse;
    final isRegistered = guest.status == GuestStatus.registered;
    final initial = guest.name.trim().isNotEmpty ? guest.name.trim()[0].toUpperCase() : 'G';
    final rawRoom = (mostRecentStay?.roomNumber ?? guest.lastRoomNumber).replaceAll('Room', '').replaceAll('#', '').trim();
    final hasAssignedRoom = rawRoom.isNotEmpty && rawRoom != 'Not Assigned' && rawRoom != 'N/A';
    final roomNum = hasAssignedRoom ? rawRoom : 'N/A';
    final formattedRoom = hasAssignedRoom ? (roomNum.startsWith('#') ? roomNum : '#$roomNum') : 'NO ROOM';
    final roomCategory = mostRecentStay?.roomCategory ?? guest.lastRoomCategory;
    final checkInDate = mostRecentStay?.checkInDate ?? guest.lastCheckInDate;
    final checkOutDate = mostRecentStay?.checkOutDate ?? guest.lastCheckOutDate;
    final amount = mostRecentStay?.totalAmount ?? (guest.totalLifetimeSpent > 0 ? guest.totalLifetimeSpent : 0.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInHouse
              ? const Color(0xFF86EFAC).withValues(alpha: 0.7)
              : isRegistered
                  ? const Color(0xFFFDE68A).withValues(alpha: 0.7)
                  : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Room Pill + Room Type + Keycard + Status Pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                      decoration: BoxDecoration(
                        color: isInHouse
                            ? const Color(0xFF0F766E)
                            : isRegistered
                                ? const Color(0xFFD97706)
                                : const Color(0xFF475569),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        formattedRoom,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        (hasAssignedRoom ? roomCategory : (isRegistered ? 'Awaiting Check-in' : roomCategory)).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (hasAssignedRoom)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.nfc_rounded, size: 9, color: AppColors.primary),
                            const SizedBox(width: 2),
                            Text(
                              'KC-$roomNum',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    _buildStatusPill(guest.status),
                  ],
                ),
                const SizedBox(height: 7),

                // Middle Row: Avatar + Guest Name + Total Amount
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isInHouse ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                      child: Text(
                        initial,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        guest.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat.format(amount),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Bottom Row: Dates + Phone + Action Chevron
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Text(
                      '${dateFormat.format(checkInDate)} - ${dateFormat.format(checkOutDate)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    if (guest.mobile.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.phone_rounded, size: 11, color: Color(0xFF64748B)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          guest.mobile,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(GuestStatus status) {
    Color bg;
    Color border;
    Color dot;
    Color text;
    String label;

    switch (status) {
      case GuestStatus.inHouse:
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFF86EFAC);
        dot = const Color(0xFF16A34A);
        text = const Color(0xFF15803D);
        label = 'IN-HOUSE';
        break;
      case GuestStatus.checkedOut:
        bg = const Color(0xFFF1F5F9);
        border = const Color(0xFFCBD5E1);
        dot = const Color(0xFF64748B);
        text = const Color(0xFF475569);
        label = 'DEPARTED';
        break;
      case GuestStatus.cancelled:
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        dot = const Color(0xFFEF4444);
        text = const Color(0xFFDC2626);
        label = 'CANCELLED';
        break;
      case GuestStatus.registered:
        bg = const Color(0xFFFEF3C7);
        border = const Color(0xFFFDE68A);
        dot = const Color(0xFFD97706);
        text = const Color(0xFFB45309);
        label = 'REGISTERED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dot,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
