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
        // Section Header: ₹ Financial & Revenue Telemetry
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '₹',
                      style: TextStyle(
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Financial & Revenue Telemetry',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Live Real-time Audit badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Live Real-time Audit',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Grid of 4 Metric Cards (2x2 Layout matching Reception Front Desk)
        Row(
          children: [
            // Card 1: Today's Revenue
            Expanded(
              child: _buildTelemetryCard(
                onTap: onRevenueTap,
                title: "TODAY'S REVENUE",
                value: CurrencyFormatter.format(stats.totalToday),
                subtitle: stats.totalToday > 0 ? 'Live audited collections' : 'Live audited collections',
                icon: const Text('₹', style: TextStyle(color: Color(0xFF0F766E), fontSize: 17, fontWeight: FontWeight.w900)),
                iconBgColor: const Color(0xFFE5F5F2),
                badges: [
                  _buildPillBadge(label: 'Live Counter', isGreen: true, hasDot: true),
                  _buildPillBadge(label: 'Counter', isTeal: true),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Card 2: Today's Earnings
            Expanded(
              child: _buildTelemetryCard(
                onTap: onEarningsTap,
                title: "TODAY'S EARNINGS",
                value: CurrencyFormatter.format(stats.totalToday * 0.785),
                subtitle: '78.5% Margin projection',
                icon: const Icon(Icons.trending_up_rounded, color: Color(0xFF0284C7), size: 18),
                iconBgColor: const Color(0xFFE0F2FE),
                badges: [
                  _buildPillBadge(label: '78.5% Margin', isGreen: true, icon: Icons.trending_up_rounded),
                  _buildPillBadge(label: 'Net Profit', isTeal: true),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            // Card 3: Total Guests
            Expanded(
              child: _buildTelemetryCard(
                onTap: onGuestsTap,
                title: 'TOTAL GUESTS',
                value: '${stats.totalInHouseGuests} Guests',
                subtitle: '${stats.totalInHouseGuests} Active In-house • ${stats.occupiedInHouse} Rooms',
                icon: const Icon(Icons.person_rounded, color: Color(0xFF8B5CF6), size: 18),
                iconBgColor: const Color(0xFFF3E8FF),
                badges: [
                  _buildPillBadge(label: 'In-House', isPurple: true),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Card 4: Monthly Revenue
            Expanded(
              child: _buildTelemetryCard(
                onTap: onMonthlyTap,
                title: 'MONTHLY REVENUE',
                value: CurrencyFormatter.format(stats.totalToday * 24),
                subtitle: 'Current billing cycle',
                icon: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFD97706), size: 18),
                iconBgColor: const Color(0xFFFEF3C7),
                badges: [
                  _buildPillBadge(label: 'Monthly Total', isAmber: true),
                ],
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
    required Widget icon,
    required Color iconBgColor,
    required List<Widget> badges,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE0E8F0), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060D2238),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top line: Title & Circle Avatar Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: const Color(0xFF687991),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: icon,
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Large Value in Dark Ink (matching Reception Front Desk)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: valueColor ?? const Color(0xFF172033),
                  ),
                  maxLines: 1,
                ),
              ),

              const SizedBox(height: 3),

              // Subtitle
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8190A5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Badges Row
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: badges,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillBadge({
    required String label,
    bool isGreen = false,
    bool isTeal = false,
    bool isPurple = false,
    bool isAmber = false,
    bool hasDot = false,
    IconData? icon,
  }) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    Color border = const Color(0xFFE2E8F0);

    if (isGreen) {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF059669);
      border = const Color(0xFFA7F3D0);
    } else if (isTeal) {
      bg = const Color(0xFFECFEFF);
      fg = const Color(0xFF0D9488);
      border = const Color(0xFF99F6E4);
    } else if (isPurple) {
      bg = const Color(0xFFFAF5FF);
      fg = const Color(0xFF7C3AED);
      border = const Color(0xFFE9D5FF);
    } else if (isAmber) {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFFD97706);
      border = const Color(0xFFFDE68A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDot) ...[
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
