class DashboardSummary {
  final String periodStartDate;
  final String periodEndDate;
  final double totalCollectedAmount;
  final double cashCollectedAmount;
  final double onlineCollectedAmount;
  final double cardCollectedAmount;
  final double upiCollectedAmount;
  final double bankTransferCollectedAmount;
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
    this.cashCollectedAmount = 0,
    this.onlineCollectedAmount = 0,
    this.cardCollectedAmount = 0,
    this.upiCollectedAmount = 0,
    this.bankTransferCollectedAmount = 0,
    this.totalOutstandingAmount = 0,
    this.totalBookingCount = 0,
    this.totalGuestCount = 0,
    this.totalBookingAmount = 0,
    this.totalDiscountAmount = 0,
    this.totalExtraChargesAmount = 0,
    this.totalLateCheckoutChargesAmount = 0,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final payments = json['collection_by_payment_method'] ?? json['collectionByPaymentMethod'];
    final methods = payments is Map ? Map<String, dynamic>.from(payments) : const <String, dynamic>{};
    return DashboardSummary(
      periodStartDate: (json['period_start_date'] ?? json['periodStartDate'] ?? '').toString(),
      periodEndDate: (json['period_end_date'] ?? json['periodEndDate'] ?? '').toString(),
      totalCollectedAmount: _num(json['total_collected_amount'] ?? json['totalCollectedAmount']),
      cashCollectedAmount: _num(methods['cash_collected_amount'] ?? methods['cashCollectedAmount']),
      onlineCollectedAmount: _num(methods['online_collected_amount'] ?? methods['onlineCollectedAmount']),
      cardCollectedAmount: _num(methods['card_collected_amount'] ?? methods['cardCollectedAmount']),
      upiCollectedAmount: _num(methods['upi_collected_amount'] ?? methods['upiCollectedAmount']),
      bankTransferCollectedAmount: _num(methods['bank_transfer_collected_amount'] ?? methods['bankTransferCollectedAmount']),
      totalOutstandingAmount: _num(json['total_outstanding_amount'] ?? json['totalOutstandingAmount']),
      totalBookingCount: _num(json['total_booking_count'] ?? json['totalBookingCount']).round(),
      totalGuestCount: _num(json['total_guest_count'] ?? json['totalGuestCount']).round(),
      totalBookingAmount: _num(json['total_booking_amount'] ?? json['totalBookingAmount']),
      totalDiscountAmount: _num(json['total_discount_amount'] ?? json['totalDiscountAmount']),
      totalExtraChargesAmount: _num(json['total_extra_charges_amount'] ?? json['totalExtraChargesAmount']),
      totalLateCheckoutChargesAmount: _num(json['total_late_checkout_charges_amount'] ?? json['totalLateCheckoutChargesAmount']),
    );
  }

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
