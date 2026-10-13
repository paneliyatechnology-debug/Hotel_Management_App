import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class MoreOperationalSheets {
  MoreOperationalSheets._();

  /// 1. OTA Reservations Sheet (Booking.com, Agoda, Expedia, Direct)
  static void showOtaReservations(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OTA Channel Reservations', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Connected OTA channels & incoming web bookings', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('8 NEW', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF059669))),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Channel summary pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _channelPill('Booking.com', '5 Bookings', const Color(0xFF003580)),
                    const SizedBox(width: 8),
                    _channelPill('Agoda', '2 Bookings', const Color(0xFF5392F9)),
                    const SizedBox(width: 8),
                    _channelPill('Expedia', '1 Booking', const Color(0xFFFFD200), textColor: Colors.black87),
                    const SizedBox(width: 8),
                    _channelPill('Other Channels', '0', const Color(0xFF64748B)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // OTA Booking list
              Expanded(
                child: ListView(
                  children: [
                    _otaBookingCard(
                      channel: 'Booking.com',
                      channelColor: const Color(0xFF003580),
                      bookingId: 'BKG-99214',
                      guestName: 'Rohit Sharma & Family',
                      roomCategory: 'Deluxe Ocean Villa (Room 204)',
                      dates: '26 Sep – 29 Sep • 3 Nights',
                      amount: '₹28,500',
                      status: 'Confirmed',
                    ),
                    _otaBookingCard(
                      channel: 'Booking.com',
                      channelColor: const Color(0xFF003580),
                      bookingId: 'BKG-99208',
                      guestName: 'Dr. Anita Desai',
                      roomCategory: 'Executive Suite (Room 302)',
                      dates: '26 Sep – 28 Sep • 2 Nights',
                      amount: '₹22,000',
                      status: 'Confirmed',
                    ),
                    _otaBookingCard(
                      channel: 'Agoda',
                      channelColor: const Color(0xFF5392F9),
                      bookingId: 'AGD-44182',
                      guestName: 'Michael Chang',
                      roomCategory: 'Premier Suite (Room 108)',
                      dates: '27 Sep – 30 Sep • 3 Nights',
                      amount: '₹34,500',
                      status: 'Confirmed',
                    ),
                    _otaBookingCard(
                      channel: 'Expedia',
                      channelColor: const Color(0xFFD97706),
                      bookingId: 'EXP-12903',
                      guestName: 'Vikram Malhotra',
                      roomCategory: 'Luxury Chalet (Room 401)',
                      dates: '28 Sep – 02 Oct • 4 Nights',
                      amount: '₹48,000',
                      status: 'Confirmed',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 2. All Reservations Sheet
  static void showAllReservations(BuildContext context, {String filter = 'All'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hotel Reservations', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Upcoming, confirmed and active reservations', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                    child: Text('24 TOTAL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: [
                    _reservationCard('RES-2026-441', 'Rajesh Kothari', 'Room 201 • Deluxe Room', '26 Sep – 28 Sep', '₹14,500', 'Confirmed', AppColors.statusOccupied),
                    _reservationCard('RES-2026-442', 'Sarah Jenkins', 'Room 105 • Super Deluxe', '26 Sep – 29 Sep', '₹21,000', 'Arriving Today', AppColors.primary),
                    _reservationCard('RES-2026-443', 'Pooja Hegde', 'Room 304 • Executive Suite', '27 Sep – 30 Sep', '₹36,000', 'Confirmed', AppColors.statusOccupied),
                    _reservationCard('RES-2026-444', 'Arjun Kapoor', 'Room 402 • Luxury Suite', '28 Sep – 01 Oct', '₹42,000', 'Advance Paid', const Color(0xFF10B981)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 3. Room Change Modal (Transfer guest to another room)
  static void showRoomChange(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String selectedGuest = 'Rajesh Kothari (Room 201)';
        String targetRoom = 'Room 205 (Clean & Ready)';
        String reason = 'Air Conditioning Noise / Issue';

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Guest Room Change', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                              Text('Transfer staying guest to another clean room', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Current Guest Selection
                    Text('CURRENT IN-HOUSE GUEST', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(selectedGuest, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Destination Room Selection
                    Text('TARGET AVAILABLE ROOM', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.meeting_room_rounded, size: 18, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(targetRoom, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)))),
                          const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Reason for room transfer
                    Text('REASON FOR ROOM CHANGE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: reason,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      items: [
                        'Air Conditioning Noise / Issue',
                        'Guest Upgrade Request',
                        'Plumbing / Water Pressure Issue',
                        'Quiet Room / High Floor Request',
                        'Other Front Desk Reason',
                      ].map((r) => DropdownMenuItem(value: r, child: Text(r, style: GoogleFonts.inter(fontSize: 12.5)))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => reason = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Submit Room Change Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.of(modalCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Room change completed successfully. Keycard updated.')),
                          );
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text('Confirm Room Transfer', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 4. Guest Requests Sheet
  static void showGuestRequests(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Guest Requests', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Active front desk and service requests', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                    child: Text('4 OPEN', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFB45309))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _requestTile('Extra Towels & Pillows', 'Room 204 • Rohit Sharma', 'Requested 15m ago', 'Delivered by HK', true),
                    _requestTile('Late Breakfast in Bed', 'Room 302 • Dr. Anita Desai', 'Requested for 10:00 AM', 'Sent to Kitchen', false),
                    _requestTile('Airport Taxi Booking', 'Room 108 • Michael Chang', 'Pickup at 04:30 PM (Goa Airport)', 'Concierge Assigned', false),
                    _requestTile('Baby Crib / Extra Bed', 'Room 401 • Vikram Malhotra', 'Needed before 06:00 PM', 'HK Pending', false),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 5. Complaints Sheet
  static void showComplaints(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Guest Complaints', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Reported issues and resolution tracking', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                    child: Text('1 ACTIVE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _complaintTile(
                      title: 'Air Conditioning cooling slow',
                      room: 'Room 205 • Assigned to Maintenance',
                      time: 'Reported 25m ago',
                      priority: 'HIGH PRIORITY',
                      status: 'In Progress',
                      isUrgent: true,
                    ),
                    _complaintTile(
                      title: 'Hot water temperature fluctuation',
                      room: 'Room 304 • Plumber inspected boiler',
                      time: 'Reported Yesterday',
                      priority: 'NORMAL',
                      status: 'Resolved & Closed',
                      isUrgent: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 6. Housekeeping Operations Sheet
  static void showHousekeeping(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Housekeeping Overview', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Room cleaning status across all floors', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                    child: Text('6 DIRTY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFB45309))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _hkMetricCard('Clean & Ready', '14', const Color(0xFF10B981))),
                  const SizedBox(width: 8),
                  Expanded(child: _hkMetricCard('Dirty / Checkout', '6', const Color(0xFFD97706))),
                  const SizedBox(width: 8),
                  Expanded(child: _hkMetricCard('Cleaning Now', '2', AppColors.primary)),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    _roomHkTile('Room 102', 'Deluxe Room', 'Dirty (Checkout at 11 AM)', const Color(0xFFD97706)),
                    _roomHkTile('Room 105', 'Super Deluxe', 'Cleaning in Progress (Staff: Sunita)', AppColors.primary),
                    _roomHkTile('Room 201', 'Deluxe Room', 'Clean & Ready for Arrival', const Color(0xFF10B981)),
                    _roomHkTile('Room 204', 'Deluxe Room', 'Occupied • Cleaned Today 10:30 AM', const Color(0xFF10B981)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 7. Maintenance Tracking Sheet
  static void showMaintenance(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Maintenance Issues', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Track room repairs and engineering tasks', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                    child: Text('2 OPEN', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _maintenanceTicket('Room 304', 'Geyser heating element inspection', 'Assigned: Ramesh (Electrician)', 'In Progress'),
                    _maintenanceTicket('Room 108', 'Electronic door lock low battery alert', 'Assigned: Duty Engg', 'Pending Parts'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 8. Reports Viewer Sheet
  static void showReport(BuildContext context, String reportTitle, String description) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reportTitle, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text(description, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _reportDataRow('Business Date', '26 Sep 2026'),
                    _reportDataRow('Property', 'Mayal Resort 2'),
                    _reportDataRow('Total Rooms', '22 Units'),
                    _reportDataRow('Occupied Rooms', '18 Units (81.8%)'),
                    _reportDataRow('Available / Vacant', '4 Units'),
                    _reportDataRow('Total Revenue / Collection', '₹1,42,800'),
                    _reportDataRow('Cash Till Received', '₹13,000'),
                    _reportDataRow('UPI / Digital Received', '₹1,29,800'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$reportTitle exported to PDF.')),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text('Export & Print Report', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 9. Emergency Contacts Sheet
  static void showEmergencyContacts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 38, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency Contacts', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Front desk quick escalation contacts', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _emergencyContactRow('General Manager (GM Desk)', '+91 98250 11223', 'Ext 101'),
              _emergencyContactRow('Duty Security Manager', '+91 98250 44556', 'Ext 100'),
              _emergencyContactRow('On-Call Doctor / Clinic', '+91 98250 77889', 'Medical'),
              _emergencyContactRow('Local Police & Emergency', '112 / 100', 'Helpline'),
            ],
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---

  static Widget _channelPill(String title, String count, Color color, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
          Text(count, style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w500, color: textColor.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  static Widget _otaBookingCard({
    required String channel,
    required Color channelColor,
    required String bookingId,
    required String guestName,
    required String roomCategory,
    required String dates,
    required String amount,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: channelColor, borderRadius: BorderRadius.circular(4)),
                child: Text(channel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              Text(bookingId, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(guestName, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(roomCategory, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dates,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Text(amount, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _reservationCard(String id, String name, String room, String dates, String amount, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(id, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                      child: Text(status, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(name, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(room, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                Text(dates, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
          ),
          Text(amount, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  static Widget _requestTile(String title, String room, String time, String tag, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(room, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                Text(time, style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isCompleted ? const Color(0xFF15803D) : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _complaintTile({required String title, required String room, required String time, required String priority, required String status, required bool isUrgent}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isUrgent ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(priority, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF15803D))),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(room, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
          Text(time, style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  static Widget _hkMetricCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(count, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  static Widget _roomHkTile(String room, String category, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(room, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(category, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  static Widget _maintenanceTicket(String room, String issue, String assigned, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(room, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFD97706))),
            ],
          ),
          const SizedBox(height: 4),
          Text(issue, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text(assigned, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  static Widget _reportDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  static Widget _emergencyContactRow(String title, String phone, String tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF991B1B))),
                Text(tag, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFFB91C1C))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.call_rounded, size: 13, color: Color(0xFFDC2626)),
                const SizedBox(width: 4),
                Text(phone, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
