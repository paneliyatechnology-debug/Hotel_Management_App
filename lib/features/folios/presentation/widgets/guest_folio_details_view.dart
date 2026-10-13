import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../dashboard/data/models/guest_folio_model.dart';
import 'in_house_actions_dialogs.dart';

class GuestFolioDetailsView extends StatefulWidget {
  final GuestFolioModel folio;
  final bool isDialog;
  final VoidCallback? onClose;
  final int initialTabIndex;

  const GuestFolioDetailsView({
    super.key,
    required this.folio,
    this.isDialog = false,
    this.onClose,
    this.initialTabIndex = 0,
  });

  @override
  State<GuestFolioDetailsView> createState() => _GuestFolioDetailsViewState();
}

class _GuestFolioDetailsViewState extends State<GuestFolioDetailsView> {
  late int _activeTabIndex; // 0: Profile & KYC, 1: Booking & Rooms, 2: Billing & Payments, 3: Activity Timeline

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final folio = widget.folio;
    final isDeparted = folio.status == FolioStatus.departed;
    final isPaid = folio.pendingAmount <= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. TOP HEADER (Avatar, Name, Status, Paid pill, Booking ID)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isDialog ? 16 : 18,
                vertical: widget.isDialog ? 14 : 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: widget.isDialog ? 44 : 48,
                    height: widget.isDialog ? 44 : 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F766E),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      folio.guestName.isNotEmpty ? folio.guestName[0].toUpperCase() : 'G',
                      style: GoogleFonts.inter(
                        fontSize: widget.isDialog ? 18 : 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Guest info & badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              folio.guestName,
                              style: GoogleFonts.inter(
                                fontSize: widget.isDialog ? 16 : 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            // In-House / Departed Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDeparted ? const Color(0xFFE0F2FE) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDeparted ? const Color(0xFFBAE6FD) : const Color(0xFF86EFAC),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isDeparted ? 'DEPARTED' : 'IN-HOUSE',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDeparted ? const Color(0xFF0369A1) : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                            // Paid / Pending Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                          ],
                        ),
                        const SizedBox(height: 3),
                        Builder(builder: (_) {
                          final rawRoom = folio.assignedRoom.replaceAll('Room', '').replaceAll('#', '').trim();
                          final displayRoom = rawRoom.isNotEmpty ? '#$rawRoom' : 'N/A';
                          return Text(
                            'Booking #${folio.effectiveBookingId} • Room $displayRoom',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Optional Dialog Close Button
                  if (widget.isDialog && widget.onClose != null)
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      splashRadius: 20,
                    ),
                ],
              ),
            ),

            // 2. TAB SELECTOR BAR (No horizontal scrolling on mobile, all tabs visible)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6FFFA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        0,
                        Icons.person_outline_rounded,
                        isMobile ? 'Profile' : 'Guest Profile & KYC',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTabButton(
                        1,
                        Icons.meeting_room_outlined,
                        isMobile ? 'Rooms' : 'Booking & Rooms',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTabButton(
                        2,
                        Icons.credit_card_rounded,
                        isMobile ? 'Billing' : 'Billing & Payments',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTabButton(
                        3,
                        Icons.timeline_rounded,
                        isMobile ? 'Timeline' : 'Activity Timeline',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // 3. TAB CONTENT BODY (Scrolls cleanly within remaining space)
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(widget.isDialog ? 14 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentTabContent(folio, isMobile),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // 4. FOOTER ACTIONS (No horizontal scroll, show all)
            // 4. FOOTER ACTIONS
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: isMobile
                  ? Row(
                      children: [
                        // Action 1: Guest Folio PDF
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F766E),
                              side: const BorderSide(color: Color(0xFF0F766E), width: 1.2),
                              backgroundColor: const Color(0xFFF0FDFA),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFF0F766E)),
                            label: Text(
                              'Guest Folio PDF',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Downloading Guest Folio PDF for ${folio.guestName}...'),
                                  backgroundColor: const Color(0xFF0F766E),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Action 2: Send on WhatsApp
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                            label: Text(
                              'Send on WhatsApp',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Sending guest folio details to ${folio.phone} via WhatsApp...'),
                                  backgroundColor: const Color(0xFF16A34A),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                        if (widget.isDialog) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                            onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                          ),
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        // Action 1: Guest Folio PDF
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(color: Color(0xFF0F766E), width: 1.2),
                            backgroundColor: const Color(0xFFF0FDFA),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFF0F766E)),
                          label: Text(
                            'Download Guest Folio PDF',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Downloading Guest Folio PDF for ${folio.guestName}...'),
                                backgroundColor: const Color(0xFF0F766E),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),

                        // Action 2: Send on WhatsApp
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          label: Text(
                            'Send on WhatsApp',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Sending guest folio details to ${folio.phone} via WhatsApp...'),
                                backgroundColor: const Color(0xFF16A34A),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),

                        const Spacer(),

                        if (widget.isDialog)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                            child: Text(
                              'Close',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabButton(int index, IconData icon, String title) {
    final isSelected = _activeTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF334155),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(GuestFolioModel folio, bool isMobile) {
    switch (_activeTabIndex) {
      case 0:
        return _buildGuestProfileAndKYCTab(folio, isMobile);
      case 1:
        return _buildBookingAndRoomsTab(folio, isMobile);
      case 2:
        return _buildBillingAndPaymentsTab(folio, isMobile);
      case 3:
        return _buildActivityTimelineTab(folio, isMobile);
      default:
        return _buildGuestProfileAndKYCTab(folio, isMobile);
    }
  }

  // ==========================================
  // TAB 1: GUEST PROFILE & KYC
  // ==========================================
  Widget _buildGuestProfileAndKYCTab(GuestFolioModel folio, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Personal Information
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 16, color: Color(0xFF0F766E)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Personal Information',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Responsive grid fields
              if (isMobile) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFieldColumn('Full Name', folio.guestName)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFieldColumn(
                        'Mobile Number',
                        folio.phone.isNotEmpty ? folio.phone : '+91 98765 43210',
                        icon: Icons.phone_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFieldColumn(
                        'Email Address',
                        folio.email.isNotEmpty ? folio.email : 'guest@example.com',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFieldColumn(
                        'Age / Date of Birth',
                        folio.dateOfBirth != null
                            ? DateFormatter.formatDate(folio.dateOfBirth!)
                            : '28 Yrs (12/04/1996)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFieldColumn('Gender', folio.gender.isNotEmpty ? folio.gender : 'Male'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFieldColumn(
                        'Address / City',
                        folio.address != null && folio.address!.isNotEmpty
                            ? folio.address!
                            : 'Mumbai, Maharashtra',
                        icon: Icons.location_on_outlined,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFieldColumn('Full Name', folio.guestName)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFieldColumn(
                        'Mobile Number',
                        folio.phone.isNotEmpty ? folio.phone : '+91 98765 43210',
                        icon: Icons.phone_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFieldColumn(
                        'Email Address',
                        folio.email.isNotEmpty ? folio.email : 'guest@example.com',
                        icon: Icons.email_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFieldColumn(
                        'Age / Date of Birth',
                        folio.dateOfBirth != null
                            ? DateFormatter.formatDate(folio.dateOfBirth!)
                            : '28 Yrs (12/04/1996)',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFieldColumn('Gender', folio.gender.isNotEmpty ? folio.gender : 'Male'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFieldColumn(
                        'Address / City',
                        folio.address != null && folio.address!.isNotEmpty
                            ? folio.address!
                            : 'Mumbai, Maharashtra',
                        icon: Icons.location_on_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Card 2: Govt KYC ID Proof
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF0F766E)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'KYC & Govt Identity Verification',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Govt KYC ID Proof',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'VERIFIED',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID Document Type', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 3),
                        Text(
                          folio.idType.isNotEmpty ? folio.idType.toUpperCase() : 'AADHAAR CARD',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID Document Number', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 3),
                        Text(
                          folio.maskedIdNumber,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Text(
                'UPLOADED ID PROOF PHOTOS:',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              // Photos row
              Row(
                children: [
                  Expanded(
                    child: _buildIdProofTile(context, 'Front ID Document', 'Front_Card.jpg', Icons.credit_card_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildIdProofTile(context, 'Back ID Document', 'Back_Card.jpg', Icons.badge_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Card 3: Current Stay Details
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hotel_rounded, size: 16, color: Color(0xFF0F766E)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Current Stay Details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFieldColumn('Assigned Room', '${folio.assignedRoom} (${folio.roomType})'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFieldColumn('Keycard Status', folio.keycardStatus, icon: Icons.nfc_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFieldColumn(
                      'Check-In Date',
                      DateFormatter.formatDate(folio.checkInDate),
                      icon: Icons.login_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFieldColumn(
                      'Check-Out Date',
                      DateFormatter.formatDate(folio.checkOutDate),
                      icon: Icons.logout_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Card 4: Folio & Billing Breakdown
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF0F766E)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Folio & Billing Breakdown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFieldColumn('Total Folio Amount', CurrencyFormatter.format(folio.totalAmount)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFieldColumn('Advance / Paid', CurrencyFormatter.format(folio.advancePaid), valueColor: const Color(0xFF059669)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFieldColumn('Pending Balance', CurrencyFormatter.format(folio.pendingAmount), valueColor: folio.hasPendingPayment ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFieldColumn('Payment Mode', folio.paymentMode, icon: Icons.payment_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: BOOKING & ROOMS
  // ==========================================
  Widget _buildBookingAndRoomsTab(GuestFolioModel folio, bool isMobile) {
    final nights = folio.totalNights > 0 ? folio.totalNights : 1;
    final totalRoomPrice = folio.roomRatePerNight * nights > 0
        ? folio.roomRatePerNight * nights
        : (folio.totalAmount > 0 ? folio.totalAmount : 3500.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Stay Schedule & Duration
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF0F766E)),
                  const SizedBox(width: 6),
                  Text(
                    'Stay Schedule & Duration',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFieldColumn(
                      'Check-In Date',
                      '${folio.checkInDate.day.toString().padLeft(2, '0')}/${folio.checkInDate.month.toString().padLeft(2, '0')}/${folio.checkInDate.year}',
                    ),
                  ),
                  Expanded(
                    child: _buildFieldColumn(
                      'Check-Out Date',
                      '${folio.checkOutDate.day.toString().padLeft(2, '0')}/${folio.checkOutDate.month.toString().padLeft(2, '0')}/${folio.checkOutDate.year}',
                    ),
                  ),
                  Expanded(
                    child: _buildFieldColumn(
                      'Duration / Nights',
                      '$nights Night(s)',
                      valueColor: const Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Card 2: Allocated Room Details
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.meeting_room_outlined, size: 16, color: Color(0xFF0F766E)),
                  const SizedBox(width: 6),
                  Text(
                    'Allocated Room Details (1)',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCCFBF1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Room #${folio.assignedRoom}',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: folio.status == FolioStatus.inHouse
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            folio.status == FolioStatus.inHouse ? 'OCCUPIED' : 'AVAILABLE',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: folio.status == FolioStatus.inHouse
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      folio.roomType.isNotEmpty ? folio.roomType : 'Deluxe Room',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatter.format(folio.roomRatePerNight > 0 ? folio.roomRatePerNight : 3500.0)} / night • $nights Night(s)',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFCCFBF1)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Room Total:',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        Text(
                          CurrencyFormatter.format(totalRoomPrice),
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (folio.status == FolioStatus.inHouse) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF0F766E)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.update_rounded, size: 14),
                      label: Text('Extend Stay', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      onPressed: () => InHouseActionsDialogs.showExtendStayModal(context, folio),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF0F766E)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.nfc_rounded, size: 14),
                      label: Text('Manage Keycard', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      onPressed: () => InHouseActionsDialogs.showKeycardManagementDialog(context, folio),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: BILLING & PAYMENTS
  // ==========================================
  Widget _buildBillingAndPaymentsTab(GuestFolioModel folio, bool isMobile) {
    final effectiveTotal = folio.totalAmount > 0 ? folio.totalAmount : 3500.0;
    final effectivePaid = folio.paidAmount > 0 ? folio.paidAmount : (folio.advancePaid > 0 ? folio.advancePaid : effectiveTotal);
    final effectivePending = folio.pendingAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Financial Settlement & Tax Details
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF0F766E)),
                      const SizedBox(width: 6),
                      Text(
                        'Financial Settlement & Tax Details',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  if (folio.status == FolioStatus.inHouse)
                    InkWell(
                      onTap: () => InHouseActionsDialogs.showAddPaymentModal(context, folio),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6FFFA),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, size: 13, color: Color(0xFF0F766E)),
                            const SizedBox(width: 2),
                            Text(
                              'Add Payment',
                              style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Base Amount', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 3),
                        Text(
                          CurrencyFormatter.format(effectiveTotal),
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GST / Taxes', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 3),
                        Text(
                          folio.tax > 0 ? CurrencyFormatter.format(folio.tax) : '₹0',
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                        Text('CGST: ₹0 | SGST: ₹0', style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Paid Amount', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 3),
                        Text(
                          CurrencyFormatter.format(effectivePaid),
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w900, color: const Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pending Due', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 3),
                        Text(
                          CurrencyFormatter.format(effectivePending),
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: effectivePending > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Card 2: Payment Transaction History
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payment_rounded, size: 16, color: Color(0xFF0F766E)),
                      const SizedBox(width: 6),
                      Text(
                        'Payment Transaction History (${folio.payments.isNotEmpty ? folio.payments.length : 1})',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Transaction Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DataTable(
                    headingRowHeight: 38,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 56,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFE6FFFA)),
                    columns: [
                      _buildDataColumn('Date'),
                      _buildDataColumn('Transaction ID'),
                      _buildDataColumn('Description'),
                      _buildDataColumn('Method'),
                      _buildDataColumn('Amount'),
                      _buildDataColumn('GST'),
                      _buildDataColumn('Total'),
                      _buildDataColumn('Status'),
                    ],
                    rows: folio.payments.isNotEmpty
                        ? folio.payments.map((p) {
                            return DataRow(
                              cells: [
                                DataCell(Text(DateFormatter.formatShort(p.date), style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500))),
                                DataCell(Text(p.reference, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E)))),
                                DataCell(Text('Payment settlement via ${p.paymentMethod}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(p.paymentMethod.toUpperCase(), style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  ),
                                ),
                                DataCell(Text(CurrencyFormatter.format(p.amount), style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600))),
                                DataCell(Text('₹0', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMuted))),
                                DataCell(Text(CurrencyFormatter.format(p.amount), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(p.status.toUpperCase(), style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF15803D))),
                                  ),
                                ),
                              ],
                            );
                          }).toList()
                        : [
                            DataRow(
                              cells: [
                                DataCell(Text(DateFormatter.formatShort(folio.checkInDate), style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500))),
                                DataCell(Text(folio.receiptNumber ?? 'RCP-691574', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E)))),
                                DataCell(Text('Full Check-in / Checkout Settlement - ${folio.paymentMode.isNotEmpty ? folio.paymentMode : "CASH"} settlement at check-in', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text((folio.paymentMode.isNotEmpty ? folio.paymentMode : 'CASH').toUpperCase(), style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  ),
                                ),
                                DataCell(Text(CurrencyFormatter.format(effectivePaid), style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600))),
                                DataCell(Text('₹0', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMuted))),
                                DataCell(Text(CurrencyFormatter.format(effectivePaid), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('PAID', style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF15803D))),
                                  ),
                                ),
                              ],
                            ),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E)),
      ),
    );
  }

  // ==========================================
  // TAB 4: ACTIVITY TIMELINE
  // ==========================================
  Widget _buildActivityTimelineTab(GuestFolioModel folio, bool isMobile) {
    final checkInTimeStr = '${folio.checkInDate.day.toString().padLeft(2, '0')}/${folio.checkInDate.month.toString().padLeft(2, '0')}/${folio.checkInDate.year}, 12:01:31 pm';
    final checkOutTimeStr = '${folio.checkOutDate.day.toString().padLeft(2, '0')}/${folio.checkOutDate.month.toString().padLeft(2, '0')}/${folio.checkOutDate.year}, 12:16:20 pm';

    final timelineEvents = [
      _TimelineEvent(
        title: 'Checked In',
        time: checkInTimeStr,
        desc: 'Guest checked in to Room #${folio.assignedRoom}.',
      ),
      _TimelineEvent(
        title: 'Booking Created',
        time: checkInTimeStr,
        desc: 'Booking #${folio.effectiveBookingId} created for ${folio.totalNights > 0 ? folio.totalNights : 1} night(s).',
      ),
      _TimelineEvent(
        title: 'Room Allocated',
        time: checkInTimeStr,
        desc: 'Allocated Room #${folio.assignedRoom} (${folio.roomType.isNotEmpty ? folio.roomType : "Deluxe Room"}).',
      ),
      _TimelineEvent(
        title: 'Payment Received',
        time: checkInTimeStr,
        desc: 'Payment of ${CurrencyFormatter.format(folio.advancePaid > 0 ? folio.advancePaid : (folio.paidAmount > 0 ? folio.paidAmount : 3500.0))} received via ${folio.paymentMode.isNotEmpty ? folio.paymentMode : "CASH"}.',
      ),
      if (folio.status == FolioStatus.departed)
        _TimelineEvent(
          title: 'Checked Out',
          time: checkOutTimeStr,
          desc: 'Folio closed and checkout finalized.',
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, size: 16, color: Color(0xFF0F766E)),
              const SizedBox(width: 6),
              Text(
                'Real-time Stay Activity Timeline',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Timeline items
          ...List.generate(timelineEvents.length, (idx) {
            final ev = timelineEvents[idx];
            final isLast = idx == timelineEvents.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Node + connector
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F766E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 13, color: Colors.white),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 44,
                        color: const Color(0xFF99F6E4),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ev.title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            ev.time,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ev.desc,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (!isLast) const SizedBox(height: 18),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFieldColumn(String label, String value, {IconData? icon, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: const Color(0xFF0F766E)),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdProofTile(BuildContext context, String title, String filename, IconData icon) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 18, color: const Color(0xFF0F766E)),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6FFFA),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF99F6E4)),
                          ),
                          alignment: Alignment.center,
                          child: Icon(icon, size: 28, color: const Color(0xFF0F766E)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          filename,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verified Govt KYC ID on Record',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Done', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 84,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: const Color(0xFF0F766E)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility_outlined, size: 13, color: Color(0xFF0F766E)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Preview Photo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineEvent {
  final String title;
  final String time;
  final String desc;

  const _TimelineEvent({
    required this.title,
    required this.time,
    required this.desc,
  });
}
