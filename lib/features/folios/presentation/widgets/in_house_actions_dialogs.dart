import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../dashboard/data/models/guest_folio_model.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_event.dart';
import '../../../payments/presentation/widgets/payment_method_dropdown.dart';
import 'checkout_settlement_dialog.dart';

class InHouseActionsDialogs {
  InHouseActionsDialogs._();

  /// 1. Safe Checkout Dialog with financial clearance verification
  static void showSafeCheckoutDialog(BuildContext context, GuestFolioModel folio) {
    CheckoutSettlementDialog.show(context, folio);
  }

  /// 2. Extend Stay Modal with date picker and real-time computation
  static void showExtendStayModal(BuildContext context, GuestFolioModel folio) {
    DateTime selectedDate = folio.checkOutDate.add(const Duration(days: 1));
    int additionalNights = selectedDate.difference(folio.checkOutDate).inDays;
    if (additionalNights <= 0) additionalNights = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final addCharges = folio.roomRatePerNight * additionalNights;
            final newTotal = folio.totalAmount + addCharges;

            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Extend Guest Stay',
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          Text(
                            '${folio.guestName} • ${folio.assignedRoom}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${folio.totalNights} Nights currently',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Current vs New checkout
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current Checkout', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                DateFormatter.formatDate(folio.checkOutDate),
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: modalContext,
                              initialDate: selectedDate,
                              firstDate: folio.checkOutDate.add(const Duration(days: 1)),
                              lastDate: folio.checkOutDate.add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                selectedDate = picked;
                                additionalNights = selectedDate.difference(folio.checkOutDate).inDays;
                                if (additionalNights <= 0) additionalNights = 1;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('New Checkout', style: GoogleFonts.inter(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                                    const Icon(Icons.edit_calendar_rounded, size: 14, color: AppColors.primary),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormatter.formatDate(selectedDate),
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Calculation summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _dialogRow('Nightly Room Rate', CurrencyFormatter.format(folio.roomRatePerNight)),
                        _dialogRow('Additional Nights', '+$additionalNights Nights'),
                        _dialogRow('Extra Room Charges', '+${CurrencyFormatter.format(addCharges)}', color: AppColors.primaryDark),
                        const Divider(height: 14, color: Color(0xFFE2E8F0)),
                        _dialogRow('Updated Total Folio', CurrencyFormatter.format(newTotal), isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.read<DashboardBloc>().add(
                                  ExtendFolioStayEvent(
                                    folioId: folio.id,
                                    newCheckoutDate: selectedDate,
                                  ),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Stay extended for ${folio.guestName} until ${DateFormatter.formatDate(selectedDate)}.'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text('Confirm Extension', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 3. Add Payment Modal
  static void showAddPaymentModal(BuildContext context, GuestFolioModel folio) {
    final amountController = TextEditingController(
      text: folio.pendingAmount > 0 ? folio.pendingAmount.toInt().toString() : '1000',
    );
    final refController = TextEditingController(text: 'UPI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    String selectedMethod = 'UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Record Folio Payment',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${folio.guestName} • Pending: ${CurrencyFormatter.format(folio.pendingAmount)}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  Text('Payment Amount (₹)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Payment Method (from /api/v1/payment-methods)
                  Text('Payment Method', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  PaymentMethodChips(
                    value: selectedMethod,
                    onChanged: (code) => setModalState(() => selectedMethod = code),
                  ),
                  const SizedBox(height: 14),

                  // Reference ID
                  Text('Reference / Transaction ID', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: refController,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. TXN-94821 or Cash receipt #',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final parsed = double.tryParse(amountController.text) ?? 0;
                            if (parsed <= 0) return;
                            final record = PaymentRecordModel(
                              id: 'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                              date: DateTime.now(),
                              amount: parsed,
                              paymentMethod: selectedMethod,
                              reference: refController.text.trim().isEmpty ? 'Direct' : refController.text.trim(),
                              status: 'Successful',
                            );
                            Navigator.of(ctx).pop();
                            context.read<DashboardBloc>().add(
                                  AddFolioPaymentEvent(
                                    folioId: folio.id,
                                    payment: record,
                                  ),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Payment of ${CurrencyFormatter.format(parsed)} recorded.'),
                                backgroundColor: AppColors.statusAvailable,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text('Record Payment', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 4. Add Extra Charge Modal
  static void showAddChargeModal(BuildContext context, GuestFolioModel folio) {
    final itemController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Restaurant';

    final categories = [
      'Restaurant',
      'Room Service',
      'Laundry',
      'Minibar',
      'Extra Bed',
      'Airport Shuttle',
      'Spa / Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Post Folio Charge',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${folio.guestName} • ${folio.assignedRoom}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  Text('Service Category', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCategory,
                        items: categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedCategory = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text('Item / Service Description', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: itemController,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. Dinner Buffet (2 Guests), Laundry 3pcs',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text('Charge Amount (₹)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                      hintText: 'e.g. 650',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final parsed = double.tryParse(amountController.text) ?? 0;
                            if (parsed <= 0) return;
                            final desc = itemController.text.trim().isEmpty ? selectedCategory : itemController.text.trim();
                            final charge = ChargeItemModel(
                              id: 'CHG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                              serviceName: desc,
                              date: DateTime.now(),
                              amount: parsed,
                              status: 'Posted',
                            );
                            Navigator.of(ctx).pop();
                            context.read<DashboardBloc>().add(
                                  AddFolioChargeEvent(
                                    folioId: folio.id,
                                    charge: charge,
                                  ),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Charge of ${CurrencyFormatter.format(parsed)} added to ${folio.guestName}\'s folio.'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text('Post Charge', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 5. Keycard Management Dialog
  static void showKeycardManagementDialog(BuildContext context, GuestFolioModel folio) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.nfc_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Manage Keycard',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Keycard for ${folio.guestName} (${folio.assignedRoom})',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _dialogRow('Current Keycard', folio.keycardNumber ?? 'None'),
                  _dialogRow('Status', folio.keycardStatus.toUpperCase(), color: folio.keycardStatus == 'Active' ? AppColors.statusAvailable : AppColors.statusCleaning),
                  if (folio.keycardIssuedAt != null)
                    _dialogRow('Issued At', DateFormatter.formatDateTime(folio.keycardIssuedAt!)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.key_rounded, color: AppColors.primary),
              title: Text('Issue / Re-encode Card', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text('Generate active RFID card code', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.of(ctx).pop();
                final newCode = 'KC-${(100 + DateTime.now().second * 3)}';
                context.read<DashboardBloc>().add(
                      UpdateFolioKeycardEvent(
                        folioId: folio.id,
                        keycardStatus: 'Active',
                        keycardNumber: newCode,
                      ),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Keycard $newCode issued successfully.'), backgroundColor: AppColors.statusAvailable),
                );
              },
            ),
            const Divider(height: 8),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.report_problem_rounded, color: Color(0xFFD97706)),
              title: Text('Report Card Issue / Lost', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text('Flag keycard for replacement', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.of(ctx).pop();
                context.read<DashboardBloc>().add(
                      UpdateFolioKeycardEvent(
                        folioId: folio.id,
                        keycardStatus: 'Lost',
                      ),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Keycard reported lost / flagged for replacement.'), backgroundColor: Color(0xFFD97706)),
                );
              },
            ),
            const Divider(height: 8),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.block_rounded, color: Color(0xFFDC2626)),
              title: Text('Deactivate Card', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
              subtitle: Text('Revoke room door access immediately', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              onTap: () {
                Navigator.of(ctx).pop();
                context.read<DashboardBloc>().add(
                      UpdateFolioKeycardEvent(
                        folioId: folio.id,
                        keycardStatus: 'Inactive',
                      ),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Keycard deactivated.'), backgroundColor: Color(0xFFDC2626)),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static Widget _dialogRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: color ?? AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
