import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../pages/admin_rooms_tariffs_page.dart';
import '../pages/admin_settings_page.dart';
import '../pages/admin_staff_management_page.dart';
import '../pages/admin_subscription_page.dart';
import '../pages/hotel_admin_dashboard_view.dart';
import '../pages/status_rooms_page.dart';

class HotelAdminDrawer extends StatelessWidget {
  final String staffName;
  final String email;
  final String resortName;
  final int selectedNavIndex;
  final ValueChanged<int> onNavItemSelected;

  const HotelAdminDrawer({
    super.key,
    this.staffName = 'Niraj Vekariya',
    this.email = 'nirajvekariya2209@gmail.com',
    this.resortName = 'Niraj Resort',
    this.selectedNavIndex = 0,
    required this.onNavItemSelected,
  });

  Future<void> _handleSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 8),
            Text(
              'Sign Out Session',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of the MYOWNPMS Hotel Admin session?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && context.mounted) {
      StaffDirectoryMemory.clear();
      RoomsDirectoryMemory.clear();
      AdminDashboardMemory.clear();
      SubscriptionPlansMemory.clear();
      HotelSettingsMemory.clear();
      StatusRoomsMemory.clear();
      await AuthRepository().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Sidebar Header: MYOWNPMS Hotel Admin PMS
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        'assets/images/myownpms_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFF042F2E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.bed_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'MYOWNPMS',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Text(
                                'MYOWNPMS',
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF047857),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Hotel Admin PMS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // 2. Main Navigation Label
            Padding(
              padding: const EdgeInsets.only(left: 18, right: 18, top: 16, bottom: 8),
              child: Text(
                'MAIN NAVIGATION',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),

            // 3. Navigation List Items matching Website Admin Screenshot
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: selectedNavIndex == 0,
                    context: context,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.payments_rounded,
                    label: 'Daily Collections',
                    isActive: selectedNavIndex == 1,
                    context: context,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.people_alt_rounded,
                    label: 'Guest Directory',
                    isActive: selectedNavIndex == 2,
                    context: context,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.badge_rounded,
                    label: 'Staff Management',
                    isActive: selectedNavIndex == 3,
                    context: context,
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.king_bed_rounded,
                    label: 'Rooms & Tariffs',
                    isActive: selectedNavIndex == 4,
                    context: context,
                  ),
                  _buildNavItem(
                    index: 5,
                    icon: Icons.card_membership_rounded,
                    label: 'Subscription Plan',
                    isActive: selectedNavIndex == 5,
                    context: context,
                  ),
                  _buildNavItem(
                    index: 6,
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    isActive: selectedNavIndex == 6,
                    context: context,
                  ),
                ],
              ),
            ),

            // 4. Bottom Profile & Sign Out Box matching Screenshot
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          staffName.isNotEmpty ? staffName[0].toUpperCase() : 'N',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staffName,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              email,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: const Color(0xFF64748B),
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
                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _handleSignOut(context),
                      icon: const Icon(Icons.logout_rounded, size: 14),
                      label: Text(
                        'Sign Out',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive ? const Color(0xFFD1FAE5).withOpacity(0.7) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(
          icon,
          size: 20,
          color: isActive ? const Color(0xFF065F46) : const Color(0xFF64748B),
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF065F46) : const Color(0xFF334155),
          ),
        ),
        trailing: isActive
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          Navigator.of(context).pop(); // Close drawer
          onNavItemSelected(index);
        },
      ),
    ),
  );
}
}
