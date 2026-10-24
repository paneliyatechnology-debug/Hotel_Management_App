import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../data/models/hotel_stats_model.dart';

/// Admin dashboard top-4 cards — same MetricCard UI as receptionist KPI grid.
class HotelAdminTelemetryCards extends StatelessWidget {
  final HotelStatsModel stats;
  final VoidCallback? onRevenueTap;
  final VoidCallback? onEarningsTap;
  final VoidCallback? onGuestsTap;
  final VoidCallback? onMonthlyTap;

  const HotelAdminTelemetryCards({
    super.key,
    required this.stats,
    this.onRevenueTap,
    this.onEarningsTap,
    this.onGuestsTap,
    this.onMonthlyTap,
  });

  @override
  Widget build(BuildContext context) {
    final outstandingValue = stats.fromAdminApi
        ? CurrencyFormatter.format(stats.outstandingDue)
        : CurrencyFormatter.format(stats.totalToday * 0.785);
    final outstandingSubtitle = stats.fromAdminApi ? 'Still to collect' : '78.5% margin';
    final outstandingTitle = stats.fromAdminApi ? 'Outstanding' : "Today's earnings";

    final monthValue = CurrencyFormatter.format(
      stats.fromAdminApi ? stats.monthRevenue : stats.totalToday * 24,
    );

    final revenueCard = MetricCard(
      title: "Today's revenue",
      displayTitle: "Today's revenue",
      displayValue: CurrencyFormatter.format(stats.totalToday),
      subtitle: 'Cash ${CurrencyFormatter.format(stats.todayCash)}',
      tagLabel: 'Today',
      themeColor: AppColors.primary,
      badgeBgColor: AppColors.primarySurface,
      icon: Icons.payments_rounded,
      onTap: onRevenueTap,
    );

    final outstandingCard = MetricCard(
      title: outstandingTitle,
      displayTitle: outstandingTitle,
      displayValue: outstandingValue,
      subtitle: outstandingSubtitle,
      tagLabel: 'Due',
      themeColor: const Color(0xFFD97706),
      badgeBgColor: const Color(0xFFFFFBEB),
      icon: Icons.account_balance_wallet_rounded,
      onTap: onEarningsTap,
    );

    final guestsCard = MetricCard(
      title: 'Guests',
      displayTitle: 'Guests',
      count: stats.totalInHouseGuests,
      subtitle: '${stats.checkedInToday} checked in today',
      tagLabel: 'In-House',
      themeColor: AppColors.statusGuests,
      badgeBgColor: AppColors.statusGuestsBg,
      icon: Icons.people_alt_rounded,
      onTap: onGuestsTap,
    );

    final monthCard = MetricCard(
      title: 'This month',
      displayTitle: 'This month',
      displayValue: monthValue,
      subtitle: 'Billing cycle',
      tagLabel: 'Month',
      themeColor: const Color(0xFF0369A1),
      badgeBgColor: const Color(0xFFE0F2FE),
      icon: Icons.calendar_month_rounded,
      onTap: onMonthlyTap,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial & Revenue Telemetry',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Live Real-time Audit',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F766E),
          ),
        ),
        const SizedBox(height: 12),
        // Same 2×2 grid layout as receptionist KpiMetricsGrid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.35,
          children: [
            revenueCard,
            outstandingCard,
            guestsCard,
            monthCard,
          ],
        ),
      ],
    );
  }
}
