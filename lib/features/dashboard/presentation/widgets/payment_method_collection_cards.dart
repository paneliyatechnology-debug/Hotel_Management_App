import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/dashboard_summary_model.dart';

/// Renders one card per `collection_by_payment_method` item (dynamic name + amount).
class PaymentMethodCollectionCards extends StatelessWidget {
  final List<PaymentMethodCollection> methods;
  final int columns;
  final EdgeInsetsGeometry padding;
  final bool showSectionTitle;

  const PaymentMethodCollectionCards({
    super.key,
    required this.methods,
    this.columns = 2,
    this.padding = EdgeInsets.zero,
    this.showSectionTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) {
      return Padding(
        padding: padding,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            'No payment methods for this period',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
          ),
        ),
      );
    }

    final cols = columns.clamp(1, 3);
    final rows = <Widget>[];
    for (var i = 0; i < methods.length; i += cols) {
      final slice = methods.sublist(i, (i + cols).clamp(0, methods.length));
      rows.add(
        Row(
          children: [
            for (var j = 0; j < cols; j++) ...[
              if (j > 0) const SizedBox(width: 8),
              Expanded(
                child: j < slice.length ? _PaymentMethodCard(method: slice[j]) : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
      if (i + cols < methods.length) {
        rows.add(const SizedBox(height: 8));
      }
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSectionTitle) ...[
            Text(
              'By payment method',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
          ],
          ...rows,
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethodCollection method;

  const _PaymentMethodCard({required this.method});

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(method.name);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(style.icon, size: 15, color: style.color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  method.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: style.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(method.collectedAmount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  static ({IconData icon, Color color, Color bg, Color border}) _styleFor(String name) {
    final key = name.trim().toUpperCase().replaceAll(' ', '_');
    switch (key) {
      case 'CASH':
        return (
          icon: Icons.payments_rounded,
          color: const Color(0xFF059669),
          bg: const Color(0xFFECFDF5),
          border: const Color(0xFFA7F3D0),
        );
      case 'UPI':
        return (
          icon: Icons.qr_code_rounded,
          color: const Color(0xFF4F46E5),
          bg: const Color(0xFFEEF2FF),
          border: const Color(0xFFC7D2FE),
        );
      case 'CARD':
      case 'CREDIT_CARD':
      case 'DEBIT_CARD':
        return (
          icon: Icons.credit_card_rounded,
          color: const Color(0xFF0284C7),
          bg: const Color(0xFFF0F9FF),
          border: const Color(0xFFBAE6FD),
        );
      case 'ONLINE':
        return (
          icon: Icons.language_rounded,
          color: const Color(0xFFD97706),
          bg: const Color(0xFFFFFBEB),
          border: const Color(0xFFFDE68A),
        );
      case 'BANK_TRANSFER':
      case 'BANK':
      case 'NEFT':
      case 'RTGS':
        return (
          icon: Icons.account_balance_rounded,
          color: const Color(0xFF475569),
          bg: const Color(0xFFF1F5F9),
          border: const Color(0xFFE2E8F0),
        );
      default:
        return (
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFF0F766E),
          bg: const Color(0xFFF0FDFA),
          border: const Color(0xFF99F6E4),
        );
    }
  }
}
