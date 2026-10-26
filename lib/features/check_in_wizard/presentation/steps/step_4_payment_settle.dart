import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../payments/data/models/payment_method_model.dart';
import '../../../payments/data/repositories/payment_methods_repository.dart';
import '../../data/models/check_in_form_data.dart';

class Step4PaymentSettle extends StatefulWidget {
  final CheckInFormData formData;
  final ValueChanged<CheckInFormData> onDataChanged;

  const Step4PaymentSettle({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step4PaymentSettle> createState() => _Step4PaymentSettleState();
}

class _Step4PaymentSettleState extends State<Step4PaymentSettle> {
  late TextEditingController _advanceController;
  late TextEditingController _discountController;
  late TextEditingController _txnRefController;
  late String _selectedPaymentMode;
  late Future<List<PaymentMethodModel>> _methodsFuture;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMode = widget.formData.paymentMode.trim().isEmpty
        ? 'UPI'
        : widget.formData.paymentMode;
    _methodsFuture = PaymentMethodsRepository().fetchPaymentMethods();
    final initialAdvance = widget.formData.advancePaid > 0
        ? widget.formData.advancePaid
        : widget.formData.grandTotal;
    _advanceController = TextEditingController(text: initialAdvance.toStringAsFixed(0));
    _discountController = TextEditingController(
        text: widget.formData.discountAmount > 0
            ? widget.formData.discountAmount.toStringAsFixed(0)
            : '');
    _txnRefController = TextEditingController(text: widget.formData.transactionRef);

    if (widget.formData.advancePaid == 0) {
      widget.formData.advancePaid = initialAdvance;
    }
  }

  IconData _iconFor(String code) {
    switch (code.toUpperCase()) {
      case 'CASH':
        return Icons.payments_outlined;
      case 'CARD':
        return Icons.credit_card;
      case 'UPI':
        return Icons.qr_code_scanner;
      case 'BANK_TRANSFER':
        return Icons.account_balance_outlined;
      case 'POS':
        return Icons.point_of_sale;
      default:
        return Icons.payment_rounded;
    }
  }

  String _resolveSelected(List<PaymentMethodModel> methods) {
    final codes = methods.map((m) => m.code).toSet();
    final raw = _selectedPaymentMode.trim().toUpperCase();
    if (codes.contains(raw)) return raw;
    if (raw.contains('CASH') && codes.contains('CASH')) return 'CASH';
    if (raw.contains('UPI') && codes.contains('UPI')) return 'UPI';
    if ((raw.contains('CARD') || raw.contains('CREDIT') || raw.contains('DEBIT')) &&
        codes.contains('CARD')) {
      return 'CARD';
    }
    if ((raw.contains('BANK') || raw.contains('NET') || raw.contains('POS')) &&
        codes.contains('BANK_TRANSFER')) {
      return 'BANK_TRANSFER';
    }
    return methods.isNotEmpty ? methods.first.code : 'UPI';
  }

  @override
  void dispose() {
    _advanceController.dispose();
    _discountController.dispose();
    _txnRefController.dispose();
    super.dispose();
  }

  void _notify() {
    final updated = widget.formData.copy();
    updated.paymentMode = _selectedPaymentMode;
    final roomTotal = updated.pricePerNight * (updated.totalNights > 0 ? updated.totalNights : 1);
    var discount = double.tryParse(_discountController.text) ?? 0.0;
    if (discount < 0) discount = 0;
    if (discount > roomTotal) {
      discount = roomTotal;
      _discountController.text = discount.toInt().toString();
    }
    updated.advancePaid = double.tryParse(_advanceController.text) ?? 0.0;
    updated.discountAmount = discount;
    updated.transactionRef = _txnRefController.text;
    widget.onDataChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 650;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Banner
        Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 4: Folio Settlement & Advance Payment',
                      style: GoogleFonts.inter(
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Collect advance deposit, apply promo discounts, and confirm payment mode.',
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

        const SizedBox(height: 20),

        // Select Payment Mode
        Text(
          'PAYMENT METHOD *',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        FutureBuilder<List<PaymentMethodModel>>(
          future: _methodsFuture,
          builder: (context, snapshot) {
            final methods = snapshot.data ?? PaymentMethodModel.fallback;
            final selected = _resolveSelected(methods);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isCompact ? 1 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isCompact ? 5.5 : 2.8,
              ),
              itemCount: methods.length,
              itemBuilder: (context, index) {
                final mode = methods[index];
                final isSelected = selected == mode.code;

                return Material(
                  color: isSelected ? AppColors.accentGreenLight : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedPaymentMode = mode.code);
                      _notify();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accentGreen : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _iconFor(mode.code),
                            size: 18,
                            color: isSelected ? AppColors.accentGreen : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mode.label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.accentGreen : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 18),

        // Advance & Discount Input
        if (isCompact) ...[
          CustomTextField(
            label: 'Advance Deposit Collected (₹)',
            controller: _advanceController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.currency_rupee,
            onChanged: (_) {
              setState(() {});
              _notify();
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Promo Discount (₹)',
            hintText: '0',
            controller: _discountController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.discount_outlined,
            onChanged: (_) {
              setState(() {});
              _notify();
            },
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Advance Deposit Collected (₹)',
                  controller: _advanceController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee,
                  onChanged: (_) {
                    setState(() {});
                    _notify();
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: CustomTextField(
                  label: 'Promo Discount (₹)',
                  hintText: '0',
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.discount_outlined,
                  onChanged: (_) {
                    setState(() {});
                    _notify();
                  },
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 14),

        CustomTextField(
          label: 'Transaction Reference / UTR Number',
          hintText: 'e.g. UPI/109283746192',
          controller: _txnRefController,
          prefixIcon: Icons.tag,
          onChanged: (_) => _notify(),
        ),

        const SizedBox(height: 18),

        // Tariff Breakdown Summary Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIVE FOLIO TARIFF BREAKDOWN',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _buildBillLine(
                'Room Tariff (${CurrencyFormatter.format(widget.formData.pricePerNight)} × ${widget.formData.totalNights} Night${widget.formData.totalNights > 1 ? 's' : ''})',
                CurrencyFormatter.format(widget.formData.pricePerNight * widget.formData.totalNights),
              ),
              if (widget.formData.extraBeds > 0) ...[
                const SizedBox(height: 5),
                _buildBillLine(
                  'Extra Bed Charges (${widget.formData.extraBeds} Bed)',
                  CurrencyFormatter.format(widget.formData.extraBeds * 500),
                ),
              ],
              const SizedBox(height: 5),
              if (widget.formData.gstTax > 0)
                _buildBillLine(
                  'GST (${widget.formData.gstRate.toStringAsFixed(0)}%)',
                  CurrencyFormatter.format(widget.formData.gstTax),
                ),
              if (widget.formData.discountAmount > 0) ...[
                const SizedBox(height: 5),
                _buildBillLine(
                  'Discount Applied',
                  '- ${CurrencyFormatter.format(widget.formData.discountAmount)}',
                  color: AppColors.accentGreen,
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Divider(height: 1),
              ),
              _buildBillLine(
                'Grand Total Folio Amount',
                CurrencyFormatter.format(widget.formData.grandTotal),
                isBold: true,
              ),
              const SizedBox(height: 5),
              _buildBillLine(
                'Advance Deposit Collected',
                CurrencyFormatter.format(widget.formData.advancePaid),
                color: AppColors.primaryDark,
                isBold: true,
              ),
              const SizedBox(height: 5),
              _buildBillLine(
                'Balance Due at Checkout',
                CurrencyFormatter.format(widget.formData.balanceDue),
                color: widget.formData.balanceDue > 0 ? AppColors.statusMaintenance : AppColors.statusAvailable,
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillLine(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? (isBold ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
