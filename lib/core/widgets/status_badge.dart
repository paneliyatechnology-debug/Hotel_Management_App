import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

enum RoomStatus { available, occupied, cleaning, maintenance }
enum FolioStatus { confirmed, inHouse, departed, cancelled }

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    this.icon,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  factory StatusBadge.fromRoomStatus(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return const StatusBadge(
          label: 'AVAILABLE',
          backgroundColor: AppColors.statusAvailableBg,
          textColor: AppColors.statusAvailable,
          borderColor: AppColors.statusAvailableBorder,
          icon: Icons.check_circle_outline,
        );
      case RoomStatus.occupied:
        return const StatusBadge(
          label: 'OCCUPIED',
          backgroundColor: AppColors.statusOccupiedBg,
          textColor: AppColors.statusOccupied,
          borderColor: AppColors.statusOccupiedBorder,
          icon: Icons.person_outline,
        );
      case RoomStatus.cleaning:
        return const StatusBadge(
          label: 'CLEANING',
          backgroundColor: AppColors.statusCleaningBg,
          textColor: AppColors.statusCleaning,
          borderColor: AppColors.statusCleaningBorder,
          icon: Icons.cleaning_services_outlined,
        );
      case RoomStatus.maintenance:
        return const StatusBadge(
          label: 'MAINTENANCE',
          backgroundColor: AppColors.statusMaintenanceBg,
          textColor: AppColors.statusMaintenance,
          borderColor: AppColors.statusMaintenanceBorder,
          icon: Icons.build_outlined,
        );
    }
  }

  factory StatusBadge.fromFolioStatus(FolioStatus status) {
    switch (status) {
      case FolioStatus.confirmed:
        return const StatusBadge(
          label: 'CONFIRMED',
          backgroundColor: AppColors.statusOccupiedBg,
          textColor: AppColors.statusOccupied,
          borderColor: AppColors.statusOccupiedBorder,
        );
      case FolioStatus.inHouse:
        return const StatusBadge(
          label: 'IN-HOUSE',
          backgroundColor: AppColors.statusAvailableBg,
          textColor: AppColors.statusAvailable,
          borderColor: AppColors.statusAvailableBorder,
        );
      case FolioStatus.departed:
        return const StatusBadge(
          label: 'DEPARTED',
          backgroundColor: AppColors.statusDepartedBg,
          textColor: AppColors.statusDeparted,
          borderColor: AppColors.statusDepartedBorder,
        );
      case FolioStatus.cancelled:
        return const StatusBadge(
          label: 'CANCELLED',
          backgroundColor: AppColors.statusMaintenanceBg,
          textColor: AppColors.statusMaintenance,
          borderColor: AppColors.statusMaintenanceBorder,
        );
    }
  }

  factory StatusBadge.tag({
    required String label,
    required Color color,
    required Color bgColor,
    Color? borderColor,
  }) {
    return StatusBadge(
      label: label,
      backgroundColor: bgColor,
      textColor: color,
      borderColor: borderColor ?? color.withValues(alpha: 0.3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: textColor),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
