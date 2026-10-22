import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

    final mostRecentStay = guest.currentStay ?? (guest.stayHistory.isNotEmpty ? guest.stayHistory.first : null);
    final isInHouse = guest.status == GuestStatus.inHouse;
    final isRegistered = guest.status == GuestStatus.registered;
    final initial = guest.name.trim().isNotEmpty ? guest.name.trim()[0].toUpperCase() : 'G';
    final rawRoom = (mostRecentStay?.roomNumber ?? guest.lastRoomNumber).replaceAll('Room', '').replaceAll('#', '').trim();
    final hasAssignedRoom = rawRoom.isNotEmpty && rawRoom != 'Not Assigned' && rawRoom != 'N/A';
    final roomNum = hasAssignedRoom ? rawRoom : 'N/A';
    final formattedRoom = hasAssignedRoom ? (roomNum.startsWith('#') ? roomNum : '#$roomNum') : 'NO ROOM';
    final checkInDate = mostRecentStay?.checkInDate ?? guest.lastCheckInDate;
    final checkOutDate = mostRecentStay?.checkOutDate ?? guest.lastCheckOutDate;

    final stayDate = isInHouse ? checkInDate : checkOutDate;
    final detail = [
      if (hasAssignedRoom) formattedRoom else if (isRegistered) 'Awaiting check-in',
      dateFormat.format(stayDate),
      if (guest.mobile.trim().isNotEmpty) guest.mobile.trim(),
    ].join('  ·  ');

    final accent = _statusColor(guest.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7EEF2)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isInHouse ? const Color(0xFFE6F7F2) : const Color(0xFFF4F7F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      initial,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isInHouse ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                guest.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                  height: 1.1,
                                ),
                              ),
                            ),
                            if (!isRegistered) ...[
                              const SizedBox(width: 8),
                              _buildStatusPill(guest.status, accent),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(GuestStatus status) {
    switch (status) {
      case GuestStatus.inHouse:
        return const Color(0xFF15803D);
      case GuestStatus.checkedOut:
        return const Color(0xFF475569);
      case GuestStatus.cancelled:
        return const Color(0xFFDC2626);
      case GuestStatus.registered:
        return const Color(0xFFB45309);
    }
  }

  Widget _buildStatusPill(GuestStatus status, Color color) {
    final String label;
    switch (status) {
      case GuestStatus.inHouse:
        label = 'IN-HOUSE';
        break;
      case GuestStatus.checkedOut:
        label = 'DEPARTED';
        break;
      case GuestStatus.cancelled:
        label = 'CANCELLED';
        break;
      case GuestStatus.registered:
        label = 'REGISTERED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}
