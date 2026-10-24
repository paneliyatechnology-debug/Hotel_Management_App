import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/data/models/guest_folio_model.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_event.dart';
import '../../../payments/presentation/widgets/payment_method_dropdown.dart';

class CheckoutSettlementDialog extends StatefulWidget {
  final GuestFolioModel folio;

  const CheckoutSettlementDialog({
    super.key,
    required this.folio,
  });

  static Future<bool?> show(BuildContext context, GuestFolioModel folio) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => CheckoutSettlementDialog(folio: folio),
      ),
    );
  }

  @override
  State<CheckoutSettlementDialog> createState() => _CheckoutSettlementDialogState();
}

class _CheckoutSettlementDialogState extends State<CheckoutSettlementDialog> {
  bool _isLoading = false;
  bool _settlementReady = false;
  bool _notesEdited = false;
  String? _paymentError;
  String? _discountError;
  String _paymentMethod = 'CASH';

  late final TextEditingController _extraController;
  late final TextEditingController _discountController;
  late final TextEditingController _lateHoursController;
  late final TextEditingController _lateChargeController;
  late final TextEditingController _notesController;

  double _roomCharges = 0;
  double _advancePaid = 0;
  double _cgstRate = 9;
  double _sgstRate = 9;
  String _guestName = '';
  String _guestPhone = '';
  String _bookingNumber = '';
  List<String> _roomNumbers = const [];

  double get _extraCharges => _parseAmount(_extraController.text) ?? 0;
  double get _discountRaw => _parseAmount(_discountController.text) ?? 0;
  double get _maxDiscount => _roomCharges < 0 ? 0 : _roomCharges;
  double get _discount =>
      _discountRaw > _maxDiscount ? _maxDiscount : _discountRaw;
  double get _lateHours => _parseAmount(_lateHoursController.text) ?? 0;
  double get _lateCharge => _parseAmount(_lateChargeController.text) ?? 0;

  double get _taxable {
    final value = _roomCharges - _discount + _extraCharges + _lateCharge;
    return value < 0 ? 0 : value;
  }

  double get _cgst => _taxable * _cgstRate / 100;
  double get _sgst => _taxable * _sgstRate / 100;
  double get _billTotal => _taxable + _cgst + _sgst;
  double get _balanceDue {
    final due = _billTotal - _advancePaid;
    return due < 0 ? 0 : due;
  }

  double get _collectingNow => _balanceDue;

  @override
  void initState() {
    super.initState();
    final folio = widget.folio;
    _roomCharges = folio.roomCharges > 0 ? folio.roomCharges : folio.totalAmount;
    _advancePaid = folio.advancePaid;
    _cgstRate = folio.gstRate > 0 ? folio.gstRate / 2 : 9;
    _sgstRate = folio.gstRate > 0 ? folio.gstRate / 2 : 9;
    _guestName = folio.guestName;
    _guestPhone = folio.phone;
    _bookingNumber = folio.bookingId ?? folio.effectiveBookingId;
    final initialRoom = _cleanRoomNumber(folio.assignedRoom);
    _roomNumbers = initialRoom.isEmpty ? const [] : [initialRoom];

    _extraController = TextEditingController();
    _discountController = TextEditingController();
    _lateHoursController = TextEditingController();
    _lateChargeController = TextEditingController();
    _notesController = TextEditingController();
    _setHintOnlyAmount(_extraController, folio.extraCharges);
    _setHintOnlyAmount(_discountController, folio.discount);
    _loadSettlement();
  }

  @override
  void dispose() {
    _extraController.dispose();
    _discountController.dispose();
    _lateHoursController.dispose();
    _lateChargeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _amountText(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }

  /// Keep field empty when 0 so hint "0" is visible; only fill non-zero values.
  void _setHintOnlyAmount(TextEditingController controller, double value) {
    controller.text = value > 0 ? _amountText(value) : '';
  }

  double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').replaceAll('₹', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  String? _discountValidationError() {
    final raw = _discountController.text.replaceAll(',', '').replaceAll('₹', '').trim();
    if (raw.isEmpty) return null;
    final amount = double.tryParse(raw);
    if (amount == null || amount < 0) return 'Enter a valid discount';
    if (amount > _maxDiscount + 0.009) {
      return 'Discount cannot exceed room charges (${CurrencyFormatter.format(_maxDiscount)})';
    }
    return null;
  }

  bool _validatePayment() {
    final paymentError = _paymentMethod.trim().isEmpty ? 'Select payment type' : null;
    final discountError = _discountValidationError();
    setState(() {
      _paymentError = paymentError;
      _discountError = discountError;
    });
    return paymentError == null && discountError == null;
  }

  Future<void> _loadSettlement() async {
    final settlement = await DashboardRepository().fetchBookingSettlement(widget.folio.id);
    if (!mounted) return;
    setState(() {
      if (settlement != null) {
        _roomCharges = settlement.roomCharges;
        _advancePaid = settlement.paid;
        _cgstRate = settlement.cgstRate;
        _sgstRate = settlement.sgstRate;
        if (settlement.guestName.trim().isNotEmpty) _guestName = settlement.guestName.trim();
        if (settlement.phone.trim().isNotEmpty) _guestPhone = settlement.phone.trim();
        if (settlement.bookingNumber.trim().isNotEmpty) {
          _bookingNumber = settlement.bookingNumber.trim();
        }
        if (settlement.roomNumbers.isNotEmpty) {
          _roomNumbers = List<String>.from(settlement.roomNumbers);
        }
        _setHintOnlyAmount(_extraController, settlement.extraCharges);
        _setHintOnlyAmount(_discountController, settlement.discount);
        _setHintOnlyAmount(_lateHoursController, settlement.lateHours);
        _setHintOnlyAmount(_lateChargeController, settlement.lateCharge);
        if (!_notesEdited) {
          _notesController.text = '';
        }
      }
      _settlementReady = true;
    });
  }

  void _onBillFieldChanged() {
    setState(() {
      _discountError = _discountValidationError();
    });
  }

  String _cleanRoomNumber(String raw) {
    var room = raw.replaceAll('Room', '').replaceAll('#', '').trim();
    if (room.isEmpty) room = '01';
    return room;
  }

  Object _jsonAmount(double value) {
    if (value == value.roundToDouble()) return value.round();
    return double.parse(value.toStringAsFixed(2));
  }

  InputDecoration _fieldDecoration({String hint = '', String? prefix, String? error, String? helper}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      prefixText: prefix == null ? null : '$prefix ',
      prefixStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
      hintStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
      helperText: helper,
      helperStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
      helperMaxLines: 1,
      errorText: error,
      errorStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.3)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDC2626))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.3)),
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    String? helper,
    String? error,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled && !_isLoading,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: (_) => _onBillFieldChanged(),
          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          decoration: _fieldDecoration(hint: '0', helper: error == null ? helper : null, error: error).copyWith(
            hintText: '0',
            hintStyle: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _billLine({
    required String label,
    required String amount,
    Color amountColor = const Color(0xFF0F172A),
    bool strong = false,
    Color? background,
  }) {
    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                color: amountColor,
                height: 1.2,
              ),
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: strong ? 12.5 : 12,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirmCheckout() async {
    if (!_validatePayment()) return;
    final paid = _balanceDue;
    final paymentMethod = _paymentMethod;
    setState(() => _isLoading = true);

    try {
      final repo = DashboardRepository();
      if (!_settlementReady) await _loadSettlement();
      final notes = _notesController.text.trim();
      final response = await repo.checkoutFolio(
        widget.folio.id,
        customPayload: {
          'paid_amount': _jsonAmount(paid),
          'extra_charges_total': _jsonAmount(_extraCharges),
          'discount_amount': _jsonAmount(_discount),
          'late_checkout_charge': _jsonAmount(_lateCharge),
          'late_checkout_hours': _jsonAmount(_lateHours),
          'notes': notes.isNotEmpty
              ? notes
              : 'Checked out and settled via $paymentMethod',
          'payment_method': paymentMethod,
        },
      );

      final message = response['message']?.toString() ??
          'Checkout completed successfully. Room is now marked for cleaning.';

      if (mounted) {
        context.read<DashboardBloc>().add(LoadBookingsEvent());
        context.read<DashboardBloc>().add(RefreshDashboardDataEvent());

        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F766E),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  String get _roomsTitle {
    if (_roomNumbers.isEmpty) {
      return 'Room #${_cleanRoomNumber(widget.folio.assignedRoom)}';
    }
    if (_roomNumbers.length == 1) return 'Room #${_roomNumbers.first}';
    return 'Rooms ${_roomNumbers.map((n) => '#$n').join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final pending = _balanceDue;
    final isCleared = pending <= 0.009;
    final initial = _guestName.trim().isEmpty ? 'G' : _guestName.trim()[0].toUpperCase();
    final folioLabel = _bookingNumber.startsWith('#') ? _bookingNumber : '#$_bookingNumber';
    final guestMeta = [
      if (_guestPhone.trim().isNotEmpty) _guestPhone.trim(),
      'Folio $folioLabel',
    ].join(' · ');
    final maxDiscountLabel = _roomCharges > 0 ? 'Max ${CurrencyFormatter.format(_roomCharges)}' : null;
    final collecting = _collectingNow;
    final confirmLabel = isCleared
        ? 'Confirm checkout'
        : 'Collect ${CurrencyFormatter.format(pending)} & check out';
    final roomNumbers = _roomNumbers.isNotEmpty
        ? _roomNumbers
        : [_cleanRoomNumber(widget.folio.assignedRoom)];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        titleSpacing: 0,
        title: Text(
          'Check-out · $_roomsTitle',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: !_settlementReady
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Review the bill, collect payment and release the room.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF0F766E),
                                    child: Text(
                                      initial,
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _guestName,
                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                        ),
                                        Text(
                                          guestMeta,
                                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                roomNumbers.length > 1 ? 'Rooms' : 'Room',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: roomNumbers.map((number) {
                                  return Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCCFBF1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF0F766E), width: 1.1),
                                    ),
                                    child: Text(
                                      number,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0F766E),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _labeledField(
                                      label: 'Extra charges (₹)',
                                      controller: _extraController,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _labeledField(
                                      label: 'Discount (₹)',
                                      controller: _discountController,
                                      helper: maxDiscountLabel,
                                      error: _discountError,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _labeledField(
                                      label: 'Late check-out hours',
                                      controller: _lateHoursController,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _labeledField(
                                      label: 'Late check-out charge (₹)',
                                      controller: _lateChargeController,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Payment method',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                              ),
                              const SizedBox(height: 4),
                              PaymentMethodDropdown(
                                value: _paymentMethod,
                                enabled: !_isLoading,
                                errorText: _paymentError,
                                decoration: _fieldDecoration(error: _paymentError),
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _paymentMethod = value;
                                    _paymentError = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Notes',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _notesController,
                                maxLines: 2,
                                onChanged: (_) => _notesEdited = true,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                                decoration: _fieldDecoration(hint: 'e.g. Collected remaining balance at the desk'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                                child: Text(
                                  'Bill summary',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCCFBF1)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    _billLine(
                                      label: 'Room charges (Before tax)',
                                      amount: CurrencyFormatter.format(_roomCharges),
                                    ),
                                    _billLine(
                                      label: 'Discount',
                                      amount: '-${CurrencyFormatter.format(_discount)}',
                                      amountColor: const Color(0xFF059669),
                                    ),
                                    _billLine(
                                      label: 'Extra charges',
                                      amount: _extraCharges > 0
                                          ? '+${CurrencyFormatter.format(_extraCharges)}'
                                          : CurrencyFormatter.format(_extraCharges),
                                    ),
                                    _billLine(
                                      label: 'Late check-out charges',
                                      amount: CurrencyFormatter.format(_lateCharge),
                                    ),
                                    const Divider(height: 1, color: Color(0xFFCCFBF1)),
                                    _billLine(
                                      label: 'Taxable amount',
                                      amount: CurrencyFormatter.format(_taxable),
                                      strong: true,
                                    ),
                                    _billLine(
                                      label: 'CGST (${_cgstRate == _cgstRate.roundToDouble() ? _cgstRate.round() : _cgstRate}%)',
                                      amount: '+${CurrencyFormatter.format(_cgst)}',
                                    ),
                                    _billLine(
                                      label: 'SGST (${_sgstRate == _sgstRate.roundToDouble() ? _sgstRate.round() : _sgstRate}%)',
                                      amount: '+${CurrencyFormatter.format(_sgst)}',
                                    ),
                                    const Divider(height: 1, color: Color(0xFFCCFBF1)),
                                    _billLine(
                                      label: 'Total bill (Taxable amount + GST)',
                                      amount: CurrencyFormatter.format(_billTotal),
                                      strong: true,
                                    ),
                                    _billLine(
                                      label: 'Advance paid',
                                      amount: '-${CurrencyFormatter.format(_advancePaid)}',
                                      amountColor: const Color(0xFF059669),
                                    ),
                                    const Divider(height: 1, color: Color(0xFFCCFBF1)),
                                    _billLine(
                                      label: 'Balance due',
                                      amount: CurrencyFormatter.format(pending),
                                      amountColor: isCleared ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                      strong: true,
                                    ),
                                    if (!isCleared)
                                      _billLine(
                                        label: 'Collecting now',
                                        amount: '-${CurrencyFormatter.format(collecting)}',
                                        amountColor: const Color(0xFF059669),
                                      ),
                                    _billLine(
                                      label: 'Fully settled',
                                      amount: CurrencyFormatter.format(0),
                                      amountColor: const Color(0xFF059669),
                                      strong: true,
                                      background: const Color(0xFFD1FAE5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCleared ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCleared ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCleared ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                                size: 16,
                                color: isCleared ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isCleared
                                      ? 'Nothing left to collect'
                                      : 'Unsettled Folio Balance (${CurrencyFormatter.format(pending)} Due)',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isCleared ? const Color(0xFF14532D) : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                              const Offstage(child: Text('Unsettled Folio Balance')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size.fromHeight(42),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _isLoading || !_settlementReady || _discountError != null
                          ? null
                          : _handleConfirmCheckout,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              confirmLabel,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size.fromHeight(40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
