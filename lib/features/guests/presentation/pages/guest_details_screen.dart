import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/guest_model.dart';
import '../widgets/historical_stay_modal.dart';

class GuestDetailsScreen extends StatelessWidget {
  final GuestProfileModel guest;

  const GuestDetailsScreen({
    super.key,
    required this.guest,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Group stay history by year
    final Map<int, List<HistoricalStayModel>> staysByYear = {};
    for (final stay in guest.stayHistory) {
      final year = stay.checkInDate.year;
      staysByYear.putIfAbsent(year, () => []).add(stay);
    }
    final sortedYears = staysByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.neutral900, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Guest Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.neutral900,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.neutral700, size: 20),
            onPressed: () {},
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderSubtle),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PROFILE HEADER
            _buildProfileHeader(),

            const SizedBox(height: 16),

            // CURRENT STAY (If In-House) OR LAST STAY BANNER
            if (guest.currentStay != null) ...[
              _buildCurrentStayCard(dateFormat, timeFormat, currencyFormat),
              const SizedBox(height: 16),
            ] else ...[
              _buildCheckedOutSummaryCard(dateFormat, currencyFormat),
              const SizedBox(height: 16),
            ],

            // PERSONAL INFORMATION
            _buildPersonalInfoCard(dateFormat),

            const SizedBox(height: 16),

            // KYC / IDENTITY SECTION
            _buildKycCard(),

            const SizedBox(height: 20),

            // COMPLETE STAY HISTORY SECTION (with year grouping)
            _buildStayHistorySection(context, sortedYears, staysByYear, dateFormat, currencyFormat),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Large Avatar
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: guest.status == GuestStatus.inHouse
                    ? [AppColors.statusSuccess, const Color(0xFF059669)]
                    : [AppColors.primary, const Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                guest.initials,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        guest.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral900,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildStatusChip(guest.status),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        guest.status == GuestStatus.inHouse
                            ? 'Room ${guest.currentStay?.roomNumber ?? guest.lastRoomNumber}'
                            : 'Last: Room ${guest.lastRoomNumber}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${guest.stayCount} Total Stays',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
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
    );
  }

  Widget _buildCurrentStayCard(DateFormat dateFormat, DateFormat timeFormat, NumberFormat currencyFormat) {
    final stay = guest.currentStay!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.statusSuccess.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.statusSuccess.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.statusSuccess,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'CURRENT STAY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.statusSuccess,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccessSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'IN-HOUSE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusSuccess,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 12),
          _buildInfoRow('Room Number', 'Room ${stay.roomNumber} (${stay.floor})'),
          _buildInfoRow('Room Category', stay.roomCategory),
          _buildInfoRow('Check-in Date & Time', '${dateFormat.format(stay.checkInDate)} at ${timeFormat.format(stay.checkInDate)}'),
          _buildInfoRow('Expected Checkout', dateFormat.format(stay.checkOutDate)),
          _buildInfoRow('Number of Guests', '${stay.numberOfGuests} Guests'),
          _buildInfoRow('Booking ID', stay.bookingId),
          _buildInfoRow('Payment Status', stay.paymentStatus, isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildCheckedOutSummaryCard(DateFormat dateFormat, NumberFormat currencyFormat) {
    final isRegistered = guest.status == GuestStatus.registered;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRegistered ? const Color(0xFFFEF3C7).withValues(alpha: 0.3) : AppColors.neutral100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRegistered ? const Color(0xFFFDE68A) : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRegistered ? Icons.how_to_reg_rounded : Icons.history_rounded,
            size: 20,
            color: isRegistered ? const Color(0xFFD97706) : AppColors.neutral700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRegistered ? 'Guest Status: Registered' : 'Guest Status: Checked-Out',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isRegistered
                      ? (guest.roomAssigned.isNotEmpty &&
                              guest.roomAssigned != 'Not Assigned' &&
                              guest.roomAssigned != 'N/A'
                          ? 'Assigned to Room ${guest.roomAssigned} • Awaiting check-in'
                          : 'Profile created • No room assigned yet')
                      : 'Last departed on ${dateFormat.format(guest.lastCheckOutDate)} from Room ${guest.lastRoomNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'PERSONAL INFORMATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 10),
          _buildInfoRow('Full Name', guest.name),
          _buildInfoRow('Mobile Number', guest.mobile),
          _buildInfoRow('Email Address', guest.email),
          _buildInfoRow('Gender', guest.gender),
          _buildInfoRow('Date of Birth', dateFormat.format(guest.dateOfBirth)),
          _buildInfoRow('Address', guest.address),
          _buildInfoRow('Nationality', guest.nationality),
        ],
      ),
    );
  }

  Widget _buildKycCard() {
    final kyc = guest.kycDetails;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'KYC / IDENTITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.neutral700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kyc.isVerified ? AppColors.statusSuccessSurface : AppColors.statusWarningSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      kyc.isVerified ? Icons.check_circle_rounded : Icons.pending_rounded,
                      size: 12,
                      color: kyc.isVerified ? AppColors.statusSuccess : AppColors.statusWarning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      kyc.isVerified ? 'VERIFIED' : 'PENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: kyc.isVerified ? AppColors.statusSuccess : AppColors.statusWarning,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 10),
          _buildInfoRow('ID Document Type', kyc.idType),
          _buildInfoRow('ID Number', kyc.maskedIdNumber),
          const SizedBox(height: 12),
          const Text(
            'Document Preview',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDocPreviewCard('Front Copy', kyc.frontDocumentPath, kyc.idType),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDocPreviewCard('Back Copy', kyc.backDocumentPath, kyc.idType),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocPreviewCard(String label, String? docPath, String idType) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.document_scanner_rounded, size: 24, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            '$label ($idType)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral800,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStayHistorySection(
    BuildContext context,
    List<int> sortedYears,
    Map<int, List<HistoricalStayModel>> staysByYear,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Stay History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.neutral900,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Complete archive of all previous visits and bookings',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.neutral600,
          ),
        ),
        const SizedBox(height: 14),

        // Iteration across years (e.g. 2026, 2025, 2024...)
        ...sortedYears.map((year) {
          final stays = staysByYear[year]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Year Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$year',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.borderSubtle,
                      ),
                    ),
                  ],
                ),
              ),

              // Stay Cards for this year
              ...stays.map((stay) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      HistoricalStayModal.show(
                        context,
                        stay: stay,
                        guestName: guest.name,
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${dateFormat.format(stay.checkInDate)} → ${dateFormat.format(stay.checkOutDate)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.neutral900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(stay.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Room ${stay.roomNumber} • ${stay.roomCategory}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.neutral700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currencyFormat.format(stay.totalAmount),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.neutral900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                stay.bookingId,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.neutral500,
                                ),
                              ),
                              Row(
                                children: const [
                                  Text(
                                    'View Stay Details',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 10,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.neutral600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                color: isHighlight ? AppColors.statusSuccess : AppColors.neutral900,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(GuestStatus status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case GuestStatus.inHouse:
        bg = AppColors.statusSuccessSurface;
        text = AppColors.statusSuccess;
        label = 'IN-HOUSE';
        break;
      case GuestStatus.checkedOut:
        bg = AppColors.primarySurface;
        text = AppColors.primary;
        label = 'CHECKED-OUT';
        break;
      case GuestStatus.cancelled:
        bg = AppColors.statusErrorSurface;
        text = AppColors.statusError;
        label = 'CANCELLED';
        break;
      case GuestStatus.registered:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        label = 'REGISTERED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: text,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(GuestStatus status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case GuestStatus.inHouse:
        bg = AppColors.statusSuccessSurface;
        text = AppColors.statusSuccess;
        label = 'IN-HOUSE';
        break;
      case GuestStatus.checkedOut:
        bg = AppColors.primarySurface;
        text = AppColors.primary;
        label = 'CHECKED-OUT';
        break;
      case GuestStatus.cancelled:
        bg = AppColors.statusErrorSurface;
        text = AppColors.statusError;
        label = 'CANCELLED';
        break;
      case GuestStatus.registered:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        label = 'REGISTERED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: text,
        ),
      ),
    );
  }
}
