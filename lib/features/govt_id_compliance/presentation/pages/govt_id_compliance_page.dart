import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_state.dart';

class GovtIdCompliancePage extends StatelessWidget {
  const GovtIdCompliancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Govt ID & Regulatory Compliance Hub',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Form-C hotel guest registry, local police verification records, and biometric/ID compliance.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  CustomButton(
                    text: 'Export Form-C Daily Report',
                    icon: Icons.download,
                    variant: ButtonVariant.primary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Form-C Daily Compliance Report exported.')),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Compliance Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.statusAvailableBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.statusAvailableBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.statusAvailable, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '100% Guest ID Verification Status: All In-House Guests Compliant',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusAvailable,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Every registered guest record has verified Photo Identification and valid residential credentials.',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Compliance Table
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.folios.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final folio = state.folios[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.verified, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        folio.guestName,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${folio.idType}: ${folio.idNumber} • Checked in on ${DateFormatter.formatDate(folio.checkInDate)}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: StatusBadge.tag(
                        label: 'VERIFIED',
                        color: AppColors.statusAvailable,
                        bgColor: AppColors.statusAvailableBg,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
