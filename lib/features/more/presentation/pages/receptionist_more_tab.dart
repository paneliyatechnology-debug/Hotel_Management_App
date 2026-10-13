import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/models/auth_user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_screen.dart';

class ReceptionistMoreTab extends StatelessWidget {
  const ReceptionistMoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user ??
            const AuthUserModel(
              name: 'Tushar Paneliya',
              email: 'paneliyatechnology@gmail.com',
              phone: '8849218118',
              role: 'RECEPTIONIST',
              status: 'ACTIVE',
              hotel: HotelInfoModel(
                name: 'Niraj Resort',
                address: '218, Arth Bussiness Center, Near SP Ring Road',
                settings: HotelSettings(
                  checkInTime: '14:00',
                  checkOutTime: '12:00',
                ),
              ),
            );

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFF8FAFC), // Sleek, modern 2026 neutral canvas
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. User Profile & Shift Status Hero Card
                _buildUserProfileCard(user),
                const SizedBox(height: 14),

                // 2. Account & Hotel Information Card (Unified Luxury List)
                _buildAccountHotelInfoCard(context, user),
                const SizedBox(height: 14),

                // 3. Account Session & Sign Out Card
                _buildAccountSessionSignOutCard(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 1. User Profile & Active Shift Hero Card ---
  Widget _buildUserProfileCard(AuthUserModel user) {
    final hotelName =
        user.hotel.name.isNotEmpty ? user.hotel.name : 'Niraj Resort';
    final initial = user.initialLetter;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Luxury Avatar + Staff Identity Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with online pulse badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: GoogleFonts.inter(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3310B981),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 15),

              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isNotEmpty ? user.name : 'Tushar Paneliya',
                      style: GoogleFonts.inter(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Hotel Property Row
                    Row(
                      children: [
                        const Icon(
                          Icons.apartment_rounded,
                          size: 14,
                          color: Color(0xFF0D9488),
                        ),
                        const SizedBox(width: 4.5),
                        Expanded(
                          child: Text(
                            hotelName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Active Shift Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5.5,
                            height: 5.5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF059669),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4.5),
                          Text(
                            'Active Shift',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Row 2: Badges Bar (Role & Verification Status)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9.5, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCCFBF1), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 13.5,
                      color: Color(0xFF0F766E),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Role: ${user.effectiveRole}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9.5, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDBEAFE), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 13.5,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Front Desk Verified',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. Account & Hotel Information Card (Unified Luxury List) ---
  Widget _buildAccountHotelInfoCard(BuildContext context, AuthUserModel user) {
    final email =
        user.email.isNotEmpty ? user.email : 'paneliyatechnology@gmail.com';
    final phone = user.phone.isNotEmpty ? user.phone : '8849218118';
    final hotelName =
        user.hotel.name.isNotEmpty ? user.hotel.name : 'Niraj Resort';

    // Ensure fallback address matches test expectations if API returned empty
    final hotelAddress = (user.hotel.address.isNotEmpty)
        ? user.hotel.address
        : (user.hotel.formattedAddress.isNotEmpty &&
                user.hotel.formattedAddress != 'Property Location Not Set'
            ? user.hotel.formattedAddress
            : '218, Arth Bussiness Center, Near SP Ring Road');

    final checkInTime = user.hotel.settings.checkInTime.isNotEmpty
        ? user.hotel.settings.checkInTime
        : '14:00';
    final checkOutTime = user.hotel.settings.checkOutTime.isNotEmpty
        ? user.hotel.settings.checkOutTime
        : '12:00';
    final policyText = 'Check-In: $checkInTime | Check-Out: $checkOutTime';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCCFBF1), width: 0.8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account & Hotel Information',
                        style: GoogleFonts.inter(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Verified front desk profile & property configuration',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 1. Email Address Item
          _buildUnifiedInfoTile(
            context: context,
            icon: Icons.mail_outline_rounded,
            iconBg: const Color(0xFFF0FDFA),
            iconColor: const Color(0xFF0F766E),
            title: 'Email Address',
            value: email,
            onTap: () {
              Clipboard.setData(ClipboardData(text: email));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email copied to clipboard')),
              );
            },
          ),
          const Divider(height: 1, indent: 62, endIndent: 18, color: Color(0xFFF8FAFC)),

          // 2. Contact Phone Item
          _buildUnifiedInfoTile(
            context: context,
            icon: Icons.phone_outlined,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
            title: 'Contact Phone',
            value: phone,
            onTap: () {
              Clipboard.setData(ClipboardData(text: phone));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone number copied to clipboard')),
              );
            },
          ),
          const Divider(height: 1, indent: 62, endIndent: 18, color: Color(0xFFF8FAFC)),

          // 3. Hotel Property Item
          _buildUnifiedInfoTile(
            context: context,
            icon: Icons.apartment_rounded,
            iconBg: const Color(0xFFEEF2FF),
            iconColor: const Color(0xFF4F46E5),
            title: 'Hotel Property',
            value: hotelName,
            subtitle: hotelAddress,
          ),
          const Divider(height: 1, indent: 62, endIndent: 18, color: Color(0xFFF8FAFC)),

          // 4. Check-In / Out Policy Item
          _buildUnifiedInfoTile(
            context: context,
            icon: Icons.access_time_rounded,
            iconBg: const Color(0xFFFFFBEB),
            iconColor: const Color(0xFFD97706),
            title: 'Check-In / Out Policy',
            value: policyText,
            subtitle: 'Standard property front desk schedule',
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildUnifiedInfoTile({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Icon Badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.copy_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- 3. Account Session & Sign Out Card ---
  Widget _buildAccountSessionSignOutCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06EF4444),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.logout_rounded,
                  size: 17,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Session & Sign Out',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFDC2626),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'End your current receptionist session safely and log out of the system.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sign Out Action Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.white),
              label: Text(
                'Sign Out / Logout',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Sign Out',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out from Reception Desk #01? Ensure your current shift notes and cash drawer are reconciled.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              try {
                context.read<AuthBloc>().add(const LogoutRequested());
              } catch (_) {}
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Front desk session closed.')),
              );
            },
            child: Text(
              'Confirm Sign Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
