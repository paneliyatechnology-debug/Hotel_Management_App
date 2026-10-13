import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/guest_folio_model.dart';

class RecentCheckInOutSection extends StatefulWidget {
  final List<GuestFolioModel> folios;
  final ValueChanged<GuestFolioModel> onFolioTap;
  final ValueChanged<GuestFolioModel>? onCheckout;
  final VoidCallback? onNewCheckIn;
  final VoidCallback onViewAll;

  const RecentCheckInOutSection({
    super.key,
    required this.folios,
    required this.onFolioTap,
    this.onCheckout,
    this.onNewCheckIn,
    required this.onViewAll,
  });

  @override
  State<RecentCheckInOutSection> createState() => _RecentCheckInOutSectionState();
}

class _RecentCheckInOutSectionState extends State<RecentCheckInOutSection> {
  String _selectedFilter = 'All'; // 'All', 'Checked-In', 'Checked-Out'

  List<GuestFolioModel> get _filteredFolios {
    if (_selectedFilter == 'Checked-In') {
      return widget.folios.where((f) => f.status == FolioStatus.inHouse).toList();
    } else if (_selectedFilter == 'Checked-Out') {
      return widget.folios.where((f) => f.status == FolioStatus.departed).toList();
    }
    return widget.folios;
  }

  @override
  Widget build(BuildContext context) {
    final inHouseCount = widget.folios.where((f) => f.status == FolioStatus.inHouse).length;
    final departedCount = widget.folios.where((f) => f.status == FolioStatus.departed).length;
    final filtered = _filteredFolios;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECENT CHECK-IN & CHECK-OUT',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            "Today's guest activity",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: widget.onViewAll,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF99F6E4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF0F766E)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Filter Segment Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterTab('All', 'All (${widget.folios.length})'),
                const SizedBox(width: 8),
                _buildFilterTab('Checked-In', 'Checked-in ($inHouseCount)'),
                const SizedBox(width: 8),
                _buildFilterTab('Checked-Out', 'Checked-out ($departedCount)'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // List of Folio Cards matching screenshot
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.folder_open_rounded, size: 36, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'No $_selectedFilter folios found.',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...filtered.map((folio) => _buildCheckInOutCard(context, folio)),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x220F766E),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInOutCard(BuildContext context, GuestFolioModel folio) {
    final isInHouse = folio.status == FolioStatus.inHouse;
    final initial = folio.guestName.isNotEmpty ? folio.guestName[0].toUpperCase() : 'G';
    final stayNights = folio.checkOutDate.difference(folio.checkInDate).inDays.clamp(1, 30);

    String roomLabel = folio.assignedRoom;
    if (!roomLabel.startsWith('Room ')) {
      roomLabel = 'Room #${roomLabel.replaceAll('#', '')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => widget.onFolioTap(folio),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Dark Teal Avatar + Name + Room Pill + Category + Status Badge
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F766E),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            folio.guestName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  roomLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '•',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  folio.roomType.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isInHouse ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isInHouse ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isInHouse ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                            size: 11,
                            color: isInHouse ? const Color(0xFF059669) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isInHouse ? 'CHECKED-IN' : 'CHECKED-OUT',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isInHouse ? const Color(0xFF059669) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Row 2: Date + Night Pill + Keycard Pill + Chevron
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormatter.formatDate(folio.checkInDate)} → ${DateFormatter.formatDate(folio.checkOutDate)}',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Night badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🌙', style: TextStyle(fontSize: 9.5)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$stayNights Night${stayNights > 1 ? 's' : ''}',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Keycard badge
                            if (folio.keycardNumber != null && folio.keycardNumber!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.vpn_key_outlined,
                                      size: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      folio.keycardNumber!,
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
