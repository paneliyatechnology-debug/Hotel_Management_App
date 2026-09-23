import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../rooms/data/models/room_model.dart';

class ModernRoomCardMobile extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;

  const ModernRoomCardMobile({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    Color bgColor;

    switch (room.status) {
      case RoomStatus.available:
        accentColor = AppColors.statusAvailable;
        bgColor = AppColors.statusAvailableBg;
        break;
      case RoomStatus.occupied:
        accentColor = AppColors.statusOccupied;
        bgColor = AppColors.statusOccupiedBg;
        break;
      case RoomStatus.cleaning:
        accentColor = AppColors.statusCleaning;
        bgColor = AppColors.statusCleaningBg;
        break;
      case RoomStatus.maintenance:
        accentColor = AppColors.statusMaintenance;
        bgColor = AppColors.statusMaintenanceBg;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Room Number Box with Accent Badge
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        room.roomNumber,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Room Type & Status Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  room.roomType.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
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
                            '${room.floor} • Max ${room.maxOccupancy} Guests',
                            style: GoogleFonts.inter(
                              fontSize: 11,
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

                const SizedBox(height: 10),
                Container(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 8),

                // Bottom Row: Guest info / Vacant status + Nightly Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: room.currentGuestName != null
                          ? Row(
                              children: [
                                const Icon(Icons.person_rounded, size: 14, color: AppColors.statusOccupied),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    room.currentGuestName!,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.statusOccupied,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.statusAvailable,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Vacant • Ready',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.statusAvailable,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.formatWithPerNight(room.pricePerNight),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
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
