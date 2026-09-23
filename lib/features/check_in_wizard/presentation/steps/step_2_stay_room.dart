import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../data/models/check_in_form_data.dart';

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
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  late int _guests;
  late int _extraBeds;
  late String _selectedRoomId;

  @override
  void initState() {
    super.initState();
    _checkInDate = widget.formData.checkInDate;
    _checkOutDate = widget.formData.checkOutDate;
    _guests = widget.formData.numberOfGuests;
    _extraBeds = widget.formData.extraBeds;
    _selectedRoomId = widget.formData.selectedRoomId;
  }

  void _notify() {
    final updated = widget.formData.copy();
    updated.checkInDate = _checkInDate;
    updated.checkOutDate = _checkOutDate;
    updated.numberOfGuests = _guests;
    updated.extraBeds = _extraBeds;
    updated.selectedRoomId = _selectedRoomId;
    widget.onDataChanged(updated);
  }

  Future<void> _selectCheckInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _checkInDate = picked;
        if (_checkOutDate.isBefore(_checkInDate) || _checkOutDate.isAtSameMomentAs(_checkInDate)) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
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
      setState(() => _checkOutDate = picked);
      _notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 650;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Banner
        Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.hotel_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 2: Room Allocation & Stay Duration',
                      style: GoogleFonts.inter(
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose an available vacant room and define check-in / check-out timeline.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Date selection row
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectCheckInDate,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHECK-IN DATE',
                        style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 13, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              DateFormatter.formatDate(_checkInDate),
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _selectCheckOutDate,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHECK-OUT DATE',
                        style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.event_available, size: 13, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              DateFormatter.formatDate(_checkOutDate),
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Guests & Extra Bed Counters (Stacked on compact mobile if needed)
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // Guests Counter
            SizedBox(
              width: isCompact ? double.infinity : (MediaQuery.of(context).size.width / 2) - 40,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GUESTS', style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        Text('$_guests Person${_guests > 1 ? 's' : ''}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 18),
                          onPressed: _guests > 1
                              ? () {
                                  setState(() => _guests--);
                                  _notify();
                                }
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                          onPressed: () {
                            setState(() => _guests++);
                            _notify();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Extra Bed Counter
            SizedBox(
              width: isCompact ? double.infinity : (MediaQuery.of(context).size.width / 2) - 40,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EXTRA BED (+₹500)', style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        Text('$_extraBeds Bed${_extraBeds > 1 ? 's' : ''}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 18),
                          onPressed: _extraBeds > 0
                              ? () {
                                  setState(() => _extraBeds--);
                                  _notify();
                                }
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                          onPressed: () {
                            setState(() => _extraBeds++);
                            _notify();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        if (!widget.formData.isRoomPreLocked) ...[
          const SizedBox(height: 18),
          Text(
            'SELECT AVAILABLE ROOM *',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          if (widget.availableRooms.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusMaintenanceBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No rooms currently in Available / Vacant status.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.statusMaintenance),
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.availableRooms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final room = widget.availableRooms[index];
              final isSelected = room.id == _selectedRoomId || room.roomNumber == widget.formData.selectedRoomNumber;

              return Material(
                color: isSelected ? AppColors.accentGreenLight : Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedRoomId = room.id);
                    final updated = widget.formData.copy();
                    updated.selectedRoomId = room.id;
                    updated.selectedRoomNumber = room.roomNumber;
                    updated.selectedFloor = room.floor;
                    updated.roomType = room.roomType;
                    updated.pricePerNight = room.pricePerNight;
                    widget.onDataChanged(updated);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.accentGreen : AppColors.border,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentGreen : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            room.roomNumber,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                room.roomType.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${room.floor} • ${CurrencyFormatter.formatWithPerNight(room.pricePerNight)}',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    ],
  );
  }
}
