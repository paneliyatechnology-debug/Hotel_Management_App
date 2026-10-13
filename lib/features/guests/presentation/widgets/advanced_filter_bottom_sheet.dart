import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/guest_model.dart';
import '../bloc/guests_event.dart';

class AdvancedFilterBottomSheet extends StatefulWidget {
  final AdvancedFiltersData initialFilters;
  final ValueChanged<AdvancedFiltersData> onApply;

  const AdvancedFilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required AdvancedFiltersData initialFilters,
    required ValueChanged<AdvancedFiltersData> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedFilterBottomSheet(
        initialFilters: initialFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<AdvancedFilterBottomSheet> createState() => _AdvancedFilterBottomSheetState();
}

class _AdvancedFilterBottomSheetState extends State<AdvancedFilterBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _floorController;
  late final TextEditingController _roomNumberController;

  String? _selectedCategory;
  GuestStatus? _selectedStatus;
  String? _selectedPaymentStatus;

  final List<String> _roomCategories = const [
    'Deluxe Room',
    'Executive Suite',
    'Family Room',
    'Standard Room',
    'Presidential Suite',
  ];

  final List<String> _paymentStatuses = const [
    'Paid',
    'Partially Paid',
    'Pending',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialFilters.name);
    _mobileController = TextEditingController(text: widget.initialFilters.mobile);
    _emailController = TextEditingController(text: widget.initialFilters.email);
    _floorController = TextEditingController(text: widget.initialFilters.floor);
    _roomNumberController = TextEditingController(text: widget.initialFilters.roomNumber);
    _selectedCategory = widget.initialFilters.roomCategory;
    _selectedStatus = widget.initialFilters.status;
    _selectedPaymentStatus = widget.initialFilters.paymentStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _floorController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _nameController.clear();
      _mobileController.clear();
      _emailController.clear();
      _floorController.clear();
      _roomNumberController.clear();
      _selectedCategory = null;
      _selectedStatus = null;
      _selectedPaymentStatus = null;
    });
  }

  AdvancedFiltersData _buildFiltersData() {
    return AdvancedFiltersData(
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      floor: _floorController.text.trim().isEmpty ? null : _floorController.text.trim(),
      roomNumber: _roomNumberController.text.trim().isEmpty ? null : _roomNumberController.text.trim(),
      roomCategory: _selectedCategory,
      status: _selectedStatus,
      paymentStatus: _selectedPaymentStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: keyboardPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Guests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Refine guest records by details',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _clearAll,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.borderSubtle),

          // Scrollable filter fields
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                // GUEST SECTION
                _buildSectionHeader('GUEST DETAILS'),
                const SizedBox(height: 12),
                _buildInputField(
                  label: 'Guest Name',
                  controller: _nameController,
                  hint: 'e.g. Rahul Sharma',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'Mobile Number',
                        controller: _mobileController,
                        hint: 'e.g. 9876543210',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        label: 'Email Address',
                        controller: _emailController,
                        hint: 'e.g. guest@email.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                // ROOM SECTION
                _buildSectionHeader('ROOM INFORMATION'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'Floor',
                        controller: _floorController,
                        hint: 'e.g. 1st Floor',
                        icon: Icons.layers_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        label: 'Room Number',
                        controller: _roomNumberController,
                        hint: 'e.g. 203',
                        icon: Icons.meeting_room_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Room Category',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _roomCategories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return _buildSelectableChip(
                      label: cat,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedCategory = isSelected ? null : cat;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                // STATUS SECTION
                _buildSectionHeader('STAY STATUS'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSelectableChip(
                      label: 'In-House',
                      isSelected: _selectedStatus == GuestStatus.inHouse,
                      color: AppColors.statusSuccess,
                      onTap: () {
                        setState(() {
                          _selectedStatus = _selectedStatus == GuestStatus.inHouse ? null : GuestStatus.inHouse;
                        });
                      },
                    ),
                    _buildSelectableChip(
                      label: 'Checked-Out',
                      isSelected: _selectedStatus == GuestStatus.checkedOut,
                      color: AppColors.primary,
                      onTap: () {
                        setState(() {
                          _selectedStatus = _selectedStatus == GuestStatus.checkedOut ? null : GuestStatus.checkedOut;
                        });
                      },
                    ),
                    _buildSelectableChip(
                      label: 'Cancelled',
                      isSelected: _selectedStatus == GuestStatus.cancelled,
                      color: AppColors.statusError,
                      onTap: () {
                        setState(() {
                          _selectedStatus = _selectedStatus == GuestStatus.cancelled ? null : GuestStatus.cancelled;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                // PAYMENT SECTION
                _buildSectionHeader('PAYMENT STATUS'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _paymentStatuses.map((pay) {
                    final isSelected = _selectedPaymentStatus == pay;
                    return _buildSelectableChip(
                      label: pay,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedPaymentStatus = isSelected ? null : pay;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.borderSubtle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _clearAll,
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final filters = _buildFiltersData();
                      widget.onApply(filters);
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.neutral600,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.neutral900,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.neutral400,
              ),
              prefixIcon: Icon(icon, size: 18, color: AppColors.neutral500),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : AppColors.neutral100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? activeColor : AppColors.neutral800,
          ),
        ),
      ),
    );
  }
}
