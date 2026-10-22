import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_event.dart';
import '../../data/models/check_in_form_data.dart';
import '../bloc/check_in_bloc.dart';
import '../bloc/check_in_event.dart';
import '../bloc/check_in_state.dart';
import '../steps/step_1_guest_identity.dart';
import '../steps/step_2_stay_room.dart';
import '../steps/step_3_billing_settlement.dart';
import '../steps/step_5_keycard_summary.dart';
import '../../../rooms/presentation/pages/category_rooms_page.dart';
import '../../../dashboard/data/models/guest_folio_model.dart';
import '../../../../core/widgets/status_badge.dart';
import '../widgets/check_in_success_dialog.dart';

class CheckInWizardPage extends StatefulWidget {
  final bool hasScaffold;
  const CheckInWizardPage({super.key, this.hasScaffold = true});

  @override
  State<CheckInWizardPage> createState() => _CheckInWizardPageState();
}

class _CheckInWizardPageState extends State<CheckInWizardPage> {
  bool _checkInInFlight = false;
  final List<Map<String, dynamic>> _stepItems = [
    {'title': 'Guest', 'short': 'Guest', 'icon': Icons.person_pin_rounded},
    {'title': 'Stay', 'short': 'Stay', 'icon': Icons.hotel_rounded},
    {'title': 'Billing', 'short': 'Billing', 'icon': Icons.credit_card_rounded},
    {'title': 'Review', 'short': 'Review', 'icon': Icons.verified_user_rounded},
  ];

  bool _validateCurrentStep(BuildContext context, CheckInState state) {
    bool isValid = true;
    switch (state.currentStep) {
      case 0:
        final phoneDigits = _guestMobileDigits(state.formData.contactPhone);
        final proofCount = _guestProofCount(state.formData);
        if (state.formData.guestFullName.trim().isEmpty ||
            phoneDigits.isEmpty ||
            !RegExp(r'^[6-9]\d{9}$').hasMatch(phoneDigits) ||
            proofCount < 1 ||
            !state.formData.isSignatureCaptured) {
          isValid = false;
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
        if (state.formData.pricePerNight < 0 || state.formData.advancePaid < 0) {
          isValid = false;
        }
        break;

      case 3:
        if (!state.formData.agreeTermsAndSignature) {
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

  String _guestMobileDigits(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(digits.length - 10);
    }
    return digits;
  }

  int _guestProofCount(CheckInFormData formData) {
    final proofs = <String>{
      for (final path in formData.idPhotos)
        if (path.trim().isNotEmpty) path.trim(),
      if ((formData.idFrontPhotoUrl ?? '').trim().isNotEmpty) formData.idFrontPhotoUrl!.trim(),
      if ((formData.idBackPhotoUrl ?? '').trim().isNotEmpty) formData.idBackPhotoUrl!.trim(),
    };
    return proofs.length;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 650;

    return BlocConsumer<CheckInBloc, CheckInState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == CheckInStatus.error && _checkInInFlight) {
          setState(() => _checkInInFlight = false);
        }
        if (state.status == CheckInStatus.success) {
          // 1. Refresh dashboard data so room status is updated to occupied
          context.read<DashboardBloc>().add(RefreshDashboardDataEvent());

          final category = state.formData.roomType.trim().isNotEmpty
              ? state.formData.roomType.trim()
              : (state.completedFolio?.roomType.trim().isNotEmpty == true
                  ? state.completedFolio!.roomType.trim()
                  : 'Standard Room');

          final folio = state.completedFolio ??
              GuestFolioModel(
                id: 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                bookingId: 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                guestName: state.formData.guestFullName.isNotEmpty
                    ? state.formData.guestFullName
                    : 'Niraj Vekariya',
                phone: state.formData.contactPhone.isNotEmpty
                    ? state.formData.contactPhone
                    : '0884921811',
                email: state.formData.email.isNotEmpty
                    ? state.formData.email
                    : 'niraj.v@example.com',
                assignedRoom: state.formData.selectedRoomNumber.isNotEmpty
                    ? state.formData.selectedRoomNumber
                    : 'Room 03',
                roomType: state.formData.roomType.isNotEmpty
                    ? state.formData.roomType
                    : 'Deluxe Room',
                checkInDate: state.formData.checkInDate,
                checkOutDate: state.formData.checkOutDate,
                status: FolioStatus.inHouse,
                idType: state.formData.idType.isNotEmpty
                    ? state.formData.idType
                    : 'Aadhaar Card',
                idNumber: state.formData.idNumber.isNotEmpty
                    ? state.formData.idNumber
                    : '5421-9876-1234',
                isGovtIdVerified: state.formData.isIdVerified,
                roomRatePerNight: state.formData.pricePerNight,
                advancePaid: state.formData.advancePaid,
                totalAmount: state.formData.grandTotal > 0
                    ? state.formData.grandTotal
                    : state.formData.pricePerNight * state.formData.totalNights,
                paymentMode: state.formData.paymentMode,
                keycardNumber: state.formData.assignedKeycardNumber.isNotEmpty
                    ? state.formData.assignedKeycardNumber
                    : 'KC-101',
              );

          // 2. Show Success Pop-Up dialog with Send WhatsApp and Done actions
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogCtx) => CheckInSuccessDialog(
              folio: folio,
              formData: state.formData,
              onDone: () {
                Navigator.of(dialogCtx).pop();

                // Reset wizard state
                context.read<CheckInBloc>().add(InitCheckInWizardEvent());

                // Redirect directly to CategoryRoomsPage (Room Number Inventory)
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => CategoryRoomsPage(categoryName: category),
                  ),
                  (route) => route.isFirst,
                );
              },
            ),
          );
        } else if (state.status == CheckInStatus.error) {
          AppSnackBar.showError(
            context,
            state.errorMessage ?? (state.formData.isEditingBooking ? 'Could not update this booking.' : 'Check-in failed'),
            title: state.formData.isEditingBooking ? 'Update failed' : 'Check-in failed',
          );
        }
      },
      builder: (context, state) {
        final content = SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 14 : 24,
            vertical: isCompact ? 8 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2026 Executive Connected Stepper (Zero Horizontal Scroll, Clean Luxury Design)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'STEP ${state.currentStep + 1} OF ${_stepItems.length}',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              letterSpacing: 0.3,
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
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

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
                            borderRadius: BorderRadius.circular(6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    // Left connector
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: index == 0
                                            ? Colors.transparent
                                            : (isCompleted || isCurrent
                                                ? AppColors.primary
                                                : const Color(0xFFE2E8F0)),
                                      ),
                                    ),

                                    // Circle Node
                                    Container(
                                      width: 22,
                                      height: 22,
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
                                          width: isCurrent ? 1.8 : 1,
                                        ),
                                        boxShadow: isCurrent
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1.5),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: isCompleted
                                          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                                          : Text(
                                              '${index + 1}',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: isCurrent ? Colors.white : const Color(0xFF94A3B8),
                                              ),
                                            ),
                                    ),

                                    // Right connector
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: index == _stepItems.length - 1
                                            ? Colors.transparent
                                            : (isCompleted
                                                ? AppColors.primary
                                                : const Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _stepItems[index]['short'] as String,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
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



              // Step Form Content (Direct clean layout without oversized outer card)
              _buildCurrentStepWidget(context, state),
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
                          'Back',
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
                      onPressed: _checkInInFlight || state.status == CheckInStatus.submitting
                          ? null
                          : () {
                              if (_checkInInFlight) return;
                              if (_validateCurrentStep(context, state)) {
                                setState(() => _checkInInFlight = true);
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
                            if (_checkInInFlight || state.status == CheckInStatus.submitting)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            else
                              const Icon(Icons.check_circle_rounded, size: 17),
                            const SizedBox(width: 6),
                            Text(
                              state.formData.isEditingBooking ? 'Update booking' : 'Complete Express Check-In',
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
        return Step3BillingSettlement(
          formData: state.formData,
          onDataChanged: (data) => context.read<CheckInBloc>().add(UpdateFormDataEvent(data)),
        );
      case 3:
        return Step5KeycardSummary(
          formData: state.formData,
          onDataChanged: (data) => context.read<CheckInBloc>().add(UpdateFormDataEvent(data)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
