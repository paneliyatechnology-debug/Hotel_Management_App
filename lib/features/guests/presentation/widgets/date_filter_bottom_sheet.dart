import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/guests_event.dart';

class DateFilterBottomSheet extends StatefulWidget {
  final DateFilterOption initialOption;
  final DateTimeRange? initialCustomRange;
  final ValueChanged<({DateFilterOption option, DateTimeRange? customRange})> onApply;

  const DateFilterBottomSheet({
    super.key,
    required this.initialOption,
    required this.initialCustomRange,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required DateFilterOption initialOption,
    required DateTimeRange? initialCustomRange,
    required ValueChanged<({DateFilterOption option, DateTimeRange? customRange})> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DateFilterBottomSheet(
        initialOption: initialOption,
        initialCustomRange: initialCustomRange,
        onApply: onApply,
      ),
    );
  }

  @override
  State<DateFilterBottomSheet> createState() => _DateFilterBottomSheetState();
}

class _DateFilterBottomSheetState extends State<DateFilterBottomSheet> {
  late DateFilterOption _selectedOption;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  final List<({DateFilterOption option, String label, IconData icon})> _quickFilters = const [
    (option: DateFilterOption.today, label: 'Today', icon: Icons.today_rounded),
    (option: DateFilterOption.yesterday, label: 'Yesterday', icon: Icons.history_rounded),
    (option: DateFilterOption.thisWeek, label: 'This Week', icon: Icons.date_range_rounded),
    (option: DateFilterOption.lastWeek, label: 'Last Week', icon: Icons.event_repeat_rounded),
    (option: DateFilterOption.thisMonth, label: 'This Month', icon: Icons.calendar_month_rounded),
    (option: DateFilterOption.lastMonth, label: 'Last Month', icon: Icons.calendar_view_month_rounded),
    (option: DateFilterOption.thisYear, label: 'This Year', icon: Icons.calendar_today_rounded),
    (option: DateFilterOption.lastYear, label: 'Last Year', icon: Icons.history_edu_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialOption;
    if (widget.initialCustomRange != null) {
      _customStartDate = widget.initialCustomRange!.start;
      _customEndDate = widget.initialCustomRange!.end;
    }
  }

  String _getDateHint(DateFilterOption option) {
    final now = DateTime.now();
    switch (option) {
      case DateFilterOption.today:
        return _dateFormat.format(now);
      case DateFilterOption.yesterday:
        return _dateFormat.format(now.subtract(const Duration(days: 1)));
      case DateFilterOption.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return '${DateFormat('dd MMM').format(start)} – ${DateFormat('dd MMM').format(now)}';
      case DateFilterOption.lastWeek:
        final start = now.subtract(Duration(days: now.weekday + 6));
        final end = now.subtract(Duration(days: now.weekday));
        return '${DateFormat('dd MMM').format(start)} – ${DateFormat('dd MMM').format(end)}';
      case DateFilterOption.thisMonth:
        return DateFormat('MMM yyyy').format(now);
      case DateFilterOption.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return DateFormat('MMM yyyy').format(lastMonth);
      case DateFilterOption.thisYear:
        return '${now.year}';
      case DateFilterOption.lastYear:
        return '${now.year - 1}';
      case DateFilterOption.allTime:
        return 'All Records';
      default:
        return '';
    }
  }

  Future<void> _pickFullRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: (_customStartDate != null && _customEndDate != null)
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.neutral900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedOption = DateFilterOption.custom;
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_customStartDate ?? now)
        : (_customEndDate ?? _customStartDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.neutral900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedOption = DateFilterOption.custom;
        if (isStart) {
          _customStartDate = picked;
          if (_customEndDate != null && _customEndDate!.isBefore(picked)) {
            _customEndDate = picked;
          }
        } else {
          _customEndDate = picked;
          if (_customStartDate != null && _customStartDate!.isAfter(picked)) {
            _customStartDate = picked;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final durationDays = (_customStartDate != null && _customEndDate != null)
        ? _customEndDate!.difference(_customStartDate!).inDays + 1
        : null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 10,
        left: 18,
        right: 18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Premium Header with Icon Badge
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: const Icon(Icons.date_range_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by Date',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.neutral900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Select timeframe to find historical stays',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedOption != DateFilterOption.all)
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedOption = DateFilterOption.all;
                      _customStartDate = null;
                      _customEndDate = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. Quick Date Filters Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'QUICK DATE FILTERS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.neutral600,
                        ),
                      ),
                      Text(
                        _selectedOption.label,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // "All Time" Master Chip
                  _buildAllTimeBanner(),
                  const SizedBox(height: 8),

                  // 2x4 Modern Quick Filter Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _quickFilters.length,
                    itemBuilder: (context, index) {
                      final item = _quickFilters[index];
                      final isSelected = _selectedOption == item.option;
                      return _buildQuickCard(
                        label: item.label,
                        dateHint: _getDateHint(item.option),
                        icon: item.icon,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedOption = item.option;
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // 4. Custom Date Range Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'CUSTOM DATE RANGE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.neutral600,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _pickFullRange,
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Calendar Picker',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePickerBox(
                          label: 'From Date',
                          value: _customStartDate != null ? _dateFormat.format(_customStartDate!) : 'Select Date',
                          isSelected: _selectedOption == DateFilterOption.custom && _customStartDate != null,
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF94A3B8)),
                      ),
                      Expanded(
                        child: _buildDatePickerBox(
                          label: 'To Date',
                          value: _customEndDate != null ? _dateFormat.format(_customEndDate!) : 'Select Date',
                          isSelected: _selectedOption == DateFilterOption.custom && _customEndDate != null,
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),

                  // Range summary card
                  if (_selectedOption == DateFilterOption.custom &&
                      _customStartDate != null &&
                      _customEndDate != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_dateFormat.format(_customStartDate!)} – ${_dateFormat.format(_customEndDate!)}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          if (durationDays != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$durationDays ${durationDays == 1 ? 'day' : 'days'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 5. Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                DateTimeRange? range;
                if (_selectedOption == DateFilterOption.custom &&
                    _customStartDate != null &&
                    _customEndDate != null) {
                  range = DateTimeRange(
                    start: _customStartDate!,
                    end: _customEndDate!,
                  );
                }
                widget.onApply((
                  option: _selectedOption,
                  customRange: range,
                ));
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.done_rounded, size: 18),
              label: const Text(
                'Apply Filter',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTimeBanner() {
    final isSelected = _selectedOption == DateFilterOption.all;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedOption = DateFilterOption.all;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.all_inclusive_rounded,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.neutral700,
                ),
                const SizedBox(width: 8),
                Text(
                  'All Time',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.neutral800,
                  ),
                ),
              ],
            ),
            Flexible(
              child: Text(
                'All records',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard({
    required String label,
    required String dateHint,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    dateHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      color: isSelected ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerBox({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface.withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primaryDark : AppColors.neutral600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.neutral900 : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
