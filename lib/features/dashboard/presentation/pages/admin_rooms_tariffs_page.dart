import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../rooms/data/models/room_category_model.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../data/repositories/hotel_admin_repository.dart';

class AdminRoomsTariffsPage extends StatefulWidget {
  final HotelAdminRepository? repository;

  const AdminRoomsTariffsPage({super.key, this.repository});

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
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repo.fetchAdminRooms(),
        _repo.fetchRoomTypes(),
      ]);

      if (mounted) {
        setState(() {
          _rooms = results[0] as List<RoomModel>;
          _roomTypes = results[1] as List<RoomTypeModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (isError) {
      AppSnackBar.showError(context, message);
    } else {
      AppSnackBar.showSuccess(context, message);
    }
  }

  // --- ROOMS ACTIONS ---
  Future<void> _changeRoomStatus(RoomModel room, String newStatus) async {
    try {
      final msg = await _repo.updateRoomStatus(room.id, newStatus);
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
    int totalBedsValue = room?.bedCount ?? 1;
    int maxGuestValue = room?.seatingCapacity ?? 2;
    final notesCtrl = TextEditingController(text: room?.notes ?? '');

    String selectedTypeId = room?.roomTypeId ?? (_roomTypes.isNotEmpty ? _roomTypes.first.id : '');
    String selectedBedSetup = '1 King Size Bed';
    if (room != null && room.bedType.isNotEmpty) {
      selectedBedSetup = room.bedType.split('(').first.trim();
    }

    const bedSetupOptions = [
      '1 King Size Bed',
      '1 Queen Size Bed',
      '2 Single Beds',
      '1 Double Bed',
      '1 King + 1 Single Bed',
      '2 Queen Beds',
      'Single Bed',
    ];

    String selectedStatus = room?.status.name.toUpperCase() ?? 'AVAILABLE';

    // Amenities
    RoomTypeModel? selectedCat = _roomTypes.where((t) => t.id == selectedTypeId).firstOrNull;
    final defaultAmenities = [
      'Free High-Speed WiFi',
      'Air Conditioner (AC)',
      'Smart 4K LED TV',
      'Attached Bathroom & Geyser',
    ];
    final selectedAmenities = List<String>.from(
      room?.amenities ?? (selectedCat != null && selectedCat.amenities.isNotEmpty ? selectedCat.amenities : defaultAmenities),
    );
    final customAmenityCtrl = TextEditingController();

    const popularAmenities = [
      ('Free High-Speed WiFi', Icons.wifi_rounded),
      ('Air Conditioner (AC)', Icons.ac_unit_rounded),
      ('Smart 4K LED TV', Icons.tv_rounded),
      ('Mini Fridge / Bar', Icons.kitchen_rounded),
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final cat = _roomTypes.where((t) => t.id == selectedTypeId).firstOrNull;

          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
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
                                  isEdit ? 'Update room setup and details' : 'Configure room number, category, floor & amenities',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
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
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                    children: [
                      // 1. Room Category
                      _buildFormSectionHeader('ROOM CATEGORY', Icons.category_rounded),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTypeId.isNotEmpty ? selectedTypeId : null,
                            hint: Text('Select Room Category', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8))),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F766E)),
                            items: _roomTypes.map((t) {
                              return DropdownMenuItem(
                                value: t.id,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        t.name,
                                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6F7F2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '₹${t.basePrice.round()}/night',
                                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F766E)),
                                      ),
                                    ),
                                  ],
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
                      const SizedBox(height: 20),

                      // 2. Room Identity & Floor
                      _buildFormSectionHeader('ROOM IDENTIFICATION', Icons.pin_drop_rounded),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Room Number *', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: numberCtrl,
                              style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                hintText: isEdit ? 'e.g. 101' : 'e.g. 101 or 101, 102 or 201-205',
                                hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.tag_rounded, size: 19, color: Color(0xFF0F766E)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                              ),
                            ),
                            if (!isEdit) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Batch create multiple rooms with commas or hyphen range (e.g. 101-105).',
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Floor selection stepper
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Floor Level', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                                    Text('Physical building floor', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                                  ],
                                ),
                                _buildCounterStepper(
                                  value: floorValue,
                                  minValue: 0,
                                  maxValue: 50,
                                  onChanged: (newVal) => setModalState(() => floorValue = newVal),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Custom Tariff (Optional) - ZERO GST
                      _buildFormSectionHeader('ROOM TARIFF (NO TAX)', Icons.payments_rounded),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Custom Price / Night', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                  child: Text('Optional Override', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F766E)),
                              decoration: InputDecoration(
                                hintText: cat != null ? 'Default: ₹${cat.basePrice.round()}' : 'Enter custom price',
                                hintStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.normal, color: const Color(0xFF94A3B8)),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F766E))),
                                ),
                                suffixText: '/ night',
                                suffixStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat != null
                                  ? 'Leaves empty to inherit category rate (₹${cat.basePrice.round()}/night).'
                                  : 'Overrides the default category rate if entered.',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Capacity & Bed Configuration
                      _buildFormSectionHeader('CAPACITY & BED SETUP', Icons.king_bed_rounded),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bed Setup Type', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: bedSetupOptions.contains(selectedBedSetup) ? selectedBedSetup : bedSetupOptions.first,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F766E)),
                                  items: bedSetupOptions.map((opt) {
                                    return DropdownMenuItem(
                                      value: opt,
                                      child: Text(opt, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedBedSetup = val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Total Beds', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                                      const SizedBox(height: 6),
                                      _buildCounterStepper(
                                        value: totalBedsValue,
                                        minValue: 1,
                                        maxValue: 10,
                                        onChanged: (newVal) => setModalState(() => totalBedsValue = newVal),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Max Guests', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                                      const SizedBox(height: 6),
                                      _buildCounterStepper(
                                        value: maxGuestValue,
                                        minValue: 1,
                                        maxValue: 12,
                                        onChanged: (newVal) => setModalState(() => maxGuestValue = newVal),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 5. Room Status Selection
                      _buildFormSectionHeader('INITIAL STATUS', Icons.hotel_rounded),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusSelectPill(
                            label: 'AVAILABLE',
                            icon: Icons.check_circle_rounded,
                            activeColor: const Color(0xFF10B981),
                            bgColor: const Color(0xFFECFDF5),
                            isSelected: selectedStatus == 'AVAILABLE',
                            onTap: () => setModalState(() => selectedStatus = 'AVAILABLE'),
                          ),
                          const SizedBox(width: 6),
                          _buildStatusSelectPill(
                            label: 'OCCUPIED',
                            icon: Icons.person_rounded,
                            activeColor: const Color(0xFF3B82F6),
                            bgColor: const Color(0xFFEFF6FF),
                            isSelected: selectedStatus == 'OCCUPIED',
                            onTap: () => setModalState(() => selectedStatus = 'OCCUPIED'),
                          ),
                          const SizedBox(width: 6),
                          _buildStatusSelectPill(
                            label: 'CLEANING',
                            icon: Icons.cleaning_services_rounded,
                            activeColor: const Color(0xFFF59E0B),
                            bgColor: const Color(0xFFFFFBEB),
                            isSelected: selectedStatus == 'CLEANING',
                            onTap: () => setModalState(() => selectedStatus = 'CLEANING'),
                          ),
                          const SizedBox(width: 6),
                          _buildStatusSelectPill(
                            label: 'MAINTENANCE',
                            icon: Icons.build_rounded,
                            activeColor: const Color(0xFFEF4444),
                            bgColor: const Color(0xFFFEF2F2),
                            isSelected: selectedStatus == 'MAINTENANCE',
                            onTap: () => setModalState(() => selectedStatus = 'MAINTENANCE'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 6. Amenities Section
                      _buildFormSectionHeader('AMENITIES (${selectedAmenities.length})', Icons.stars_rounded),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: popularAmenities.map((item) {
                                final isSelected = selectedAmenities.contains(item.$1);
                                return InkWell(
                                  borderRadius: BorderRadius.circular(20),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFE6F7F2) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                                        width: isSelected ? 1.4 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item.$2,
                                          size: 15,
                                          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item.$1,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF334155),
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.check_rounded, size: 14, color: Color(0xFF0F766E)),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            // Custom Amenity Row
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
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 7. Notes
                      _buildFormSectionHeader('INTERNAL NOTES (OPTIONAL)', Icons.edit_note_rounded),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
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

                                  final customPrice = double.tryParse(priceCtrl.text.trim());
                                  final notes = notesCtrl.text.trim();

                                  setModalState(() => isSaving = true);
                                  try {
                                    String responseMessage = '';
                                    if (isEdit) {
                                      final result = await _repo.updateRoom(
                                        room.id,
                                        roomNumber: roomNums.first,
                                        roomTypeId: selectedTypeId,
                                        floor: floorValue,
                                        seatingCapacity: maxGuestValue,
                                        bedCount: totalBedsValue,
                                        bedType: selectedBedSetup,
                                        customPricePerNight: customPrice,
                                        status: selectedStatus,
                                        notes: notes,
                                        amenities: selectedAmenities,
                                        gstEnabled: false,
                                        gstRate: 0.0,
                                        cgstRate: 0.0,
                                        sgstRate: 0.0,
                                        taxInclusive: false,
                                      );
                                      responseMessage = result.message;
                                    } else {
                                      final result = await _repo.createRoomsBatch(
                                        roomNumbers: roomNums,
                                        roomTypeId: selectedTypeId,
                                        floor: floorValue,
                                        seatingCapacity: maxGuestValue,
                                        bedCount: totalBedsValue,
                                        bedType: selectedBedSetup,
                                        customPricePerNight: customPrice,
                                        status: selectedStatus,
                                        notes: notes,
                                        amenities: selectedAmenities,
                                        gstEnabled: false,
                                        gstRate: 0.0,
                                        cgstRate: 0.0,
                                        sgstRate: 0.0,
                                        taxInclusive: false,
                                      );
                                      responseMessage = result.message;
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
    final isEdit = category != null;
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    final priceCtrl = TextEditingController(text: category != null ? '${category.basePrice.round()}' : '');
    int adultsValue = category?.adults ?? 2;
    int childrenValue = category?.children ?? 0;
    int bedCountValue = category?.bedCount ?? 1;

    final bedSetupOptions = [
      '1 King Size Bed',
      '1 Queen Size Bed',
      '2 Single Beds',
      '1 Double Bed',
      '1 King + 1 Single Bed',
      '2 Queen Beds',
      'Single Bed',
    ];
    String selectedBedSetup = category?.bedType.split('(').first.trim() ?? '1 King Size Bed';
    if (!bedSetupOptions.contains(selectedBedSetup)) {
      selectedBedSetup = bedSetupOptions.first;
    }

    final selectedAmenities = List<String>.from(category?.amenities ?? []);
    final customAmenityCtrl = TextEditingController();

    const popularAmenities = [
      ('Free High-Speed WiFi', Icons.wifi_rounded),
      ('Air Conditioner (AC)', Icons.ac_unit_rounded),
      ('Smart 4K LED TV', Icons.tv_rounded),
      ('Mini Fridge / Bar', Icons.kitchen_rounded),
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
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
                            child: const Icon(Icons.hotel_class_rounded, color: Color(0xFF0F766E), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? 'Edit Room Category' : 'Create Room Category',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEdit ? 'Update category specifications & tariff' : 'Configure category name, tariff, bed setup & amenities',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
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
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                    children: [
                      // 1. Category Information
                      _buildFormSectionHeader('CATEGORY DETAILS', Icons.badge_outlined),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category Name *', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: nameCtrl,
                              style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                hintText: 'e.g. Deluxe Room, Executive Suite, Family Room',
                                hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.hotel_rounded, size: 20, color: Color(0xFF0F766E)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text('Description (Optional)', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: descCtrl,
                              maxLines: 2,
                              style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                hintText: 'Brief description of category features and amenities...',
                                hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Base Tariff (Price per Night) - ZERO GST
                      _buildFormSectionHeader('BASE TARIFF (PER NIGHT)', Icons.currency_rupee_rounded),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nightly Tariff Rate *', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                            const SizedBox(height: 8),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF0F766E)),
                              decoration: InputDecoration(
                                hintText: 'e.g. 2500',
                                hintStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: const Color(0xFF94A3B8)),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Text('₹', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F766E))),
                                ),
                                suffixText: '/ night',
                                suffixStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Standard room tariff charged per night (no taxes applied).',
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Guest Capacity & Bed Configuration
                      _buildFormSectionHeader('GUEST CAPACITY & BEDS', Icons.bed_rounded),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Adults & Children
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Adults Capacity', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                                      const SizedBox(height: 6),
                                      _buildCounterStepper(
                                        value: adultsValue,
                                        minValue: 1,
                                        maxValue: 10,
                                        onChanged: (newVal) => setModalState(() => adultsValue = newVal),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Children Capacity', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                                      const SizedBox(height: 6),
                                      _buildCounterStepper(
                                        value: childrenValue,
                                        minValue: 0,
                                        maxValue: 10,
                                        onChanged: (newVal) => setModalState(() => childrenValue = newVal),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 14),

                            // Total Beds & Bed Type
                            Text('Bed Setup Type', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: bedSetupOptions.contains(selectedBedSetup) ? selectedBedSetup : bedSetupOptions.first,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F766E)),
                                  items: bedSetupOptions.map((opt) {
                                    return DropdownMenuItem(
                                      value: opt,
                                      child: Text(opt, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedBedSetup = val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total Beds in Room', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                                    Text('Number of physical beds', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                                  ],
                                ),
                                _buildCounterStepper(
                                  value: bedCountValue,
                                  minValue: 1,
                                  maxValue: 10,
                                  onChanged: (newVal) => setModalState(() => bedCountValue = newVal),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Default Category Amenities
                      _buildFormSectionHeader('CATEGORY AMENITIES (${selectedAmenities.length})', Icons.stars_rounded),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: popularAmenities.map((item) {
                                final isSelected = selectedAmenities.contains(item.$1);
                                return InkWell(
                                  borderRadius: BorderRadius.circular(20),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFE6F7F2) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                                        width: isSelected ? 1.4 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item.$2,
                                          size: 15,
                                          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item.$1,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF334155),
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.check_rounded, size: 14, color: Color(0xFF0F766E)),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            // Custom Amenity Row
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
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                          ],
                        ),
                      ),
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
                                  final name = nameCtrl.text.trim();
                                  final price = double.tryParse(priceCtrl.text.trim()) ?? 0;

                                  if (name.isEmpty || price <= 0) {
                                    _showToast('Category Name and valid Base Price are required!', isError: true);
                                    return;
                                  }

                                  setModalState(() => isSaving = true);
                                  try {
                                    String responseMessage;
                                    if (isEdit) {
                                      final res = await _repo.updateRoomType(
                                        category.id,
                                        name: name,
                                        description: descCtrl.text.trim(),
                                        basePrice: price,
                                        adults: adultsValue,
                                        children: childrenValue,
                                        bedCount: bedCountValue,
                                        bedType: selectedBedSetup,
                                        amenities: selectedAmenities,
                                        gstEnabled: false,
                                        gstRate: 0.0,
                                        cgstRate: 0.0,
                                        sgstRate: 0.0,
                                        taxInclusive: false,
                                      );
                                      responseMessage = res.message;
                                    } else {
                                      final res = await _repo.createRoomType(
                                        name: name,
                                        description: descCtrl.text.trim(),
                                        basePrice: price,
                                        adults: adultsValue,
                                        children: childrenValue,
                                        bedCount: bedCountValue,
                                        bedType: selectedBedSetup,
                                        amenities: selectedAmenities,
                                        gstEnabled: false,
                                        gstRate: 0.0,
                                        cgstRate: 0.0,
                                        sgstRate: 0.0,
                                        taxInclusive: false,
                                      );
                                      responseMessage = res.message;
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
                                    _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  isEdit ? 'Save Changes' : 'Save & Create Category',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13.5),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: value > minValue ? () => onChanged(value - 1) : null,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Icon(
                Icons.remove_rounded,
                size: 16,
                color: value > minValue ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
          ),
          InkWell(
            onTap: value < maxValue ? () => onChanged(value + 1) : null,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Icon(
                Icons.add_rounded,
                size: 16,
                color: value < maxValue ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelectPill({
    required String label,
    required IconData icon,
    required Color activeColor,
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? activeColor : const Color(0xFF94A3B8)),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
            Text('Delete Category "${cat.name}"', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${cat.name}"? This will delete all ${assignedRooms.length} room(s) assigned to this category.',
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
          _loadData();
        }
      } catch (e) {
        if (mounted) {
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
        leading: Padding(
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
          preferredSize: const Size.fromHeight(58),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                height: 44,
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
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

          // Status Filter Chips
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
            // Row 1: Key Squircle Badge + Room Type & Floor + Status Pill Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left squircle with Room number key styling
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

                // Middle: Room Number & Category Name & Tariff / Floor
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
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right Status Badge
                _buildRoomStatusBadge(room.status),
              ],
            ),

            const SizedBox(height: 9),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),

            // Row 2: Status Changer Button on left, Guest name in middle, Edit & Delete on right
            Row(
              children: [
                // Quick status changer popup
                PopupMenuButton<String>(
                  onSelected: (newStatus) => _changeRoomStatus(room, newStatus),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'AVAILABLE',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                          SizedBox(width: 8),
                          Text('Available'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'OCCUPIED',
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded, color: Color(0xFFEF4444), size: 16),
                          SizedBox(width: 8),
                          Text('Occupied'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'CLEANING',
                      child: Row(
                        children: [
                          Icon(Icons.cleaning_services_rounded, color: Color(0xFFF59E0B), size: 16),
                          SizedBox(width: 8),
                          Text('Cleaning'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'MAINTENANCE',
                      child: Row(
                        children: [
                          Icon(Icons.build_rounded, color: Color(0xFF64748B), size: 16),
                          SizedBox(width: 8),
                          Text('Maintenance'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync_rounded, size: 13, color: Color(0xFF475569)),
                        const SizedBox(width: 4),
                        Text(
                          'Status',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF64748B)),
                      ],
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

                // Edit squircle icon button
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

                // Delete squircle icon button
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
    final totalCount = assignedRooms.length;
    final availableCount = assignedRooms.where((r) => r.status == RoomStatus.available).length;
    final bookedCount = assignedRooms.where((r) => r.status == RoomStatus.occupied).length;
    final cleaningCount = assignedRooms.where((r) => r.status == RoomStatus.cleaning || r.status == RoomStatus.maintenance).length;

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
                          Row(
                            children: [
                              Text(
                                '${CurrencyFormatter.format(cat.basePrice)}/night',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F766E),
                                ),
                              ),
                              if (totalCount > 0) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '• $totalCount Rooms',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
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

                // Bottom Row: 3 Status Pills spanning full width with NO SCROLL
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
