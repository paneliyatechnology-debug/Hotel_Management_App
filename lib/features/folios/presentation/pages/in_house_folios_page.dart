import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../dashboard/data/models/guest_folio_model.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_event.dart';
import '../../../dashboard/presentation/bloc/dashboard_state.dart';
import '../widgets/guest_folio_details_dialog.dart';
import '../widgets/checkout_settlement_dialog.dart';
import 'in_house_guest_details_page.dart';
import '../../../dashboard/presentation/widgets/dashboard_shimmer_loader.dart';

class InHouseFoliosPage extends StatefulWidget {
  const InHouseFoliosPage({super.key});

  @override
  State<InHouseFoliosPage> createState() => _InHouseFoliosPageState();
}

class _InHouseFoliosPageState extends State<InHouseFoliosPage>
    with AutomaticKeepAliveClientMixin<InHouseFoliosPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'In-House', 'Departed', 'Checkout Today', 'Payment Pending', 'Keycard Issue'
  bool _isSearchFocused = false;
  String? _selectedFolioId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load live bookings with status=CHECKED_IN from /api/v1/receptionist/bookings smoothly in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardBloc>().add(LoadBookingsEvent(status: 'CHECKED_IN', showLoading: false));
      }
    });

    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSearchFocused = _searchFocusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showFolioDetails(BuildContext context, GuestFolioModel folio) {
    setState(() => _selectedFolioId = folio.id);
    final isWide = MediaQuery.of(context).size.width >= 900;
    if (!isWide) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InHouseGuestDetailsPage(folioId: folio.id),
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) => GuestFolioDetailsDialog(folio: folio),
      );
    }
  }

  void _confirmCheckout(BuildContext context, GuestFolioModel folio) {
    CheckoutSettlementDialog.show(context, folio);
  }

  Widget _buildStatusPill(FolioStatus status) {
    final isInHouse = status == FolioStatus.inHouse;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isInHouse ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInHouse ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isInHouse ? const Color(0xFF16A34A) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isInHouse ? 'IN-HOUSE' : 'DEPARTED',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: isInHouse ? const Color(0xFF15803D) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state.status == DashboardStatus.loading && state.folios.isEmpty && state.allRooms.isEmpty) {
          return const InHouseShimmerLoader();
        }
        final allFolios = state.folios;
        final inHouseCount = allFolios.where((f) => f.status == FolioStatus.inHouse).length;
        final departedCount = allFolios.where((f) => f.status == FolioStatus.departed).length;
        final checkoutTodayCount = allFolios.where((f) => f.isCheckoutToday).length;
        final paymentPendingCount = allFolios.where((f) => f.hasPendingPayment).length;
        final totalRevenue = allFolios.fold<double>(0, (sum, f) => sum + f.totalAmount);

        // Filter folios
        final filteredFolios = allFolios.where((folio) {
          // Status filter
          if (_selectedFilter == 'In-House' && folio.status != FolioStatus.inHouse) {
            return false;
          }
          if (_selectedFilter == 'Departed' && folio.status != FolioStatus.departed) {
            return false;
          }
          if (_selectedFilter == 'Checkout Today' && !folio.isCheckoutToday) {
            return false;
          }
          if (_selectedFilter == 'Payment Pending' && !folio.hasPendingPayment) {
            return false;
          }
          if (_selectedFilter == 'Keycard Issue' && !folio.hasKeycardIssue) {
            return false;
          }

          // Search query
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchesName = folio.guestName.toLowerCase().contains(query);
            final matchesRoom = folio.assignedRoom.toLowerCase().contains(query);
            final matchesPhone = folio.phone.toLowerCase().contains(query);
            final matchesEmail = folio.email.toLowerCase().contains(query);
            final matchesId = folio.id.toLowerCase().contains(query);
            final matchesBookingId = folio.bookingId?.toLowerCase().contains(query) ?? false;
            return matchesName || matchesRoom || matchesPhone || matchesEmail || matchesId || matchesBookingId;
          }
          return true;
        }).toList();

        final isWideScreen = MediaQuery.of(context).size.width >= 900;
        final effectiveSelectedId = _selectedFolioId ?? (filteredFolios.isNotEmpty ? filteredFolios.first.id : (allFolios.isNotEmpty ? allFolios.first.id : null));

        if (isWideScreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Folios list
              Expanded(
                flex: 5,
                child: _buildFoliosScrollContent(
                  context,
                  state,
                  filteredFolios,
                  allFolios.length,
                  inHouseCount,
                  departedCount,
                  checkoutTodayCount,
                  paymentPendingCount,
                  totalRevenue,
                ),
              ),
              Container(width: 1, color: const Color(0xFFE2E8F0)),
              // Right side: Selected guest details
              Expanded(
                flex: 6,
                child: effectiveSelectedId != null
                    ? InHouseGuestDetailsPage(
                        folioId: effectiveSelectedId,
                        isEmbedded: true,
                      )
                    : Center(
                        child: Text(
                          'Select a guest folio to inspect details',
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                      ),
              ),
            ],
          );
        }

        return _buildFoliosScrollContent(
          context,
          state,
          filteredFolios,
          allFolios.length,
          inHouseCount,
          departedCount,
          checkoutTodayCount,
          paymentPendingCount,
          totalRevenue,
        );
      },
    );
  }

  Widget _buildFoliosScrollContent(
    BuildContext context,
    DashboardState state,
    List<GuestFolioModel> filteredFolios,
    int totalCount,
    int inHouseCount,
    int departedCount,
    int checkoutTodayCount,
    int paymentPendingCount,
    double totalRevenue,
  ) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<DashboardBloc>().add(LoadBookingsEvent(status: 'CHECKED_IN'));
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4 KPI Summary Metrics Cards
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'IN-HOUSE',
                    value: '$inHouseCount Active',
                    icon: Icons.hotel_rounded,
                    iconBg: const Color(0xFFE6F7F2),
                    iconColor: const Color(0xFF0F766E),
                    onTap: () => setState(() => _selectedFilter = 'In-House'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: 'FOLIO VALUE',
                    value: CurrencyFormatter.format(totalRevenue),
                    icon: Icons.currency_rupee_rounded,
                    iconBg: const Color(0xFFE6F7F2),
                    iconColor: const Color(0xFF0F766E),
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'CHECKOUT TODAY',
                    value: '$checkoutTodayCount Due',
                    icon: Icons.calendar_month_outlined,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    onTap: () => setState(() => _selectedFilter = 'Checkout Today'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: 'PAYMENT PENDING',
                    value: '$paymentPendingCount Guests',
                    icon: Icons.assignment_late_outlined,
                    iconBg: const Color(0xFFFEE2E2),
                    iconColor: const Color(0xFFEF4444),
                    onTap: () => setState(() => _selectedFilter = 'Payment Pending'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar & Filter Button
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSearchFocused ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                        width: _isSearchFocused ? 1.5 : 1.0,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    child: TextField(
                      focusNode: _searchFocusNode,
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      cursorColor: const Color(0xFF0F766E),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        hintText: 'Search guest name, room, phone, booking...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                splashRadius: 16,
                                icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter Settings Button
                InkWell(
                  onTap: () => _showFilterOptionsBottomSheet(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    child: const Icon(Icons.tune_rounded, size: 20, color: Color(0xFF0F766E)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill('All', 'All ($totalCount)'),
                  const SizedBox(width: 6),
                  _buildFilterPill('In-House', 'In-House ($inHouseCount)'),
                  const SizedBox(width: 6),
                  _buildFilterPill('Departed', 'Departed ($departedCount)'),
                  const SizedBox(width: 6),
                  _buildFilterPill('Checkout Today', 'Checkout Today ($checkoutTodayCount)'),
                  const SizedBox(width: 6),
                  _buildFilterPill('Payment Pending', 'Payment Pending ($paymentPendingCount)'),
                  const SizedBox(width: 6),
                  _buildFilterPill('Keycard Issue', 'Keycard Issue'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Folios List
            if (filteredFolios.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_off_rounded, size: 32, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Matching Folios Found',
                      style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try searching with a different guest name, phone, or clear your filters.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    if (_searchQuery.isNotEmpty || _selectedFilter != 'All') ...[
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedFilter = 'All';
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text('Reset Filters', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredFolios.length,
                itemBuilder: (context, index) {
                  final folio = filteredFolios[index];
                  return _buildLuxuryFolioCard(context, folio);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1.5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.22),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryFolioCard(BuildContext context, GuestFolioModel folio) {
    final isInHouse = folio.status == FolioStatus.inHouse;
    final initial = folio.guestName.isNotEmpty ? folio.guestName[0].toUpperCase() : 'G';
    final roomNum = folio.assignedRoom.replaceAll('Room ', '').trim();
    final nightsCount = folio.totalNights;
    final adultsCount = folio.numberOfGuests > 0 ? folio.numberOfGuests : 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInHouse ? const Color(0xFF6EE7B7) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Compact Header Row
            Row(
              children: [
                // Compact Avatar circle (32x32)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F766E),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Guest Name + Phone inline
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        folio.guestName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          const Icon(Icons.call_rounded, size: 10, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              folio.phone,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Status Pill
                _buildStatusPill(folio.status),

                const SizedBox(width: 2),

                // 3-dots more menu
                InkWell(
                  onTap: () => _showFolioQuickActions(context, folio),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // 2. Compact Details Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  // Section 1: Room
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bed_outlined, size: 10, color: Color(0xFF64748B)),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                'Room',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          roomNum.startsWith('#') ? roomNum : '#$roomNum',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          folio.roomType.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  Container(width: 0.6, height: 34, color: const Color(0xFFE2E8F0)),

                  // Section 2: Stay Dates
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 9.5, color: Color(0xFF64748B)),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  'Stay Dates',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${DateFormatter.formatShort(folio.checkInDate)} - ${DateFormatter.formatShort(folio.checkOutDate)}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$nightsCount Night${nightsCount > 1 ? "s" : ""}',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(width: 0.6, height: 34, color: const Color(0xFFE2E8F0)),

                  // Section 3: Guests
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline_rounded, size: 10, color: Color(0xFF64748B)),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  'Guests',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$adultsCount Adult${adultsCount > 1 ? "s" : ""}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '0 Child',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(width: 0.6, height: 34, color: const Color(0xFFE2E8F0)),

                  // Section 4: Folio Amount
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Folio Total',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            CurrencyFormatter.format(folio.totalAmount),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F766E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            folio.keycardNumber != null ? folio.keycardNumber! : 'KC-${roomNum.replaceAll("#", "")}',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // 3. Compact Action Buttons (View Details, Checkout)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () => _showFolioDetails(context, folio),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0F766E), width: 1.0),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description_outlined, size: 13, color: Color(0xFF0F766E)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'View Details',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _confirmCheckout(context, folio),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInHouse ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.logout_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Checkout',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFolioQuickActions(BuildContext context, GuestFolioModel folio) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  folio.guestName,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                Text(
                  '${folio.assignedRoom} • ${folio.roomType}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: Color(0xFF0F766E)),
                  title: Text('View Full Details', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showFolioDetails(context, folio);
                  },
                ),
                if (folio.status == FolioStatus.inHouse)
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                    title: Text('Checkout Guest', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626))),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _confirmCheckout(context, folio);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Filter In-House Guests',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'All',
                    'In-House',
                    'Departed',
                    'Checkout Today',
                    'Payment Pending',
                    'Keycard Issue',
                  ].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0F766E),
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                        Navigator.pop(bottomSheetContext);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
