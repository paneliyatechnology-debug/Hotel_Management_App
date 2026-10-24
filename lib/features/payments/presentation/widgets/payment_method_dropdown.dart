import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/payment_method_model.dart';
import '../../data/repositories/payment_methods_repository.dart';

/// Loads `/api/v1/payment-methods` and shows a standard dropdown of API codes.
class PaymentMethodDropdown extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final InputDecoration? decoration;
  final String? errorText;
  final bool enabled;
  final bool isExpanded;
  final TextStyle? style;
  final Color? dropdownColor;
  final Widget? icon;
  final bool hideUnderline;

  const PaymentMethodDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.decoration,
    this.errorText,
    this.enabled = true,
    this.isExpanded = true,
    this.style,
    this.dropdownColor,
    this.icon,
    this.hideUnderline = false,
  });

  @override
  State<PaymentMethodDropdown> createState() => _PaymentMethodDropdownState();
}

class _PaymentMethodDropdownState extends State<PaymentMethodDropdown> {
  final _repo = PaymentMethodsRepository();
  late Future<List<PaymentMethodModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchPaymentMethods();
  }

  String? _resolveValue(List<PaymentMethodModel> methods) {
    if (methods.isEmpty) return null;
    final codes = methods.map((m) => m.code).toSet();
    final raw = (widget.value ?? '').trim().toUpperCase();
    if (raw.isNotEmpty) {
      if (codes.contains(raw)) return raw;
      // Map legacy wizard labels → API codes.
      if (raw.contains('CASH')) return codes.contains('CASH') ? 'CASH' : methods.first.code;
      if (raw.contains('UPI')) return codes.contains('UPI') ? 'UPI' : methods.first.code;
      if (raw.contains('CARD') || raw.contains('CREDIT') || raw.contains('DEBIT')) {
        return codes.contains('CARD') ? 'CARD' : methods.first.code;
      }
      if (raw.contains('BANK') || raw.contains('NET') || raw.contains('NEFT')) {
        return codes.contains('BANK_TRANSFER') ? 'BANK_TRANSFER' : methods.first.code;
      }
    }
    return methods.first.code;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PaymentMethodModel>>(
      future: _future,
      builder: (context, snapshot) {
        final methods = snapshot.data ?? PaymentMethodModel.fallback;
        final selected = _resolveValue(methods);
        final loading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

        if (widget.hideUnderline) {
          return DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isExpanded: widget.isExpanded,
              dropdownColor: widget.dropdownColor ?? Colors.white,
              style: widget.style ??
                  GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
              icon: widget.icon ??
                  const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF0F766E), size: 24),
              items: methods
                  .map(
                    (m) => DropdownMenuItem<String>(
                      value: m.code,
                      child: Text(m.label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: !widget.enabled || loading
                  ? null
                  : (value) {
                      if (value == null) return;
                      widget.onChanged(value);
                    },
            ),
          );
        }

        return DropdownButtonFormField<String>(
          key: ValueKey<String>('pm-$selected-${methods.length}'),
          isExpanded: widget.isExpanded,
          initialValue: selected,
          dropdownColor: widget.dropdownColor ?? Colors.white,
          style: widget.style ??
              GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
          icon: widget.icon,
          decoration: (widget.decoration ?? const InputDecoration()).copyWith(
            errorText: widget.errorText,
            suffixIcon: loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          items: methods
              .map(
                (m) => DropdownMenuItem<String>(
                  value: m.code,
                  child: Text(m.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: !widget.enabled || loading
              ? null
              : (value) {
                  if (value == null) return;
                  widget.onChanged(value);
                },
        );
      },
    );
  }
}

/// Chip / choice selector fed by the same payment-methods API.
class PaymentMethodChips extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const PaymentMethodChips({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<PaymentMethodChips> createState() => _PaymentMethodChipsState();
}

class _PaymentMethodChipsState extends State<PaymentMethodChips> {
  final _repo = PaymentMethodsRepository();
  late Future<List<PaymentMethodModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchPaymentMethods();
  }

  String _resolve(List<PaymentMethodModel> methods) {
    final codes = methods.map((m) => m.code).toSet();
    final raw = (widget.value ?? '').trim().toUpperCase();
    if (codes.contains(raw)) return raw;
    if (raw.contains('CASH') && codes.contains('CASH')) return 'CASH';
    if (raw.contains('UPI') && codes.contains('UPI')) return 'UPI';
    if ((raw.contains('CARD') || raw.contains('CREDIT') || raw.contains('DEBIT')) &&
        codes.contains('CARD')) {
      return 'CARD';
    }
    if ((raw.contains('BANK') || raw.contains('NET')) && codes.contains('BANK_TRANSFER')) {
      return 'BANK_TRANSFER';
    }
    return methods.isNotEmpty ? methods.first.code : 'UPI';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PaymentMethodModel>>(
      future: _future,
      builder: (context, snapshot) {
        final methods = snapshot.data ?? PaymentMethodModel.fallback;
        final selected = _resolve(methods);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: methods.map((m) {
            final isSel = selected == m.code;
            return ChoiceChip(
              label: Text(
                m.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isSel,
              selectedColor: const Color(0xFFE6F7F2),
              onSelected: !widget.enabled
                  ? null
                  : (val) {
                      if (val) widget.onChanged(m.code);
                    },
            );
          }).toList(),
        );
      },
    );
  }
}
