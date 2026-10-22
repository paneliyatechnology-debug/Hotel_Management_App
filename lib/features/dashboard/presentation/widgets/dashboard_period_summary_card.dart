import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../../data/repositories/hotel_admin_repository.dart';

typedef DashboardSummaryLoader = Future<DashboardSummary> Function({
  required DateTime startDate,
  required DateTime endDate,
});

class DashboardPeriodSummaryCard extends StatefulWidget {
  final bool enabled;
  final DashboardSummaryLoader? loader;

  const DashboardPeriodSummaryCard({
    super.key,
    this.enabled = true,
    this.loader,
  });

  @override
  State<DashboardPeriodSummaryCard> createState() => DashboardPeriodSummaryCardState();
}

enum _DatePreset { today, yesterday, week, month, year, custom }

class DashboardPeriodSummaryCardState extends State<DashboardPeriodSummaryCard> {
  late DateTime _startDate;
  late DateTime _endDate;
  _DatePreset _preset = _DatePreset.today;
  DashboardSummary? _summary;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _startDate = today;
    _endDate = today;
    if (widget.enabled) {
      _loading = true;
      _fetch();
    }
  }

  Future<void> reload() async {
    if (!widget.enabled || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final summary = await (widget.loader ?? HotelAdminRepository().fetchDashboardSummary)(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
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
      case _DatePreset.year:
        start = DateTime(today.year, 1, 1);
        end = DateTime(today.year, 12, 31);
      case _DatePreset.custom:
        return;
    }
    setState(() => _preset = preset);
    _applyRange(start, end);
  }

  void _applyRange(DateTime start, DateTime end) {
    final nextStart = _dateOnly(start);
    final nextEnd = _dateOnly(end);
    setState(() {
      if (nextEnd.isBefore(nextStart)) {
        _startDate = nextEnd;
        _endDate = nextStart;
      } else {
        _startDate = nextStart;
        _endDate = nextEnd;
      }
    });
    reload();
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    _applyRange(start ? picked : _startDate, start ? _endDate : picked);
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final period = summary == null || summary.periodStartDate.isEmpty
        ? '${DateFormat('d MMM yyyy').format(_startDate)} – ${DateFormat('d MMM yyyy').format(_endDate)}'
        : summary.periodStartDate == summary.periodEndDate
            ? summary.periodStartDate
            : '${summary.periodStartDate} – ${summary.periodEndDate}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(color: const Color(0xFF0F766E), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Date summary',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            period,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
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
                _chip('This year', _preset == _DatePreset.year, () => _selectPreset(_DatePreset.year)),
                const SizedBox(width: 8),
                _chip('Custom date', _preset == _DatePreset.custom, () => _selectPreset(_DatePreset.custom)),
              ],
            ),
          ),
          if (_preset == _DatePreset.custom) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _dateField('Start date', _startDate, () => _pickDate(start: true))),
                const SizedBox(width: 8),
                Expanded(child: _dateField('End date', _endDate, () => _pickDate(start: false))),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (_error != null && summary == null)
            _message(_error!)
          else if (summary == null)
            _message(widget.enabled ? 'Loading this date range…' : 'Pick a date range to see collections and bookings.')
          else
            _summaryBody(summary),
          if (_error != null && summary != null) ...[
            const SizedBox(height: 8),
            _message(_error!),
          ],
        ],
      ),
    );
  }

  Widget _summaryBody(DashboardSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(child: _heroStat('Collected', CurrencyFormatter.format(summary.totalCollectedAmount))),
              Container(width: 1, height: 36, color: const Color(0x33FFFFFF)),
              Expanded(child: _heroStat('Outstanding', CurrencyFormatter.format(summary.totalOutstandingAmount))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _countTile('Bookings', '${summary.totalBookingCount}')),
            const SizedBox(width: 8),
            Expanded(child: _countTile('Guests', '${summary.totalGuestCount}')),
          ],
        ),
        const SizedBox(height: 10),
        _amountRow('Booking amount', summary.totalBookingAmount),
        _amountRow('Discount', summary.totalDiscountAmount),
        _amountRow('Extra charges', summary.totalExtraChargesAmount),
        _amountRow('Late checkout', summary.totalLateCheckoutChargesAmount),
        const SizedBox(height: 8),
        Text(
          'By payment method',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF334155)),
        ),
        const SizedBox(height: 8),
        _methodRow([
          _methodTile('Cash', summary.cashCollectedAmount),
          _methodTile('UPI', summary.upiCollectedAmount),
          _methodTile('Card', summary.cardCollectedAmount),
        ]),
        const SizedBox(height: 8),
        _methodRow([
          _methodTile('Online', summary.onlineCollectedAmount),
          _methodTile('Bank', summary.bankTransferCollectedAmount),
          const SizedBox.shrink(),
        ]),
      ],
    );
  }

  Widget _heroStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFCCFBF1))),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _countTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          ),
          Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _methodRow(List<Widget> tiles) {
    return Row(
      children: [
        for (var index = 0; index < tiles.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(child: tiles[index]),
        ],
      ],
    );
  }

  Widget _methodTile(String label, double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.format(amount),
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
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
          color: selected ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF334155),
            ),
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
          color: const Color(0xFFF8FAFC),
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

  Widget _message(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
    );
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
}
