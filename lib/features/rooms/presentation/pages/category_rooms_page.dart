import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../check_in_wizard/presentation/bloc/check_in_bloc.dart';
import '../../../check_in_wizard/presentation/bloc/check_in_event.dart';
import '../../../check_in_wizard/presentation/pages/check_in_wizard_page.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_event.dart';
import '../../../dashboard/presentation/bloc/dashboard_state.dart';
import '../../../dashboard/presentation/widgets/modern_room_bottom_sheet.dart';
import '../../data/models/room_model.dart';

class CategoryRoomsPage extends StatefulWidget {
  final String categoryName;
  final String? roomTypeId;

  const CategoryRoomsPage({
    super.key,
    required this.categoryName,
    this.roomTypeId,
  });

  @override
  State<CategoryRoomsPage> createState() => _CategoryRoomsPageState();
}

class _CategoryRoomsPageState extends State<CategoryRoomsPage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isSearchOpen = false;

  void _openGuestForm(RoomModel room) {
    context.read<CheckInBloc>().add(InitCheckInWizardEvent(preselectedRoom: room));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CheckInWizardPage(),
      ),
    );
  }

  String get _displayCategoryName {
    final words = widget.categoryName.trim().split(RegExp(r'\s+'));
    return words
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  IconData get _categoryIcon {
    final name = widget.categoryName.toLowerCase();
    if (name.contains('family')) {
      return Icons.people_alt_rounded;
    } else if (name.contains('suite')) {
      return Icons.meeting_room_rounded;
    } else if (name.contains('deluxe')) {
      return Icons.meeting_room_rounded;
    } else if (name.contains('penthouse') || name.contains('vip') || name.contains('presidential')) {
      return Icons.workspace_premium_rounded;
    }
    return Icons.hotel_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        // Filter rooms matching this category ID or category name
        final categoryRooms = state.allRooms.where((r) {
          if (widget.roomTypeId != null && widget.roomTypeId!.isNotEmpty && r.roomTypeId == widget.roomTypeId) {
            return true;
          }
          return r.roomType.trim().toLowerCase() == widget.categoryName.trim().toLowerCase();
        }).toList();

        final totalCount = categoryRooms.length;
        final availableCount = categoryRooms.where((r) => r.status == RoomStatus.available).length;
        final occupiedCount = categoryRooms.where((r) => r.status == RoomStatus.occupied).length;
        final cleaningCount = categoryRooms.where((r) => r.status == RoomStatus.cleaning).length;
        final maintenanceCount = categoryRooms.where((r) => r.status == RoomStatus.maintenance).length;
        final floor1Count = categoryRooms.where((r) => r.floor == 'Floor 1').length;
        final floor2Count = categoryRooms.where((r) => r.floor == 'Floor 2').length;
        final floor3Count = categoryRooms.where((r) => r.floor == 'Floor 3').length;

        // Filter based on tab selection
        List<RoomModel> filteredRooms = categoryRooms;
        if (_selectedFilter == 'Available') {
          filteredRooms = categoryRooms.where((r) => r.status == RoomStatus.available).toList();
        } else if (_selectedFilter == 'Occupied') {
          filteredRooms = categoryRooms.where((r) => r.status == RoomStatus.occupied).toList();
        } else if (_selectedFilter == 'Cleaning') {
          filteredRooms = categoryRooms.where((r) => r.status == RoomStatus.cleaning).toList();
        } else if (_selectedFilter == 'Maintenance') {
          filteredRooms = categoryRooms.where((r) => r.status == RoomStatus.maintenance).toList();
        } else if (_selectedFilter == 'Floor 1') {
          filteredRooms = categoryRooms.where((r) => r.floor == 'Floor 1').toList();
        } else if (_selectedFilter == 'Floor 2') {
          filteredRooms = categoryRooms.where((r) => r.floor == 'Floor 2').toList();
        } else if (_selectedFilter == 'Floor 3') {
          filteredRooms = categoryRooms.where((r) => r.floor == 'Floor 3').toList();
        }

        // Apply search query if present
        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.trim().toLowerCase();
          filteredRooms = filteredRooms.where((r) {
            return r.roomNumber.toLowerCase().contains(query) ||
                r.floor.toLowerCase().contains(query) ||
                (r.currentGuestName != null && r.currentGuestName!.toLowerCase().contains(query));
          }).toList();
        }

        // Category subtitle info from first room
        String categoryDetailsText = '2 Bed (2 Double Beds) • Max 2 Guests';
        if (categoryRooms.isNotEmpty) {
          final first = categoryRooms.first;
          categoryDetailsText = '${first.bedInfoLabel} • ${first.capacityLabel}';
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF0F172A)),
                ),
              ),
            ),
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Mayal Resort 2 • Room Number Inventory',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.hotel_rounded,
                    size: 19,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            children: [
              // 1. Category Header Card
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _categoryIcon,
                        color: const Color(0xFF0F766E),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayCategoryName,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            categoryDetailsText,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 36,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Rooms',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalCount',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F766E),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Section Title & Search/Filter Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        const Opacity(
                          opacity: 0.0,
                          child: Text(
                            'AVAILABLE ROOM NUMBERS',
                            style: TextStyle(fontSize: 1),
                          ),
                        ),
                        Text(
                          'ROOM NUMBERS (${filteredRooms.length})',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: const Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isSearchOpen = !_isSearchOpen),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _isSearchOpen ? const Color(0xFFECFDF5) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isSearchOpen ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.search_rounded,
                            size: 16,
                            color: _isSearchOpen ? const Color(0xFF0F766E) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedFilter = 'All';
                            _searchQuery = '';
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (_isSearchOpen) ...[
                const SizedBox(height: 8),
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search room number or guest name...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 14),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // 3. Filter Pills Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill('All', totalCount),
                    _buildFilterPill('Available', availableCount),
                    _buildFilterPill('Occupied', occupiedCount),
                    _buildFilterPill('Cleaning', cleaningCount),
                    _buildFilterPill('Maintenance', maintenanceCount),
                    if (floor1Count > 0) _buildFilterPill('Floor 1', floor1Count),
                    if (floor2Count > 0) _buildFilterPill('Floor 2', floor2Count),
                    if (floor3Count > 0) _buildFilterPill('Floor 3', floor3Count),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 4. Room Units List
              if (filteredRooms.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.meeting_room_outlined, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        'No room units match this filter.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: filteredRooms.map((room) => _buildRoomCard(context, room)).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterPill(String label, int count) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x220F766E),
                    blurRadius: 4,
                    offset: Offset(0, 1.5),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          '$label ($count)',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room) {
    final isAvailable = room.status == RoomStatus.available;
    final isOccupied = room.status == RoomStatus.occupied;
    final isCleaning = room.status == RoomStatus.cleaning;
    final isMaintenance = room.status == RoomStatus.maintenance;

    Color squircleBg = const Color(0xFFE6F7F2);
    Color squircleColor = const Color(0xFF0F766E);
    Color badgeBg = const Color(0xFFECFDF5);
    Color badgeColor = const Color(0xFF059669);
    IconData badgeIcon = Icons.check_circle_rounded;
    String badgeLabel = 'AVAILABLE';

    if (isOccupied) {
      squircleBg = const Color(0xFFEFF6FF);
      squircleColor = const Color(0xFF2563EB);
      badgeBg = const Color(0xFFEFF6FF);
      badgeColor = const Color(0xFF2563EB);
      badgeIcon = Icons.person_rounded;
      badgeLabel = 'OCCUPIED';
    } else if (isCleaning) {
      squircleBg = const Color(0xFFFFFBEB);
      squircleColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFFFBEB);
      badgeColor = const Color(0xFFD97706);
      badgeIcon = Icons.cleaning_services_rounded;
      badgeLabel = 'CLEANING';
    } else if (isMaintenance) {
      squircleBg = const Color(0xFFFEF2F2);
      squircleColor = const Color(0xFFDC2626);
      badgeBg = const Color(0xFFFEF2F2);
      badgeColor = const Color(0xFFDC2626);
      badgeIcon = Icons.build_rounded;
      badgeLabel = 'MAINTENANCE';
    }

    String roomTitle = room.roomNumber;
    if (!roomTitle.startsWith('Room ')) {
      roomTitle = 'Room #${roomTitle.replaceAll('#', '')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (isAvailable) {
              _openGuestForm(room);
            } else {
              ModernRoomBottomSheet.show(
                context: context,
                room: room,
                onStatusChanged: (newStatus) {
                  context.read<DashboardBloc>().add(
                        ChangeRoomStatusDashboardEvent(
                          roomId: room.id,
                          newStatus: newStatus,
                        ),
                      );
                },
                onExpressCheckIn: () => _openGuestForm(room),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Squircle: Bed Icon + Room Number
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: squircleBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hotel_rounded,
                        size: 18,
                        color: squircleColor,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        room.roomNumber,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: squircleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 9),

                // Middle Column: Room Name + Status Pill + Floor + (Guest / Capacity)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            roomTitle,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon, size: 9.5, color: badgeColor),
                                const SizedBox(width: 2.5),
                                Text(
                                  badgeLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: badgeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        room.floor,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (isOccupied && room.currentGuestName != null && room.currentGuestName!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 11.5, color: Color(0xFF64748B)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                room.currentGuestName!,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const Icon(Icons.hotel_rounded, size: 11, color: Color(0xFF64748B)),
                              const SizedBox(width: 2.5),
                              Text(
                                room.bedInfoLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.people_alt_rounded, size: 11, color: Color(0xFF64748B)),
                              const SizedBox(width: 2.5),
                              Text(
                                room.capacityLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Right Column: Price + Action Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          room.pricePerNight == 0 ? '₹0' : CurrencyFormatter.format(room.pricePerNight),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F766E),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '/nt',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Select Room',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 2.5),
                            const Icon(Icons.arrow_forward_rounded, size: 10.5, color: Colors.white),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF0F766E),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.tune_rounded, size: 11, color: Color(0xFF0F766E)),
                            const SizedBox(width: 3),
                            Text(
                              'Manage',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
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
}
