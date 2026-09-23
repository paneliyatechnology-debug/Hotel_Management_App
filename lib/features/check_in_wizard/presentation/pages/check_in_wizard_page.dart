import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_event.dart';
import '../../data/models/check_in_form_data.dart';
import '../bloc/check_in_bloc.dart';
import '../bloc/check_in_event.dart';
import '../bloc/check_in_state.dart';
import '../steps/step_1_guest_identity.dart';
import '../steps/step_2_stay_room.dart';
import '../steps/step_5_keycard_summary.dart';

class CheckInWizardPage extends StatefulWidget {
  final bool hasScaffold;
  const CheckInWizardPage({super.key, this.hasScaffold = true});

  @override
  State<CheckInWizardPage> createState() => _CheckInWizardPageState();
}

class _CheckInWizardPageState extends State<CheckInWizardPage> {
  final List<Map<String, dynamic>> _stepItems = [
    {'title': 'Guest Identity', 'short': 'Guest & ID', 'icon': Icons.person_pin_rounded},
    {'title': 'Stay & Room', 'short': 'Stay & Room', 'icon': Icons.king_bed_rounded},
    {'title': 'Keycard & Confirm', 'short': 'Keycard', 'icon': Icons.vpn_key_rounded},
  ];

  bool _validateCurrentStep(BuildContext context, CheckInState state) {
    bool isValid = true;
    switch (state.currentStep) {
      case 0:
        if (state.formData.guestFullName.trim().isEmpty ||
            state.formData.idNumber.trim().isEmpty ||
            state.formData.contactPhone.trim().isEmpty ||
            !state.formData.isIdVerified) {
          isValid = false;
        }
        for (final guest in state.formData.accompanyingGuests) {
          if (guest.name.trim().isEmpty || guest.idNumber.trim().isEmpty || !guest.isIdVerified) {
            isValid = false;
            break;
          }
        }
        break;

      case 1:
        if (state.formData.selectedRoomNumber.isEmpty ||
            state.formData.checkOutDate.isBefore(state.formData.checkInDate) ||
            state.formData.checkOutDate.isAtSameMomentAs(state.formData.checkInDate)) {
          isValid = false;
        }
        break;

      case 2:
        if (state.formData.assignedKeycardNumber.isEmpty ||
            !state.formData.agreeTermsAndSignature) {
          isValid = false;
        }
        break;

      default:
        isValid = true;
    }

    if (!isValid) {
      context.read<CheckInBloc>().add(SetValidationErrorsEvent(true));
      return false;
    }

    context.read<CheckInBloc>().add(SetValidationErrorsEvent(false));
    return true;
  }

  void _autoFillDemoData(BuildContext context, CheckInState state) {
    final updated = state.formData.copy();
    updated.guestFullName = 'Niraj Vekariya';
    updated.idType = 'Aadhaar Card';
    updated.idNumber = '5421-9876-1234';
    updated.nationality = 'Indian';
    updated.isIdVerified = true;
    updated.idFrontPhotoUrl = 'scanned_aadhaar.png';
    updated.idBackPhotoUrl = 'scanned_aadhaar_back.png';

    // Auto-fill attached companion for Couple / Family
    if (updated.partyType == 'Family / Group' || updated.roomType.toLowerCase().contains('family')) {
      updated.partyType = 'Family / Group';
      updated.accompanyingGuests = [
        AccompanyingGuest(
          name: 'Pooja Vekariya',
          relationship: 'Spouse',
          age: '28',
          idType: 'Aadhaar Card',
          idNumber: '5421-9876-5678',
          isIdVerified: true,
          idPhotoUrl: 'scanned_aadhaar.png',
          idBackPhotoUrl: 'scanned_aadhaar_back.png',
        ),
        AccompanyingGuest(
          name: 'Aarav Vekariya',
          relationship: 'Child',
          age: '6',
          idType: 'Aadhaar Card',
          idNumber: '5421-9876-9012',
          isIdVerified: true,
          idPhotoUrl: 'scanned_aadhaar.png',
          idBackPhotoUrl: 'scanned_aadhaar_back.png',
        ),
      ];
      updated.numberOfGuests = 3;
    } else if (updated.partyType == 'Couple (2 Guests)' || updated.roomType.toLowerCase().contains('couple')) {
      updated.partyType = 'Couple (2 Guests)';
      updated.accompanyingGuests = [
        AccompanyingGuest(
          name: 'Pooja Vekariya',
          relationship: 'Spouse',
          age: '28',
          idType: 'Aadhaar Card',
          idNumber: '5421-9876-5678',
          isIdVerified: true,
          idPhotoUrl: 'scanned_aadhaar.png',
          idBackPhotoUrl: 'scanned_aadhaar_back.png',
        ),
      ];
      updated.numberOfGuests = 2;
    } else {
      // Solo guest
      updated.accompanyingGuests = [];
      updated.numberOfGuests = 1;
    }

    updated.contactPhone = '+91 98765 43210';
    updated.email = 'niraj.v@example.com';
    updated.residentialAddress = '702, Skyline Residency, Ring Road';
    updated.city = 'Surat';
    updated.state = 'Gujarat';
    updated.pincode = '395007';
    updated.gstNumber = '24AAACV1234F1Z5';
    updated.paymentMode = 'UPI';
    updated.advancePaid = updated.grandTotal;
    updated.assignedKeycardNumber = 'KC-101';
    updated.agreeTermsAndSignature = true;

    context.read<CheckInBloc>().add(UpdateFormDataEvent(updated));

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Demo primary & attached guest identities auto-filled!',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 650;

    return BlocConsumer<CheckInBloc, CheckInState>(
      listener: (context, state) {
        if (state.status == CheckInStatus.success) {
          context.read<DashboardBloc>().add(RefreshDashboardDataEvent());

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.accentGreenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-In Complete!',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        Text(
                          'Folio #${state.completedFolio?.id ?? "FOL-7001"}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hotel_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Room ${state.formData.selectedRoomNumber} • ${state.formData.selectedFloor}',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryDark),
                              ),
                              Text(
                                'Guest: ${state.formData.guestFullName} (Keycard: ${state.formData.assignedKeycardNumber})',
                                style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Room status updated to Occupied In-House. RFID keycard active.',
                    style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
              actions: [
                CustomButton(
                  text: 'Done',
                  variant: ButtonVariant.primary,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.read<CheckInBloc>().add(InitCheckInWizardEvent());
                  },
                ),
              ],
            ),
          );
        } else if (state.status == CheckInStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Check-in failed'),
              backgroundColor: AppColors.statusMaintenance,
            ),
          );
        }
      },
      builder: (context, state) {
        final content = SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 14 : 24,
            vertical: isCompact ? 12 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2026 Executive Connected Stepper (Zero Horizontal Scroll, Clean Luxury Design)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Stepper Top Bar: Step Indicator & Quick Fill Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'STEP ${state.currentStep + 1} OF ${_stepItems.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _stepItems[state.currentStep]['title'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Quick Fill Action Pill
                        InkWell(
                          onTap: () => _autoFillDemoData(context, state),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.flash_on_rounded, size: 13, color: Color(0xFFD97706)),
                                const SizedBox(width: 4),
                                Text(
                                  'Quick Fill',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 4-Step Interactive Connected Timeline
                    Row(
                      children: List.generate(_stepItems.length, (index) {
                        final isCurrent = index == state.currentStep;
                        final isCompleted = index < state.currentStep;
                        final isFuture = index > state.currentStep;

                        return Expanded(
                          child: InkWell(
                            onTap: isFuture
                                ? null
                                : () {
                                    context.read<CheckInBloc>().add(GoToStepEvent(index));
                                  },
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    // Left connector
                                    Expanded(
                                      child: Container(
                                        height: 2.5,
                                        color: index == 0
                                            ? Colors.transparent
                                            : (isCompleted || isCurrent
                                                ? AppColors.primary
                                                : const Color(0xFFE2E8F0)),
                                      ),
                                    ),

                                    // Circle Node
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: isCurrent
                                            ? const LinearGradient(
                                                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        color: isCurrent
                                            ? null
                                            : isCompleted
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFF1F5F9),
                                        border: Border.all(
                                          color: isCurrent
                                              ? const Color(0xFF0F766E)
                                              : isCompleted
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFFCBD5E1),
                                          width: isCurrent ? 2 : 1,
                                        ),
                                        boxShadow: isCurrent
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: isCompleted
                                          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                                          : Text(
                                              '${index + 1}',
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                color: isCurrent ? Colors.white : const Color(0xFF94A3B8),
                                              ),
                                            ),
                                    ),

                                    // Right connector
                                    Expanded(
                                      child: Container(
                                        height: 2.5,
                                        color: index == _stepItems.length - 1
                                            ? Colors.transparent
                                            : (isCompleted
                                                ? AppColors.primary
                                                : const Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _stepItems[index]['short'] as String,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                    color: isCurrent
                                        ? AppColors.primaryDark
                                        : isCompleted
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),



              // Main Form Container
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isCompact ? 16 : 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildCurrentStepWidget(context, state),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );

        if (widget.hasScaffold) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildWizardAppBar(context, state),
            body: content,
            bottomNavigationBar: _buildStickyBottomActionBar(context, state, isCompact),
          );
        }
        return Column(
          children: [
            Expanded(child: content),
            _buildStickyBottomActionBar(context, state, isCompact),
          ],
        );
      },
    );
  }

  Widget _buildStickyBottomActionBar(BuildContext context, CheckInState state, bool isCompact) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 14 : 24,
        12,
        isCompact ? 14 : 24,
        bottomPadding > 0 ? bottomPadding + 6 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (state.currentStep > 0) ...[
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<CheckInBloc>().add(PreviousStepEvent());
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_rounded, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          'Previous',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: state.currentStep < _stepItems.length - 1
                  ? ElevatedButton(
                      onPressed: () {
                        if (_validateCurrentStep(context, state)) {
                          context.read<CheckInBloc>().add(NextStepEvent());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Continue to Step ${state.currentStep + 2}',
                              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: state.status == CheckInStatus.submitting
                          ? null
                          : () {
                              if (_validateCurrentStep(context, state)) {
                                context.read<CheckInBloc>().add(SubmitCheckInEvent());
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state.status == CheckInStatus.submitting)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            else
                              const Icon(Icons.check_circle_rounded, size: 17),
                            const SizedBox(width: 6),
                            Text(
                              'Complete Express Check-In',
                              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildWizardAppBar(BuildContext context, CheckInState state) {
    final hasRoom = state.formData.selectedRoomNumber.isNotEmpty;
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      elevation: 0.5,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      titleSpacing: canPop ? 0 : 16,
      title: hasRoom
          ? Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    state.formData.selectedRoomNumber,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'ROOM ${state.formData.selectedRoomNumber} • ${(state.formData.selectedFloor.isNotEmpty ? state.formData.selectedFloor : "Floor 1").toUpperCase()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF14532D),
                              ),
                            ),
                          ),
                          if (state.formData.isRoomPreLocked) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_rounded, size: 8.5, color: Color(0xFF15803D)),
                                  const SizedBox(width: 2.5),
                                  Text(
                                    'LOCKED',
                                    style: GoogleFonts.inter(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${(state.formData.roomType.isNotEmpty ? state.formData.roomType : "Room").toUpperCase()} • ${CurrencyFormatter.formatWithPerNight(state.formData.pricePerNight)} • ${DateFormatter.formatShort(state.formData.checkInDate)} to ${DateFormatter.formatShort(state.formData.checkOutDate)} (${state.formData.totalNights}N)',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF166534),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Text(
              'Guest Check-In Form',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
      actions: [
        if (hasRoom)
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF16A34A)),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentStepWidget(BuildContext context, CheckInState state) {
    switch (state.currentStep) {
      case 0:
        return Step1GuestIdentity(
          formData: state.formData,
          showValidationErrors: state.showValidationErrors,
          onDataChanged: (data) => context.read<CheckInBloc>().add(UpdateFormDataEvent(data)),
        );
      case 1:
        return Step2StayRoom(
          formData: state.formData,
          availableRooms: state.availableRooms,
          onDataChanged: (data) => context.read<CheckInBloc>().add(UpdateFormDataEvent(data)),
        );
      case 2:
        return Step5KeycardSummary(
          formData: state.formData,
          onDataChanged: (data) => context.read<CheckInBloc>().add(UpdateFormDataEvent(data)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
