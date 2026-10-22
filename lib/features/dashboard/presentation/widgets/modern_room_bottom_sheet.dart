import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../rooms/data/models/room_model.dart';

Future<bool> showMarkRoomAvailableDialog(
  BuildContext context, {
  required String roomNumber,
}) {
  final label = roomNumber.trim().isEmpty ? 'this room' : 'Room ${roomNumber.replaceAll('#', '')}';
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mark room available?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$label is in cleaning. Confirm to make it available for the next guest.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 18),
              _appColorButton(
                label: 'Available',
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
              const SizedBox(height: 8),
              _appColorButton(
                label: 'Cancel',
                filled: false,
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
            ],
          ),
        ),
      );
    },
  ).then((value) => value == true);
}

Widget _appColorButton({
  required String label,
  required VoidCallback onPressed,
  bool filled = true,
}) {
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  final text = Text(
    label,
    style: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: filled ? Colors.white : AppColors.primary,
    ),
  );
  if (!filled) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.primary, width: 1.4),
        shape: shape,
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
      onPressed: onPressed,
      child: text,
    );
  }
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: AppColors.primary,
      elevation: 0,
      shape: shape,
      padding: const EdgeInsets.symmetric(vertical: 13),
    ),
    onPressed: onPressed,
    child: text,
  );
}

class ModernRoomBottomSheet {
  ModernRoomBottomSheet._();

  static void show({
    required BuildContext context,
    required RoomModel room,
    required ValueChanged<RoomStatus> onStatusChanged,
    required VoidCallback onExpressCheckIn,
    VoidCallback? onCheckout,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        var selectedStatus = room.status;
        return StatefulBuilder(
          builder: (context, setSheetState) {
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

                  if (room.status == RoomStatus.occupied) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(bottomSheetContext).pop();
                          onCheckout?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFDC2626), width: 1.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
                        label: Text(
                          'Checkout',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                  ] else if (room.status == RoomStatus.cleaning) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showMarkRoomAvailableDialog(
                            bottomSheetContext,
                            roomNumber: room.roomNumber,
                          );
                          if (!confirmed || !bottomSheetContext.mounted) return;
                          Navigator.of(bottomSheetContext).pop();
                          onStatusChanged(RoomStatus.available);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.primary, width: 1.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
                        label: Text(
                          'Available',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
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
                        isSelected: selectedStatus == RoomStatus.available,
                        activeColor: const Color(0xFF0F766E),
                        onTap: () => setSheetState(() => selectedStatus = RoomStatus.available),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        context: bottomSheetContext,
                        label: 'Occupied',
                        icon: Icons.person_rounded,
                        status: RoomStatus.occupied,
                        isSelected: selectedStatus == RoomStatus.occupied,
                        activeColor: const Color(0xFF0F766E),
                        onTap: () => setSheetState(() => selectedStatus = RoomStatus.occupied),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        context: bottomSheetContext,
                        label: 'Cleaning',
                        icon: Icons.cleaning_services_rounded,
                        status: RoomStatus.cleaning,
                        isSelected: selectedStatus == RoomStatus.cleaning,
                        activeColor: const Color(0xFFD97706),
                        onTap: () => setSheetState(() => selectedStatus = RoomStatus.cleaning),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                        context: bottomSheetContext,
                        label: 'Repair',
                        icon: Icons.build_rounded,
                        status: RoomStatus.maintenance,
                        isSelected: selectedStatus == RoomStatus.maintenance,
                        activeColor: const Color(0xFFDC2626),
                        onTap: () => setSheetState(() => selectedStatus = RoomStatus.maintenance),
                      ),
                    ],
                  ),

                  if (selectedStatus != room.status) ...[
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Update Status',
                      icon: Icons.check_rounded,
                      variant: ButtonVariant.primary,
                      height: 48,
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        onStatusChanged(selectedStatus);
                      },
                    ),
                  ] else if (room.status == RoomStatus.available) ...[
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
                ],
              ),
            ),
          ),
        );
          },
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
