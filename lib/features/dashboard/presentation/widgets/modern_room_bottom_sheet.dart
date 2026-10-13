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
      builder: (bottomSheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // Room Header Card
                  Row(
                    children: [
                      // Left Squircle: Bed Icon + Room Number
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F7F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.hotel_rounded,
                              size: 20,
                              color: Color(0xFF0F766E),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              room.roomNumber,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F766E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                StatusBadge.fromRoomStatus(room.status),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${room.floor} • ${CurrencyFormatter.formatWithPerNight(room.pricePerNight)} • Max ${room.maxOccupancy} Guests',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
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

                  // Occupied Guest Card
                  if (room.currentGuestName != null && room.currentGuestName!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCCFBF1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF0F766E), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Currently Occupied by: ${room.currentGuestName}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Section Title: Quick Status Switcher
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
                        context: bottomSheetContext,
                        label: 'Available',
                        icon: Icons.hotel_rounded,
                        status: RoomStatus.available,
                        isSelected: room.status == RoomStatus.available,
                        activeColor: const Color(0xFF0F766E),
                        onTap: () {
                          Navigator.of(bottomSheetContext).pop();
                          onStatusChanged(RoomStatus.available);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        context: bottomSheetContext,
                        label: 'Occupied',
                        icon: Icons.person_rounded,
                        status: RoomStatus.occupied,
                        isSelected: room.status == RoomStatus.occupied,
                        activeColor: const Color(0xFF0F766E),
                        onTap: () {
                          Navigator.of(bottomSheetContext).pop();
                          onStatusChanged(RoomStatus.occupied);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        context: bottomSheetContext,
                        label: 'Cleaning',
                        icon: Icons.cleaning_services_rounded,
                        status: RoomStatus.cleaning,
                        isSelected: room.status == RoomStatus.cleaning,
                        activeColor: const Color(0xFFD97706),
                        onTap: () {
                          Navigator.of(bottomSheetContext).pop();
                          onStatusChanged(RoomStatus.cleaning);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        context: bottomSheetContext,
                        label: 'Repair',
                        icon: Icons.build_rounded,
                        status: RoomStatus.maintenance,
                        isSelected: room.status == RoomStatus.maintenance,
                        activeColor: const Color(0xFFDC2626),
                        onTap: () {
                          Navigator.of(bottomSheetContext).pop();
                          onStatusChanged(RoomStatus.maintenance);
                        },
                      ),
                    ],
                  ),

                  // Action Buttons for other statuses (if applicable)
                  if (room.status == RoomStatus.available) ...[
                    const SizedBox(height: 20),
                    CustomButton(
                      text: '⚡ Allocate 4-Step Express Check-In',
                      icon: Icons.add_circle_outline,
                      variant: ButtonVariant.primary,
                      height: 48,
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        onExpressCheckIn();
                      },
                    ),
                  ] else if (room.status == RoomStatus.cleaning) ...[
                    const SizedBox(height: 20),
                    CustomButton(
                      text: '✓ Mark Linen Clean & Ready for Guests',
                      icon: Icons.check,
                      variant: ButtonVariant.secondary,
                      height: 48,
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        onStatusChanged(RoomStatus.available);
                      },
                    ),
                  ] else if (room.status == RoomStatus.maintenance) ...[
                    const SizedBox(height: 20),
                    CustomButton(
                      text: '✓ Repairs Completed • Release Room',
                      icon: Icons.build_circle,
                      variant: ButtonVariant.primary,
                      height: 48,
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        onStatusChanged(RoomStatus.available);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Status Chip with icon and label
  static Widget _buildStatusChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required RoomStatus status,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final bgColor = isSelected ? activeColor : Colors.white;
    final fgColor = isSelected ? Colors.white : const Color(0xFF475569);
    final borderColor = isSelected ? activeColor : const Color(0xFFE2E8F0);

    return Expanded(
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.0),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: fgColor,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: fgColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
