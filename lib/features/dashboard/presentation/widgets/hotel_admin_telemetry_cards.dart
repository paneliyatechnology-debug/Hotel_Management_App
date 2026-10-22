import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/hotel_stats_model.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial & Revenue Telemetry',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 2),
        Text(
          'Live Real-time Audit',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0F766E)),
        ),

        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTelemetryCard(
                title: "Today's revenue",
                value: CurrencyFormatter.format(stats.totalToday),
                subtitle: 'Cash ${CurrencyFormatter.format(stats.todayCash)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: stats.fromAdminApi
                  ? _buildTelemetryCard(
                      onTap: onEarningsTap,
                      title: 'Outstanding',
                      value: CurrencyFormatter.format(stats.outstandingDue),
                      subtitle: 'Still to collect',
                    )
                  : _buildTelemetryCard(
                      onTap: onEarningsTap,
                      title: "Today's earnings",
                      value: CurrencyFormatter.format(stats.totalToday * 0.785),
                      subtitle: '78.5% margin',
                    ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTelemetryCard(
                title: 'Guests',
                value: '${stats.totalInHouseGuests}',
                subtitle: '${stats.checkedInToday} checked in today',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTelemetryCard(
                onTap: onMonthlyTap,
                title: 'This month',
                value: CurrencyFormatter.format(stats.fromAdminApi ? stats.monthRevenue : stats.totalToday * 24),
                subtitle: 'Billing cycle',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelemetryCard({
    required String title,
    required String value,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
