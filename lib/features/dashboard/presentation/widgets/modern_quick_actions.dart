import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class ModernQuickActions extends StatelessWidget {
  final VoidCallback onExpressCheckIn;
  final VoidCallback onGovtIdHub;
  final VoidCallback onPosInvoice;
  final VoidCallback onKeycardHub;

  const ModernQuickActions({
    super.key,
    required this.onExpressCheckIn,
    required this.onGovtIdHub,
    required this.onPosInvoice,
    required this.onKeycardHub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'QUICK OPERATIONS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                'Instant Actions',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Horizontal Action Slider
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              // 1. Express Check-In Hero Card
              _buildPrimaryActionCard(
                title: '4-Step Check-In',
                subtitle: 'Fast Guest Allocation',
                icon: Icons.person_add_alt_1_rounded,
                badgeText: 'HOT',
                onTap: onExpressCheckIn,
              ),
              const SizedBox(width: 10),

              // 2. Govt ID Scan Card
              _buildSecondaryActionCard(
                title: 'Govt ID Hub',
                subtitle: 'Form-C Compliance',
                icon: Icons.verified_user_rounded,
                color: AppColors.accentCyan,
                bgColor: AppColors.statusOccupiedBg,
                onTap: onGovtIdHub,
              ),
              const SizedBox(width: 10),

              // 3. POS & Invoice Settle Card
              _buildSecondaryActionCard(
                title: 'POS & Invoice',
                subtitle: 'Folio Add-on Billing',
                icon: Icons.receipt_long_rounded,
                color: AppColors.accentGold,
                bgColor: AppColors.accentGoldBg,
                onTap: onPosInvoice,
              ),
              const SizedBox(width: 10),

              // 4. RFID Keycard Dispenser
              _buildSecondaryActionCard(
                title: 'RFID Keycards',
                subtitle: 'NFC Room Access',
                icon: Icons.nfc_rounded,
                color: AppColors.statusGuests,
                bgColor: AppColors.statusGuestsBg,
                onTap: onKeycardHub,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              const BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
