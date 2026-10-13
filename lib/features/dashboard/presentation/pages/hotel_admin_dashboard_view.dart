import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../data/models/guest_folio_model.dart';
import '../../data/models/hotel_stats_model.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/hotel_admin_telemetry_cards.dart';
import '../widgets/hotel_admin_charts.dart';
import 'admin_daily_collections_page.dart';
import 'admin_staff_management_page.dart';
import 'admin_rooms_tariffs_page.dart';
import 'admin_revenue_reports_page.dart';

class HotelAdminDashboardView extends StatefulWidget {
  final String resortName;
  final String staffName;
  final String userRole;
  final HotelStatsModel stats;
  final List<RoomModel> rooms;
  final List<GuestFolioModel> folios;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onNavigateToRooms;
  final VoidCallback? onNavigateToInHouse;
  final VoidCallback? onNavigateToGuests;
  final VoidCallback? onNavigateToMore;

  const HotelAdminDashboardView({
    super.key,
    required this.resortName,
    required this.staffName,
    required this.userRole,
    required this.stats,
    required this.rooms,
    required this.folios,
    this.onOpenDrawer,
    this.onNavigateToRooms,
    this.onNavigateToInHouse,
    this.onNavigateToGuests,
    this.onNavigateToMore,
  });

  @override
  State<HotelAdminDashboardView> createState() => _HotelAdminDashboardViewState();
}

class _HotelAdminDashboardViewState extends State<HotelAdminDashboardView> {
  String _selectedChartTab = 'ALL';

  @override
  Widget build(BuildContext context) {
    final totalInventory = widget.rooms.isNotEmpty ? widget.rooms.length : 4;
    final occupancy = totalInventory > 0
        ? ((widget.stats.occupiedInHouse / totalInventory) * 100).round()
        : 0;

    return RefreshIndicator(
      color: const Color(0xFF0F766E),
      onRefresh: () async {
        context.read<DashboardBloc>().add(RefreshDashboardDataEvent());
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          // 1. Financial & Revenue Telemetry Section (4 Cards Grid)
          HotelAdminTelemetryCards(
            stats: widget.stats,
            onRevenueTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminDailyCollectionsPage()),
              );
            },
            onEarningsTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminRevenueReportsPage()),
              );
            },
            onGuestsTap: widget.onNavigateToInHouse,
            onMonthlyTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminRevenueReportsPage()),
              );
            },
          ),

          const SizedBox(height: 14),

          // 3. Live Room Occupancy Donut Card
          LiveRoomOccupancyDonutCard(
            stats: widget.stats,
            totalRooms: totalInventory,
          ),

          const SizedBox(height: 20),

          // 4. Core Mobile Management Hub (4 Tactile Action Tiles)
          _buildMobileCoreHub(context),

          const SizedBox(height: 20),

          // 5. Visual Revenue & Occupancy Analytics Section Header
          _buildAnalyticsHeader(context),

          const SizedBox(height: 12),

          // 8. Interactive Analytics Chart Cards Deck
          _buildAnalyticsDeck(totalInventory),
        ],
      ),
    );
  }

  // --- 3. CORE MOBILE MANAGEMENT HUB ---
  Widget _buildMobileCoreHub(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'HOTEL MANAGEMENT HUB',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Admin Suite',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F766E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2x2 Grid of Primary Admin Modules
        Row(
          children: [
            Expanded(
              child: _buildCoreFeatureCard(
                context,
                title: 'Daily Collections',
                subtitle: 'Cash Drawer & Vault',
                icon: Icons.payments_rounded,
                accentColor: const Color(0xFF059669),
                gradientColors: [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                badgeText: 'Handover',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminDailyCollectionsPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCoreFeatureCard(
                context,
                title: 'Rooms & Tariffs',
                subtitle: '${widget.rooms.isNotEmpty ? widget.rooms.length : 4} Rooms • Tariffs',
                icon: Icons.meeting_room_rounded,
                accentColor: const Color(0xFF0284C7),
                gradientColors: [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                badgeText: 'Live Matrix',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminRoomsTariffsPage()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCoreFeatureCard(
                context,
                title: 'Staff Hub',
                subtitle: 'Receptionists & Shifts',
                icon: Icons.badge_rounded,
                accentColor: const Color(0xFF7C3AED),
                gradientColors: [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
                badgeText: 'Staff Team',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminStaffManagementPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCoreFeatureCard(
                context,
                title: 'Revenue Reports',
                subtitle: 'Audited Ledger & Tax',
                icon: Icons.analytics_rounded,
                accentColor: const Color(0xFFD97706),
                gradientColors: [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                badgeText: 'Analytics',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminRevenueReportsPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoreFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<Color> gradientColors,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradientColors),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accentColor, size: 17),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. ANALYTICS SECTION HEADER ---
  Widget _buildAnalyticsHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: Color(0xFF0284C7), size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Visual Revenue & Occupancy Analytics',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Live Realtime Telemetry',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Interactive Segmented Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChartFilterChip('ALL', 'All Analytics'),
              const SizedBox(width: 6),
              _buildChartFilterChip('OCCUPANCY', 'Live Occupancy'),
              const SizedBox(width: 6),
              _buildChartFilterChip('REVENUE', 'Revenue Dynamics'),
              const SizedBox(width: 6),
              _buildChartFilterChip('GOAL', 'Daily Goal'),
              const SizedBox(width: 6),
              _buildChartFilterChip('TRAFFIC', 'Traffic Flow'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartFilterChip(String key, String label) {
    final isSelected = _selectedChartTab == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartTab = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // --- 7. ANALYTICS DECK ---
  Widget _buildAnalyticsDeck(int totalInventory) {
    final showAll = _selectedChartTab == 'ALL';

    return Column(
      children: [
        if (showAll || _selectedChartTab == 'OCCUPANCY') ...[
          LiveRoomOccupancyDonutCard(
            stats: widget.stats,
            totalRooms: totalInventory,
          ),
          const SizedBox(height: 14),
        ],

        if (showAll || _selectedChartTab == 'REVENUE') ...[
          const RevenueDynamicsSplineCard(
            total7DayCollection: '₹21,000',
            upiPercentage: '98% UPI',
            cashPercentage: '32% Cash',
            projectedMonthEnd: '₹0',
            weeklyGrowth: '+14.8% vs last week',
          ),
          const SizedBox(height: 14),
        ],

        if (showAll || _selectedChartTab == 'GOAL') ...[
          const DailyRevenueGoalCard(
            percentage: 53,
            achievedAmount: '₹18,500',
            targetAmount: '₹35,000 / Day',
          ),
          const SizedBox(height: 14),
        ],

        if (showAll || _selectedChartTab == 'TRAFFIC') ...[
          const WeeklyReceptionTrafficCard(),
        ],
      ],
    );
  }
}
