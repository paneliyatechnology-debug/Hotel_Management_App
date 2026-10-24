class PaymentMethodModel {
  final int id;
  final int? hotelId;
  final String name;
  final bool isSystem;
  final int displayOrder;

  const PaymentMethodModel({
    required this.id,
    this.hotelId,
    required this.name,
    this.isSystem = false,
    this.displayOrder = 0,
  });

  /// API code used in payloads (`CASH`, `UPI`, `CARD`, `BANK_TRANSFER`).
  String get code => name.trim().toUpperCase();

  /// Friendly label for dropdowns / chips.
  String get label {
    switch (code) {
      case 'CASH':
        return 'Cash';
      case 'CARD':
        return 'Card';
      case 'UPI':
        return 'UPI';
      case 'BANK_TRANSFER':
        return 'Bank Transfer';
      case 'POS':
        return 'POS';
      default:
        return name
            .replaceAll('_', ' ')
            .split(' ')
            .where((p) => p.isNotEmpty)
            .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
            .join(' ');
    }
  }

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      hotelId: json['hotel_id'] == null && json['hotelId'] == null
          ? null
          : int.tryParse('${json['hotel_id'] ?? json['hotelId']}'),
      name: (json['name'] ?? '').toString(),
      isSystem: json['is_system'] == true || json['isSystem'] == true,
      displayOrder: int.tryParse('${json['display_order'] ?? json['displayOrder'] ?? 0}') ?? 0,
    );
  }

  static const List<PaymentMethodModel> fallback = [
    PaymentMethodModel(id: 0, name: 'CASH', isSystem: true, displayOrder: 1),
    PaymentMethodModel(id: 0, name: 'CARD', isSystem: true, displayOrder: 2),
    PaymentMethodModel(id: 0, name: 'UPI', isSystem: true, displayOrder: 3),
    PaymentMethodModel(id: 0, name: 'BANK_TRANSFER', isSystem: true, displayOrder: 4),
  ];
}
