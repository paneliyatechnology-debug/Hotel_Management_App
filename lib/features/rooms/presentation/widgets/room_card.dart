import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/room_model.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;
  final VoidCallback? onQuickCheckIn;

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.onQuickCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    Color cardBorderColor;
    switch (room.status) {
      case RoomStatus.available:
        cardBorderColor = AppColors.statusAvailableBorder;
        break;
      case RoomStatus.occupied:
        cardBorderColor = AppColors.statusOccupiedBorder;
        break;
      case RoomStatus.cleaning:
        cardBorderColor = AppColors.statusCleaningBorder;
        break;
      case RoomStatus.maintenance:
        cardBorderColor = AppColors.statusMaintenanceBorder;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorderColor, width: 1.5),
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
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Floor Pill + Price per night
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.statusAvailableBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        room.floor,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusAvailable,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatWithPerNight(room.pricePerNight),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Middle: Room Number & Type
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      room.roomNumber,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      room.roomType,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (room.currentGuestName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Guest: ${room.currentGuestName}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 6),

                // Bottom: Status Badge
                StatusBadge.fromRoomStatus(room.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
