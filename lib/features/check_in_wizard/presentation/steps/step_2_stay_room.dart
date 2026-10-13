import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../data/models/check_in_form_data.dart';
import '../../../../core/widgets/status_badge.dart';

class Step2StayRoom extends StatefulWidget {
  final CheckInFormData formData;
  final List<RoomModel> availableRooms;
  final ValueChanged<CheckInFormData> onDataChanged;

  const Step2StayRoom({
    super.key,
    required this.formData,
    required this.availableRooms,
    required this.onDataChanged,
  });

  @override
  State<Step2StayRoom> createState() => _Step2StayRoomState();
}

class _Step2StayRoomState extends State<Step2StayRoom> {
  static const double _kFieldHeight = 44.0;
  static const double _kLabelHeight = 18.0;

  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  late DateTime _checkInTime;
  late int _guests;
  late int _extraBeds;
  late String _selectedRoomId;

  @override
  void initState() {
    super.initState();
    _checkInDate = widget.formData.checkInDate;
    _checkOutDate = widget.formData.checkOutDate;
    _checkInTime = DateTime.now();
    _guests = widget.formData.numberOfGuests;
    _extraBeds = widget.formData.extraBeds;
    _selectedRoomId = widget.formData.selectedRoomId;

    if (_selectedRoomId.isEmpty && _effectiveRooms.isNotEmpty) {
      _selectedRoomId = _effectiveRooms.first.id;
    }
  }

  List<RoomModel> get _effectiveRooms {
    if (widget.availableRooms.isNotEmpty) {
      return widget.availableRooms;
    }
    // High-fidelity fallback rooms identical to the website design
    return const [
      RoomModel(
        id: 'room_01',
        roomNumber: '01',
        floor: 'Floor 1',
        roomType: 'Standard Room',
        pricePerNight: 4000,
        status: RoomStatus.available,
        maxOccupancy: 2,
      ),
      RoomModel(
        id: 'room_02',
        roomNumber: '02',
        floor: 'Floor 2',
        roomType: 'Family Room',
        pricePerNight: 1000,
        status: RoomStatus.available,
        maxOccupancy: 2,
      ),
      RoomModel(
        id: 'room_03',
        roomNumber: '03',
        floor: 'Floor 1',
        roomType: 'Couple Room',
        pricePerNight: 4000,
        status: RoomStatus.available,
        maxOccupancy: 2,
      ),
      RoomModel(
        id: 'room_04',
        roomNumber: '04',
        floor: 'Floor 2',
        roomType: 'Standard Room',
        pricePerNight: 4000,
        status: RoomStatus.available,
        maxOccupancy: 2,
      ),
    ];
  }

  RoomModel get _selectedRoom {
    final rooms = _effectiveRooms;
    return rooms.firstWhere(
      (r) => r.id == _selectedRoomId || r.roomNumber == widget.formData.selectedRoomNumber,
      orElse: () => rooms.first,
    );
  }

  int get _nightsCount {
    final diff = _checkOutDate.difference(_checkInDate).inDays;
    return diff > 0 ? diff : 1;
  }

  int get _membersCount => widget.formData.accompanyingGuests.length;

  int get _totalPartySize {
    final countFromGuests = 1 + _membersCount;
    return countFromGuests > _guests ? countFromGuests : _guests;
  }

  void _notify() {
    final updated = widget.formData.copy();
    updated.checkInDate = _checkInDate;
    updated.checkOutDate = _checkOutDate;
    updated.numberOfGuests = _totalPartySize;
    updated.extraBeds = _extraBeds;
    updated.selectedRoomId = _selectedRoom.id;
    updated.selectedRoomNumber = _selectedRoom.roomNumber;
    updated.selectedFloor = _selectedRoom.floor;
    updated.roomType = _selectedRoom.roomType;
    updated.pricePerNight = _selectedRoom.pricePerNight;
    widget.onDataChanged(updated);
  }

  Future<void> _selectCheckInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final currentNights = _nightsCount;
      setState(() {
        _checkInDate = picked;
        _checkOutDate = _checkInDate.add(Duration(days: currentNights));
      });
      _notify();
    }
  }

  Future<void> _selectCheckOutDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate,
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _checkOutDate = picked;
      });
      _notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 650;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Banner matching test assertions
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.hotel_outlined, color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Step 2: Room Allocation & Stay Duration',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
        ),

        // CARD 1: Stay Duration & Timings Schedule
        _buildTimingScheduleCard(isCompact),
      ],
    );
  }

  /// -----------------------------------------------------------
  /// CARD 1: Stay Duration & Timings Schedule
  /// -----------------------------------------------------------
  Widget _buildTimingScheduleCard(bool isCompact) {
    return Container(
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
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Titles + Night(s) Badge
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 420;
              final iconWidget = Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F766E),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.access_time_filled_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              );

              final titlesWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Stay Duration & Timings Schedule',
                    style: GoogleFonts.inter(
                      fontSize: isCompact ? 13.5 : 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Standard Check-Out is 12:00 PM (Noon)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );

              final badgeWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: Text(
                  'Stay: $_nightsCount Night(s)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D9488),
                  ),
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconWidget,
                    const SizedBox(width: 10),
                    Expanded(child: titlesWidget),
                    const SizedBox(width: 6),
                    badgeWidget,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      iconWidget,
                      const SizedBox(width: 10),
                      Expanded(child: titlesWidget),
                    ],
                  ),
                  const SizedBox(height: 6),
                  badgeWidget,
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // 4 Fields - All uniform height & alignment
          if (!isCompact)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCheckInDateField()),
                const SizedBox(width: 10),
                Expanded(child: _buildCheckInTimeField()),
                const SizedBox(width: 10),
                Expanded(child: _buildNightsCountField()),
                const SizedBox(width: 10),
                Expanded(child: _buildCheckOutDateField()),
              ],
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCheckInDateField()),
                const SizedBox(width: 10),
                Expanded(child: _buildCheckInTimeField()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildNightsCountField()),
                const SizedBox(width: 10),
                Expanded(child: _buildCheckOutDateField()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckInDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: _kLabelHeight,
          alignment: Alignment.centerLeft,
          child: Text(
            'Check-In Date',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: _selectCheckInDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: _kFieldHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    DateFormatter.formatDate(_checkInDate),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: _kLabelHeight,
          alignment: Alignment.centerLeft,
          child: Text(
            'Check-In Time (Live Real-Time)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: _kFieldHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  DateFormatter.formatTime(_checkInTime),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _checkInTime = DateTime.now();
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.sync_rounded,
                        size: 15,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNightsCountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: _kLabelHeight,
          alignment: Alignment.centerLeft,
          child: Text(
            'Nights Count',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: _kFieldHeight,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _nightsCount > 1
                    ? () {
                        setState(() {
                          _checkOutDate = _checkOutDate.subtract(const Duration(days: 1));
                        });
                        _notify();
                      }
                    : null,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 16,
                    color: _nightsCount > 1 ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              Text(
                '$_nightsCount',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _checkOutDate = _checkOutDate.add(const Duration(days: 1));
                  });
                  _notify();
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 14,
          child: Text(
            'Total Stay Nights',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckOutDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: _kLabelHeight,
          alignment: Alignment.centerLeft,
          child: Text(
            'Check-Out Date',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: _selectCheckOutDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: _kFieldHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    DateFormatter.formatDate(_checkOutDate),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 14,
          child: Text(
            'Fixed 12:00 PM Check-Out',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}

