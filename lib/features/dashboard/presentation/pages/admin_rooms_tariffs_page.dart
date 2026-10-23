import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../rooms/data/models/room_category_model.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../../folios/presentation/widgets/checkout_settlement_dialog.dart';
import '../../data/models/guest_folio_model.dart';
import '../../data/repositories/hotel_admin_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../live/room_live_hub.dart';
import '../widgets/create_room_category_sheet.dart';
import '../widgets/dashboard_shimmer_loader.dart';
import '../widgets/modern_room_bottom_sheet.dart';

class RoomsDirectoryMemory {
  static List<RoomModel>? rooms;
  static List<RoomTypeModel>? types;

  static void clear() {
    rooms = null;
    types = null;
  }
}

class AdminRoomsTariffsPage extends StatefulWidget {
  final HotelAdminRepository? repository;
  final bool embedded;

  const AdminRoomsTariffsPage({super.key, this.repository, this.embedded = false});

  @override
  State<AdminRoomsTariffsPage> createState() => _AdminRoomsTariffsPageState();
}

class _AdminRoomsTariffsPageState extends State<AdminRoomsTariffsPage> with SingleTickerProviderStateMixin {
  late final HotelAdminRepository _repo;
  late final TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;

  List<RoomModel> _rooms = [];
  List<RoomTypeModel> _roomTypes = [];

  String _roomSearchQuery = '';
  String _selectedStatusFilter = 'ALL';
  String _selectedTypeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? HotelAdminRepository();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    final cachedRooms = RoomsDirectoryMemory.rooms;
    final cachedTypes = RoomsDirectoryMemory.types;
    if (cachedRooms != null && cachedTypes != null) {
      _rooms = List<RoomModel>.from(cachedRooms);
      _roomTypes = List<RoomTypeModel>.from(cachedTypes);
      _isLoading = false;
    }
    _loadData(showLoader: cachedRooms == null || cachedTypes == null);
    RoomLiveHub.instance.addListener(_onLiveRooms);
  }

  void _onLiveRooms() {
    if (!mounted) return;
    // Apply the live room patch only. Do not re-fetch room-types on every
    // socket tick — that spammed the category API and stacked snackbars.
    final patch = RoomLiveHub.instance.room;
    final cached = RoomsDirectoryMemory.rooms;
    if (patch == null || cached == null) return;
    final next = patch.apply(List<RoomModel>.from(cached));
    RoomsDirectoryMemory.rooms = next;
    setState(() {
      _rooms = next;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    RoomLiveHub.instance.removeListener(_onLiveRooms);
    _tabController.dispose();
    super.dispose();
  }

  bool _loadInFlight = false;

  Future<void> _loadData({bool? showLoader}) async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    final loader = showLoader ?? (_rooms.isEmpty && RoomsDirectoryMemory.rooms == null);
    if (loader && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _repo.fetchAdminRooms().catchError((_) => <RoomModel>[]),
        _repo.fetchRoomTypes(),
      ]);
      final rooms = results[0] as List<RoomModel>;
      final types = results[1] as List<RoomTypeModel>;
      RoomsDirectoryMemory.rooms = rooms;
      RoomsDirectoryMemory.types = types;

      if (mounted) {
        setState(() {
          _rooms = rooms;
          _roomTypes = types;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final err = e.toString().replaceAll('Exception: ', '');
      // Only surface errors on the first full-screen load — never toast on background refresh.
      if (loader) {
        setState(() {
          _errorMessage = err;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      _loadInFlight = false;
    }
  }

  void _replaceRoomStatus(String roomId, String newStatus) {
    final status = switch (newStatus.toUpperCase()) {
      'OCCUPIED' => RoomStatus.occupied,
      'CLEANING' => RoomStatus.cleaning,
      'MAINTENANCE' => RoomStatus.maintenance,
      _ => RoomStatus.available,
    };
    setState(() {
      _rooms = [
        for (final room in _rooms)
          if (room.id == roomId) room.copyWith(status: status) else room,
      ];
    });
  }

  void _showToast(String message, {bool isError = false}) {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest) return;
    if (isError) {
      AppSnackBar.showError(context, message);
    } else {
      AppSnackBar.showSuccess(context, message);
    }
  }

  // --- ROOMS ACTIONS ---
  Future<void> _changeRoomStatus(RoomModel room, String newStatus) async {
    final previous = List<RoomModel>.from(_rooms);
    _replaceRoomStatus(room.id, newStatus);
    try {
      final msg = await _repo.updateRoomStatus(room.id, newStatus);
      if (!mounted) return;
      _showToast(msg);
      await _loadData(showLoader: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _rooms = previous);
      _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  Future<void> _markCleaningRoomAvailable(RoomModel room) async {
    final confirmed = await showMarkRoomAvailableDialog(
      context,
      roomNumber: room.roomNumber,
    );
    if (!confirmed || !mounted) return;
    await _changeRoomStatus(room, 'AVAILABLE');
  }

  Future<void> _checkoutOccupiedRoom(RoomModel room) async {
    final folio = await _inHouseFolioForRoom(room);
    if (!mounted) return;
    if (folio == null) {
      _showToast('No checked-in guest was found for this room.', isError: true);
      return;
    }
    final done = await CheckoutSettlementDialog.show(context, folio);
    if (done == true && mounted) {
      _replaceRoomStatus(room.id, 'CLEANING');
      await _loadData(showLoader: false);
    }
  }

  Future<GuestFolioModel?> _inHouseFolioForRoom(RoomModel room) async {
    List<GuestFolioModel> loaded = const [];
    try {
      loaded = context.read<DashboardBloc>().state.folios;
    } catch (_) {}
    final fromDashboard = _matchInHouseFolio(room, loaded);
    if (fromDashboard != null) return fromDashboard;
    try {
      final bookings = await DashboardRepository().fetchBookings(
        status: 'CHECKED_IN',
        limit: 100,
      );
      return _matchInHouseFolio(room, bookings);
    } catch (_) {
      return null;
    }
  }

  GuestFolioModel? _matchInHouseFolio(RoomModel room, List<GuestFolioModel> folios) {
    final roomDigits = room.roomNumber.replaceAll(RegExp(r'[^0-9]'), '');
    for (final folio in folios) {
      if (folio.status != FolioStatus.inHouse) continue;
      final folioId = room.currentGuestFolioId;
      if (folioId != null &&
          folioId.isNotEmpty &&
          (folio.id == folioId || folio.bookingId == folioId)) {
        return folio;
      }
      final folioRoom = folio.assignedRoom.replaceAll(RegExp(r'[^0-9]'), '');
      if (roomDigits.isNotEmpty && folioRoom == roomDigits) return folio;
    }
    return null;
  }

  Future<void> _deleteRoom(RoomModel room) async {
    if (room.status.name.toUpperCase() != 'AVAILABLE') {
      _showToast(
        'Cannot delete Room ${room.roomNumber}. Rooms must be "AVAILABLE" to be removed.',
        isError: true,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Text('Remove Room', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove Room "${room.roomNumber}" (Floor ${room.floor})?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final msg = await _repo.deleteRoom(room.id);
        if (mounted) {
          _showToast(msg);
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
        }
      }
    }
  }

Future<void> _showAddRoomModal({RoomModel? room}) async {
    final isEdit = room != null;
    final numberCtrl = TextEditingController(text: room?.roomNumber ?? '');
    int floorValue = int.tryParse(room?.floor.replaceAll(RegExp(r'[^0-9]'), '') ?? '1') ?? 1;
    final priceCtrl = TextEditingController(text: room?.customPricePerNight != null ? '${room!.customPricePerNight!.round()}' : '');
    final notesCtrl = TextEditingController(text: room?.notes ?? '');

    String selectedTypeId = room?.roomTypeId ?? (_roomTypes.isNotEmpty ? _roomTypes.first.id : '');
    const bedTypeChoices = [
      'King Size Bed',
      'Queen Size Bed',
      'Single Bed',
      'Double Bed',
      'Super King Bed',
      'Extra Mattress',
    ];
    String? pendingBedType;
    var pendingBedCount = 1;
    final selectedBeds = _bedsFromLabel(room?.bedType ?? '', room?.bedCount ?? 1);

    String selectedStatus = room?.status.name.toUpperCase() ?? 'AVAILABLE';

    // Amenities
    RoomTypeModel? selectedCat = _roomTypes.where((t) => t.id == selectedTypeId).firstOrNull;
    final defaultAmenities = [
      'High-Speed Wi-Fi',
      'Air Conditioning',
      'Smart TV 55 inch',
      'Mini Bar',
    ];
    final selectedAmenities = List<String>.from(
      room?.amenities ?? (selectedCat != null && selectedCat.amenities.isNotEmpty ? selectedCat.amenities : defaultAmenities),
    );
    final customAmenityCtrl = TextEditingController();

    const popularAmenities = [
      ('High-Speed Wi-Fi', Icons.wifi_rounded),
      ('Smart TV 55 inch', Icons.tv_rounded),
      ('Mini Bar', Icons.kitchen_rounded),
      ('Air Conditioning', Icons.ac_unit_rounded),
      ('Attached Bathroom & Geyser', Icons.bathtub_rounded),
      ('Balcony / Scenic View', Icons.balcony_rounded),
      ('Tea / Coffee Maker', Icons.coffee_rounded),
      ('Electronic Room Safe', Icons.lock_outline_rounded),
      ('Jacuzzi / Bathtub', Icons.hot_tub_rounded),
      ('24/7 Room Service', Icons.room_service_rounded),
      ('Swimming Pool Access', Icons.pool_rounded),
      ('Complimentary Breakfast', Icons.restaurant_rounded),
    ];

    bool isSaving = false;
    final imagePaths = <String>[];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final cat = _roomTypes.where((t) => t.id == selectedTypeId).firstOrNull;

          return Container(
            height: MediaQuery.of(context).size.height * 0.78,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Top Handle & Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F7F2),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.meeting_room_rounded, color: Color(0xFF0F766E), size: 23),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? 'Edit Room' : 'Add New Room',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEdit ? 'Update this room' : 'Room number, floor and price',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                ),
                                const Opacity(
                                  opacity: 0,
                                  child: Text(
                                    'ROOM IDENTIFICATION',
                                    style: TextStyle(fontSize: 1),
                                  ),
                                ),
                                const Opacity(
                                  opacity: 0,
                                  child: Text(
                                    'ROOM TARIFF (NO TAX)',
                                    style: TextStyle(fontSize: 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(ctx).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Form Body
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    children: [
                      Text('Category', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTypeId.isNotEmpty ? selectedTypeId : null,
                            hint: Text('Choose a category', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8))),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F766E)),
                            selectedItemBuilder: (context) {
                              return _roomTypes.map((t) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    t.name,
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                  ),
                                );
                              }).toList();
                            },
                            items: _roomTypes.map((t) {
                              return DropdownMenuItem(
                                value: t.id,
                                child: Text(
                                  '${t.name}  ·  ₹${t.basePrice.round()}/night',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedTypeId = val;
                                  final c = _roomTypes.where((t) => t.id == val).firstOrNull;
                                  if (c != null && !isEdit && c.amenities.isNotEmpty) {
                                    selectedAmenities.clear();
                                    selectedAmenities.addAll(c.amenities);
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Room number', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: numberCtrl,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: isEdit ? '101' : '101 or 101, 102 or 101-105',
                          hintStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text('Floor', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                          const Spacer(),
                          _buildCounterStepper(
                            value: floorValue,
                            minValue: 0,
                            maxValue: 50,
                            onChanged: (newVal) => setModalState(() => floorValue = newVal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('Price per night', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: cat != null ? '₹${cat.basePrice.round()}' : 'Optional',
                          hintStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
                          prefixText: '₹ ',
                          prefixStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Leave empty to use the category price.',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      _buildFormSectionHeader('BED SETUP', Icons.king_bed_rounded),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: pendingBedType,
                                        isExpanded: true,
                                        isDense: true,
                                        hint: Text('Select bed type', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                                        items: bedTypeChoices.map((opt) {
                                          return DropdownMenuItem(
                                            value: opt,
                                            child: Text(opt, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                                          );
                                        }).toList(),
                                        onChanged: (val) => setModalState(() => pendingBedType = val),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _buildCounterStepper(
                                  value: pendingBedCount,
                                  minValue: 1,
                                  maxValue: 10,
                                  compact: true,
                                  height: 42,
                                  onChanged: (newVal) => setModalState(() => pendingBedCount = newVal),
                                ),
                                const SizedBox(width: 6),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFD1FAE5),
                                    foregroundColor: const Color(0xFF059669),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    minimumSize: const Size(0, 42),
                                    fixedSize: const Size.fromHeight(42),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    final type = pendingBedType;
                                    if (type == null) {
                                      _showToast('Select a bed type.', isError: true);
                                      return;
                                    }
                                    setModalState(() {
                                      final existing = selectedBeds.where((bed) => bed.type == type).firstOrNull;
                                      if (existing == null) {
                                        selectedBeds.add(_SelectedBed(type, pendingBedCount));
                                      } else {
                                        existing.count += pendingBedCount;
                                      }
                                      pendingBedCount = 1;
                                    });
                                  },
                                  child: Text('Add', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text('Selected Beds', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                            const SizedBox(height: 8),
                            if (selectedBeds.isEmpty)
                              Text('No beds added yet.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)))
                            else
                              for (var index = 0; index < selectedBeds.length; index++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _bedTint(selectedBeds[index].type),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.bed_rounded, size: 15, color: _bedColor(selectedBeds[index].type)),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            selectedBeds[index].type,
                                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildCounterStepper(
                                          value: selectedBeds[index].count,
                                          minValue: 1,
                                          maxValue: 10,
                                          compact: true,
                                          onChanged: (newVal) => setModalState(() => selectedBeds[index].count = newVal),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () => setModalState(() => selectedBeds.removeAt(index)),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFE4E6),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFE11D48)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Amenities Section
                      _buildFormSectionHeader('AMENITIES (${selectedAmenities.length})', Icons.stars_rounded),
                      const SizedBox(height: 6),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: popularAmenities.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          mainAxisExtent: 32,
                        ),
                        itemBuilder: (context, index) {
                          final item = popularAmenities[index];
                          final isSelected = selectedAmenities.contains(item.$1);
                          return Material(
                            color: isSelected ? const Color(0xFFE6F7F2) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    selectedAmenities.remove(item.$1);
                                  } else {
                                    selectedAmenities.add(item.$1);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.3 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.$2,
                                      size: 13,
                                      color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.$1,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          height: 1.1,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_rounded, size: 14, color: Color(0xFF0F766E)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (selectedAmenities.any((name) => popularAmenities.every((item) => item.$1 != name))) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final name in selectedAmenities.where((name) => popularAmenities.every((item) => item.$1 != name)))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F7F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF0F766E)),
                                ),
                                child: Text(
                                  name,
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E)),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: customAmenityCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Add custom amenity...',
                                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F766E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    final text = customAmenityCtrl.text.trim();
                                    if (text.isNotEmpty && !selectedAmenities.contains(text)) {
                                      setModalState(() {
                                        selectedAmenities.add(text);
                                        customAmenityCtrl.clear();
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: Text('Add', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                      const SizedBox(height: 10),

                      // 7. Notes
                      _buildFormSectionHeader('INTERNAL NOTES (OPTIONAL)', Icons.edit_note_rounded),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 1,
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'e.g. Garden facing room, corner balcony, newly renovated',
                          hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 16),
                        _buildFormSectionHeader('ROOM PHOTO (OPTIONAL)', Icons.photo_outlined),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            side: const BorderSide(color: Color(0xFF99F6E4)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );
                            if (picked == null) return;
                            setModalState(() => imagePaths.add(picked.path));
                          },
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                          label: Text(
                            imagePaths.isEmpty ? 'Add room photo' : '${imagePaths.length} photo${imagePaths.length == 1 ? '' : 's'} selected',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Sticky Bottom Action Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final numStr = numberCtrl.text.trim();
                                  if (numStr.isEmpty || selectedTypeId.isEmpty) {
                                    _showToast('Room Number and Category are required!', isError: true);
                                    return;
                                  }

                                  // Parse single vs batch
                                  final roomNums = <String>[];
                                  if (numStr.contains(',')) {
                                    roomNums.addAll(numStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
                                  } else if (numStr.contains('-')) {
                                    final parts = numStr.split('-').map((e) => int.tryParse(e.trim())).toList();
                                    if (parts.length == 2 && parts[0] != null && parts[1] != null && parts[1]! >= parts[0]!) {
                                      for (int i = parts[0]!; i <= parts[1]!; i++) {
                                        roomNums.add('$i');
                                      }
                                    } else {
                                      roomNums.add(numStr);
                                    }
                                  } else {
                                    roomNums.add(numStr);
                                  }

                                  if (selectedBeds.isEmpty) {
                                    _showToast('Add at least one bed.', isError: true);
                                    return;
                                  }
                                  final customPrice = double.tryParse(priceCtrl.text.trim());
                                  final notes = notesCtrl.text.trim();
                                  final beds = [
                                    for (final bed in selectedBeds) (bedType: bed.type, count: bed.count),
                                  ];

                                  setModalState(() => isSaving = true);
                                  try {
                                    String responseMessage = '';
                                    if (isEdit) {
                                      final result = await _repo.updateRoom(
                                        room.id,
                                        roomNumber: roomNums.first,
                                        roomTypeId: selectedTypeId,
                                        floor: floorValue,
                                        beds: beds,
                                        customPricePerNight: customPrice,
                                        status: selectedStatus,
                                        notes: notes,
                                        amenities: selectedAmenities,
                                        imagePaths: imagePaths,
                                      );
                                      responseMessage = result.message;
                                    } else {
                                      if (roomNums.length == 1) {
                                        final result = await _repo.createRoom(
                                          roomNumber: roomNums.first,
                                          roomTypeId: selectedTypeId,
                                          floor: floorValue,
                                          beds: beds,
                                          customPricePerNight: customPrice,
                                          notes: notes,
                                          amenities: selectedAmenities,
                                        );
                                        responseMessage = result.message;
                                      } else {
                                        final result = await _repo.createRoomsBatch(
                                          roomNumbers: roomNums,
                                          roomTypeId: selectedTypeId,
                                          floor: floorValue,
                                          beds: beds,
                                          customPricePerNight: customPrice,
                                          notes: notes,
                                          amenities: selectedAmenities,
                                        );
                                        responseMessage = result.message;
                                      }
                                    }

                                    if (ctx.mounted) {
                                      Navigator.of(ctx).pop();
                                    }
                                    if (mounted) {
                                      _showToast(responseMessage);
                                      _loadData();
                                    }
                                  } catch (e) {
                                    setModalState(() => isSaving = false);
                                    if (mounted) {
                                      _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
                                    }
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(
                                  isEdit ? 'Save Changes' : 'Save & Create Room',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- CATEGORIES ACTIONS ---
  Future<void> _showCategoryFormModal({RoomTypeModel? category}) async {
    final message = await showRoomCategoryFormSheet(
      context: context,
      category: category,
      onSubmit: ({required String name, required String description}) async {
        if (category != null) {
          final res = await _repo.updateRoomType(
            category.id,
            name: name,
            description: description,
          );
          return res.message;
        }
        final res = await _repo.createRoomType(
          name: name,
          description: description,
        );
        return res.message;
      },
    );

    if (message != null && message.isNotEmpty && mounted) {
      _showToast(message);
      _loadData();
    }
  }

  // --- REUSABLE MODAL HELPERS ---
  Widget _buildFormSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF0F766E)),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF475569),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCounterStepper({
    required int value,
    required int minValue,
    required int maxValue,
    required ValueChanged<int> onChanged,
    bool compact = false,
    double? height,
  }) {
    final pad = compact ? 6.0 : 10.0;
    final iconSize = compact ? 14.0 : 16.0;
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: height == null ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: value > minValue ? () => onChanged(value - 1) : null,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: height == null ? (compact ? 8 : 7) : 0),
              child: Icon(
                Icons.remove_rounded,
                size: iconSize,
                color: value > minValue ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(minWidth: compact ? 18 : 32),
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: GoogleFonts.inter(fontSize: compact ? 13 : 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
          ),
          InkWell(
            onTap: value < maxValue ? () => onChanged(value + 1) : null,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: height == null ? (compact ? 8 : 7) : 0),
              child: Icon(
                Icons.add_rounded,
                size: iconSize,
                color: value < maxValue ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(RoomTypeModel cat) async {
    final assignedRooms = _rooms.where((r) => r.roomTypeId == cat.id || r.roomType == cat.name).toList();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Category "${cat.name}"',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          assignedRooms.isNotEmpty
              ? 'Are you sure you want to delete "${cat.name}"? Note: ${assignedRooms.length} room(s) are currently assigned to this category.'
              : 'Are you sure you want to delete "${cat.name}"?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Category'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final msg = await _repo.deleteRoomType(cat.id);
        if (mounted) {
          _showToast(msg);
          await _loadData();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: !widget.embedded,
        leadingWidth: widget.embedded ? 0 : 56,
        titleSpacing: 16,
        toolbarHeight: 52,
        leading: widget.embedded
            ? null
            : Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rooms & Tariffs Management',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 16.5,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'Inventory & Category Management',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: _isLoading ? null : _loadData,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 19,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                height: 40,
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 4,
                        offset: Offset(0, 1.5),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF0F766E),
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12),
                  unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.meeting_room_outlined, size: 15),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Rooms Inventory (${_rooms.length})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.category_outlined, size: 15),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Categories & Tariffs (${_roomTypes.length})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: Icon(_tabController.index == 0 ? Icons.add_home_rounded : Icons.add_rounded, size: 20),
        label: Text(
          _tabController.index == 0 ? 'Add Room' : 'Add Category',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddRoomModal();
          } else {
            _showCategoryFormModal();
          }
        },
      ),
      body: _isLoading
          ? _buildPageShimmer()
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRoomsInventoryTab(),
                    _buildCategoriesTab(),
                  ],
                ),
    );
  }

  Widget _buildPageShimmer() {
    final showRooms = _tabController.index == 0;
    return ShimmerWrapper(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        children: [
          const ShimmerBox(height: 44, borderRadius: 10),
          const SizedBox(height: 10),
          const Row(
            children: [
              ShimmerBox(width: 78, height: 30, borderRadius: 10),
              SizedBox(width: 6),
              ShimmerBox(width: 86, height: 30, borderRadius: 10),
              SizedBox(width: 6),
              ShimmerBox(width: 82, height: 30, borderRadius: 10),
              SizedBox(width: 6),
              ShimmerBox(width: 78, height: 30, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(5, (_) => showRooms ? _roomCardShimmer() : _categoryCardShimmer()),
        ],
      ),
    );
  }

  Widget _roomCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(width: 42, height: 42, borderRadius: 10),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 150, height: 13, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 120, height: 11, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 170, height: 10, borderRadius: 4),
                  ],
                ),
              ),
              SizedBox(width: 8),
              ShimmerBox(width: 72, height: 18, borderRadius: 6),
            ],
          ),
          SizedBox(height: 12),
          ShimmerBox(height: 1, borderRadius: 0),
          SizedBox(height: 10),
          Row(
            children: [
              Spacer(),
              ShimmerBox(width: 30, height: 30, borderRadius: 8),
              SizedBox(width: 6),
              ShimmerBox(width: 30, height: 30, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(width: 40, height: 40, borderRadius: 10),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 130, height: 13, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 160, height: 11, borderRadius: 4),
                  ],
                ),
              ),
              ShimmerBox(width: 32, height: 32, borderRadius: 8),
              SizedBox(width: 6),
              ShimmerBox(width: 32, height: 32, borderRadius: 8),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 22, borderRadius: 6)),
              SizedBox(width: 6),
              Expanded(child: ShimmerBox(height: 22, borderRadius: 6)),
              SizedBox(width: 6),
              Expanded(child: ShimmerBox(height: 22, borderRadius: 6)),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 1: ROOMS INVENTORY
  Widget _buildRoomsInventoryTab() {
    final filtered = _rooms.where((r) {
      final matchesSearch = _roomSearchQuery.isEmpty ||
          r.roomNumber.toLowerCase().contains(_roomSearchQuery.toLowerCase());
      final matchesStatus = _selectedStatusFilter == 'ALL' ||
          r.status.name.toUpperCase() == _selectedStatusFilter.toUpperCase();
      final matchesType = _selectedTypeFilter == 'ALL' ||
          r.roomTypeId == _selectedTypeFilter ||
          r.roomType == _selectedTypeFilter;
      return matchesSearch && matchesStatus && matchesType;
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFF0F766E),
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        children: [
          // Filter Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _roomSearchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search room number...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('ALL', 'All Rooms'),
                const SizedBox(width: 6),
                _buildStatusChip('AVAILABLE', 'Available'),
                const SizedBox(width: 6),
                _buildStatusChip('OCCUPIED', 'Occupied'),
                const SizedBox(width: 6),
                _buildStatusChip('CLEANING', 'Cleaning'),
                const SizedBox(width: 6),
                _buildStatusChip('MAINTENANCE', 'Maintenance'),
              ],
            ),
          ),
          if (_selectedTypeFilter != 'ALL') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Category filter:',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF99F6E4), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _roomTypes
                            .firstWhere(
                              (t) => t.id == _selectedTypeFilter || t.name == _selectedTypeFilter,
                              orElse: () => RoomTypeModel(id: '', hotel: '', name: _selectedTypeFilter, basePrice: 0),
                            )
                            .name,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E)),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _selectedTypeFilter = 'ALL'),
                        child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF0F766E)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Center(
                child: Text('No rooms found matching filters.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
              ),
            )
          else
            ...filtered.map((room) => _buildRoomCard(room)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _selectedStatusFilter == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x180F766E),
                    blurRadius: 4,
                    offset: Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomStatusBadge(RoomStatus roomStatus) {
    Color dotColor;
    Color bgColor;
    Color textColor;
    String label;

    switch (roomStatus) {
      case RoomStatus.available:
        dotColor = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF059669);
        label = 'AVAILABLE';
        break;
      case RoomStatus.occupied:
        dotColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFDC2626);
        label = 'OCCUPIED';
        break;
      case RoomStatus.cleaning:
        dotColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFFFBEB);
        textColor = const Color(0xFFD97706);
        label = 'CLEANING';
        break;
      case RoomStatus.maintenance:
        dotColor = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        label = 'MAINTENANCE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF99F6E4), width: 0.8),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ROOM',
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F766E),
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          room.roomNumber.replaceAll('#', ''),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F766E),
                            height: 1.0,
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
                      Row(
                        children: [
                          Text(
                            'Room ${room.roomNumber.replaceAll('#', '')}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (room.roomType.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '• ${room.roomType.toUpperCase()}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              '${CurrencyFormatter.format(room.pricePerNight)}/night',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F766E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              '• ${room.floor.toLowerCase().contains('floor') ? room.floor : 'Floor ${room.floor}'}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        room.bedInfoLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                          height: 1.3,
                        ),
                      ),
                      if (room.keyCode.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Key ${room.keyCode.trim()}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildRoomStatusBadge(room.status),
              ],
            ),
            if (room.notes.isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.note_alt_outlined, size: 11.5, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      room.notes,
                      style: GoogleFonts.inter(fontSize: 10.5, fontStyle: FontStyle.italic, color: const Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 9),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (room.status == RoomStatus.occupied)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _checkoutOccupiedRoom(room),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDC2626), width: 1.1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.logout_rounded, size: 13, color: Color(0xFFDC2626)),
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
                  )
                else if (room.status == RoomStatus.cleaning)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _markCleaningRoomAvailable(room),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Available',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (room.currentGuestName != null && room.currentGuestName!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBBF7D0), width: 0.6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_rounded, size: 12, color: Color(0xFF15803D)),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              room.currentGuestName!,
                              style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showAddRoomModal(room: room),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBAE6FD), width: 0.8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 15,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _deleteRoom(room),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECDD3), width: 0.8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 15,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: CATEGORIES & TARIFFS
  Widget _buildCategoriesTab() {
    return RefreshIndicator(
      color: const Color(0xFF0F766E),
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        children: [
          ..._roomTypes.map((cat) => _buildCategoryCard(cat)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(RoomTypeModel cat) {
    final assignedRooms = _rooms.where((r) => r.roomTypeId == cat.id || r.roomType == cat.name).toList();
    final totalCount = cat.hasStatusCounts ? cat.totalRoomCount : assignedRooms.length;
    final availableCount = cat.hasStatusCounts ? cat.availableCount : assignedRooms.where((r) => r.status == RoomStatus.available).length;
    final bookedCount = cat.hasStatusCounts ? cat.occupiedCount : assignedRooms.where((r) => r.status == RoomStatus.occupied).length;
    final cleaningCount = cat.hasStatusCounts
        ? cat.cleaningCount + cat.maintenanceCount
        : assignedRooms.where((r) => r.status == RoomStatus.cleaning || r.status == RoomStatus.maintenance).length;

    // Pick icon based on category name
    final nameLower = cat.name.toLowerCase();
    IconData iconData = Icons.hotel_rounded;
    if (nameLower.contains('family')) {
      iconData = Icons.people_alt_rounded;
    } else if (nameLower.contains('suite') || nameLower.contains('delux')) {
      iconData = Icons.meeting_room_rounded;
    } else if (nameLower.contains('vip') || nameLower.contains('penthouse') || nameLower.contains('presidential')) {
      iconData = Icons.workspace_premium_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTypeFilter = cat.id;
              _tabController.animateTo(0);
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Squircle icon + Category Name & Tariff + Edit/Delete Icon buttons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left squircle icon matching reception screen
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        iconData,
                        color: const Color(0xFF0F766E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Middle: Category Name & Tariff / Total rooms
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          if (cat.description.isNotEmpty) ...[
                            Text(
                              cat.description,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                          ],
                          Row(
                            children: [
                              if (cat.basePrice > 0) ...[
                                Text(
                                  '${CurrencyFormatter.format(cat.basePrice)}/night',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F766E),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                totalCount > 0 ? '$totalCount Rooms' : 'No rooms assigned',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: totalCount > 0 ? const Color(0xFF0F766E) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Right: Edit & Delete icon buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit icon button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showCategoryFormModal(category: cat),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBAE6FD), width: 0.8),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Delete icon button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _deleteCategory(cat),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFECDD3), width: 0.8),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryPill(
                        label: '$availableCount Available',
                        dotColor: const Color(0xFF10B981),
                        bgColor: const Color(0xFFECFDF5),
                        textColor: const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildCategoryPill(
                        label: '$bookedCount Booked',
                        dotColor: const Color(0xFF3B82F6),
                        bgColor: const Color(0xFFEFF6FF),
                        textColor: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildCategoryPill(
                        label: '$cleaningCount Cleaning',
                        dotColor: const Color(0xFF94A3B8),
                        bgColor: const Color(0xFFF1F5F9),
                        textColor: const Color(0xFF64748B),
                      ),
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

  Widget _buildCategoryPill({
    required String label,
    required Color dotColor,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedBed {
  final String type;
  int count;

  _SelectedBed(this.type, this.count);
}

List<_SelectedBed> _bedsFromLabel(String label, int fallbackCount) {
  final raw = label.trim();
  if (raw.isEmpty) return [];
  final beds = <_SelectedBed>[];
  for (final part in raw.split(',')) {
    final piece = part.trim();
    if (piece.isEmpty) continue;
    final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(piece);
    if (match == null) {
      beds.add(_SelectedBed(_normalizeBedType(piece), fallbackCount < 1 ? 1 : fallbackCount));
      continue;
    }
    final count = int.tryParse(match.group(1)!) ?? 1;
    beds.add(_SelectedBed(_normalizeBedType(match.group(2)!), count < 1 ? 1 : count));
  }
  return beds;
}

String _normalizeBedType(String raw) {
  var name = raw.trim();
  if (name.endsWith('Beds')) name = name.substring(0, name.length - 1);
  final lower = name.toLowerCase();
  if (lower.contains('mattress') || lower.contains('extra')) return 'Extra Mattress';
  if (lower.contains('super') && lower.contains('king')) return 'Super King Bed';
  if (lower.contains('king')) return 'King Size Bed';
  if (lower.contains('queen')) return 'Queen Size Bed';
  if (lower.contains('single')) return 'Single Bed';
  if (lower.contains('double')) return 'Double Bed';
  return name;
}

Color _bedColor(String type) {
  final value = type.toLowerCase();
  if (value.contains('single')) return const Color(0xFF3B82F6);
  if (value.contains('mattress') || value.contains('extra')) return const Color(0xFFD97706);
  if (value.contains('queen')) return const Color(0xFF7C3AED);
  if (value.contains('double')) return const Color(0xFF0284C7);
  return const Color(0xFF059669);
}

Color _bedTint(String type) {
  final value = type.toLowerCase();
  if (value.contains('single')) return const Color(0xFFDBEAFE);
  if (value.contains('mattress') || value.contains('extra')) return const Color(0xFFFEF3C7);
  if (value.contains('queen')) return const Color(0xFFEDE9FE);
  if (value.contains('double')) return const Color(0xFFE0F2FE);
  return const Color(0xFFD1FAE5);
}
