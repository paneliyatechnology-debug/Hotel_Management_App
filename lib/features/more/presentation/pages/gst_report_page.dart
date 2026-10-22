import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../../folios/presentation/pages/guest_folio_pdf_preview_page.dart';
import 'excel_preview_page.dart';

class GstReportPage extends StatefulWidget {
  const GstReportPage({super.key});

  @override
  State<GstReportPage> createState() => _GstReportPageState();
}

class _GstReportPageState extends State<GstReportPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _format = 'pdf';
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  String _label(DateTime date) => DateFormat('d MMM yyyy').format(date);

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = DateTime(picked.year, picked.month, picked.day);
        if (_startDate.isAfter(_endDate)) _startDate = _endDate;
      }
    });
  }

  Future<void> _download() async {
    if (_downloading) return;
    if (_endDate.isBefore(_startDate)) {
      _showMessage('End date must be on or after the start date.', error: true);
      return;
    }
    setState(() => _downloading = true);
    try {
      final file = await DashboardRepository().exportGstReport(
        startDate: _startDate,
        endDate: _endDate,
        format: _format,
      );
      if (!mounted) return;
      if (_format == 'pdf') {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GuestFolioPdfPreviewPage(bytes: file.bytes, fileName: file.fileName),
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExcelPreviewPage(bytes: file.bytes, fileName: file.fileName),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFDC2626) : const Color(0xFF0F766E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'GST Report',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Custom date',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose the stay dates to include in the GST report.',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _dateField('Start date', _startDate, () => _pickDate(start: true))),
                    const SizedBox(width: 10),
                    Expanded(child: _dateField('End date', _endDate, () => _pickDate(start: false))),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Download as',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _formatButton('PDF', 'pdf')),
                    const SizedBox(width: 10),
                    Expanded(child: _formatButton('Excel', 'xlsx')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _downloading ? null : _download,
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_format == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded, size: 18),
              label: Text(
                _downloading ? 'Downloading...' : 'Download ${_format == 'pdf' ? 'PDF' : 'Excel'}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(_label(date), style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  Widget _formatButton(String label, String value) {
    final selected = _format == value;
    return InkWell(
      onTap: () => setState(() => _format = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F766E) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
