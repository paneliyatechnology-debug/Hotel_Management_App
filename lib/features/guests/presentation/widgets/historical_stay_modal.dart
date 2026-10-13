import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/guest_model.dart';

class HistoricalStayModal extends StatelessWidget {
  final HistoricalStayModel stay;
  final String guestName;

  const HistoricalStayModal({
    super.key,
    required this.stay,
    required this.guestName,
  });

  static Future<void> show(
    BuildContext context, {
    required HistoricalStayModel stay,
    required String guestName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HistoricalStayModal(
        stay: stay,
        guestName: guestName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            stay.bookingId,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.neutral900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(stay.status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stay Record • $guestName',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.neutral600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.borderSubtle),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // BOOKING SECTION
                _buildCard(
                  title: 'BOOKING INFORMATION',
                  icon: Icons.confirmation_number_outlined,
                  children: [
                    _buildRow('Booking ID', stay.bookingId),
                    _buildRow('Booking Date', dateFormat.format(stay.bookingDate)),
                    _buildRow('Booking Source', stay.bookingSource),
                    _buildRow('Booking Status', stay.status == GuestStatus.inHouse ? 'Active In-House' : stay.status == GuestStatus.checkedOut ? 'Completed' : 'Cancelled'),
                  ],
                ),

                const SizedBox(height: 16),

                // STAY SECTION
                _buildCard(
                  title: 'STAY DETAILS',
                  icon: Icons.hotel_outlined,
                  children: [
                    _buildRow('Room Number', 'Room ${stay.roomNumber}'),
                    _buildRow('Floor', stay.floor),
                    _buildRow('Room Category', stay.roomCategory),
                    _buildRow('Check-in', dateFormat.format(stay.checkInDate)),
                    _buildRow('Check-out', dateFormat.format(stay.checkOutDate)),
                    _buildRow('Number of Guests', '${stay.numberOfGuests} Guests'),
                  ],
                ),

                const SizedBox(height: 16),

                // BILLING SECTION
                _buildCard(
                  title: 'BILLING BREAKDOWN',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    _buildRow('Room Charges', currencyFormat.format(stay.roomCharges)),
                    if (stay.extraCharges > 0)
                      _buildRow('Extra Charges', currencyFormat.format(stay.extraCharges)),
                    if (stay.discount > 0)
                      _buildRow('Discount Applied', '- ${currencyFormat.format(stay.discount)}', isDiscount: true),
                    _buildRow('Taxes & GST (12%)', currencyFormat.format(stay.tax)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1, color: AppColors.borderSubtle),
                    ),
                    _buildRow(
                      'Grand Total',
                      currencyFormat.format(stay.totalAmount),
                      isTotal: true,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // PAYMENT SECTION
                _buildCard(
                  title: 'PAYMENT DETAILS',
                  icon: Icons.payments_outlined,
                  children: [
                    _buildRow('Paid Amount', currencyFormat.format(stay.paidAmount), isSuccess: stay.paidAmount > 0),
                    if (stay.pendingAmount > 0)
                      _buildRow('Pending Balance', currencyFormat.format(stay.pendingAmount), isWarning: true),
                    _buildRow('Payment Mode', stay.paymentMethod),
                    _buildRow('Payment Status', stay.paymentStatus),
                  ],
                ),

                const SizedBox(height: 16),

                // ACTIVITY AUDIT TRAIL
                _buildCard(
                  title: 'AUDIT & RECEPTION ACTIVITY',
                  icon: Icons.history_edu_outlined,
                  children: [
                    _buildRow('Checked-in by', stay.checkedInBy),
                    if (stay.checkedOutBy != null)
                      _buildRow('Checked-out by', stay.checkedOutBy!),
                    _buildRow('Check-in Timestamp', dateFormat.format(stay.checkInDate)),
                    if (stay.status == GuestStatus.checkedOut)
                      _buildRow('Check-out Timestamp', dateFormat.format(stay.checkOutDate)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.neutral700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
    bool isSuccess = false,
    bool isWarning = false,
  }) {
    Color valueColor = AppColors.neutral900;
    if (isDiscount) valueColor = AppColors.statusSuccess;
    if (isSuccess) valueColor = AppColors.statusSuccess;
    if (isWarning) valueColor = AppColors.statusWarning;
    if (isTotal) valueColor = AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 14 : 12,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: isTotal ? AppColors.neutral900 : AppColors.neutral600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: isTotal ? 16 : 13,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(GuestStatus status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case GuestStatus.inHouse:
        bg = AppColors.statusSuccessSurface;
        text = AppColors.statusSuccess;
        label = 'IN-HOUSE';
        break;
      case GuestStatus.checkedOut:
        bg = AppColors.primarySurface;
        text = AppColors.primary;
        label = 'CHECKED-OUT';
        break;
      case GuestStatus.cancelled:
        bg = AppColors.statusErrorSurface;
        text = AppColors.statusError;
        label = 'CANCELLED';
        break;
      case GuestStatus.registered:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        label = 'REGISTERED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: text,
        ),
      ),
    );
  }
}
