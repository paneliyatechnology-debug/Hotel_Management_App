class StaffMemberModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String employeeId;
  final String status;
  final String shift;
  final bool mustChangePassword;
  final int failedLoginAttempts;

  const StaffMemberModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'RECEPTIONIST',
    this.employeeId = '',
    this.status = 'ACTIVE',
    this.shift = 'Morning (07:00 - 15:00)',
    this.mustChangePassword = false,
    this.failedLoginAttempts = 0,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory StaffMemberModel.fromJson(Map<String, dynamic> json) {
    final activeFlag = json['is_active'] ?? json['isActive'];
    final rawStatus = json['status']?.toString();
    final status = (rawStatus != null && rawStatus.isNotEmpty)
        ? rawStatus
        : (activeFlag is bool ? (activeFlag ? 'ACTIVE' : 'INACTIVE') : 'ACTIVE');

    return StaffMemberModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: (json['phone'] ?? json['mobile'] ?? '').toString(),
      role: json['role']?.toString() ?? 'RECEPTIONIST',
      employeeId: (json['employeeId'] ?? json['employee_id'] ?? '').toString(),
      status: status,
      shift: (json['shift'] ?? json['shift_name'] ?? 'Morning (07:00 - 15:00)').toString(),
      mustChangePassword: json['mustChangePassword'] == true || json['must_change_password'] == true,
      failedLoginAttempts: (json['failedLoginAttempts'] as num?)?.toInt() ??
          (json['failed_login_attempts'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'employeeId': employeeId,
        'status': status,
        'shift': shift,
      };
}

class DailyCollectionsTelemetry {
  final double todayGross;
  final double todayCash;
  final double todayUpi;
  final double todayCard;
  final double todayBank;
  final double todayOnline;
  final double yesterdayGross;
  final double thisMonthGross;
  final double lastMonthGross;
  final double cashInDrawer;
  final double unsettledUpi;
  final double unsettledTotal;
  final double totalVaultSettled;
  final int unsettledCount;
  final double todayEstimatedNetEarnings;
  final double monthEstimatedNetEarnings;

  const DailyCollectionsTelemetry({
    this.todayGross = 0,
    this.todayCash = 0,
    this.todayUpi = 0,
    this.todayCard = 0,
    this.todayBank = 0,
    this.todayOnline = 0,
    this.yesterdayGross = 0,
    this.thisMonthGross = 0,
    this.lastMonthGross = 0,
    this.cashInDrawer = 0,
    this.unsettledUpi = 0,
    this.unsettledTotal = 0,
    this.totalVaultSettled = 0,
    this.unsettledCount = 0,
    this.todayEstimatedNetEarnings = 0,
    this.monthEstimatedNetEarnings = 0,
  });

  factory DailyCollectionsTelemetry.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DailyCollectionsTelemetry();
    return DailyCollectionsTelemetry(
      todayGross: (json['todayGross'] as num?)?.toDouble() ?? 0,
      todayCash: (json['todayCash'] as num?)?.toDouble() ?? 0,
      todayUpi: (json['todayUpi'] as num?)?.toDouble() ?? 0,
      todayCard: (json['todayCard'] as num?)?.toDouble() ?? 0,
      todayBank: (json['todayBank'] as num?)?.toDouble() ?? 0,
      todayOnline: (json['todayOnline'] as num?)?.toDouble() ?? 0,
      yesterdayGross: (json['yesterdayGross'] as num?)?.toDouble() ?? 0,
      thisMonthGross: (json['thisMonthGross'] as num?)?.toDouble() ?? 0,
      lastMonthGross: (json['lastMonthGross'] as num?)?.toDouble() ?? 0,
      cashInDrawer: (json['cashInDrawer'] as num?)?.toDouble() ?? 0,
      unsettledUpi: (json['unsettledUpi'] as num?)?.toDouble() ?? 0,
      unsettledTotal: (json['unsettledTotal'] as num?)?.toDouble() ?? 0,
      totalVaultSettled: (json['totalVaultSettled'] as num?)?.toDouble() ?? 0,
      unsettledCount: (json['unsettledCount'] as num?)?.toInt() ?? 0,
      todayEstimatedNetEarnings: (json['todayEstimatedNetEarnings'] as num?)?.toDouble() ?? 0,
      monthEstimatedNetEarnings: (json['monthEstimatedNetEarnings'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AdminPaymentTransaction {
  final String id;
  final String transactionId;
  final String receiptNumber;
  final String date;
  final String formattedDate;
  final String guestName;
  final String guestMobile;
  final String guestEmail;
  final String bookingNumber;
  final String roomNumber;
  final String roomType;
  final String description;
  final String paymentMethod;
  final double amount;
  final double tax;
  final double total;
  final String status;

  const AdminPaymentTransaction({
    required this.id,
    this.transactionId = '',
    this.receiptNumber = '',
    this.date = '',
    this.formattedDate = '',
    this.guestName = '',
    this.guestMobile = '',
    this.guestEmail = '',
    this.bookingNumber = '',
    this.roomNumber = '',
    this.roomType = '',
    this.description = '',
    this.paymentMethod = 'CASH',
    this.amount = 0,
    this.tax = 0,
    this.total = 0,
    this.status = 'PAID',
  });

  factory AdminPaymentTransaction.fromJson(Map<String, dynamic> json) {
    return AdminPaymentTransaction(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      transactionId: json['transactionId'] as String? ?? json['receiptNumber'] as String? ?? '',
      receiptNumber: json['receiptNumber'] as String? ?? json['transactionId'] as String? ?? '',
      date: json['date'] as String? ?? json['createdAt'] as String? ?? '',
      formattedDate: json['formattedDate'] as String? ?? '',
      guestName: json['guestName'] as String? ?? (json['guest'] is Map ? json['guest']['name'] as String? ?? '' : ''),
      guestMobile: json['guestMobile'] as String? ?? (json['guest'] is Map ? json['guest']['phone'] as String? ?? '' : ''),
      guestEmail: json['guestEmail'] as String? ?? '',
      bookingNumber: json['bookingNumber'] as String? ?? '',
      roomNumber: json['roomNumber'] as String? ?? '',
      roomType: json['roomType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? 'CASH',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'PAID',
    );
  }
}

class RevenueBreakdown {
  final double roomBooking;
  final double extraServices;
  final double foodRestaurant;
  final double otherCharges;
  final double total;

  const RevenueBreakdown({
    this.roomBooking = 0,
    this.extraServices = 0,
    this.foodRestaurant = 0,
    this.otherCharges = 0,
    this.total = 0,
  });

  factory RevenueBreakdown.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RevenueBreakdown();
    return RevenueBreakdown(
      roomBooking: (json['roomBooking'] as num?)?.toDouble() ?? 0,
      extraServices: (json['extraServices'] as num?)?.toDouble() ?? 0,
      foodRestaurant: (json['foodRestaurant'] as num?)?.toDouble() ?? 0,
      otherCharges: (json['otherCharges'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RevenueDetailsData {
  final String dateRangeLabel;
  final double totalRevenue;
  final int totalTransactions;
  final RevenueBreakdown breakdown;
  final List<AdminPaymentTransaction> transactions;

  const RevenueDetailsData({
    this.dateRangeLabel = '',
    this.totalRevenue = 0,
    this.totalTransactions = 0,
    this.breakdown = const RevenueBreakdown(),
    this.transactions = const [],
  });

  factory RevenueDetailsData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RevenueDetailsData();
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final range = data['dateRange'] as Map<String, dynamic>?;
    final trans = data['transactions'] as List<dynamic>? ?? [];

    return RevenueDetailsData(
      dateRangeLabel: range?['label'] as String? ?? '',
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0,
      totalTransactions: (data['totalTransactions'] as num?)?.toInt() ?? 0,
      breakdown: RevenueBreakdown.fromJson(data['revenueBreakdown'] as Map<String, dynamic>?),
      transactions: trans.map((e) => AdminPaymentTransaction.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
