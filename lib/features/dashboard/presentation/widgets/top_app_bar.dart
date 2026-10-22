import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String resortName;
  final VoidCallback? onOpenDrawer;
  final bool showMenuButton;

  const TopAppBar({
    super.key,
    this.resortName = '',
    this.onOpenDrawer,
    this.showMenuButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 650;

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            IconButton(
              onPressed: onOpenDrawer,
              icon: const Icon(Icons.menu, color: AppColors.textPrimary, size: 22),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 6),
          ],
          // Resort Name / Switcher
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    resortName.isNotEmpty ? resortName : 'MYOWNPMS',
                    style: GoogleFonts.inter(
                      fontSize: isCompact ? 14 : 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 18),
              ],
            ),
          ),

          const Spacer(),

          // Right Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // FRONT DESK Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'FRONT DESK',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),

              if (!isCompact) ...[
                const SizedBox(width: 10),
                // Network Status Icon
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.statusAvailableBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.public,
                    size: 15,
                    color: AppColors.statusAvailable,
                  ),
                ),
                const SizedBox(width: 8),

                // Notification Bell with badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.notifications_none_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                        child: Text(
                          '0',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),

                // Settings Gear
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],

              const SizedBox(width: 8),

              // User Avatar Circle
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'J',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
