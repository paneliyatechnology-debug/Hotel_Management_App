import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../payments/presentation/widgets/payment_method_dropdown.dart';
import '../../data/models/check_in_form_data.dart';

class Step3BillingSettlement extends StatefulWidget {
  final CheckInFormData formData;
  final ValueChanged<CheckInFormData> onDataChanged;

  const Step3BillingSettlement({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<Step3BillingSettlement> createState() => _Step3BillingSettlementState();
}

class _Step3BillingSettlementState extends State<Step3BillingSettlement> {
  late TextEditingController _tariffRateController;
  late TextEditingController _discountController;
  late TextEditingController _advanceController;
  late TextEditingController _txnNoteController;
  late String _selectedPaymentMethod;
  bool _userEditedAdvance = false;

  @override
  void initState() {
    super.initState();
    final initialRate = widget.formData.pricePerNight > 0
        ? widget.formData.pricePerNight
        : 4000.0;
    _tariffRateController =
        TextEditingController(text: initialRate.toInt().toString());
    _discountController = TextEditingController(
        text: widget.formData.discountAmount.toInt().toString());

    final initialNights =
        widget.formData.totalNights > 0 ? widget.formData.totalNights : 1;
    final initialTaxable = (initialRate * initialNights) - widget.formData.discountAmount;
    final taxable = initialTaxable > 0 ? initialTaxable : 0.0;
    final gst = widget.formData.gstEnabled && widget.formData.gstRate > 0
        ? taxable * widget.formData.gstRate / 100
        : 0.0;
    final initialFinal = taxable + gst;
    final initialAdvance = widget.formData.advancePaid > 0
        ? widget.formData.advancePaid
        : initialFinal;

    _advanceController =
        TextEditingController(text: initialAdvance.toInt().toString());
    _txnNoteController =
        TextEditingController(text: widget.formData.transactionRef);

    _selectedPaymentMethod = widget.formData.paymentMode.trim().isEmpty
        ? 'UPI'
        : widget.formData.paymentMode;
  }

  @override
  void dispose() {
    _tariffRateController.dispose();
    _discountController.dispose();
    _advanceController.dispose();
    _txnNoteController.dispose();
    super.dispose();
  }

  int get _nights =>
      widget.formData.totalNights > 0 ? widget.formData.totalNights : 1;

  double get _nightlyRate =>
      double.tryParse(_tariffRateController.text) ??
      widget.formData.pricePerNight;

  double get _discount {
    final typed = double.tryParse(_discountController.text) ?? 0.0;
    if (typed <= 0) return 0;
    if (typed > _roomTotal) return _roomTotal;
    return typed;
  }

  double get _roomTotal => _nightlyRate * _nights;

  double get _taxable {
    final total = _roomTotal - _discount;
    return total > 0 ? total : 0.0;
  }

  bool get _gstOn => widget.formData.gstEnabled && widget.formData.gstRate > 0;

  double get _gstAmount => _gstOn ? _taxable * widget.formData.gstRate / 100 : 0;

  double get _netPayable => _taxable + _gstAmount;

  double get _advancePaid => double.tryParse(_advanceController.text) ?? 0.0;

  double get _balanceDue => _netPayable - _advancePaid;

  void _onRateOrDiscountChanged() {
    final typed = double.tryParse(_discountController.text) ?? 0.0;
    if (typed > _roomTotal) {
      final capped = _roomTotal.toInt().toString();
      _discountController.value = TextEditingValue(
        text: capped,
        selection: TextSelection.collapsed(offset: capped.length),
      );
    }
    if (!_userEditedAdvance) {
      _advanceController.text = _netPayable.toInt().toString();
    }
    _notify();
    setState(() {});
  }

  void _notify() {
    final updated = widget.formData.copy();
    updated.pricePerNight = _nightlyRate;
    updated.discountAmount = _discount;
    updated.advancePaid = _advancePaid;
    updated.paymentMode = _selectedPaymentMethod;
    updated.transactionRef = _txnNoteController.text;
    widget.onDataChanged(updated);
  }

  String _cleanRoomNumber(String raw) {
    final cleaned = raw.replaceAll('#', '').trim();
    return cleaned.isNotEmpty ? cleaned : (raw.isNotEmpty ? raw : '01');
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 650;
    final roomNum = _cleanRoomNumber(widget.formData.selectedRoomNumber);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Icon + Title + Room Subtitle
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6FFFA),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.credit_card_rounded,
                    color: Color(0xFF0D9488),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tariff Calculation & Advance Settlement',
                      style: GoogleFonts.inter(
                        fontSize: isCompact ? 13.5 : 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      'Room${widget.formData.selectedRoomCount > 1 ? 's' : ''} #$roomNum • $_nights night(s) stay',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Clean Bill Summary Card (Only Needed Details, Zero Noise)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Base Tariff Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Room Tariff (₹${_nightlyRate.toInt()} × $_nights N)',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(_roomTotal),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),

                if (_discount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Special Discount',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                      Text(
                        '-${CurrencyFormatter.format(_discount)}',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ],

                if (_gstOn) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'GST (${widget.formData.gstRate.toStringAsFixed(0)}%)',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(_gstAmount),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),
                Divider(
                    height: 1,
                    thickness: 1,
                    color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Final Price',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(_netPayable),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Row 1: Nightly Tariff Rate & Special Discount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFloatingTextField(
                  controller: _tariffRateController,
                  label: 'Nightly Tariff Rate (₹)',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _onRateOrDiscountChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFloatingTextField(
                  controller: _discountController,
                  label: 'Special Discount (₹)',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _onRateOrDiscountChanged(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Payment Method Dropdown
          _buildPaymentMethodDropdown(),

          const SizedBox(height: 12),

          // Row 3: Advance Amount Paid & Transaction ID / Payment Note
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFloatingTextField(
                  controller: _advanceController,
                  label: 'Advance Amount Paid (₹)',
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    _userEditedAdvance = true;
                    _notify();
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFloatingTextField(
                  controller: _txnNoteController,
                  label: 'Transaction ID / Note',
                  hintText: 'Txn / UTR / Note',
                  keyboardType: TextInputType.text,
                  onChanged: (_) => _notify(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Live Settlement Balance Indicator
          _buildBalanceStatusRow(),
        ],
      ),
    );
  }

  Widget _buildFloatingTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    required TextInputType keyboardType,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF94A3B8),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.8),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Payment Method',
        labelStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F766E),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF0D9488), width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF0D9488), width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF0F766E), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      child: PaymentMethodDropdown(
        value: _selectedPaymentMethod,
        hideUnderline: true,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
        onChanged: (val) {
          setState(() => _selectedPaymentMethod = val);
          _notify();
        },
      ),
    );
  }

  Widget _buildBalanceStatusRow() {
    final isSettled = _balanceDue <= 0;
    final isExcess = _balanceDue < 0;

    final Color color = isExcess
        ? const Color(0xFF2563EB)
        : isSettled
            ? const Color(0xFF16A34A)
            : const Color(0xFFD97706);
    final IconData icon = isExcess
        ? Icons.info_outline_rounded
        : isSettled
            ? Icons.check_circle_rounded
            : Icons.pending_actions_rounded;

    final String text = isExcess
        ? 'Excess Paid: ${CurrencyFormatter.format(-_balanceDue)}'
        : isSettled
            ? 'Fully Settled • No Balance Outstanding'
            : 'Balance Due: ${CurrencyFormatter.format(_balanceDue)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (!isSettled) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                _advanceController.text = _netPayable.toInt().toString();
                _userEditedAdvance = true;
                _notify();
                setState(() {});
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF0D9488)),
                ),
                child: Text(
                  'Settle Full',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F766E),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
