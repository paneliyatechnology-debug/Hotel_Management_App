class SubscriptionPlan {
  final int id;
  final String name;
  final String code;
  final String billingCycle;
  final double price;
  final double discountPercent;
  final int maxRooms;
  final String description;
  final String badge;
  final bool isPopular;
  final bool isActive;
  final bool isCurrentPlan;
  final bool? isTrialUsed;
  final int displayOrder;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    this.code = '',
    this.billingCycle = 'MONTHLY',
    this.price = 0,
    this.discountPercent = 0,
    this.maxRooms = 0,
    this.description = '',
    this.badge = '',
    this.isPopular = false,
    this.isActive = true,
    this.isCurrentPlan = false,
    this.isTrialUsed,
    this.displayOrder = 0,
    this.features = const [],
  });

  bool get isFreeTrial {
    final codeText = code.toUpperCase();
    final nameText = name.toLowerCase();
    final badgeText = badge.toUpperCase();
    return codeText == 'TRIAL' || nameText.contains('free trial') || badgeText.contains('FREE TRIAL');
  }

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final hasTrialFlag = json.containsKey('is_trial_used') || json.containsKey('isTrialUsed');
    return SubscriptionPlan(
      id: _int(json['id']),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      billingCycle: (json['billingCycle'] ?? json['billing_cycle'] ?? 'MONTHLY').toString(),
      price: _double(json['price']),
      discountPercent: _double(json['discountPercent'] ?? json['discount_percent']),
      maxRooms: _int(json['maxRooms'] ?? json['max_rooms']),
      description: (json['description'] ?? '').toString(),
      badge: (json['badge'] ?? '').toString(),
      isPopular: json['isPopular'] == true || json['is_popular'] == true,
      isActive: json['isActive'] != false && json['is_active'] != false,
      isCurrentPlan: json['isCurrentPlan'] == true || json['is_current_plan'] == true,
      isTrialUsed: hasTrialFlag
          ? (json['isTrialUsed'] == true || json['is_trial_used'] == true)
          : null,
      displayOrder: _int(json['displayOrder'] ?? json['display_order']),
      features: rawFeatures is List
          ? rawFeatures.map((item) => item.toString()).where((item) => item.isNotEmpty).toList()
          : const [],
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class SubscriptionPlanList {
  final List<SubscriptionPlan> plans;
  final bool isTrialUsed;

  const SubscriptionPlanList({
    required this.plans,
    required this.isTrialUsed,
  });
}

class SubscriptionPurchase {
  final int id;
  final int planId;
  final double amount;
  final String billingCycle;
  final String paymentMethod;
  final String status;
  final bool autoRenew;
  final String startsAt;
  final String endsAt;
  final String planName;
  final String planCode;
  final int maxRooms;

  const SubscriptionPurchase({
    required this.id,
    required this.planId,
    this.amount = 0,
    this.billingCycle = '',
    this.paymentMethod = '',
    this.status = '',
    this.autoRenew = false,
    this.startsAt = '',
    this.endsAt = '',
    this.planName = '',
    this.planCode = '',
    this.maxRooms = 0,
  });

  factory SubscriptionPurchase.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] is Map ? Map<String, dynamic>.from(json['plan'] as Map) : const <String, dynamic>{};
    return SubscriptionPurchase(
      id: SubscriptionPlan._int(json['id']),
      planId: SubscriptionPlan._int(json['plan_id'] ?? json['planId'] ?? plan['id']),
      amount: SubscriptionPlan._double(json['amount'] ?? plan['price']),
      billingCycle: (json['billing_cycle'] ?? json['billingCycle'] ?? plan['billingCycle'] ?? plan['billing_cycle'] ?? '').toString(),
      paymentMethod: (json['payment_method'] ?? json['paymentMethod'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      autoRenew: json['auto_renew'] == true || json['autoRenew'] == true,
      startsAt: (json['starts_at'] ?? json['startsAt'] ?? '').toString(),
      endsAt: (json['ends_at'] ?? json['endsAt'] ?? '').toString(),
      planName: (plan['name'] ?? '').toString(),
      planCode: (plan['code'] ?? '').toString(),
      maxRooms: SubscriptionPlan._int(plan['maxRooms'] ?? plan['max_rooms']),
    );
  }
}
