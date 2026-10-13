import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_state.dart';
import '../widgets/guest_folio_details_view.dart';

class InHouseGuestDetailsPage extends StatelessWidget {
  final String folioId;
  final bool isEmbedded;
  final VoidCallback? onClose;
  final int initialTabIndex;

  const InHouseGuestDetailsPage({
    super.key,
    required this.folioId,
    this.isEmbedded = false,
    this.onClose,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final folioList = state.folios.where((f) => f.id == folioId).toList();
        if (folioList.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: isEmbedded
                ? null
                : AppBar(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    title: Text(
                      'Guest Details',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  Text(
                    'Folio Not Found',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The selected folio was not found or has been removed.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        final folio = folioList.first;

        if (isEmbedded) {
          return Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Guest Details',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (onClose != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: onClose,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: GuestFolioDetailsView(
                    folio: folio,
                    isDialog: false,
                    onClose: onClose,
                    initialTabIndex: initialTabIndex,
                  ),
                ),
              ],
            ),
          );
        }

        final isDeparted = folio.status == FolioStatus.departed;
        final isPaid = folio.pendingAmount <= 0;

        final rawRoom = folio.assignedRoom.replaceAll(RegExp(r'^(Room\s*#?|#)'), '').trim();
        final displayRoom = rawRoom.isNotEmpty ? 'Room #$rawRoom' : 'Room #01';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0.5,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            titleSpacing: 0,
            leading: const BackButton(color: AppColors.textPrimary),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guest Details',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  '${folio.guestName} • $displayRoom',
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              // In-House / Departed Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDeparted ? const Color(0xFFE0F2FE) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDeparted ? const Color(0xFFBAE6FD) : const Color(0xFF86EFAC),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDeparted ? const Color(0xFF0369A1) : const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDeparted ? 'DEPARTED' : 'IN-HOUSE',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isDeparted ? const Color(0xFF0369A1) : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Paid / Pending Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPaid ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  folio.paymentStatusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isPaid ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
          body: GuestFolioDetailsView(
            folio: folio,
            isDialog: false,
            initialTabIndex: initialTabIndex,
          ),
        );
      },
    );
  }
}
