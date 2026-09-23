import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/search_filter_bar.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../../rooms/presentation/widgets/room_card.dart';

class RoomMatrixSection extends StatelessWidget {
  final List<RoomModel> rooms;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String selectedFloor;
  final ValueChanged<String?> onFloorChanged;
  final String selectedStatus;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<RoomModel> onRoomSelected;
  final ValueChanged<RoomModel>? onQuickCheckIn;

  const RoomMatrixSection({
    super.key,
    required this.rooms,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedFloor,
    required this.onFloorChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onRoomSelected,
    this.onQuickCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Filter Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              // Title & Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Room Status Matrix',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Click any room to quickly switch housekeeping status or allocate guests.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Filter Bar
              SearchFilterBar(
                searchHint: 'Search room #, guest...',
                onSearchChanged: onSearchChanged,
                selectedFloor: selectedFloor,
                floors: const ['All Floors', 'Floor 1', 'Floor 2'],
                onFloorChanged: onFloorChanged,
                selectedStatus: selectedStatus,
                statuses: const [
                  'All Status (2)',
                  'All Status',
                  'Available',
                  'Occupied',
                  'Cleaning',
                  'Maintenance',
                ],
                onStatusChanged: onStatusChanged,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Room Cards Grid
          if (rooms.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.meeting_room_outlined, size: 40, color: AppColors.textMuted),
                  const SizedBox(height: 10),
                  Text(
                    'No rooms match your filter criteria',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 4;
                double childAspectRatio = 1.6;
                if (constraints.maxWidth < 600) {
                  crossAxisCount = 1;
                  childAspectRatio = 2.0;
                } else if (constraints.maxWidth < 900) {
                  crossAxisCount = 2;
                  childAspectRatio = 1.35;
                } else if (constraints.maxWidth < 1200) {
                  crossAxisCount = 3;
                  childAspectRatio = 1.5;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return RoomCard(
                      room: room,
                      onTap: () => onRoomSelected(room),
                      onQuickCheckIn: () => onQuickCheckIn?.call(room),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
