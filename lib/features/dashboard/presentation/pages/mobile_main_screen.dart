import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/modern_bottom_nav_bar.dart';
import '../../../check_in_wizard/presentation/bloc/check_in_bloc.dart';
import '../../../check_in_wizard/presentation/bloc/check_in_event.dart';
import '../../../check_in_wizard/presentation/pages/check_in_wizard_page.dart';
import '../../../folios/presentation/pages/in_house_folios_page.dart';
import '../../../govt_id_compliance/presentation/pages/govt_id_compliance_page.dart';
import '../../../pos_settlement/presentation/pages/pos_settlement_page.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../../rooms/presentation/pages/category_rooms_page.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/kpi_metrics_grid.dart';
import '../widgets/modern_folio_card_mobile.dart';
import '../widgets/modern_mobile_header.dart';
import '../widgets/modern_quick_actions.dart';
import '../widgets/modern_room_card_mobile.dart';

class MobileMainScreen extends StatefulWidget {
  const MobileMainScreen({super.key});

  @override
  State<MobileMainScreen> createState() => _MobileMainScreenState();
}

class _MobileMainScreenState extends State<MobileMainScreen> {
  int _selectedTabIndex = 0;
  String _roomsSearchQuery = '';
  String _roomsFilterType = 'All';
  final TextEditingController _roomSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboardDataEvent());
  }

  @override
  void dispose() {
    _roomSearchController.dispose();
    super.dispose();
  }

  void _openCategoryRooms(BuildContext context, String categoryName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryRoomsPage(categoryName: categoryName),
      ),
    );
  }

  void _openCheckInWizard({RoomModel? preselectedRoom}) {
    context.read<CheckInBloc>().add(InitCheckInWizardEvent(preselectedRoom: preselectedRoom));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CheckInWizardPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // 1. Mobile Header
                ModernMobileHeader(
                  resortName: 'Mayal Resort 2',
                  onNotificationTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new operational alerts.')),
                    );
                  },
                  onProfileTap: () {
                    _showProfileBottomSheet(context);
                  },
                ),

                // 2. Tab Content View
                Expanded(
                  child: state.status == DashboardStatus.loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _buildCurrentTab(context, state),
                ),
              ],
            ),
          ),
          // 3. Floating Modern Bottom Navigation Bar
          bottomNavigationBar: ModernBottomNavBar(
            currentIndex: _selectedTabIndex,
            onTap: (index) {
              setState(() => _selectedTabIndex = index);
            },
            onQuickCheckIn: () => _openCheckInWizard(),
          ),
        );
      },
    );
  }

  Widget _buildCurrentTab(BuildContext context, DashboardState state) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildFrontDeskDashboard(context, state);
      case 1:
        return _buildRoomsMatrixTab(context, state);
      case 2:
        return _buildInHouseTab(context, state);
      case 3:
        return _buildMoreTab(context, state);
      default:
        return _buildFrontDeskDashboard(context, state);
    }
  }

  // TAB 0: Modern Front Desk Dashboard
  Widget _buildFrontDeskDashboard(BuildContext context, DashboardState state) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<DashboardBloc>().add(RefreshDashboardDataEvent());
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 14),
        children: [
          // KPI Metric Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'LIVE METRICS OVERVIEW',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      'Tap card to filter',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                KpiMetricsGrid(
                  stats: state.stats,
                  onMetricSelected: (filter) {
                    if (filter == 'InHouseFolios') {
                      setState(() => _selectedTabIndex = 2);
                    } else {
                      setState(() => _selectedTabIndex = 1);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Action Slider (5-Step Check-In, Govt ID, POS, Keycard)
          ModernQuickActions(
            onExpressCheckIn: () => _openCheckInWizard(),
            onGovtIdHub: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text('Govt ID Hub', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    body: const GovtIdCompliancePage(),
                  ),
                ),
              );
            },
            onPosInvoice: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text('POS & Invoices', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    body: const PosSettlementPage(),
                  ),
                ),
              );
            },
            onKeycardHub: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('RFID Keycard Terminal Active • Hold card near reader')),
              );
            },
          ),

          const SizedBox(height: 22),

          // Live Rooms Feed
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'LIVE ROOM STATUS MATRIX',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _selectedTabIndex = 1),
                  child: Text(
                    'View All (${state.allRooms.length}) →',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Room Cards List (Top Preview)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: state.allRooms.take(5).map((room) {
                return ModernRoomCardMobile(
                  room: room,
                  onTap: () => _openCategoryRooms(context, room.roomType),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Recent In-House Folios Feed
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'RECENT IN-HOUSE FOLIOS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _selectedTabIndex = 2),
                  child: Text(
                    'See All →',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: state.folios.map((folio) {
                return ModernFolioCardMobile(
                  folio: folio,
                  onTap: () => setState(() => _selectedTabIndex = 2),
                  onCheckout: folio.status == FolioStatus.inHouse
                      ? () {
                          context.read<DashboardBloc>().add(CheckoutGuestEvent(folio.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${folio.guestName} checked out successfully.')),
                          );
                        }
                      : null,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // TAB 1: Rooms Inventory & Categories
  Widget _buildRoomsMatrixTab(BuildContext context, DashboardState state) {
    final allCategories = <String, List<RoomModel>>{};
    for (final room in state.allRooms) {
      allCategories.putIfAbsent(room.roomType, () => []).add(room);
    }

    final totalRoomsCount = state.allRooms.length;
    final totalReadyCount = state.allRooms.where((r) => r.status == RoomStatus.available).length;
    final totalOccupiedCount = state.allRooms.where((r) => r.status == RoomStatus.occupied).length;
    final totalCleaningCount = state.allRooms.where((r) => r.status == RoomStatus.cleaning || r.status == RoomStatus.maintenance).length;

    // Filter categories based on search query & filter chip
    final query = _roomsSearchQuery.trim().toLowerCase();
    final filteredCategories = allCategories.entries.where((entry) {
      final catName = entry.key.toLowerCase();
      final rooms = entry.value;

      // Filter chip matching
      if (_roomsFilterType == 'Ready Only') {
        if (!rooms.any((r) => r.status == RoomStatus.available)) return false;
      } else if (_roomsFilterType == 'Family') {
        if (!catName.contains('family')) return false;
      } else if (_roomsFilterType == 'Couples') {
        if (!catName.contains('couple')) return false;
      } else if (_roomsFilterType == 'Suites') {
        if (!catName.contains('suite')) return false;
      }

      // Search query matching
      if (query.isNotEmpty) {
        final matchesCat = catName.contains(query);
        final matchesRoom = rooms.any((r) => r.roomNumber.toLowerCase().contains(query) || r.floor.toLowerCase().contains(query));
        if (!matchesCat && !matchesRoom) return false;
      }

      return true;
    }).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<DashboardBloc>().add(RefreshDashboardDataEvent());
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. Header Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Room Inventory & Categories',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                'Select a room category to view all room units and assign guests.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Real-Time Inventory Metrics Strip (Luxury Dark/Emerald Card)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2B28), Color(0xFF0A1F1D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'LIVE INVENTORY HEALTH',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: const Color(0xFF5EEAD4),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$totalRoomsCount Units Total',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildInventoryMetricPill(
                      label: 'Ready',
                      count: totalReadyCount,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                      icon: Icons.check_circle_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildInventoryMetricPill(
                      label: 'Occupied',
                      count: totalOccupiedCount,
                      color: const Color(0xFF38BDF8),
                      bgColor: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildInventoryMetricPill(
                      label: 'Turnaround',
                      count: totalCleaningCount,
                      color: const Color(0xFFFBBF24),
                      bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      icon: Icons.cleaning_services_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Search & Filter Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _roomSearchController,
              onChanged: (val) => setState(() => _roomsSearchQuery = val),
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search category or room # (e.g. #01, Suite)...',
                hintStyle: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                suffixIcon: _roomsSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                        onPressed: () {
                          _roomSearchController.clear();
                          setState(() => _roomsSearchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Quick Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'All (${allCategories.length})'),
                const SizedBox(width: 6),
                _buildFilterChip('Ready Only', 'Available ($totalReadyCount)'),
                const SizedBox(width: 6),
                _buildFilterChip('Family', 'Family'),
                const SizedBox(width: 6),
                _buildFilterChip('Couples', 'Couples'),
                const SizedBox(width: 6),
                _buildFilterChip('Suites', 'Suites'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 4. Category Cards List
          if (filteredCategories.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 44, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No categories match your filter',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try changing your search term or select another category filter.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () {
                      _roomSearchController.clear();
                      setState(() {
                        _roomsSearchQuery = '';
                        _roomsFilterType = 'All';
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset Filters'),
                  ),
                ],
              ),
            )
          else
            ...filteredCategories.map((entry) {
              return _buildLuxuryCategoryCard(context, entry.key, entry.value);
            }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInventoryMetricPill({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _roomsFilterType == key;
    return InkWell(
      onTap: () => setState(() => _roomsFilterType = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getCategoryStyle(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('family')) {
      return {
        'icon': Icons.family_restroom_rounded,
        'tag': 'FAMILY SUITE',
        'badgeColor': const Color(0xFFD97706),
        'badgeBg': const Color(0xFFFEF3C7),
        'iconBg': const Color(0xFFFFF7ED),
        'iconColor': const Color(0xFFEA580C),
        'borderColor': const Color(0xFFFDE68A),
        'highlight': 'Spacious 45m² • Balcony View',
      };
    } else if (lower.contains('couple')) {
      return {
        'icon': Icons.favorite_rounded,
        'tag': 'COUPLE HAVEN',
        'badgeColor': const Color(0xFFE11D48),
        'badgeBg': const Color(0xFFFFF1F2),
        'iconBg': const Color(0xFFFFF1F2),
        'iconColor': const Color(0xFFE11D48),
        'borderColor': const Color(0xFFFECDD3),
        'highlight': 'King Bed • Romantic Ambience',
      };
    } else if (lower.contains('presidential')) {
      return {
        'icon': Icons.workspace_premium_rounded,
        'tag': 'VIP PENTHOUSE',
        'badgeColor': const Color(0xFF7C3AED),
        'badgeBg': const Color(0xFFF5F3FF),
        'iconBg': const Color(0xFFFAF5FF),
        'iconColor': const Color(0xFF7C3AED),
        'borderColor': const Color(0xFFDDD6FE),
        'highlight': 'Butler Service • Top Floor',
      };
    } else if (lower.contains('executive')) {
      return {
        'icon': Icons.business_center_rounded,
        'tag': 'BUSINESS CLASS',
        'badgeColor': const Color(0xFF2563EB),
        'badgeBg': const Color(0xFFEFF6FF),
        'iconBg': const Color(0xFFEFF6FF),
        'iconColor': const Color(0xFF2563EB),
        'borderColor': const Color(0xFFBFDBFE),
        'highlight': 'High Floor • Ergonomic Desk',
      };
    } else {
      return {
        'icon': Icons.diamond_rounded,
        'tag': 'LUXURY DELUXE',
        'badgeColor': const Color(0xFF0D9488),
        'badgeBg': const Color(0xFFF0FDFA),
        'iconBg': const Color(0xFFF0FDFA),
        'iconColor': const Color(0xFF0F766E),
        'borderColor': const Color(0xFF99F6E4),
        'highlight': 'City View • Jacuzzi Tub',
      };
    }
  }

  Widget _buildLuxuryCategoryCard(BuildContext context, String categoryName, List<RoomModel> categoryRooms) {
    final availableCount = categoryRooms.where((r) => r.status == RoomStatus.available).length;
    final totalCount = categoryRooms.length;
    final sampleRoom = categoryRooms.first;
    final price = sampleRoom.pricePerNight;
    final maxGuests = sampleRoom.maxOccupancy;
    final style = _getCategoryStyle(categoryName);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _openCategoryRooms(context, categoryName),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: style['iconBg'] as Color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: style['borderColor'] as Color, width: 1),
                      ),
                      child: Icon(style['icon'] as IconData, color: style['iconColor'] as Color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    // Title & Specs
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryName.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: style['badgeBg'] as Color,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  style['tag'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: style['badgeColor'] as Color,
                                  ),
                                ),
                              ),
                              Text(
                                'Max $maxGuests Guests',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: availableCount > 0 ? AppColors.statusAvailableBg : AppColors.statusMaintenanceBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: availableCount > 0 ? AppColors.statusAvailableBorder : AppColors.statusMaintenanceBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: availableCount > 0 ? AppColors.statusAvailable : AppColors.statusMaintenance,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$availableCount / $totalCount Ready',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: availableCount > 0 ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Smooth Readiness Progress Track
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalCount > 0 ? (availableCount / totalCount) : 0,
                    minHeight: 4.5,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      availableCount > 0 ? AppColors.statusAvailable : AppColors.statusMaintenance,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Room Units Interactive Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Units: ',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: categoryRooms.map((room) {
                          final isAvail = room.status == RoomStatus.available;
                          final isClean = room.status == RoomStatus.cleaning;
                          final bg = isAvail
                              ? AppColors.statusAvailableBg
                              : (isClean ? AppColors.statusCleaningBg : AppColors.statusOccupiedBg);
                          final border = isAvail
                              ? AppColors.statusAvailableBorder
                              : (isClean ? AppColors.statusCleaningBorder : AppColors.statusOccupiedBorder);
                          final textCol = isAvail
                              ? const Color(0xFF065F46)
                              : (isClean ? const Color(0xFF92400E) : const Color(0xFF075985));

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: border, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isAvail
                                        ? AppColors.statusAvailable
                                        : (isClean ? AppColors.statusCleaning : AppColors.statusOccupied),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  room.roomNumber,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: textCol,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 10),

                // Bottom Action & Price Row (No Horizontal Overflow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: CurrencyFormatter.format(price),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              children: [
                                TextSpan(
                                  text: ' / night',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            style['highlight'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Room Numbers',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TAB 2: In-House Folios
  Widget _buildInHouseTab(BuildContext context, DashboardState state) {
    return const InHouseFoliosPage();
  }

  // TAB 3: More / Settings / Operations
  Widget _buildMoreTab(BuildContext context, DashboardState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Operations & Hubs',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 14),
        _buildSettingsTile(
          icon: Icons.verified_user_rounded,
          title: 'Govt ID & Form-C Compliance',
          subtitle: 'Police registry records, biometric ID verification',
          color: AppColors.accentCyan,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('Govt ID Compliance', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  body: const GovtIdCompliancePage(),
                ),
              ),
            );
          },
        ),
        _buildSettingsTile(
          icon: Icons.point_of_sale_rounded,
          title: 'POS Folio Settlement Desk',
          subtitle: 'Dining, mini-bar & laundry charge postings',
          color: AppColors.accentGold,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('POS & Invoices', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  body: const PosSettlementPage(),
                ),
              ),
            );
          },
        ),
        _buildSettingsTile(
          icon: Icons.schedule_rounded,
          title: 'Front Desk Master Schedule',
          subtitle: 'Check-in: 02:00 PM • Check-out: 12:00 PM (Asia/Kolkata)',
          color: AppColors.primary,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
      ),
    );
  }

  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('J', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(height: 10),
              Text('Jatin Raval', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('abhishekraval1531@gmail.com', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.security, color: AppColors.primary),
                title: Text('Role: Front Desk Supervisor', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.statusMaintenance),
                title: Text('Sign Out', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.statusMaintenance)),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
