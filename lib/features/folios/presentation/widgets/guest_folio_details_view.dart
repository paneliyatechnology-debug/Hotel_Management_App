import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final statusLabel = switch (folio.status) {
      FolioStatus.inHouse => 'IN-HOUSE',
      FolioStatus.departed => 'DEPARTED',
      FolioStatus.cancelled => 'CANCELLED',
      FolioStatus.confirmed => 'REGISTERED',
    };
    final totalBill = folio.totalAmount;
    final paid = folio.paidAmount > 0 ? folio.paidAmount : folio.advancePaid;
    final balance = folio.pendingAmount;
    final imageCount = folio.idImageUrls.length + folio.signatureUrls.length;
    final paymentCount = folio.payments.isNotEmpty ? folio.payments.length : (paid > 0 ? 1 : 0);
    final roomLine = _roomLine(folio);

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loadingBooking) const LinearProgressIndicator(minHeight: 2, color: Color(0xFF0F766E)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Guest header card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F766E),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      folio.guestName.isNotEmpty ? folio.guestName[0].toUpperCase() : 'G',
                                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              folio.guestName,
                                              style: GoogleFonts.inter(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isDeparted ? const Color(0xFFE0F2FE) : const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                statusLabel,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDeparted ? const Color(0xFF0369A1) : const Color(0xFF15803D),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        _metaIconRow(Icons.phone_rounded, folio.phone.isNotEmpty ? folio.phone : '—'),
                                        const SizedBox(height: 4),
                                        _metaIconRow(Icons.email_outlined, folio.email.isNotEmpty ? folio.email : '—'),
                                        const SizedBox(height: 4),
                                        _metaIconRow(Icons.bed_rounded, roomLine),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: _moneyStat('Total Bill', CurrencyFormatter.format(totalBill), const Color(0xFF0F172A))),
                                    Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                                    Expanded(child: _moneyStat('Paid', CurrencyFormatter.format(paid), const Color(0xFF16A34A))),
                                    Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                                    Expanded(
                                      child: _moneyStat(
                                        'Balance Due',
                                        CurrencyFormatter.format(balance),
                                        balance > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // All tabs visible — no horizontal scroll
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6FFFA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildTabButton(0, Icons.bed_rounded, 'Stay')),
                        Expanded(child: _buildTabButton(1, Icons.image_outlined, 'Images ($imageCount)')),
                        Expanded(child: _buildTabButton(2, Icons.receipt_long_rounded, 'Billing')),
                        Expanded(child: _buildTabButton(3, Icons.account_balance_wallet_outlined, 'Ledger ($paymentCount)')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCurrentTabContent(folio, true),
                ],
              ),
            ),
          ),

          // Bottom — PDF + WhatsApp only (same as before)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roomLine(GuestFolioModel folio) {
    final room = folio.assignedRoom.trim().isEmpty ? '—' : folio.assignedRoom.trim();
    final type = folio.roomType.trim();
    if (type.isEmpty) return room.startsWith('Room') ? room : 'Room $room';
    final roomLabel = room.toLowerCase().startsWith('room') ? room : 'Room $room';
    return '$roomLabel ($type)';
  }

  Widget _metaIconRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
          ),
        ),
      ],
    );
  }

  Widget _moneyStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, IconData icon, String title) {
    final isSelected = _activeTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x140F172A), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF475569)),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF475569),
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
        return _buildStayAndRoomTab(folio);
      case 1:
        return _buildImagesTab(folio);
      case 2:
        return _buildFolioBillingTab(folio);
      case 3:
        return _buildPaymentLedgerTab(folio);
      default:
        return _buildStayAndRoomTab(folio);
    }
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
    );
  }

  // TAB 0 — Stay & Room Details
  Widget _buildStayAndRoomTab(GuestFolioModel folio) {
    final nights = folio.totalNights > 0 ? folio.totalNights : 1;
    final adults = folio.adultCount ?? folio.numberOfGuests;
    final checkIn = DateFormatter.formatDateTime(folio.actualCheckIn ?? folio.checkInDate);
    final checkOut = DateFormatter.formatDateTime(folio.actualCheckOut ?? folio.checkOutDate);
    final notes = (folio.guestNotes ?? '').trim().isEmpty
        ? 'No special requests recorded for this stay.'
        : folio.guestNotes!.trim();
    final statusLabel = switch (folio.status) {
      FolioStatus.inHouse => 'IN-HOUSE',
      FolioStatus.departed => 'DEPARTED',
      FolioStatus.cancelled => 'CANCELLED',
      FolioStatus.confirmed => 'REGISTERED',
    };

    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Room & Stay Summary'),
              const SizedBox(height: 12),
              _kv('Assigned Room', folio.assignedRoom.trim().isEmpty ? '—' : folio.assignedRoom),
              _kv('Room Category', folio.roomType.trim().isEmpty ? '—' : folio.roomType),
              _kv('Check-In Date & Time', checkIn),
              _kv('Check-Out Date & Time', checkOut),
              _kv('Stay Duration', '$nights Night${nights == 1 ? '' : 's'}'),
              _kv('Number of Guests', '$adults Adult${adults == 1 ? '' : '(s)'}'),
              _kv('Address', (folio.address ?? '').trim().isEmpty ? '—' : folio.address!.trim()),
              const SizedBox(height: 8),
              Text('Special Requests / Notes', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(notes, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Booking Metadata'),
              const SizedBox(height: 10),
              _metaRow(
                'Booking ID / Reference',
                folio.effectiveBookingId,
                trailing: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF0F766E)),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: folio.effectiveBookingId));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking ID copied'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ),
              _metaRow(
                'Reservation Status',
                statusLabel,
                valueWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF15803D)),
                  ),
                ),
              ),
              _metaRow('Booking Date', DateFormatter.formatDate(folio.checkInDate)),
              _metaRow(
                'Payment Method',
                folio.paymentMode.isEmpty ? '—' : folio.paymentMode.toUpperCase(),
                valueWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    folio.paymentMode.isEmpty ? '—' : folio.paymentMode.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF334155)),
                  ),
                ),
              ),
              _metaRow('Handled By (Front Desk)', (folio.createdByName ?? '').trim().isEmpty ? 'Receptionist' : folio.createdByName!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, {Widget? trailing, Widget? valueWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: valueWidget ?? Text(value, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)))),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
        ],
      ),
    );
  }

  // TAB 1 — Images
  Widget _buildImagesTab(GuestFolioModel folio) {
    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _sectionTitle('ID proofs'),
                  const SizedBox(width: 8),
                  _countBadge(folio.idImageUrls.length),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Identity documents uploaded at check-in.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              if (folio.idImageUrls.isEmpty)
                Text('No ID proof images available.', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)))
              else
                _buildImageGrid(
                  context,
                  urls: folio.idImageUrls,
                  titleFor: (i) => 'ID proof ${i + 1}',
                  icon: Icons.badge_outlined,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _sectionTitle('Signatures'),
                  const SizedBox(width: 8),
                  _countBadge(folio.signatureUrls.length),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Guest signature captured at check-in.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              if (folio.signatureUrls.isEmpty)
                Text('No signature images available.', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)))
              else
                _buildImageGrid(
                  context,
                  urls: folio.signatureUrls,
                  titleFor: (i) => 'Signature ${i + 1}',
                  icon: Icons.draw_outlined,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$count', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF15803D))),
    );
  }

  // TAB 2 — Folio & Billing
  Widget _buildFolioBillingTab(GuestFolioModel folio) {
    final roomCharges = folio.roomCharges > 0
        ? folio.roomCharges
        : (folio.roomRatePerNight * (folio.totalNights > 0 ? folio.totalNights : 1));
    final discount = folio.discount;
    final extra = folio.extraCharges;
    const late = 0.0;
    final taxableRaw = roomCharges - discount + extra + late;
    final taxable = taxableRaw < 0 ? 0.0 : taxableRaw;
    final splitTax = folio.cgstAmount <= 0 && folio.sgstAmount <= 0 && folio.tax > 0;
    final cgst = splitTax ? folio.tax / 2 : folio.cgstAmount;
    final sgst = splitTax ? folio.tax / 2 : folio.sgstAmount;
    final total = folio.totalAmount;
    final paid = folio.paidAmount > 0 ? folio.paidAmount : folio.advancePaid;
    final balance = folio.pendingAmount;
    final nights = folio.totalNights > 0 ? folio.totalNights : 1;

    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Bill calculation'),
              const SizedBox(height: 12),
              _billLine('Room charges ($nights night${nights == 1 ? '' : 's'} - before tax)', CurrencyFormatter.format(roomCharges)),
              _billLine('Discount', '-${CurrencyFormatter.format(discount)}', valueColor: const Color(0xFF16A34A)),
              _billLine('Extra charges', CurrencyFormatter.format(extra)),
              _billLine('Late check-out charges', CurrencyFormatter.format(late)),
              _billLine('Taxable amount', CurrencyFormatter.format(taxable), bold: true),
              _billLine('CGST (9%)', '+${CurrencyFormatter.format(cgst)}'),
              _billLine('SGST (9%)', '+${CurrencyFormatter.format(sgst)}'),
              const Divider(height: 18, color: Color(0xFFE2E8F0)),
              _billLine('Total bill', CurrencyFormatter.format(total), bold: true),
              const SizedBox(height: 8),
              Text(
                '${CurrencyFormatter.format(roomCharges)} - ${CurrencyFormatter.format(discount)} discount + ${CurrencyFormatter.format(extra)} extra + ${CurrencyFormatter.format(late)} late check-out = ${CurrencyFormatter.format(taxable)}; + GST ${CurrencyFormatter.format(cgst + sgst)} = ${CurrencyFormatter.format(total)}',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Settlement Summary'),
              const SizedBox(height: 12),
              _billLine('Extra charges', CurrencyFormatter.format(extra)),
              _billLine('Late check-out charges', CurrencyFormatter.format(late)),
              const Divider(height: 18, color: Color(0xFFE2E8F0)),
              _billLine('Gross Total', CurrencyFormatter.format(total), bold: true),
              _billLine('Total Paid (Advance & Settled)', CurrencyFormatter.format(paid), valueColor: const Color(0xFF16A34A)),
              const Divider(height: 18, color: Color(0xFFE2E8F0)),
              _billLine('Balance Remaining', CurrencyFormatter.format(balance), bold: true, valueColor: balance > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
              if (balance > 0) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFEA580C)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Outstanding balance of ${CurrencyFormatter.format(balance)} pending collection at reception desk.',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF9A3412)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _billLine(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: const Color(0xFF334155),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3 — Payment Ledger
  Widget _buildPaymentLedgerTab(GuestFolioModel folio) {
    final paid = folio.paidAmount > 0 ? folio.paidAmount : folio.advancePaid;
    final rows = folio.payments.isNotEmpty
        ? folio.payments
        : (paid > 0
            ? [
                PaymentRecordModel(
                  id: folio.receiptNumber ?? 'ADVANCE',
                  date: folio.actualCheckIn ?? folio.checkInDate,
                  amount: paid,
                  paymentMethod: folio.paymentMode.isNotEmpty ? folio.paymentMode : 'UPI',
                  reference: 'Booking',
                  status: folio.paymentStatusLabel,
                ),
              ]
            : <PaymentRecordModel>[]);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Payment Receipts & Transaction Ledger'),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text('No payment receipts yet.', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)))
          else
            ...rows.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCCFBF1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormatter.formatDateTime(p.date),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p.paymentMethod.toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF334155)),
                          ),
                        ),
                        Text('Source: ${p.reference.isEmpty ? 'Booking' : p.reference}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Received By: ${(folio.createdByName ?? '').trim().isEmpty ? 'Receptionist' : folio.createdByName!}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.format(p.amount),
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF16A34A)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p.status.toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
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

