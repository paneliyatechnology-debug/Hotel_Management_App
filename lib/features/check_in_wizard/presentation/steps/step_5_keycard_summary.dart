import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/check_in_form_data.dart';

class Step5KeycardSummary extends StatefulWidget {
  final CheckInFormData formData;
  final ValueChanged<CheckInFormData> onDataChanged;

  const Step5KeycardSummary({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step5KeycardSummary> createState() => _Step5KeycardSummaryState();
}

class _Step5KeycardSummaryState extends State<Step5KeycardSummary> {
  late String _keycard;
  late bool _agree;

  final List<String> _availableKeycards = [
    'KC-101 (Floor 1 NFC)',
    'KC-102 (Floor 1 NFC)',
    'KC-103 (Floor 1 Master)',
    'KC-201 (Floor 2 NFC)',
    'KC-202 (Floor 2 NFC)',
  ];

  @override
  void initState() {
    super.initState();
    _keycard = widget.formData.assignedKeycardNumber.isNotEmpty
        ? widget.formData.assignedKeycardNumber
        : _availableKeycards.first;
    _agree = widget.formData.agreeTermsAndSignature;
  }

  void _notify() {
    final updated = widget.formData.copy();
    updated.assignedKeycardNumber = _keycard;
    updated.agreeTermsAndSignature = _agree;
    widget.onDataChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // RFID Keycard Assignment
        Text(
          'ASSIGN PHYSICAL RFID KEYCARD *',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _availableKeycards.contains(_keycard) ? _keycard : _availableKeycards.first,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              items: _availableKeycards.map((kc) {
                return DropdownMenuItem<String>(
                  value: kc,
                  child: Row(
                    children: [
                      const Icon(Icons.nfc, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(kc),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _keycard = val);
                  _notify();
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'CHECK-IN SUMMARY',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.statusAvailableBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ready to Check-In',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusAvailable,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              _buildSummaryRow('Primary Guest', widget.formData.guestFullName.isNotEmpty ? widget.formData.guestFullName : 'Not provided'),
              _buildSummaryRow('Primary Govt ID', '${widget.formData.idType} (${widget.formData.idNumber.isNotEmpty ? widget.formData.idNumber : "Verified"})'),
              if (widget.formData.idFrontPhotoUrl != null || widget.formData.idBackPhotoUrl != null)
                _buildSummaryRow(
                  'ID Document Photos',
                  (widget.formData.idFrontPhotoUrl != null && widget.formData.idBackPhotoUrl != null)
                      ? 'Front & Back Stored ✓'
                      : (widget.formData.idFrontPhotoUrl != null ? 'Front Side Stored ✓' : 'Back Side Stored ✓'),
                ),
              _buildSummaryRow('Party / Guests', '${widget.formData.partyType} (${widget.formData.numberOfGuests} Total Guests)'),
              if (widget.formData.accompanyingGuests.isNotEmpty)
                _buildSummaryRow(
                  'Attached Identities',
                  widget.formData.accompanyingGuests.map((g) => '${g.name.isNotEmpty ? g.name : "Member"} (${g.relationship})').join(', '),
                ),
              _buildSummaryRow('Assigned Room', 'Room ${widget.formData.selectedRoomNumber} (${widget.formData.roomType})'),
              _buildSummaryRow('Stay Period', '${DateFormatter.formatDate(widget.formData.checkInDate)} to ${DateFormatter.formatDate(widget.formData.checkOutDate)} (${widget.formData.totalNights} Nights)'),
              if (widget.formData.contactPhone.isNotEmpty)
                _buildSummaryRow('Contact / Phone', widget.formData.contactPhone),
              if (widget.formData.email.isNotEmpty)
                _buildSummaryRow('Email Address', widget.formData.email),
              _buildSummaryRow('Payment Method', widget.formData.paymentMode),
              _buildSummaryRow('Grand Total Folio', CurrencyFormatter.format(widget.formData.grandTotal), isHighlighted: true),
              _buildSummaryRow('Advance Deposit Paid', CurrencyFormatter.format(widget.formData.advancePaid), isHighlighted: true),
              _buildSummaryRow('Balance Due', CurrencyFormatter.format(widget.formData.balanceDue)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Digital Agreement
        InkWell(
          onTap: () {
            setState(() => _agree = !_agree);
            _notify();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agree,
                  activeColor: AppColors.accentGreen,
                  onChanged: (val) {
                    setState(() => _agree = val ?? true);
                    _notify();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest acknowledges resort policies & digital signature confirmed.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Generates live Folio invoice, assigns keycard, and updates room status to Occupied In-House.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: isHighlighted ? AppColors.primaryDark : AppColors.textPrimary,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
