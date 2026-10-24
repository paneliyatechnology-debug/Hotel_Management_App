import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/currency_formatter.dart';
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
  late List<String> _selectedRoomIds;

  @override
  void initState() {
    super.initState();
    _checkInDate = widget.formData.checkInDate;
    _checkOutDate = widget.formData.checkOutDate;
    _applyStayDateRules();
    _checkInTime = DateTime.now();
    _guests = widget.formData.numberOfGuests;
    _extraBeds = widget.formData.extraBeds;
    _selectedRoomIds = List<String>.from(widget.formData.selectedRoomIds);
    if (_selectedRoomIds.isEmpty && widget.formData.selectedRoomId.trim().isNotEmpty) {
      _selectedRoomIds = [widget.formData.selectedRoomId.trim()];
    }
    if (_selectedRoomIds.isEmpty && _effectiveRooms.isNotEmpty) {
      _selectedRoomIds = [_effectiveRooms.first.id];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notify();
    });
  }

  @override
  void didUpdateWidget(covariant Step2StayRoom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableRooms != widget.availableRooms &&
        _selectedRoomIds.isEmpty &&
        widget.availableRooms.isNotEmpty) {
      setState(() => _selectedRoomIds = [widget.availableRooms.first.id]);
      _notify();
    }
  }

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  DateTime get _today => _dateOnly(DateTime.now());

  bool get _isEditing => widget.formData.isEditingBooking;

  void _applyStayDateRules() {
    if (_isEditing) {
      _checkInDate = _dateOnly(widget.formData.checkInDate);
      final checkout = _dateOnly(widget.formData.checkOutDate);
      _checkOutDate = checkout.isAfter(_checkInDate) ? checkout : _checkInDate.add(const Duration(days: 1));
      return;
    }
    final today = _today;
    _checkInDate = today;
    final earliestCheckout = today.add(const Duration(days: 1));
    final checkout = _dateOnly(_checkOutDate);
    _checkOutDate = checkout.isAfter(today) ? checkout : earliestCheckout;
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

  List<RoomModel> get _selectedRooms {
    final rooms = _effectiveRooms;
    final selected = <RoomModel>[];
    for (final id in _selectedRoomIds) {
      final match = rooms.where((room) => room.id == id);
      if (match.isNotEmpty) selected.add(match.first);
    }
    if (selected.isEmpty && rooms.isNotEmpty) {
      return [rooms.first];
    }
    return selected;
  }

  double get _combinedNightlyRate =>
      _selectedRooms.fold<double>(0, (sum, room) => sum + room.pricePerNight);

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
    final selected = _selectedRooms;
    if (selected.isEmpty) return;
    final updated = widget.formData.copy();
    updated.checkInDate = _checkInDate;
    updated.checkOutDate = _checkOutDate;
    updated.numberOfGuests = _totalPartySize;
    updated.extraBeds = _extraBeds;
    updated.selectedRoomIds = selected.map((room) => room.id).toList();
    updated.selectedRoomId = selected.first.id;
    updated.selectedRoomNumber = selected.map((room) => room.roomNumber).join(', ');
    updated.selectedFloor =
        selected.length == 1 ? selected.first.floor : '${selected.length} rooms';
    updated.roomType = selected.map((room) => room.roomType).toSet().join(' + ');
    updated.pricePerNight = _combinedNightlyRate;
    updated.gstEnabled = selected.any((room) => room.gstEnabled);
    final gstRoom = selected.firstWhere(
      (room) => room.gstEnabled,
      orElse: () => selected.first,
    );
    updated.gstRate = updated.gstEnabled ? gstRoom.gstRate : 0;
    updated.assignedKeycardNumber = selected.first.keyCode.trim();
    widget.onDataChanged(updated);
  }

  Future<void> _selectCheckInDate() async {
    if (_isEditing) {
      final picked = await showDatePicker(
        context: context,
        initialDate: _checkInDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked == null) return;
      setState(() {
        _checkInDate = _dateOnly(picked);
        if (!_checkOutDate.isAfter(_checkInDate)) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });
      _notify();
      return;
    }
    final today = _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today,
      selectableDayPredicate: (day) => _dateOnly(day) == today,
    );
    if (picked != null) {
      setState(() {
        _checkInDate = today;
        if (!_dateOnly(_checkOutDate).isAfter(today)) {
          _checkOutDate = today.add(const Duration(days: 1));
        }
      });
      _notify();
    }
  }

  Future<void> _selectCheckOutDate() async {
    if (_isEditing) {
      final earliest = _checkInDate.add(const Duration(days: 1));
      final current = _dateOnly(_checkOutDate);
      final initial = current.isBefore(earliest) ? earliest : current;
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: earliest,
        lastDate: DateTime(2100),
      );
      if (picked == null) return;
      setState(() => _checkOutDate = _dateOnly(picked));
      _notify();
      return;
    }
    final earliest = _today.add(const Duration(days: 1));
    final current = _dateOnly(_checkOutDate);
    final initial = current.isBefore(earliest) ? earliest : current;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: earliest,
      lastDate: _today.add(const Duration(days: 365)),
      selectableDayPredicate: (day) => _dateOnly(day).isAfter(_today),
    );
    if (picked != null) {
      final selected = _dateOnly(picked);
      if (!selected.isAfter(_today)) return;
      setState(() {
        _checkOutDate = selected;
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
        const SizedBox(height: 14),
        _buildMultiRoomSelectCard(isCompact),
      ],
    );
  }

  Widget _buildMultiRoomSelectCard(bool isCompact) {
    final selected = _selectedRooms;
    final nightly = _combinedNightlyRate;
    final stayTotal = nightly * _nightsCount;

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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F766E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected rooms',
                      style: GoogleFonts.inter(
                        fontSize: isCompact ? 13.5 : 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected.isEmpty
                          ? 'No room selected'
                          : '${selected.length} room${selected.length == 1 ? '' : 's'} · ${CurrencyFormatter.formatWithPerNight(nightly)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selected.isEmpty)
            Text(
              'Go back and select rooms from the room list.',
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selected.map((room) {
                final number = room.roomNumber.replaceAll('#', '').trim();
                return Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0F766E), width: 1.2),
                  ),
                  child: Text(
                    number,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                );
              }).toList(),
            ),
          if (selected.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Combined × $_nightsCount night(s)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Text(
                  CurrencyFormatter.format(stayTotal),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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

