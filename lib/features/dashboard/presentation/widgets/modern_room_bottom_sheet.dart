import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../rooms/data/models/room_model.dart';

class ModernRoomBottomSheet {
  ModernRoomBottomSheet._();

  static void show({
    required BuildContext context,
    required RoomModel room,
    required ValueChanged<RoomStatus> onStatusChanged,
    required VoidCallback onExpressCheckIn,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Room Header Card
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryLight, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      room.roomNumber,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
                            Flexible(
                              child: Text(
                                room.roomType.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
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
                          '${room.floor} • ${CurrencyFormatter.formatWithPerNight(room.pricePerNight)} • Max ${room.maxOccupancy} Guests',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (room.currentGuestName != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusOccupiedBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.statusOccupiedBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: AppColors.statusOccupied, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Currently Occupied by: ${room.currentGuestName}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusOccupied,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              Text(
                'QUICK STATUS SWITCHER',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              // Status Switcher Pills
              Row(
                children: [
                  _buildStatusChip(
                    context: context,
                    label: 'Available',
                    status: RoomStatus.available,
                    isSelected: room.status == RoomStatus.available,
                    color: AppColors.statusAvailable,
                    bgColor: AppColors.statusAvailableBg,
                    onTap: () {
                      Navigator.of(context).pop();
                      onStatusChanged(RoomStatus.available);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    context: context,
                    label: 'Occupied',
                    status: RoomStatus.occupied,
                    isSelected: room.status == RoomStatus.occupied,
                    color: AppColors.statusOccupied,
                    bgColor: AppColors.statusOccupiedBg,
                    onTap: () {
                      Navigator.of(context).pop();
                      onStatusChanged(RoomStatus.occupied);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    context: context,
                    label: 'Cleaning',
                    status: RoomStatus.cleaning,
                    isSelected: room.status == RoomStatus.cleaning,
                    color: AppColors.statusCleaning,
                    bgColor: AppColors.statusCleaningBg,
                    onTap: () {
                      Navigator.of(context).pop();
                      onStatusChanged(RoomStatus.cleaning);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    context: context,
                    label: 'Repair',
                    status: RoomStatus.maintenance,
                    isSelected: room.status == RoomStatus.maintenance,
                    color: AppColors.statusMaintenance,
                    bgColor: AppColors.statusMaintenanceBg,
                    onTap: () {
                      Navigator.of(context).pop();
                      onStatusChanged(RoomStatus.maintenance);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action CTA Button
              if (room.status == RoomStatus.available)
                CustomButton(
                  text: '⚡ Allocate 4-Step Express Check-In',
                  icon: Icons.add_circle_outline,
                  variant: ButtonVariant.primary,
                  height: 48,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onExpressCheckIn();
                  },
                )
              else if (room.status == RoomStatus.cleaning)
                CustomButton(
                  text: '✓ Mark Linen Clean & Ready for Guests',
                  icon: Icons.check,
                  variant: ButtonVariant.secondary,
                  height: 48,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onStatusChanged(RoomStatus.available);
                  },
                )
              else if (room.status == RoomStatus.maintenance)
                CustomButton(
                  text: '✓ Repairs Completed • Release Room',
                  icon: Icons.build_circle,
                  variant: ButtonVariant.primary,
                  height: 48,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onStatusChanged(RoomStatus.available);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildStatusChip({
    required BuildContext context,
    required String label,
    required RoomStatus status,
    required bool isSelected,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: isSelected ? bgColor : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
