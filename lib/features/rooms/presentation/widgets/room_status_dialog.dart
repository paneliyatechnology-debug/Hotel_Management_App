import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/room_model.dart';

class RoomStatusDialog {
  RoomStatusDialog._();

  static void show({
    required BuildContext context,
    required RoomModel room,
    required ValueChanged<RoomStatus> onStatusChanged,
    required VoidCallback onCheckIn,
  }) {
    AppDialog.show(
      context: context,
      title: 'Room Details & Operations',
      subtitle: 'Manage housekeeping, repairs, or allocate new check-in.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Information Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    room.roomNumber,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            room.roomType.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge.fromRoomStatus(room.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${room.floor} • Rate: ${CurrencyFormatter.formatWithPerNight(room.pricePerNight)} • Max ${room.maxOccupancy} Guests',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (room.currentGuestName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Occupied by: ${room.currentGuestName}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'CHANGE ROOM STATUS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // Status Change Options Grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStatusOption(
                context: context,
                label: 'Available / Vacant',
                status: RoomStatus.available,
                isSelected: room.status == RoomStatus.available,
                color: AppColors.statusAvailable,
                bgColor: AppColors.statusAvailableBg,
                icon: Icons.check_circle_outline,
                onTap: () {
                  Navigator.of(context).pop();
                  onStatusChanged(RoomStatus.available);
                },
              ),
              _buildStatusOption(
                context: context,
                label: 'Occupied In-House',
                status: RoomStatus.occupied,
                isSelected: room.status == RoomStatus.occupied,
                color: AppColors.statusOccupied,
                bgColor: AppColors.statusOccupiedBg,
                icon: Icons.person_outline,
                onTap: () {
                  Navigator.of(context).pop();
                  onStatusChanged(RoomStatus.occupied);
                },
              ),
              _buildStatusOption(
                context: context,
                label: 'Housekeeping Cleaning',
                status: RoomStatus.cleaning,
                isSelected: room.status == RoomStatus.cleaning,
                color: AppColors.statusCleaning,
                bgColor: AppColors.statusCleaningBg,
                icon: Icons.cleaning_services_outlined,
                onTap: () {
                  Navigator.of(context).pop();
                  onStatusChanged(RoomStatus.cleaning);
                },
              ),
              _buildStatusOption(
                context: context,
                label: 'Maintenance / Blocked',
                status: RoomStatus.maintenance,
                isSelected: room.status == RoomStatus.maintenance,
                color: AppColors.statusMaintenance,
                bgColor: AppColors.statusMaintenanceBg,
                icon: Icons.build_outlined,
                onTap: () {
                  Navigator.of(context).pop();
                  onStatusChanged(RoomStatus.maintenance);
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (room.status == RoomStatus.available) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentGreenLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentGreenBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.accentGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This room is clean and ready. You can initiate a 5-step express check-in right away.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        CustomButton(
          text: 'Close',
          variant: ButtonVariant.outlined,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 10),
        if (room.status == RoomStatus.available)
          CustomButton(
            text: 'Allocate / Check-In',
            icon: Icons.add,
            variant: ButtonVariant.secondary,
            onPressed: () {
              Navigator.of(context).pop();
              onCheckIn();
            },
          ),
      ],
    );
  }

  static Widget _buildStatusOption({
    required BuildContext context,
    required String label,
    required RoomStatus status,
    required bool isSelected,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? bgColor : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
