import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class SearchFilterBar extends StatelessWidget {
  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String selectedFloor;
  final List<String> floors;
  final ValueChanged<String?> onFloorChanged;
  final String selectedStatus;
  final List<String> statuses;
  final ValueChanged<String?> onStatusChanged;

  const SearchFilterBar({
    super.key,
    this.searchHint = 'Search room #, guest...',
    this.searchController,
    this.onSearchChanged,
    required this.selectedFloor,
    required this.floors,
    required this.onFloorChanged,
    required this.selectedStatus,
    required this.statuses,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search Input Field
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260, minWidth: 180),
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                ),
              ),
            ),
          ),
        ),

        // Floor Filter Dropdown
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedFloor,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              items: floors.map((floor) {
                return DropdownMenuItem<String>(
                  value: floor,
                  child: Text(floor),
                );
              }).toList(),
              onChanged: onFloorChanged,
            ),
          ),
        ),

        // Status Filter Dropdown
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStatus,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              items: statuses.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: onStatusChanged,
            ),
          ),
        ),
      ],
    );
  }
}
