import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../dashboard/data/models/guest_folio_model.dart';
import '../../data/models/check_in_form_data.dart';

class CheckInSuccessDialog extends StatelessWidget {
  final GuestFolioModel folio;
  final CheckInFormData formData;
  final VoidCallback onDone;

  const CheckInSuccessDialog({
    super.key,
    required this.folio,
    required this.formData,
    required this.onDone,
  });

  String _formatRoom(String rawRoom) {
    final clean = rawRoom
        .replaceAll('#', '')
        .replaceAll('Room', '')
        .trim();
    if (clean.isEmpty) return 'Room 03';
    return 'Room $clean';
  }

  String _formatBookingRef(String rawId) {
    String ref = rawId.trim();
    if (ref.isEmpty) ref = 'BK-579337-516';
    if (!ref.startsWith('#')) {
      ref = '#$ref';
    }
    return ref;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _cleanPhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) {
      clean = '91${clean.substring(1)}';
    } else if (clean.length == 10) {
      clean = '91$clean';
    }
    return clean;
  }

  Future<void> _sendWhatsApp(BuildContext context) async {
    final guestName = folio.guestName.isNotEmpty && folio.guestName != 'Guest'
        ? folio.guestName
        : (formData.guestFullName.isNotEmpty ? formData.guestFullName : 'Valued Guest');

    final phone = folio.phone.isNotEmpty
        ? folio.phone
        : (formData.contactPhone.isNotEmpty ? formData.contactPhone : '0884921811');

    final cleanPhone = _cleanPhoneNumber(phone);

    final rawRoom = formData.selectedRoomNumber.isNotEmpty
        ? formData.selectedRoomNumber
        : folio.assignedRoom;
    final roomName = _formatRoom(rawRoom);

    final roomType = formData.roomType.isNotEmpty
        ? formData.roomType
        : folio.roomType;

    final bookingRef = _formatBookingRef(
      folio.bookingId?.isNotEmpty == true
          ? folio.bookingId!
          : (folio.effectiveBookingId.isNotEmpty ? folio.effectiveBookingId : 'BK-579337-516'),
    );

    final inDate = _formatDate(formData.checkInDate);
    final outDate = _formatDate(formData.checkOutDate);

    final keycard = formData.assignedKeycardNumber.trim().isNotEmpty
        ? formData.assignedKeycardNumber.trim()
        : (folio.keycardNumber ?? '').trim();

    final advancePaid = formData.advancePaid > 0
        ? formData.advancePaid
        : folio.advancePaid;

    final totalAmount = formData.grandTotal > 0
        ? formData.grandTotal
        : (folio.totalAmount > 0 ? folio.totalAmount : formData.pricePerNight * formData.totalNights);

    final message = '''
🏨 *CHECK-IN CONFIRMATION*
*The Grand Palace Hotel & Suites*

Dear *$guestName*,
Welcome! Your express check-in has been successfully completed.

📋 *Stay Details:*
• *Booking Ref:* $bookingRef
• *Room Allocation:* $roomName ($roomType)
• *Check-in Date:* $inDate
• *Check-out Date:* $outDate
• *Assigned Keycard:* $keycard
• *Advance Paid:* ₹${advancePaid.toStringAsFixed(0)}
• *Total Folio:* ₹${totalAmount.toStringAsFixed(0)}

📄 *Digital Folio Invoice:*
Your digital guest folio invoice and room registration are securely confirmed.

If you require any room service, dining, or assistance, please reply to this WhatsApp message or dial 9 from your room phone.

Wish you a relaxing and pleasant stay! ✨🛎️
'''.trim();

    final encodedMessage = Uri.encodeComponent(message);
    final waUniversalUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');
    final waAppUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedMessage');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Opening WhatsApp for $guestName ($phone)...',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF15803D),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      if (await canLaunchUrl(waAppUri)) {
        await launchUrl(waAppUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(waUniversalUri)) {
        await launchUrl(waUniversalUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waUniversalUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(waUniversalUri, mode: LaunchMode.externalApplication);
      } catch (err) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open WhatsApp for $phone: $err'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final guestName = folio.guestName.isNotEmpty && folio.guestName != 'Guest'
        ? folio.guestName
        : (formData.guestFullName.isNotEmpty ? formData.guestFullName : 'Niraj Vekariya');

    final mobileNumber = folio.phone.isNotEmpty
        ? folio.phone
        : (formData.contactPhone.isNotEmpty ? formData.contactPhone : '0884921811');

    final rawRoom = formData.selectedRoomNumber.isNotEmpty
        ? formData.selectedRoomNumber
        : folio.assignedRoom;
    final roomAllocation = _formatRoom(rawRoom);

    final bookingRef = _formatBookingRef(
      folio.bookingId?.isNotEmpty == true
          ? folio.bookingId!
          : (folio.effectiveBookingId.isNotEmpty ? folio.effectiveBookingId : 'BK-579337-516'),
    );

    final checkInDateStr = _formatDate(formData.checkInDate);
    final checkOutDateStr = _formatDate(formData.checkOutDate);
    final stayPeriod = '$checkInDateStr to $checkOutDateStr';

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with Check Icon & Titles
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00C853),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formData.isEditingBooking ? 'Booking updated' : 'Check-In Completed Successfully!',
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Guest has been assigned to $roomAllocation',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 2. Subtle Divider
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                height: 1,
                color: const Color(0xFFE2E8F0),
              ),

              // 3. Info Key-Value Rows
              _buildInfoRow('Guest Name:', guestName, isTeal: false),
              const SizedBox(height: 14),
              _buildInfoRow('Mobile Number:', mobileNumber, isTeal: true),
              const SizedBox(height: 14),
              _buildInfoRow('Booking Ref #:', bookingRef, isTeal: true),
              const SizedBox(height: 14),
              _buildInfoRow('Room Allocation:', roomAllocation, isTeal: false),
              const SizedBox(height: 14),
              _buildInfoRow('Check-in & Check-out:', stayPeriod, isTeal: false),

              const SizedBox(height: 26),

              // 4. Responsive Action Buttons Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 540;

                  final whatsappButton = ElevatedButton.icon(
                    onPressed: () => _sendWhatsApp(context),
                    icon: const _WhatsAppBubbleIcon(size: 18),
                    label: Text(
                      'Send WhatsApp',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );

                  final doneButton = OutlinedButton(
                    onPressed: onDone,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        whatsappButton,
                        const SizedBox(height: 10),
                        doneButton,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      whatsappButton,
                      const SizedBox(width: 10),
                      doneButton,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required bool isTeal}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isTeal ? const Color(0xFF0F766E) : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

class _WhatsAppBubbleIcon extends StatelessWidget {
  final double size;

  const _WhatsAppBubbleIcon({this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.chat_bubble_rounded, size: size, color: Colors.white),
          Icon(Icons.phone_rounded, size: size * 0.52, color: const Color(0xFF22C55E)),
        ],
      ),
    );
  }
}
