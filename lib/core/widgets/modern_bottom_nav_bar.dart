import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAdmin;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: isAdmin
                ? [
                    Expanded(
                      child: _buildNavItem(
                        index: 0,
                        icon: Icons.dashboard_rounded,
                        outlinedIcon: Icons.dashboard_outlined,
                        label: 'Dashboard',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: 1,
                        icon: Icons.king_bed_rounded,
                        outlinedIcon: Icons.king_bed_outlined,
                        label: 'Rooms',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: 2,
                        icon: Icons.people_alt_rounded,
                        outlinedIcon: Icons.people_alt_outlined,
                        label: 'Guests',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: 3,
                        icon: Icons.badge_rounded,
                        outlinedIcon: Icons.badge_outlined,
                        label: 'Staff',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: 4,
                        icon: Icons.apps_rounded,
                        outlinedIcon: Icons.apps_outlined,
                        label: 'More',
                      ),
                    ),
                  ]
                : [
                    Expanded(
                      child: _buildNavItem(
                        index: 0,
                        icon: Icons.dashboard_rounded,
                        outlinedIcon: Icons.dashboard_outlined,
                        label: 'Front Desk',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: 1,
                        icon: Icons.meeting_room_rounded,
                        outlinedIcon: Icons.meeting_room_outlined,
                        label: 'Rooms',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: 2,
                        icon: Icons.people_alt_rounded,
                        outlinedIcon: Icons.people_alt_outlined,
                        label: 'In-House',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: 3,
                        icon: Icons.badge_rounded,
                        outlinedIcon: Icons.badge_outlined,
                        label: 'Guests',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: 4,
                        icon: Icons.apps_rounded,
                        outlinedIcon: Icons.apps_outlined,
                        label: 'More',
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData outlinedIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primarySurface : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelected ? icon : outlinedIcon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
