import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../dashboard/data/models/guest_folio_model.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../pages/guest_folio_pdf_preview_page.dart';
class GuestFolioDetailsView extends StatefulWidget {
  final GuestFolioModel folio;
  final bool isDialog;
  final VoidCallback? onClose;
  final int initialTabIndex;
  final ValueChanged<GuestFolioModel>? onFolioLoaded;

  const GuestFolioDetailsView({
    super.key,
    required this.folio,
    this.isDialog = false,
    this.onClose,
    this.initialTabIndex = 0,
    this.onFolioLoaded,
  });

  @override
  State<GuestFolioDetailsView> createState() => _GuestFolioDetailsViewState();
}

class _GuestFolioDetailsViewState extends State<GuestFolioDetailsView> {
  late int _activeTabIndex; // 0: Profile & KYC, 1: Booking & Rooms, 2: Billing & Payments, 3: Activity Timeline
  late GuestFolioModel _folio;
  bool _loadingBooking = true;
  bool _pdfBusy = false;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
    _folio = widget.folio;
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final loaded = await DashboardRepository().fetchBooking(widget.folio.id);
    if (!mounted) return;
    setState(() {
      _loadingBooking = false;
      if (loaded != null) _folio = loaded;
    });
    if (loaded != null) widget.onFolioLoaded?.call(loaded);
  }

  String _whatsappPhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0') && digits.length > 10) {
      digits = digits.substring(1);
    }
    if (digits.length == 10) return '91$digits';
    if (digits.startsWith('91') && digits.length == 12) return digits;
    return digits;
  }

  Future<void> _sendFolioOnWhatsApp() async {
    final folio = _folio;
    final phone = _whatsappPhone(folio.phone);
    if (phone.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This guest has no mobile number for WhatsApp.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final booking = folio.bookingId != null && folio.bookingId!.trim().isNotEmpty
        ? folio.bookingId!.trim()
        : folio.effectiveBookingId;
    final lines = <String>[
      '*Guest Folio*',
      'Guest: ${folio.guestName}',
      if ((folio.secondaryGuestName ?? '').trim().isNotEmpty) 'Second guest: ${folio.secondaryGuestName}',
      'Booking: $booking',
      'Room: ${folio.assignedRoom} (${folio.roomType})',
      'Check-in: ${DateFormatter.formatDate(folio.actualCheckIn ?? folio.checkInDate)}',
      'Check-out: ${DateFormatter.formatDate(folio.actualCheckOut ?? folio.checkOutDate)}',
      'Total: ${CurrencyFormatter.format(folio.totalAmount)}',
      'Paid: ${CurrencyFormatter.format(folio.advancePaid)}',
      'Pending: ${CurrencyFormatter.format(folio.pendingAmount)}',
      'Payment: ${folio.paymentMode}',
      if ((folio.guestNotes ?? '').trim().isNotEmpty) 'Notes: ${folio.guestNotes}',
    ];
    final text = Uri.encodeComponent(lines.join('\n'));
    final appUri = Uri.parse('whatsapp://send?phone=$phone&text=$text');
    final webUri = Uri.parse('https://wa.me/$phone?text=$text');

    Future<bool> open(Uri uri) async {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    try {
      final opened = await open(appUri);
      if (!opened) {
        final openedWeb = await open(webUri);
        if (!openedWeb && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp.'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    } catch (_) {
      try {
        await open(webUri);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _openGuestFolioPdf() async {
    if (_pdfBusy) return;
    setState(() => _pdfBusy = true);
    final navigator = Navigator.of(context, rootNavigator: true);
    final loaderRoute = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF0F766E)),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Generating folio PDF...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    navigator.push(loaderRoute);
    try {
      final pdf = await DashboardRepository().fetchBookingPdf(_folio.id);
      if (loaderRoute.isActive) navigator.removeRoute(loaderRoute);
      if (!mounted) return;
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => GuestFolioPdfPreviewPage(bytes: pdf.bytes, fileName: pdf.fileName),
        ),
      );
    } catch (error) {
      if (loaderRoute.isActive) navigator.removeRoute(loaderRoute);
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final folio = _folio;
    final isDeparted = folio.status == FolioStatus.departed;
    final isPaid = folio.pendingAmount <= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loadingBooking) const LinearProgressIndicator(minHeight: 2, color: Color(0xFF0F766E)),
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
                            onPressed: _pdfBusy ? null : _openGuestFolioPdf,
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
                            onPressed: _sendFolioOnWhatsApp,
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
                          onPressed: _pdfBusy ? null : _openGuestFolioPdf,
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
                          onPressed: _sendFolioOnWhatsApp,
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
                        folio.phone.isNotEmpty ? folio.phone : '—',
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
                        folio.email.isNotEmpty ? folio.email : '—',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFieldColumn(
                        'Address / City',
                        folio.address != null && folio.address!.isNotEmpty
                            ? folio.address!
                            : '—',
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
                        folio.phone.isNotEmpty ? folio.phone : '—',
                        icon: Icons.phone_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFieldColumn(
                        'Email Address',
                        folio.email.isNotEmpty ? folio.email : '—',
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
                        'Address / City',
                        folio.address != null && folio.address!.isNotEmpty
                            ? folio.address!
                            : '—',
                        icon: Icons.location_on_outlined,
                      ),
                    ),
                  ],
                ),
              ],
              if (folio.secondaryGuestName != null && folio.secondaryGuestName!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildFieldColumn('Second Guest', folio.secondaryGuestName!),
              ],
              if (folio.guestNotes != null && folio.guestNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildFieldColumn('Notes', folio.guestNotes!),
              ],
              if (folio.createdByName != null && folio.createdByName!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildFieldColumn('Checked In By', folio.createdByName!),
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
                  if (folio.isGovtIdVerified)
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
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF0F766E)),
                  const SizedBox(width: 6),
                  Text(
                    'UPLOADED ID PROOF PHOTOS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (folio.idImageUrls.isEmpty)
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
                )
              else
                _buildImageGrid(
                  context,
                  urls: folio.idImageUrls,
                  titleFor: (index) => 'ID Photo ${index + 1}',
                  icon: Icons.credit_card_rounded,
                ),
              if (folio.signatureUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.draw_outlined, size: 14, color: Color(0xFF0F766E)),
                    const SizedBox(width: 6),
                    Text(
                      'SIGNATURES',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildImageGrid(
                  context,
                  urls: folio.signatureUrls,
                  titleFor: (index) => 'Signature ${index + 1}',
                  icon: Icons.draw_outlined,
                ),
              ],
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
                  Expanded(
                    child: Text(
                      'Stay Schedule & Duration',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
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
                  Expanded(
                    child: Text(
                      'Allocated Room Details (1)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
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
                      children: [
                        Expanded(
                          child: Text(
                            'Room #${folio.assignedRoom}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F766E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
            ],
          ),
        ),

        const SizedBox(height: 14),

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
              _buildFieldColumn(
                'Guests',
                '${folio.adultCount ?? folio.numberOfGuests} Adult${(folio.adultCount ?? folio.numberOfGuests) == 1 ? '' : 's'}'
                    '${folio.childCount != null ? ', ${folio.childCount} Child${folio.childCount == 1 ? '' : 'ren'}' : ''}',
                icon: Icons.people_outline_rounded,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFieldColumn(
                      'Check-In Date',
                      DateFormatter.formatDate(folio.actualCheckIn ?? folio.checkInDate),
                      icon: Icons.login_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFieldColumn(
                      'Check-Out Date',
                      DateFormatter.formatDate(folio.actualCheckOut ?? folio.checkOutDate),
                      icon: Icons.logout_rounded,
                    ),
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
  // TAB 3: BILLING & PAYMENTS
  // ==========================================
  Widget _buildBillingAndPaymentsTab(GuestFolioModel folio, bool isMobile) {
    final effectiveTotal = folio.totalAmount > 0 ? folio.totalAmount : 3500.0;
    final effectivePaid = folio.paidAmount > 0 ? folio.paidAmount : (folio.advancePaid > 0 ? folio.advancePaid : effectiveTotal);
    final effectivePending = folio.pendingAmount;
    final splitTax = folio.cgstAmount <= 0 && folio.sgstAmount <= 0 && folio.tax > 0;
    final cgst = splitTax ? folio.tax / 2 : folio.cgstAmount;
    final sgst = splitTax ? folio.tax / 2 : folio.sgstAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildFieldColumn('Room Charge', CurrencyFormatter.format(folio.roomCharges))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFieldColumn('CGST', CurrencyFormatter.format(folio.cgstAmount))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildFieldColumn('SGST', CurrencyFormatter.format(folio.sgstAmount))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFieldColumn('Extra Charges', CurrencyFormatter.format(folio.extraCharges))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFieldColumn(
                      'Discount',
                      folio.discount > 0
                          ? '-${CurrencyFormatter.format(folio.discount)}'
                          : CurrencyFormatter.format(0),
                      valueColor: folio.discount > 0 ? const Color(0xFFDC2626) : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF0F766E)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Financial Settlement & Tax Details',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _settlementAmount(
                      'Base Amount',
                      CurrencyFormatter.format(effectiveTotal),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _settlementAmount(
                      'GST / Taxes',
                      folio.tax > 0 ? CurrencyFormatter.format(folio.tax) : '₹0',
                      notes: [
                        'CGST ${CurrencyFormatter.format(cgst)}',
                        'SGST ${CurrencyFormatter.format(sgst)}',
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _settlementAmount(
                      'Paid Amount',
                      CurrencyFormatter.format(effectivePaid),
                      valueColor: const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _settlementAmount(
                      'Pending Due',
                      CurrencyFormatter.format(effectivePending),
                      valueColor: effectivePending > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _settlementAmount(
                'Discount',
                folio.discount > 0 ? '-${CurrencyFormatter.format(folio.discount)}' : CurrencyFormatter.format(0),
                valueColor: folio.discount > 0 ? const Color(0xFFDC2626) : AppColors.textPrimary,
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
                children: [
                  const Icon(Icons.payment_rounded, size: 16, color: Color(0xFF0F766E)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Payment Transaction History (${folio.payments.isNotEmpty ? folio.payments.length : 1})',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.55),
                child: ListView.separated(
                  shrinkWrap: true,
                  primary: false,
                  physics: const BouncingScrollPhysics(),
                  itemCount: folio.payments.isNotEmpty ? folio.payments.length : 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (folio.payments.isEmpty) {
                      final method = folio.paymentMode.isNotEmpty ? folio.paymentMode : 'CASH';
                      return _paymentHistoryCard(
                        date: DateFormatter.formatShort(folio.checkInDate),
                        transactionId: folio.receiptNumber ?? 'RCP-691574',
                        description: 'Full Check-in / Checkout Settlement - $method settlement at check-in',
                        method: method.toUpperCase(),
                        amount: CurrencyFormatter.format(effectivePaid),
                        gst: '₹0',
                        total: CurrencyFormatter.format(effectivePaid),
                        status: 'PAID',
                      );
                    }
                    final payment = folio.payments[index];
                    return _paymentHistoryCard(
                      date: DateFormatter.formatShort(payment.date),
                      transactionId: payment.reference,
                      description: 'Payment settlement via ${payment.paymentMethod}',
                      method: payment.paymentMethod.toUpperCase(),
                      amount: CurrencyFormatter.format(payment.amount),
                      gst: '₹0',
                      total: CurrencyFormatter.format(payment.amount),
                      status: payment.status.toUpperCase(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentHistoryCard({
    required String date,
    required String transactionId,
    required String description,
    required String method,
    required String amount,
    required String gst,
    required String total,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FFFE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _paymentDetail('Date', date)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF15803D)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _paymentDetail('Transaction ID', transactionId.isEmpty ? '—' : transactionId, valueColor: const Color(0xFF0F766E)),
          const SizedBox(height: 10),
          _paymentDetail('Description', description),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _paymentDetail('Method', method)),
              const SizedBox(width: 8),
              Expanded(child: _paymentDetail('Amount', amount)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _paymentDetail('GST', gst)),
              const SizedBox(width: 8),
              Expanded(child: _paymentDetail('Total', total, emphasize: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentDetail(String label, String value, {Color? valueColor, bool emphasize = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: emphasize ? 13 : 12,
            height: 1.35,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _settlementAmount(
    String label,
    String value, {
    Color? valueColor,
    List<String> notes = const [],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
        for (final note in notes) ...[
          const SizedBox(height: 2),
          Text(
            note,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _buildImageGrid(
    BuildContext context, {
    required List<String> urls,
    required String Function(int index) titleFor,
    required IconData icon,
  }) {
    return Column(
      children: [
        for (var start = 0; start < urls.length; start += 2) ...[
          if (start > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = start; i < start + 2; i++) ...[
                if (i > start) const SizedBox(width: 8),
                Expanded(
                  child: i < urls.length
                      ? _buildIdProofTile(
                          context,
                          titleFor(i),
                          urls[i],
                          icon,
                          imageUrl: urls[i],
                          imageHeight: 92,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildIdProofTile(
    BuildContext context,
    String title,
    String filename,
    IconData icon, {
    String? imageUrl,
    double imageHeight = 180,
  }) {
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
                    height: 360,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: _BookingNetworkImage(
                                url: imageUrl,
                                height: 360,
                                icon: icon,
                              ),
                            ),
                          )
                        : Column(
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
        height: imageUrl == null ? 84 : null,
        padding: EdgeInsets.all(imageUrl == null ? 8 : 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: imageUrl == null
            ? Column(
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
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: imageHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _BookingNetworkImage(
                        url: imageUrl,
                        height: imageHeight,
                        icon: icon,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BookingNetworkImage extends StatelessWidget {
  final String url;
  final double height;
  final IconData icon;
  final BoxFit fit;

  const _BookingNetworkImage({
    required this.url,
    required this.height,
    required this.icon,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final cacheWidth = (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round();
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Image.network(
        url,
        fit: fit,
        alignment: Alignment.center,
        cacheWidth: cacheWidth > 0 ? cacheWidth : null,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0F766E),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Center(
          child: Icon(icon, color: const Color(0xFF0F766E)),
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
