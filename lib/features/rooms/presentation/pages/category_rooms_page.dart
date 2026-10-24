import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../check_in_wizard/presentation/bloc/check_in_bloc.dart';
import '../../../check_in_wizard/presentation/bloc/check_in_event.dart';
import '../../../check_in_wizard/presentation/pages/check_in_wizard_page.dart';
import '../../../dashboard/data/models/booking_list_query.dart';
import '../../../dashboard/data/models/guest_folio_model.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_event.dart';
import '../../../dashboard/presentation/bloc/dashboard_state.dart';
import '../../../dashboard/presentation/widgets/modern_room_bottom_sheet.dart';
import '../../../check_in_wizard/data/models/check_in_form_data.dart';
import '../../../folios/presentation/widgets/checkout_settlement_dialog.dart';
import '../../data/models/room_model.dart';

class CategoryRoomsPage extends StatefulWidget {
  final String categoryName;
  final String? roomTypeId;

  const CategoryRoomsPage({
    super.key,
    required this.categoryName,
    this.roomTypeId,
  });

  @override
  State<CategoryRoomsPage> createState() => _CategoryRoomsPageState();
}

class _CategoryRoomsPageState extends State<CategoryRoomsPage> {
  String _selectedFilter = 'All';
  String _selectedFloor = 'All';
  String _searchQuery = '';
  bool _isSearchOpen = false;
  final Set<String> _selectedAvailableRoomIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final folios = context.read<DashboardBloc>().state.folios;
      final hasInHouse = folios.any((folio) => folio.status == FolioStatus.inHouse);
      if (hasInHouse) return;
      // Only fetch when In-House list is empty — avoids repeat category API churn.
      context.read<DashboardBloc>().add(
            LoadBookingsEvent(
              query: const BookingListQuery(bookingStatus: 'CHECKED_IN', limit: 50),
              showLoading: false,
            ),
          );
    });
  }

  void _toggleAvailableRoom(RoomModel room) {
    if (room.status != RoomStatus.available) return;
    setState(() {
      if (_selectedAvailableRoomIds.contains(room.id)) {
        _selectedAvailableRoomIds.remove(room.id);
      } else {
        _selectedAvailableRoomIds.add(room.id);
      }
    });
  }

  List<RoomModel> _selectedAvailableRooms(List<RoomModel> categoryRooms) {
    return categoryRooms
        .where((room) =>
            room.status == RoomStatus.available && _selectedAvailableRoomIds.contains(room.id))
        .toList();
  }

  void _openGuestForm(RoomModel room) {
    _openGuestFormForRooms([room]);
  }

  void _openGuestFormForRooms(List<RoomModel> rooms) {
    if (rooms.isEmpty) return;
    context.read<CheckInBloc>().add(
          InitCheckInWizardEvent(
            preselectedRoom: rooms.first,
            preselectedRooms: rooms,
          ),
        );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CheckInWizardPage(),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() => _selectedAvailableRoomIds.clear());
    });
  }

  Future<void> _openUpdateBooking(RoomModel room) async {
    _showLoadingDialog();
    final booking = await _fetchBookingForRoom(room);
    if (!mounted) return;
    Navigator.of(context).pop(); // loading
    if (booking == null) {
      AppSnackBar.showError(context, 'Could not load this booking.', title: 'Update booking');
      return;
    }

    context.read<CheckInBloc>().add(
          InitCheckInWizardEvent(
            preselectedRoom: room,
            existingForm: CheckInFormData.fromFolio(booking, room),
          ),
        );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckInWizardPage()),
    );
  }

  /// Prefer rooms API `current_booking_id`, then folio id / booking id.
  String? _roomBookingApiId(RoomModel room, [GuestFolioModel? folio]) {
    final fromRoom = (room.currentBookingId ?? room.currentGuestFolioId ?? '').trim();
    if (fromRoom.isNotEmpty && fromRoom.toLowerCase() != 'null') return fromRoom;
    if (folio == null) return null;
    final id = folio.id.trim();
    if (int.tryParse(id) != null) return id;
    final bookingId = (folio.bookingId ?? '').trim();
    if (int.tryParse(bookingId) != null) return bookingId;
    return bookingId.isNotEmpty ? bookingId : null;
  }

  Future<void> _checkoutOccupiedRoom(RoomModel room) async {
    _showLoadingDialog();
    // GET /api/v1/bookings/{current_booking_id}
    final booking = await _fetchBookingForRoom(room);
    if (!mounted) return;
    Navigator.of(context).pop(); // loading
    if (booking == null) {
      AppSnackBar.showError(
        context,
        'No checked-in guest was found for this room.',
        title: 'Checkout',
      );
      return;
    }
    CheckoutSettlementDialog.show(context, booking);
  }

  void _showLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }

  /// Loads booking via GET /api/v1/bookings/{current_booking_id}.
  Future<GuestFolioModel?> _fetchBookingForRoom(RoomModel room) async {
    final repo = context.read<DashboardBloc>().repository;
    final bookingId = _roomBookingApiId(room);
    if (bookingId != null && bookingId.isNotEmpty) {
      try {
        final booking = await repo.fetchBooking(bookingId);
        if (booking != null) return booking;
      } catch (_) {}
    }

    // Fallback: match checked-in list, then fetch by that booking id.
    final folio = await _resolveInHouseFolio(room);
    if (folio == null) return null;
    final fallbackId = _roomBookingApiId(room, folio);
    if (fallbackId == null || fallbackId.isEmpty) return folio;
    try {
      return await repo.fetchBooking(fallbackId) ?? folio;
    } catch (_) {
      return folio;
    }
  }

  Future<GuestFolioModel?> _resolveInHouseFolio(RoomModel room) async {
    final bloc = context.read<DashboardBloc>();
    final bookingId = _roomBookingApiId(room);
    if (bookingId != null && bookingId.isNotEmpty) {
      try {
        final byId = await bloc.repository.fetchBooking(bookingId);
        if (byId != null) return byId;
      } catch (_) {}
    }
    final local = _checkedInFolioFor(room, bloc.state.folios);
    if (local != null) return local;
    final repo = bloc.repository;
    try {
      final byRoom = await repo.fetchBookings(
        status: 'CHECKED_IN',
        roomId: room.id,
        limit: 50,
      );
      final matched = _checkedInFolioFor(room, byRoom);
      if (matched != null) return matched;
      final allInHouse = await repo.fetchBookings(status: 'CHECKED_IN', limit: 50);
      return _checkedInFolioFor(room, allInHouse);
    } catch (_) {
      return null;
    }
  }

  GuestFolioModel? _checkedInFolioFor(RoomModel room, List<GuestFolioModel> folios) {
    final roomDigits = room.roomNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final bookingKey = (room.currentBookingId ?? room.currentGuestFolioId ?? '').trim();
    for (final folio in folios) {
      if (folio.status != FolioStatus.inHouse) continue;
      if (bookingKey.isNotEmpty &&
          (folio.id == bookingKey || folio.bookingId == bookingKey)) {
        return folio;
      }
      if (room.id.isNotEmpty && folio.roomId != null && folio.roomId == room.id) {
        return folio;
      }
      final folioRoom = folio.assignedRoom.replaceAll(RegExp(r'[^0-9]'), '');
      if (roomDigits.isNotEmpty && folioRoom == roomDigits) return folio;
    }
    return null;
  }

  String _hotelName(BuildContext context) {
    try {
      final name = context.read<AuthBloc>().state.user?.hotel.name.trim() ?? '';
      if (name.isNotEmpty) return name;
    } catch (_) {}
    return 'MYOWNPMS';
  }

  String get _displayCategoryName {
    final words = widget.categoryName.trim().split(RegExp(r'\s+'));
    return words
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  IconData get _categoryIcon {
    final name = widget.categoryName.toLowerCase();
    if (name.contains('family')) {
      return Icons.people_alt_rounded;
    } else if (name.contains('suite')) {
      return Icons.meeting_room_rounded;
    } else if (name.contains('deluxe')) {
      return Icons.meeting_room_rounded;
    } else if (name.contains('penthouse') || name.contains('vip') || name.contains('presidential')) {
      return Icons.workspace_premium_rounded;
    }
    return Icons.hotel_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        // Filter rooms matching this category ID or category name.
        // Trust rooms API status: OCCUPIED → Edit + Checkout buttons.
        final categoryRooms = state.allRooms.where((r) {
          if (widget.roomTypeId != null && widget.roomTypeId!.isNotEmpty && r.roomTypeId == widget.roomTypeId) {
            return true;
          }
          return r.roomType.trim().toLowerCase() == widget.categoryName.trim().toLowerCase();
        }).toList();

        final totalCount = categoryRooms.length;
        final occupiedCount = categoryRooms.where((r) => r.status == RoomStatus.occupied).length;
        final availableCount = categoryRooms.where((r) => r.status == RoomStatus.available).length;
        final cleaningCount = categoryRooms.where((r) => r.status == RoomStatus.cleaning).length;
        final maintenanceCount = categoryRooms.where((r) => r.status == RoomStatus.maintenance).length;

        List<RoomModel> filteredRooms = categoryRooms;
        if (_selectedFilter == 'Available') {
          filteredRooms = categoryRooms.where((r) => r.status == RoomStatus.available).toList();
        } else if (_selectedFilter == 'Occupied') {
          filteredRooms = categoryRooms.where((r) => r.status == RoomStatus.occupied).toList();
        } else if (_selectedFilter == 'Cleaning') {
          filteredRooms = categoryRooms.where((r) => r.status == RoomStatus.cleaning).toList();
        } else if (_selectedFilter == 'Maintenance') {
          filteredRooms = categoryRooms.where((r) => r.status == RoomStatus.maintenance).toList();
        }

        final floors = _floorsOf(filteredRooms);
        final activeFloor = floors.any((floor) => floor.floor == _selectedFloor) ? _selectedFloor : 'All';
        if (activeFloor != 'All') {
          filteredRooms = filteredRooms.where((room) => room.floor == activeFloor).toList();
        }

        // Apply search query if present
        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.trim().toLowerCase();
          filteredRooms = filteredRooms.where((r) {
            return r.roomNumber.toLowerCase().contains(query) ||
                r.floor.toLowerCase().contains(query) ||
                (r.currentGuestName != null && r.currentGuestName!.toLowerCase().contains(query));
          }).toList();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            toolbarHeight: 64,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF0F172A)),
                ),
              ),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_categoryIcon, color: const Color(0xFF0F766E), size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _displayCategoryName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Opacity(
                        opacity: 0,
                        child: SizedBox(
                          width: 0,
                          height: 0,
                          child: Text('${_hotelName(context)} • Room Number Inventory'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Rooms',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '$totalCount',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F766E),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        const Opacity(
                          opacity: 0.0,
                          child: Text(
                            'AVAILABLE ROOM NUMBERS',
                            style: TextStyle(fontSize: 1),
                          ),
                        ),
                        Text(
                          'ROOM NUMBERS (${filteredRooms.length})',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isSearchOpen = !_isSearchOpen),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _isSearchOpen ? const Color(0xFFECFDF5) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isSearchOpen ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.search_rounded,
                            size: 16,
                            color: _isSearchOpen ? const Color(0xFF0F766E) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (_isSearchOpen) ...[
                const SizedBox(height: 8),
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search room number or guest name...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 14),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
              ],

              const SizedBox(height: 6),

              // 3. Filter Pills Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill('All', totalCount),
                    _buildFilterPill('Available', availableCount),
                    _buildFilterPill('Occupied', occupiedCount),
                    _buildFilterPill('Cleaning', cleaningCount),
                    _buildFilterPill('Maintenance', maintenanceCount),
                  ],
                ),
              ),
              if (floors.isNotEmpty) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFloorPill('All Floors', floors.fold(0, (sum, floor) => sum + floor.count), 'All', activeFloor),
                      for (final floor in floors)
                        _buildFloorPill(floor.floor, floor.count, floor.floor, activeFloor),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 6),

              // 4. Room Units List
              if (filteredRooms.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.meeting_room_outlined, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        'No room units match this filter.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: filteredRooms.map((room) => _buildRoomCard(context, room, state.folios)).toList(),
                ),
              if (_selectedAvailableRoomIds.isNotEmpty) const SizedBox(height: 72),
            ],
          ),
          bottomNavigationBar: _selectedAvailableRoomIds.isEmpty
              ? null
              : SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_selectedAvailableRoomIds.length} room${_selectedAvailableRoomIds.length == 1 ? '' : 's'} selected',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _selectedAvailableRoomIds.clear()),
                          child: Text(
                            'Clear',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            final selected = _selectedAvailableRooms(categoryRooms);
                            _openGuestFormForRooms(selected);
                          },
                          child: Text(
                            'Check In (${_selectedAvailableRoomIds.length})',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  List<({String floor, int count})> _floorsOf(List<RoomModel> rooms) {
    final counts = <String, int>{};
    for (final room in rooms) {
      final floor = room.floor.trim();
      if (floor.isEmpty) continue;
      counts[floor] = (counts[floor] ?? 0) + 1;
    }
    final names = counts.keys.toList()
      ..sort((a, b) {
        final aNumber = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), ''));
        final bNumber = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), ''));
        if (aNumber != null && bNumber != null) return aNumber.compareTo(bNumber);
        return a.compareTo(b);
      });
    return [for (final name in names) (floor: name, count: counts[name]!)];
  }

  Widget _buildFloorPill(String label, int count, String value, String activeFloor) {
    final isSelected = activeFloor == value;
    return InkWell(
      onTap: () => setState(() => _selectedFloor = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, int count) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x220F766E),
                    blurRadius: 4,
                    offset: Offset(0, 1.5),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          '$label ($count)',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room, List<GuestFolioModel> folios) {
    // Rooms API `status: OCCUPIED` → show Edit + Checkout.
    final isOccupied = room.status == RoomStatus.occupied;
    final isAvailable = room.status == RoomStatus.available;
    final isCleaning = room.status == RoomStatus.cleaning;
    final isMaintenance = room.status == RoomStatus.maintenance;

    Color squircleBg = const Color(0xFFE6F7F2);
    Color squircleColor = const Color(0xFF0F766E);
    Color badgeColor = const Color(0xFF059669);
    IconData badgeIcon = Icons.check_circle_rounded;
    String badgeLabel = 'AVAILABLE';

    if (isOccupied) {
      squircleBg = AppColors.primarySurface;
      squircleColor = AppColors.primary;
      badgeColor = AppColors.primary;
      badgeIcon = Icons.person_rounded;
      badgeLabel = 'OCCUPIED';
    } else if (isCleaning) {
      squircleBg = const Color(0xFFFFFBEB);
      squircleColor = const Color(0xFFD97706);
      badgeColor = const Color(0xFFD97706);
      badgeIcon = Icons.cleaning_services_rounded;
      badgeLabel = 'CLEANING';
    } else if (isMaintenance) {
      squircleBg = const Color(0xFFFEF2F2);
      squircleColor = const Color(0xFFDC2626);
      badgeColor = const Color(0xFFDC2626);
      badgeIcon = Icons.build_rounded;
      badgeLabel = 'MAINTENANCE';
    }

    final digits = room.roomNumber.replaceAll('#', '').replaceAll('Room', '').trim();
    final roomNumber = room.roomNumber.trim().startsWith('#') ? room.roomNumber.trim() : '#$digits';
    final floorDigits = room.floor.replaceAll(RegExp(r'[^0-9]'), '');
    final floorLabel = floorDigits.isEmpty ? room.floor.trim().toLowerCase() : 'floor $floorDigits';
    final folioGuest = _checkedInFolioFor(room, folios)?.guestName.trim() ?? '';
    final roomGuest = room.currentGuestName?.trim() ?? '';
    final guestName = roomGuest.isNotEmpty ? roomGuest : folioGuest;
    final detail = isOccupied && guestName.isNotEmpty ? guestName : room.bedInfoLabel;
    final isMultiSelected = isAvailable && _selectedAvailableRoomIds.contains(room.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isMultiSelected ? const Color(0xFFF0FDFA) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMultiSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
          width: isMultiSelected ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            if (isAvailable) {
              _toggleAvailableRoom(room);
            } else if (isOccupied) {
              _checkoutOccupiedRoom(room);
            } else if (isCleaning) {
              _confirmMarkAvailable(room);
            } else {
              ModernRoomBottomSheet.show(
                context: context,
                room: room,
                onStatusChanged: (newStatus) {
                  context.read<DashboardBloc>().add(
                        ChangeRoomStatusDashboardEvent(
                          roomId: room.id,
                          newStatus: newStatus,
                        ),
                      );
                },
                onExpressCheckIn: () => _openGuestForm(room),
              );
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            // Identical left padding for all rooms → bed icons stay aligned.
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bed icon container — checkbox only stacks on its top-left
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: squircleBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.bed_rounded, size: 22, color: squircleColor),
                          ),
                          ExcludeSemantics(
                            child: Opacity(
                              opacity: 0,
                              child: SizedBox(
                                width: 0,
                                height: 0,
                                child: Text(roomNumber),
                              ),
                            ),
                          ),
                          if (isAvailable)
                            Positioned(
                              top: -6,
                              left: -6,
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: isMultiSelected,
                                  onChanged: (_) => _toggleAvailableRoom(room),
                                  activeColor: const Color(0xFF0F766E),
                                  checkColor: Colors.white,
                                  fillColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return const Color(0xFF0F766E);
                                    }
                                    return Colors.transparent;
                                  }),
                                  side: const BorderSide(color: Color(0xFF0F766E), width: 1.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Room $digits - $floorLabel',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(badgeIcon, size: 13, color: badgeColor),
                              const SizedBox(width: 4),
                              Text(
                                badgeLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.formatWithPerNight(room.pricePerNight),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    isOccupied
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _openUpdateBooking(room),
                                behavior: HitTestBehavior.opaque,
                                child: _roomActionButton(
                                  label: 'Edit',
                                  icon: Icons.edit_outlined,
                                  outlined: true,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _checkoutOccupiedRoom(room),
                                behavior: HitTestBehavior.opaque,
                                child: _roomActionButton(
                                  label: 'Checkout',
                                  icon: Icons.arrow_back_rounded,
                                  checkout: true,
                                ),
                              ),
                            ],
                          )
                        : isAvailable
                            ? GestureDetector(
                                onTap: () {
                                  final selected = _selectedAvailableRoomIds.isEmpty
                                      ? [room]
                                      : [
                                          ..._selectedAvailableRooms(
                                            context.read<DashboardBloc>().state.allRooms,
                                          ),
                                          if (!_selectedAvailableRoomIds.contains(room.id)) room,
                                        ];
                                  final unique = <RoomModel>[];
                                  for (final item in selected) {
                                    if (unique.any((r) => r.id == item.id)) continue;
                                    unique.add(item);
                                  }
                                  _openGuestFormForRooms(unique.isEmpty ? [room] : unique);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: _roomActionButton(
                                  label: 'Check In',
                                  icon: Icons.arrow_forward_rounded,
                                  iconAfterLabel: true,
                                ),
                              )
                            : isCleaning
                                ? _roomActionButton(
                                    label: 'Mark as Available',
                                    icon: Icons.check_circle_rounded,
                                  )
                                : _roomActionButton(
                                    label: 'Manage',
                                    icon: Icons.tune_rounded,
                                  ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmMarkAvailable(RoomModel room) async {
    final confirmed = await showMarkRoomAvailableDialog(
      context,
      roomNumber: room.roomNumber,
    );
    if (!confirmed || !mounted) return;
    context.read<DashboardBloc>().add(
          ChangeRoomStatusDashboardEvent(
            roomId: room.id,
            newStatus: RoomStatus.available,
          ),
        );
  }

  Widget _roomActionButton({
    required String label,
    required IconData icon,
    bool iconAfterLabel = false,
    bool checkout = false,
    bool outlined = false,
  }) {
    final color = checkout ? const Color(0xFFDC2626) : AppColors.primary;
    final foreground = checkout || outlined ? color : Colors.white;
    final iconWidget = Icon(icon, size: 13, color: foreground);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: checkout || outlined ? Colors.white : AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        border: checkout || outlined ? Border.all(color: color, width: 1.2) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!iconAfterLabel) ...[
            iconWidget,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
          if (iconAfterLabel) ...[
            const SizedBox(width: 4),
            iconWidget,
          ],
        ],
      ),
    );
  }
}
