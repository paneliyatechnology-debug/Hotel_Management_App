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
    final dateFormat = DateFormat('dd MMM yyyy');
    final mostRecentStay =
        guest.currentStay ?? (guest.stayHistory.isNotEmpty ? guest.stayHistory.first : null);
    final isInHouse = guest.status == GuestStatus.inHouse;
    final isRegistered = guest.status == GuestStatus.registered;
    final initial = guest.name.trim().isNotEmpty ? guest.name.trim()[0].toUpperCase() : 'G';

    final rawRoom = (mostRecentStay?.roomNumber ?? guest.lastRoomNumber)
        .replaceAll('Room', '')
        .replaceAll('#', '')
        .trim();
    final hasAssignedRoom = rawRoom.isNotEmpty && rawRoom != 'Not Assigned' && rawRoom != 'N/A';
    final roomLabel = hasAssignedRoom
        ? (rawRoom.startsWith('#') ? 'Room $rawRoom' : 'Room #$rawRoom')
        : (isRegistered ? 'Room pending' : 'No room');

    final checkInDate = guest.actualOrCheckInDate ?? mostRecentStay?.checkInDate;
    final dateLabel =
        checkInDate != null ? dateFormat.format(checkInDate.toLocal()) : '—';
    final mobile = guest.mobile.trim();
    final category = (mostRecentStay?.roomCategory ?? guest.lastRoomCategory).trim();
    final accent = _accentFor(guest.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isInHouse ? const Color(0xFF99F6E4) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: isInHouse
                      ? const Color(0x100F766E)
                      : const Color(0x080F172A),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isInHouse
                                ? const [Color(0xFF0F766E), Color(0xFF14B8A6)]
                                : const [Color(0xFF475569), Color(0xFF94A3B8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          initial,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _statusPill(guest.status),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasAssignedRoom && category.isNotEmpty
                                  ? '$roomLabel · $category'
                                  : roomLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isInHouse
                                    ? const Color(0xFF0F766E)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: accent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _infoCell(
                          icon: Icons.login_rounded,
                          label: 'Check-in',
                          value: dateLabel,
                          color: accent,
                        ),
                      ),
                      Expanded(
                        child: _infoCell(
                          icon: Icons.call_rounded,
                          label: 'Mobile',
                          value: mobile.isNotEmpty ? mobile : '—',
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCell({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                    height: 1.1,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _accentFor(GuestStatus status) {
    switch (status) {
      case GuestStatus.inHouse:
        return const Color(0xFF0F766E);
      case GuestStatus.checkedOut:
        return const Color(0xFF64748B);
      case GuestStatus.cancelled:
        return const Color(0xFFDC2626);
      case GuestStatus.registered:
        return const Color(0xFFD97706);
    }
  }

  Widget _statusPill(GuestStatus status) {
    late final String label;
    late final Color fg;
    late final Color bg;
    late final Color border;

    switch (status) {
      case GuestStatus.inHouse:
        label = 'IN-HOUSE';
        fg = const Color(0xFF166534);
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFFBBF7D0);
        break;
      case GuestStatus.checkedOut:
        label = 'DEPARTED';
        fg = const Color(0xFF475569);
        bg = const Color(0xFFF1F5F9);
        border = const Color(0xFFE2E8F0);
        break;
      case GuestStatus.cancelled:
        label = 'CANCELLED';
        fg = const Color(0xFFB91C1C);
        bg = const Color(0xFFFEE2E2);
        border = const Color(0xFFFECACA);
        break;
      case GuestStatus.registered:
        label = 'REGISTERED';
        fg = const Color(0xFFB45309);
        bg = const Color(0xFFFEF3C7);
        border = const Color(0xFFFDE68A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: fg,
        ),
      ),
    );
  }
}
