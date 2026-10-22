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
  String get _keyCode => widget.formData.assignedKeycardNumber.trim();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Step 4: Review & Check-In',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_keyCode.isNotEmpty && _keyCode.toLowerCase() != 'null') ...[
          Text(
            'ROOM KEY',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 44,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              _keyCode,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

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
              if (widget.formData.secondGuestName != null && widget.formData.secondGuestName!.isNotEmpty)
                _buildSummaryRow(
                  'Second Guest',
                  '${widget.formData.secondGuestName}${widget.formData.secondGuestPhone != null && widget.formData.secondGuestPhone!.isNotEmpty ? " (${widget.formData.secondGuestPhone})" : ""}',
                ),
              _buildSummaryRow('Total Guests', '${widget.formData.numberOfGuests}'),
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
