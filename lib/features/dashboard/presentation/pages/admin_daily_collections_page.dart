import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../../data/repositories/hotel_admin_repository.dart';
import '../widgets/dashboard_shimmer_loader.dart';
import '../widgets/payment_method_collection_cards.dart';

enum AdminCollectionsPreset { today, yesterday, week, month, custom }
typedef _DatePreset = AdminCollectionsPreset;

/// Daily Collections — driven by GET /api/v1/dashboard/summary (no static data).
class AdminDailyCollectionsPage extends StatefulWidget {
  final HotelAdminRepository? repository;
  final AdminCollectionsPreset initialPreset;

  const AdminDailyCollectionsPage({
    super.key,
    this.repository,
    this.initialPreset = AdminCollectionsPreset.today,
  });

  @override
  State<AdminDailyCollectionsPage> createState() => _AdminDailyCollectionsPageState();
}

class _AdminDailyCollectionsPageState extends State<AdminDailyCollectionsPage> {
  late final HotelAdminRepository _repo;
  late DateTime _startDate;
  late DateTime _endDate;
  _DatePreset _preset = _DatePreset.today;

  DashboardSummary? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? HotelAdminRepository();
    final today = _dateOnly(DateTime.now());
    switch (widget.initialPreset) {
      case AdminCollectionsPreset.week:
        _preset = _DatePreset.week;
        _startDate = today.subtract(Duration(days: today.weekday - 1));
        _endDate = _startDate.add(const Duration(days: 6));
      case AdminCollectionsPreset.month:
        _preset = _DatePreset.month;
        _startDate = DateTime(today.year, today.month, 1);
        _endDate = DateTime(today.year, today.month + 1, 0);
      case AdminCollectionsPreset.yesterday:
        _preset = _DatePreset.yesterday;
        _startDate = today.subtract(const Duration(days: 1));
        _endDate = _startDate;
      case AdminCollectionsPreset.today:
      default:
        _preset = _DatePreset.today;
        _startDate = today;
        _endDate = today;
    }
    _loadSummary();
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final summary = await _repo.fetchDashboardSummary(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _selectPreset(_DatePreset preset) {
    if (preset == _DatePreset.custom) {
      setState(() => _preset = _DatePreset.custom);
      return;
    }
    final today = _dateOnly(DateTime.now());
    late DateTime start;
    late DateTime end;
    switch (preset) {
      case _DatePreset.today:
        start = today;
        end = today;
      case _DatePreset.yesterday:
        start = today.subtract(const Duration(days: 1));
        end = start;
      case _DatePreset.week:
        start = today.subtract(Duration(days: today.weekday - 1));
        end = start.add(const Duration(days: 6));
      case _DatePreset.month:
        start = DateTime(today.year, today.month, 1);
        end = DateTime(today.year, today.month + 1, 0);
      case _DatePreset.custom:
        return;
    }
    setState(() {
      _preset = preset;
      _startDate = start;
      _endDate = end;
    });
    _loadSummary();
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    final next = _dateOnly(picked);
    setState(() {
      _preset = _DatePreset.custom;
      if (start) {
        _startDate = next;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = next;
        if (_endDate.isBefore(_startDate)) _startDate = _endDate;
      }
    });
    _loadSummary();
  }

  String get _rangeLabel {
    final fmt = DateFormat('d MMM yyyy');
    if (_startDate.year == _endDate.year &&
        _startDate.month == _endDate.month &&
        _startDate.day == _endDate.day) {
      return fmt.format(_startDate);
    }
    return '${fmt.format(_startDate)} – ${fmt.format(_endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Daily Collections',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadSummary,
          ),
        ],
      ),
      body: _isLoading && _summary == null
          ? const DailyCollectionsShimmer()
          : _errorMessage != null && _summary == null
              ? _buildErrorState()
              : RefreshIndicator(
                  color: const Color(0xFF0F766E),
                  onRefresh: _loadSummary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      _buildDatePresets(),
                      if (_preset == _DatePreset.custom) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _dateField('Start date', _startDate, () => _pickDate(start: true))),
                            const SizedBox(width: 8),
                            Expanded(child: _dateField('End date', _endDate, () => _pickDate(start: false))),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (_summary != null) ...[
                        _buildHero(_summary!),
                        const SizedBox(height: 14),
                        _buildCounts(_summary!),
                        const SizedBox(height: 14),
                        _buildPaymentBreakdown(_summary!),
                        const SizedBox(height: 14),
                        _buildBillingBreakdown(_summary!),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePresets() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('Today', _preset == _DatePreset.today, () => _selectPreset(_DatePreset.today)),
          const SizedBox(width: 8),
          _chip('Yesterday', _preset == _DatePreset.yesterday, () => _selectPreset(_DatePreset.yesterday)),
          const SizedBox(width: 8),
          _chip('This week', _preset == _DatePreset.week, () => _selectPreset(_DatePreset.week)),
          const SizedBox(width: 8),
          _chip('This month', _preset == _DatePreset.month, () => _selectPreset(_DatePreset.month)),
          const SizedBox(width: 8),
          _chip('Custom', _preset == _DatePreset.custom, () => _selectPreset(_DatePreset.custom)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(
              DateFormat('d MMM yyyy').format(date),
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(DashboardSummary summary) {
    final period = summary.periodStartDate.isNotEmpty
        ? (summary.periodStartDate == summary.periodEndDate
            ? summary.periodStartDate
            : '${summary.periodStartDate} – ${summary.periodEndDate}')
        : _rangeLabel;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF6EE7B7), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL COLLECTED',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    Text(
                      period,
                      style: GoogleFonts.inter(color: const Color(0xFFA7F3D0), fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(summary.totalCollectedAmount),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_actions_rounded, size: 16, color: Color(0xFFFDE68A)),
                const SizedBox(width: 6),
                Text(
                  'Outstanding  ${CurrencyFormatter.format(summary.totalOutstandingAmount)}',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounts(DashboardSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _countCard(
            label: 'Bookings',
            value: '${summary.totalBookingCount}',
            icon: Icons.hotel_rounded,
            color: const Color(0xFF0F766E),
            bg: const Color(0xFFECFDF5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _countCard(
            label: 'Guests',
            value: '${summary.totalGuestCount}',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF0284C7),
            bg: const Color(0xFFF0F9FF),
          ),
        ),
      ],
    );
  }

  Widget _countCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(DashboardSummary summary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Breakdown',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          PaymentMethodCollectionCards(
            methods: summary.collectionByPaymentMethod,
            columns: 2,
            showSectionTitle: false,
          ),
        ],
      ),
    );
  }

  Widget _buildBillingBreakdown(DashboardSummary summary) {
    final rows = <({String label, double amount, IconData icon})>[
      (label: 'Booking amount', amount: summary.totalBookingAmount, icon: Icons.bed_rounded),
      (label: 'Discount', amount: summary.totalDiscountAmount, icon: Icons.local_offer_rounded),
      (label: 'Extra charges', amount: summary.totalExtraChargesAmount, icon: Icons.add_circle_outline_rounded),
      (label: 'Late checkout', amount: summary.totalLateCheckoutChargesAmount, icon: Icons.schedule_rounded),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Billing Summary',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(row.icon, size: 16, color: const Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.label,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(row.amount),
                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
