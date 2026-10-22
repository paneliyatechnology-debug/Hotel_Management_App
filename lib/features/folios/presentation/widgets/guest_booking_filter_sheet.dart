import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../dashboard/data/models/booking_list_query.dart';
import '../../../rooms/data/models/room_model.dart';

class GuestBookingFilterSheet extends StatefulWidget {
  final BookingListQuery query;
  final List<RoomModel> rooms;

  const GuestBookingFilterSheet({
    super.key,
    required this.query,
    required this.rooms,
  });

  static Future<BookingListQuery?> show(
    BuildContext context, {
    required BookingListQuery query,
    required List<RoomModel> rooms,
  }) {
    return showModalBottomSheet<BookingListQuery>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => GuestBookingFilterSheet(query: query, rooms: rooms),
    );
  }

  @override
  State<GuestBookingFilterSheet> createState() => _GuestBookingFilterSheetState();
}

class _GuestBookingFilterSheetState extends State<GuestBookingFilterSheet> {
  late String _bookingStatus;
  late String _paymentStatus;
  late String _roomId;
  late final TextEditingController _roomIdField;
  late final TextEditingController _bookingNumber;
  late final TextEditingController _primaryGuest;
  late final TextEditingController _guestName;
  late final TextEditingController _mobile;
  DateTime? _checkInFrom;
  DateTime? _checkInTo;
  DateTime? _checkOutFrom;
  DateTime? _checkOutTo;

  static const _statuses = <String, String>{
    '': 'Any',
    'CHECKED_IN': 'Checked In',
    'CHECKED_OUT': 'Checked Out',
    'CONFIRMED': 'Confirmed',
  };

  static const _payments = <String, String>{
    '': 'Any',
    'PENDING': 'Pending',
    'PAID': 'Paid',
    'PARTIAL': 'Partial',
  };

  @override
  void initState() {
    super.initState();
    final query = widget.query;
    _bookingStatus = _statuses.containsKey(query.bookingStatus) ? query.bookingStatus : '';
    _paymentStatus = _payments.containsKey(query.paymentStatus) ? query.paymentStatus : '';
    _roomId = query.roomId;
    _roomIdField = TextEditingController(text: query.roomId);
    _bookingNumber = TextEditingController(text: query.bookingNumber);
    _primaryGuest = TextEditingController(text: query.primaryGuestName);
    _guestName = TextEditingController(text: query.guestName);
    _mobile = TextEditingController(text: query.mobileNumber);
    _checkInFrom = _parseDay(query.checkInFrom);
    _checkInTo = _parseDay(query.checkInTo);
    _checkOutFrom = _parseDay(query.checkOutFrom);
    _checkOutTo = _parseDay(query.checkOutTo);
  }

  @override
  void dispose() {
    _roomIdField.dispose();
    _bookingNumber.dispose();
    _primaryGuest.dispose();
    _guestName.dispose();
    _mobile.dispose();
    super.dispose();
  }

  DateTime? _parseDay(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }

  String _formatDay(DateTime? value) {
    if (value == null) return '';
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  BookingListQuery _buildQuery() {
    return BookingListQuery(
      bookingStatus: _bookingStatus,
      paymentStatus: _paymentStatus,
      roomId: widget.rooms.isEmpty ? _roomIdField.text.trim() : _roomId,
      bookingNumber: _bookingNumber.text.trim(),
      primaryGuestName: _primaryGuest.text.trim(),
      guestName: _guestName.text.trim(),
      mobileNumber: _mobile.text.trim(),
      search: widget.query.search,
      checkInFrom: _formatDay(_checkInFrom),
      checkInTo: _formatDay(_checkInTo),
      checkOutFrom: _formatDay(_checkOutFrom),
      checkOutTo: _formatDay(_checkOutTo),
      page: 1,
      limit: widget.query.limit < 1 ? 10 : widget.query.limit,
    );
  }

  void _clear() {
    setState(() {
      _bookingStatus = '';
      _paymentStatus = '';
      _roomId = '';
      _roomIdField.clear();
      _bookingNumber.clear();
      _primaryGuest.clear();
      _guestName.clear();
      _mobile.clear();
      _checkInFrom = null;
      _checkInTo = null;
      _checkOutFrom = null;
      _checkOutTo = null;
    });
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) onPicked(DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final rooms = widget.rooms.where((room) => room.id.trim().isNotEmpty).toList();
    final knownRoom = rooms.any((room) => room.id == _roomId);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.86,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter Guests',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Blank fields stay off the request',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  children: [
                    _sectionLabel('Booking status'),
                    _choiceWrap(_statuses, _bookingStatus, (value) => setState(() => _bookingStatus = value)),
                    const SizedBox(height: 12),
                    _sectionLabel('Payment status'),
                    _choiceWrap(_payments, _paymentStatus, (value) => setState(() => _paymentStatus = value)),
                    const SizedBox(height: 12),
                    _sectionLabel('Room'),
                    if (rooms.isEmpty)
                      _textField(controller: _roomIdField, hint: 'Room ID')
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey(_roomId),
                        isExpanded: true,
                        initialValue: _roomId.isEmpty || knownRoom ? _roomId : '',
                        decoration: _inputDecoration('Any room'),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Any room')),
                          if (_roomId.isNotEmpty && !knownRoom)
                            DropdownMenuItem(value: _roomId, child: Text('Room $_roomId')),
                          ...rooms.map(
                            (room) => DropdownMenuItem(
                              value: room.id,
                              child: Text(
                                '${room.roomNumber} · ${room.roomType}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _roomId = value ?? ''),
                      ),
                    const SizedBox(height: 12),
                    _sectionLabel('Guest'),
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller: _primaryGuest,
                            hint: 'Primary guest',
                            fieldKey: const Key('guestFilterPrimaryGuest'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _textField(controller: _guestName, hint: 'Guest name'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _textField(controller: _bookingNumber, hint: 'Booking number'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _textField(
                            controller: _mobile,
                            hint: 'Mobile',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _sectionLabel('Check-in'),
                    Row(
                      children: [
                        Expanded(child: _dateChip('From', _checkInFrom, (value) => setState(() => _checkInFrom = value), () => setState(() => _checkInFrom = null))),
                        const SizedBox(width: 8),
                        Expanded(child: _dateChip('To', _checkInTo, (value) => setState(() => _checkInTo = value), () => setState(() => _checkInTo = null))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _sectionLabel('Check-out'),
                    Row(
                      children: [
                        Expanded(child: _dateChip('From', _checkOutFrom, (value) => setState(() => _checkOutFrom = value), () => setState(() => _checkOutFrom = null))),
                        const SizedBox(width: 8),
                        Expanded(child: _dateChip('To', _checkOutTo, (value) => setState(() => _checkOutTo = value), () => setState(() => _checkOutTo = null))),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clear,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(
                          'Clear',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        key: const Key('guestFilterApply'),
                        onPressed: () => Navigator.of(context).pop(_buildQuery()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                        ),
                      ),
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

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: const Color(0xFF0F766E),
        ),
      ),
    );
  }

  Widget _choiceWrap(Map<String, String> options, String selected, ValueChanged<String> onSelected) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.entries.map((entry) {
        final isSelected = selected == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: isSelected,
          visualDensity: VisualDensity.compact,
          selectedColor: const Color(0xFF0F766E),
          backgroundColor: const Color(0xFFF8FAFC),
          side: BorderSide(color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
          onSelected: (_) => onSelected(entry.key),
        );
      }).toList(),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.4),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    Key? fieldKey,
  }) {
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
      decoration: _inputDecoration(hint),
    );
  }

  Widget _dateChip(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPicked,
    VoidCallback onClear,
  ) {
    final text = value == null ? label : _formatDay(value);
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pickDate(current: value, onPicked: onPicked),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0F766E)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: value == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (value != null)
                GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
