import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../dashboard/data/models/guest_folio_model.dart';
import 'in_house_actions_dialogs.dart';

class InHouseGuestCard extends StatelessWidget {
  final GuestFolioModel folio;
  final VoidCallback onDetailsPressed;
  final bool isSelected;

  const InHouseGuestCard({
    super.key,
    required this.folio,
    required this.onDetailsPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isInHouse = folio.status == FolioStatus.inHouse;
    final initial = folio.initial;
    final roomNum = folio.assignedRoom.replaceAll('Room ', '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isInHouse ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
          width: isSelected ? 2.0 : (isInHouse ? 1.2 : 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : (isInHouse ? const Color(0x0E16A34A) : const Color(0x06000000)),
            blurRadius: isSelected ? 12 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onDetailsPressed,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Room Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    // Room Number Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isInHouse
                              ? [const Color(0xFF0D9488), const Color(0xFF0F766E)]
                              : [const Color(0xFF64748B), const Color(0xFF475569)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (isInHouse ? const Color(0xFF0D9488) : const Color(0xFF64748B)).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        roomNum.startsWith('#') ? roomNum : '#$roomNum',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Room Title, Floor, Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'ROOM ${roomNum.replaceAll('#', '')}',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  folio.floor.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            folio.roomType.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Pill
                    _buildStatusPill(folio.status),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // 2. Guest Information & Stay Progress
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar & Guest Name
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
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
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      folio.guestName,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (folio.vipStatus != null && folio.vipStatus!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFFDE68A)),
                                      ),
                                      child: Text(
                                        folio.vipStatus!,
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                '${folio.numberOfGuests} Guests • ${folio.bookingSource} • ${folio.id}',
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
                    const SizedBox(height: 10),

                    // Stay Information Row: Check-in, Expected Checkout, Nights Remaining
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CHECK-IN',
                                      style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8)),
                                    ),
                                    Text(
                                      DateFormatter.formatShort(folio.checkInDate),
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF94A3B8)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CHECKOUT',
                                      style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8)),
                                    ),
                                    Text(
                                      DateFormatter.formatShort(folio.checkOutDate),
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isInHouse ? AppColors.primarySurface : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isInHouse ? AppColors.primaryLight.withValues(alpha: 0.3) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  '${folio.nightsRemaining}N left',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isInHouse ? AppColors.primaryDark : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick Badges: Keycard, Payment Badge, Phone, Special Info
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        // Keycard Status
                        _buildKeycardBadge(),

                        // Payment Status Badge
                        _buildPaymentBadge(folio.paymentStatusLabel),

                        // Phone
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_rounded, size: 10.5, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                folio.phone,
                                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),

                        // Meal Plan if exists
                        if (folio.mealPlan != null && folio.mealPlan!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.restaurant_rounded, size: 10.5, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(
                                  folio.mealPlan!,
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),

                        // Special Requests note
                        if (folio.specialRequests != null && folio.specialRequests!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 11, color: Color(0xFFD97706)),
                                const SizedBox(width: 3),
                                Text(
                                  folio.specialRequests!,
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Card Footer: Folio Balance & Action Buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Folio Financial Summary
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TOTAL FOLIO',
                            style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.3),
                          ),
                          Wrap(
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                CurrencyFormatter.format(folio.totalAmount),
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                              ),
                              if (folio.pendingAmount > 0)
                                Text(
                                  '(Due: ${CurrencyFormatter.format(folio.pendingAmount)})',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isInHouse) ...[
                          InkWell(
                            onTap: () => InHouseActionsDialogs.showSafeCheckoutDialog(context, folio),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFECDD3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.logout_rounded, size: 12, color: Color(0xFFDC2626)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Checkout',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],

                        // Details Button
                        InkWell(
                          onTap: onDetailsPressed,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Details',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(FolioStatus status) {
    final isInHouse = status == FolioStatus.inHouse;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isInHouse ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isInHouse ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isInHouse ? const Color(0xFF16A34A) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isInHouse ? 'IN-HOUSE' : 'DEPARTED',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: isInHouse ? const Color(0xFF15803D) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeycardBadge() {
    Color bg;
    Color border;
    Color text;
    String label;

    switch (folio.keycardStatus) {
      case 'Active':
      case 'active':
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0);
        text = const Color(0xFF15803D);
        label = folio.keycardNumber != null ? 'Card: ${folio.keycardNumber}' : 'Keycard: Active';
        break;
      case 'Lost':
      case 'lost':
        bg = const Color(0xFFFEF3C7);
        border = const Color(0xFFFDE68A);
        text = const Color(0xFFB45309);
        label = 'Keycard: Issue Reported';
        break;
      default:
        bg = const Color(0xFFF8FAFC);
        border = const Color(0xFFE2E8F0);
        text = const Color(0xFF64748B);
        label = 'Keycard: Not Issued';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.nfc_rounded, size: 10.5, color: text),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: text),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(String status) {
    Color bg;
    Color border;
    Color text;

    switch (status) {
      case 'PAID':
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFF86EFAC);
        text = const Color(0xFF15803D);
        break;
      case 'PARTIALLY PAID':
        bg = const Color(0xFFFEF3C7);
        border = const Color(0xFFFDE68A);
        text = const Color(0xFFB45309);
        break;
      default:
        bg = const Color(0xFFFEE2E2);
        border = const Color(0xFFFECDD3);
        text = const Color(0xFFB91C1C);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, color: text),
      ),
    );
  }
}
