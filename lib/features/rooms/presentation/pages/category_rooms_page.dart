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

  const CategoryRoomsPage({
    super.key,
    required this.categoryName,
  });

  @override
  State<CategoryRoomsPage> createState() => _CategoryRoomsPageState();
}

class _CategoryRoomsPageState extends State<CategoryRoomsPage> {
  String _selectedFilter = 'All';

  void _openGuestForm(RoomModel room) {
    context.read<CheckInBloc>().add(InitCheckInWizardEvent(preselectedRoom: room));
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
        // Filter rooms matching this category name (case-insensitive)
        final categoryRooms = state.allRooms
            .where((r) => r.roomType.toLowerCase() == widget.categoryName.toLowerCase())
            .toList();

        final totalCount = categoryRooms.length;
        final availableCount = categoryRooms.where((r) => r.status == RoomStatus.available).length;
        final occupiedCount = categoryRooms.where((r) => r.status == RoomStatus.occupied).length;
        final cleaningCount = categoryRooms.where((r) => r.status == RoomStatus.cleaning).length;
        final maintenanceCount = categoryRooms.where((r) => r.status == RoomStatus.maintenance).length;
        final floor1Count = categoryRooms.where((r) => r.floor == 'Floor 1').length;
        final floor2Count = categoryRooms.where((r) => r.floor == 'Floor 2').length;
        final floor3Count = categoryRooms.where((r) => r.floor == 'Floor 3').length;

        final sampleRoom = categoryRooms.isNotEmpty ? categoryRooms.first : null;
        final price = sampleRoom?.pricePerNight ?? 0;
        final maxGuests = sampleRoom?.maxOccupancy ?? 2;
        final amenities = sampleRoom?.amenities ?? const ['Wi-Fi', 'AC', 'TV', 'En-suite Bath'];

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

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Mayal Resort 2 • Room Number Inventory',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // 1. Hero Category Information Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ROOM CATEGORY',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.categoryName.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Max $maxGuests Guests per Unit',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.formatWithPerNight(price),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.statusAvailable,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$availableCount / $totalCount Units Ready',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 10),

                    // Amenities Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: amenities.map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '✓ $item',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. Filter Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'AVAILABLE ROOM NUMBERS (${filteredRooms.length})',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'Tap unit to assign',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', totalCount),
                    _buildFilterChip('Available', availableCount),
                    _buildFilterChip('Occupied', occupiedCount),
                    _buildFilterChip('Cleaning', cleaningCount),
                    _buildFilterChip('Maintenance', maintenanceCount),
                    _buildFilterChip('Floor 1', floor1Count),
                    _buildFilterChip('Floor 2', floor2Count),
                    _buildFilterChip('Floor 3', floor3Count),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Room Units List
              if (filteredRooms.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
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
                  children: filteredRooms.map((room) {
                    final isAvailable = room.status == RoomStatus.available;
                    Color accentColor = AppColors.statusAvailable;
                    Color bgColor = AppColors.statusAvailableBg;
                    if (room.status == RoomStatus.occupied) {
                      accentColor = AppColors.statusOccupied;
                      bgColor = AppColors.statusOccupiedBg;
                    } else if (room.status == RoomStatus.cleaning) {
                      accentColor = AppColors.statusCleaning;
                      bgColor = AppColors.statusCleaningBg;
                    } else if (room.status == RoomStatus.maintenance) {
                      accentColor = AppColors.statusMaintenance;
                      bgColor = AppColors.statusMaintenanceBg;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isAvailable ? AppColors.statusAvailableBorder : AppColors.border,
                          width: isAvailable ? 1.4 : 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 8,
                            offset: Offset(0, 2),
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
                              // Open status sheet to allow changing housekeeping status
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
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Room Number Box
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        room.roomNumber,
                                        style: GoogleFonts.inter(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${room.roomNumber} • ${room.floor}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              StatusBadge.fromRoomStatus(room.status),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${widget.categoryName} • ${CurrencyFormatter.formatWithPerNight(room.pricePerNight)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (room.currentGuestName != null) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.person_rounded, size: 12, color: AppColors.statusOccupied),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Occupied: ${room.currentGuestName!}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.statusOccupied,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),
                                const Divider(height: 1, color: AppColors.borderLight),
                                const SizedBox(height: 8),

                                // Bottom Action Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            isAvailable ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                                            size: 14,
                                            color: isAvailable ? AppColors.statusAvailable : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              isAvailable ? 'Ready for Guest Check-In' : 'Click to toggle status',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: isAvailable ? FontWeight.w600 : FontWeight.w500,
                                                color: isAvailable ? AppColors.statusAvailable : AppColors.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    if (isAvailable)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [AppColors.primaryLight, AppColors.primary],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Select Room',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
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
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        onSelected: (selected) {
          setState(() => _selectedFilter = label);
        },
      ),
    );
  }
}
