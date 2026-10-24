class PaymentMethodCollection {
  final int paymentMethodId;
  final String name;
  final bool isSystem;
  final double collectedAmount;

  const PaymentMethodCollection({
    this.paymentMethodId = 0,
    this.name = '',
    this.isSystem = false,
    this.collectedAmount = 0,
  });

  /// Display label from API `name` (e.g. BANK_TRANSFER → Bank Transfer, UPI → UPI).
  String get displayName {
    final raw = name.trim();
    if (raw.isEmpty) return 'Other';
    return raw
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map(_titleWord)
        .join(' ');
  }

  static String _titleWord(String word) {
    final upper = word.toUpperCase();
    // Keep short payment acronyms fully uppercase.
    if (upper == 'UPI' ||
        upper == 'NEFT' ||
        upper == 'RTGS' ||
        upper == 'IMPS' ||
        upper == 'ATM' ||
        (word.length <= 3 && word == upper)) {
      return upper;
    }
    if (word.length == 1) return upper;
    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }

  factory PaymentMethodCollection.fromJson(Map<String, dynamic> json) {
    return PaymentMethodCollection(
      paymentMethodId: DashboardSummary._num(json['payment_method_id'] ?? json['paymentMethodId']).round(),
      name: (json['name'] ?? json['payment_method'] ?? json['paymentMethod'] ?? '').toString(),
      isSystem: json['is_system'] == true || json['isSystem'] == true,
      collectedAmount: DashboardSummary._num(json['collected_amount'] ?? json['collectedAmount']),
    );
  }
}

class DashboardSummary {
  final String periodStartDate;
  final String periodEndDate;
  final double totalCollectedAmount;
  final List<PaymentMethodCollection> collectionByPaymentMethod;
  final double totalOutstandingAmount;
  final int totalBookingCount;
  final int totalGuestCount;
  final double totalBookingAmount;
  final double totalDiscountAmount;
  final double totalExtraChargesAmount;
  final double totalLateCheckoutChargesAmount;

  const DashboardSummary({
    this.periodStartDate = '',
    this.periodEndDate = '',
    this.totalCollectedAmount = 0,
    this.collectionByPaymentMethod = const [],
    this.totalOutstandingAmount = 0,
    this.totalBookingCount = 0,
    this.totalGuestCount = 0,
    this.totalBookingAmount = 0,
    this.totalDiscountAmount = 0,
    this.totalExtraChargesAmount = 0,
    this.totalLateCheckoutChargesAmount = 0,
  });

  double amountForMethod(String methodName) {
    final key = methodName.trim().toUpperCase().replaceAll(' ', '_');
    for (final m in collectionByPaymentMethod) {
      if (m.name.trim().toUpperCase().replaceAll(' ', '_') == key) {
        return m.collectedAmount;
      }
    }
    return 0;
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final payments = json['collection_by_payment_method'] ?? json['collectionByPaymentMethod'];
    return DashboardSummary(
      periodStartDate: (json['period_start_date'] ?? json['periodStartDate'] ?? '').toString(),
      periodEndDate: (json['period_end_date'] ?? json['periodEndDate'] ?? '').toString(),
      totalCollectedAmount: _num(json['total_collected_amount'] ?? json['totalCollectedAmount']),
      collectionByPaymentMethod: _parsePaymentMethods(payments),
      totalOutstandingAmount: _num(json['total_outstanding_amount'] ?? json['totalOutstandingAmount']),
      totalBookingCount: _num(json['total_booking_count'] ?? json['totalBookingCount']).round(),
      totalGuestCount: _num(json['total_guest_count'] ?? json['totalGuestCount']).round(),
      totalBookingAmount: _num(json['total_booking_amount'] ?? json['totalBookingAmount']),
      totalDiscountAmount: _num(json['total_discount_amount'] ?? json['totalDiscountAmount']),
      totalExtraChargesAmount: _num(json['total_extra_charges_amount'] ?? json['totalExtraChargesAmount']),
      totalLateCheckoutChargesAmount: _num(json['total_late_checkout_charges_amount'] ?? json['totalLateCheckoutChargesAmount']),
    );
  }

  /// Supports new array shape and legacy map shape.
  static List<PaymentMethodCollection> _parsePaymentMethods(dynamic payments) {
    if (payments is List) {
      return payments
          .whereType<Map>()
          .map((e) => PaymentMethodCollection.fromJson(Map<String, dynamic>.from(e)))
          .where((m) => m.name.trim().isNotEmpty)
          .toList();
    }
    if (payments is Map) {
      final methods = Map<String, dynamic>.from(payments);
      const legacy = <(String, String)>[
        ('cash_collected_amount', 'CASH'),
        ('cashCollectedAmount', 'CASH'),
        ('upi_collected_amount', 'UPI'),
        ('upiCollectedAmount', 'UPI'),
        ('card_collected_amount', 'CARD'),
        ('cardCollectedAmount', 'CARD'),
        ('online_collected_amount', 'ONLINE'),
        ('onlineCollectedAmount', 'ONLINE'),
        ('bank_transfer_collected_amount', 'BANK_TRANSFER'),
        ('bankTransferCollectedAmount', 'BANK_TRANSFER'),
      ];
      final seen = <String>{};
      final out = <PaymentMethodCollection>[];
      for (final entry in legacy) {
        if (!methods.containsKey(entry.$1) || seen.contains(entry.$2)) continue;
        seen.add(entry.$2);
        out.add(PaymentMethodCollection(
          name: entry.$2,
          collectedAmount: _num(methods[entry.$1]),
          isSystem: true,
        ));
      }
      return out;
    }
    return const [];
  }

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
