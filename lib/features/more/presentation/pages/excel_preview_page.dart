import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

class ExcelPreviewPage extends StatefulWidget {
  final Uint8List bytes;
  final String fileName;

  const ExcelPreviewPage({
    super.key,
    required this.bytes,
    required this.fileName,
  });

  @override
  State<ExcelPreviewPage> createState() => _ExcelPreviewPageState();
}

class _ExcelPreviewPageState extends State<ExcelPreviewPage> {
  static const _storageChannel = MethodChannel('my_own_pms/pdf_storage');
  bool _loading = true;
  bool _downloading = false;
  int _sheetIndex = 0;
  _ExcelWorkbook? _workbook;
  String? _error;

  String get _safeFileName {
    final raw = widget.fileName.trim().split(RegExp(r'[\\/]')).last.replaceAll(RegExp(r'[<>:"|?*]'), '_');
    if (raw.isEmpty) return 'gst-report.xlsx';
    return raw.toLowerCase().endsWith('.xlsx') ? raw : '$raw.xlsx';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final workbook = await Future(() => _parseExcelWorkbook(widget.bytes));
      if (!mounted) return;
      setState(() {
        _workbook = workbook;
        _loading = false;
        _error = workbook.sheets.isEmpty ? 'This Excel file has no rows to preview.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not preview this Excel file.';
      });
    }
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      await _saveExcel(widget.bytes, _safeFileName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Platform.isAndroid ? 'Excel saved to Downloads' : 'Excel report saved'),
          backgroundColor: const Color(0xFF0F766E),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_saveErrorMessage(error)),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _saveExcel(Uint8List bytes, String fileName) async {
    final tempFile = File('${(await getTemporaryDirectory()).path}/$fileName');
    await tempFile.writeAsBytes(bytes, flush: true);
    if (!Platform.isAndroid) {
      final directory = await getApplicationDocumentsDirectory();
      await tempFile.copy('${directory.path}/$fileName');
      return;
    }
    try {
      await _storageChannel.invokeMethod<String>('saveDownload', {
        'name': fileName,
        'path': tempFile.path,
        'mime': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      });
    } on MissingPluginException {
      throw Exception('Stop the app and run it again, then download the Excel file.');
    }
  }

  String _saveErrorMessage(Object error) {
    if (error is PlatformException) {
      final message = error.message?.trim() ?? '';
      if (message.isNotEmpty) return message;
    }
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty || message == 'Exception') return 'Could not save the Excel file.';
    return message;
  }

  void _selectSheet(int index) {
    if (index == _sheetIndex) return;
    setState(() => _sheetIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final sheet = _workbook == null || _workbook!.sheets.isEmpty
        ? null
        : _workbook!.sheets[_sheetIndex.clamp(0, _workbook!.sheets.length - 1)];
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'Excel Preview',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_workbook != null && _workbook!.sheets.length > 1) _sheetTabs(),
                Expanded(child: _error != null || sheet == null ? _errorState() : _reportBody(sheet)),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF99F6E4),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _downloading ? null : _download,
              icon: _downloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text('Download', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetTabs() {
    final sheets = _workbook!.sheets;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        itemCount: sheets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == _sheetIndex;
          return InkWell(
            onTap: () => _selectSheet(index),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0F766E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                sheets[index].name,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _error ?? 'Could not preview this Excel file.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _reportBody(_ExcelSheet sheet) {
    final report = sheet.report;
    final copy = _copyOf(report);
    final showHero = copy.hotel != null || copy.address != null || copy.gstin != null || copy.period != null || copy.generated != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        if (showHero) _hero(copy),
        if (showHero) const SizedBox(height: 16),
        _sectionLabel(report),
        const SizedBox(height: 10),
        if (report.records.isEmpty)
          _emptyRecords()
        else
          for (var index = 0; index < report.records.length; index++) ...[
            _invoiceCard(report, index),
            const SizedBox(height: 10),
          ],
        if (report.total != null) ...[
          const SizedBox(height: 4),
          _totalCard(report),
        ],
      ],
    );
  }

  Widget _hero(_ReportCopy copy) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.hotel ?? 'GST report',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      copy.label,
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (copy.address != null) ...[
            const SizedBox(height: 14),
            Text(
              copy.address!,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155), height: 1.35),
            ),
          ],
          if (copy.gstin != null || copy.pan != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (copy.gstin != null) Expanded(child: _idBlock('GSTIN', copy.gstin!)),
                if (copy.gstin != null && copy.pan != null) const SizedBox(width: 10),
                if (copy.pan != null) Expanded(child: _idBlock('PAN', copy.pan!)),
              ],
            ),
          ],
          if (copy.period != null || copy.generated != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (copy.period != null) _metaLine('Period', copy.period!),
                  if (copy.period != null && copy.generated != null) const SizedBox(height: 8),
                  if (copy.generated != null) _metaLine('Generated', copy.generated!),
                ],
              ),
            ),
          ],
          for (final note in copy.notes) ...[
            const SizedBox(height: 8),
            Text(note, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          ],
        ],
      ),
    );
  }

  Widget _idBlock(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E))),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _metaLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        ),
        Expanded(
          child: Text(value, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
        ),
      ],
    );
  }

  Widget _sectionLabel(_ReportLayout report) {
    final count = report.records.length;
    return Row(
      children: [
        Expanded(
          child: Text(
            report.section,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
        ),
        Text(
          '$count ${count == 1 ? 'invoice' : 'invoices'}',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _emptyRecords() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        'No invoices in this report.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
      ),
    );
  }

  Widget _invoiceCard(_ReportLayout report, int index) {
    final row = report.records[index];
    final columns = report.columns;
    final dateIndex = _columnIndexWhere(columns, (label) => label.contains('date'));
    final invoiceIndex = _columnIndexWhere(columns, (label) => label.contains('invoice') && !label.contains('date'));
    final guestIndex = _columnIndexWhere(columns, (label) => label.contains('guest') || label.contains('customer'));
    final titleIndex = invoiceIndex ?? _columnIndexWhere(columns, (label) => !label.contains('date'));
    final title = titleIndex == null ? 'Invoice ${index + 1}' : _cell(row, titleIndex);
    final titleLabel = titleIndex == null ? 'Invoice' : columns[titleIndex];
    final date = dateIndex == null ? '' : _cell(row, dateIndex);
    final guest = guestIndex == null ? '' : _cell(row, guestIndex);
    final skip = {?dateIndex, ?titleIndex, ?guestIndex};
    final fields = _visibleFields(columns, row, skip);
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF334155)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleLabel,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title.isEmpty ? 'Invoice ${index + 1}' : title,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.25),
                    ),
                  ],
                ),
              ),
              if (date.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    date,
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                  ),
                ),
            ],
          ),
          if (guest.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(guest, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
          ],
          if (fields.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
            _fieldGrid(fields),
          ],
        ],
      ),
    );
  }

  Widget _fieldGrid(List<_LabeledValue> fields) {
    final rows = <Widget>[];
    for (var index = 0; index < fields.length; index++) {
      final field = fields[index];
      final next = index + 1 < fields.length ? fields[index + 1] : null;
      final wide = field.value.length > 28 || (next != null && next.value.length > 28);
      if (wide || next == null) {
        rows.add(_fieldTile(field));
        if (index != fields.length - 1) rows.add(const SizedBox(height: 10));
      } else {
        rows.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _fieldTile(field)),
            const SizedBox(width: 12),
            Expanded(child: _fieldTile(next)),
          ],
        ));
        if (index + 1 != fields.length - 1) rows.add(const SizedBox(height: 10));
        index++;
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _fieldTile(_LabeledValue field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(field.value, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.25)),
      ],
    );
  }

  Widget _totalCard(_ReportLayout report) {
    final fields = _visibleFields(report.columns, report.total!, {0});
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          if (fields.isNotEmpty) const SizedBox(height: 10),
          for (var index = 0; index < fields.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(fields[index].label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFCCFBF1))),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    fields[index].value,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<_LabeledValue> _visibleFields(List<String> columns, List<String> row, Set<int> skip) {
    final fields = <_LabeledValue>[];
    for (var index = 0; index < columns.length; index++) {
      if (skip.contains(index)) continue;
      final label = columns[index].trim();
      final value = _cell(row, index);
      if (label.isEmpty || value.isEmpty) continue;
      if (label.toLowerCase() == 'total' && value.toLowerCase() == 'total') continue;
      fields.add(_LabeledValue(label, value));
    }
    return fields;
  }

  String _cell(List<String> row, int index) => index < row.length ? row[index].trim() : '';

  int? _columnIndexWhere(List<String> columns, bool Function(String label) test) {
    for (var index = 0; index < columns.length; index++) {
      if (test(columns[index].trim().toLowerCase())) return index;
    }
    return null;
  }

  _ReportCopy _copyOf(_ReportLayout report) {
    final title = report.title?.trim();
    String? hotel;
    var label = 'GST report';
    if (title != null && title.isNotEmpty) {
      final parts = title.split(RegExp(r'\s+-\s+'));
      if (parts.length > 1) {
        hotel = parts.first.trim();
        label = parts.sublist(1).join(' - ').trim();
      } else {
        hotel = title;
      }
    }
    String? address;
    String? gstin;
    String? pan;
    String? period;
    String? generated;
    final notes = <String>[];
    for (final raw in report.details) {
      final line = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (line.isEmpty) continue;
      final gstinMatch = RegExp(r'GSTIN:\s*(\S+)', caseSensitive: false).firstMatch(line);
      final panMatch = RegExp(r'PAN:\s*(\S+)', caseSensitive: false).firstMatch(line);
      if (gstinMatch != null || panMatch != null) {
        gstin ??= gstinMatch?.group(1);
        pan ??= panMatch?.group(1);
        continue;
      }
      final periodMatch = RegExp(r'Period:\s*(.+)', caseSensitive: false).firstMatch(line);
      if (periodMatch != null) {
        var value = periodMatch.group(1)!.trim();
        final filters = RegExp(r'Filters:\s*(.+)$', caseSensitive: false).firstMatch(value);
        if (filters != null) {
          value = value.substring(0, filters.start).trim();
          final filterValue = filters.group(1)!.trim();
          if (filterValue.toLowerCase() != 'none') notes.add('Filters: $filterValue');
        }
        period = value;
        continue;
      }
      final generatedMatch = RegExp(r'Generated:\s*(.+)', caseSensitive: false).firstMatch(line);
      if (generatedMatch != null) {
        generated = generatedMatch.group(1)!.trim();
        continue;
      }
      if (address == null && !line.contains(':')) {
        address = line;
      } else {
        notes.add(line);
      }
    }
    return _ReportCopy(
      hotel: hotel,
      label: label,
      address: address,
      gstin: gstin,
      pan: pan,
      period: period,
      generated: generated,
      notes: notes,
    );
  }
}

class _ExcelWorkbook {
  final List<_ExcelSheet> sheets;

  const _ExcelWorkbook(this.sheets);
}

class _ExcelSheet {
  final String name;
  final _ReportLayout report;

  const _ExcelSheet({required this.name, required this.report});
}

class _ReportLayout {
  final String? title;
  final List<String> details;
  final String section;
  final List<String> columns;
  final List<List<String>> records;
  final List<String>? total;

  const _ReportLayout({
    required this.title,
    required this.details,
    required this.section,
    required this.columns,
    required this.records,
    required this.total,
  });
}

class _ReportCopy {
  final String? hotel;
  final String label;
  final String? address;
  final String? gstin;
  final String? pan;
  final String? period;
  final String? generated;
  final List<String> notes;

  const _ReportCopy({
    required this.hotel,
    required this.label,
    required this.address,
    required this.gstin,
    required this.pan,
    required this.period,
    required this.generated,
    required this.notes,
  });
}

class _LabeledValue {
  final String label;
  final String value;

  const _LabeledValue(this.label, this.value);
}

const _builtinDateIds = <int>{
  14, 15, 16, 17, 18, 19, 20, 21, 22,
  27, 28, 29, 30, 31, 32, 33, 34, 35, 36,
  45, 46, 47, 50, 51, 52, 53, 54, 55, 56, 57, 58,
};

_ExcelWorkbook _parseExcelWorkbook(Uint8List bytes) {
  if (_looksLikeZip(bytes)) return _parseXlsx(bytes);
  final text = utf8.decode(bytes, allowMalformed: true).trim();
  if (text.isEmpty) throw const FormatException('Empty workbook');
  return _ExcelWorkbook([_sheetFromRows('Sheet', _parseDelimited(text))]);
}

bool _looksLikeZip(Uint8List bytes) => bytes.length > 3 && bytes[0] == 0x50 && bytes[1] == 0x4B;

_ExcelWorkbook _parseXlsx(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final shared = _sharedStrings(_xml(archive, 'xl/sharedStrings.xml'));
  final dateStyles = _dateStyleIndexes(_xml(archive, 'xl/styles.xml'));
  final sheets = _sheetPaths(archive);
  if (sheets.isEmpty) throw const FormatException('No worksheet');
  return _ExcelWorkbook([
    for (final sheet in sheets)
      _sheetFromRows(sheet.name, _readSheet(_xml(archive, sheet.path), shared, dateStyles)),
  ]);
}

_ExcelSheet _sheetFromRows(String name, List<List<String>> rows) {
  final trimmed = _trimTable(rows);
  if (trimmed.isEmpty) {
    return _ExcelSheet(
      name: name,
      report: const _ReportLayout(title: null, details: [], section: 'Invoices', columns: [], records: [], total: null),
    );
  }
  final headerIndex = _headerRowIndex(trimmed);
  final preamble = <String>[];
  for (var index = 0; index < headerIndex; index++) {
    final text = trimmed[index].map((cell) => cell.trim()).where((cell) => cell.isNotEmpty).join('  ');
    if (text.isNotEmpty) preamble.add(text);
  }
  String? section;
  if (preamble.isNotEmpty && !preamble.last.contains(':')) {
    section = preamble.removeLast();
  }
  final title = preamble.isEmpty ? null : preamble.removeAt(0);
  final columns = trimmed[headerIndex].map((cell) => cell.trim()).toList();
  final records = <List<String>>[];
  List<String>? total;
  for (var index = headerIndex + 1; index < trimmed.length; index++) {
    if (trimmed[index].every((cell) => cell.trim().isEmpty)) continue;
    final first = trimmed[index].first.trim().toLowerCase();
    if (first == 'total' || first.startsWith('total ')) {
      total = trimmed[index];
      continue;
    }
    records.add(trimmed[index]);
  }
  return _ExcelSheet(
    name: name,
    report: _ReportLayout(
      title: title,
      details: preamble,
      section: section == null || section.isEmpty ? 'Invoice-wise detail' : section,
      columns: columns,
      records: records,
      total: total,
    ),
  );
}

int _headerRowIndex(List<List<String>> rows) {
  var bestIndex = 0;
  var bestScore = -1;
  for (var index = 0; index < rows.length; index++) {
    final values = rows[index].map((cell) => cell.trim()).where((cell) => cell.isNotEmpty).toList();
    if (values.isEmpty) continue;
    if (values.first.toLowerCase() == 'total' || values.first.toLowerCase().startsWith('total ')) continue;
    final textCount = values.where((cell) => num.tryParse(cell.replaceAll(',', '')) == null).length;
    final headerBonus = values.length >= 2 && textCount >= (values.length * 0.7) ? 1000 : 0;
    final score = headerBonus + (values.length * 10) + textCount;
    if (score > bestScore) {
      bestScore = score;
      bestIndex = index;
    }
  }
  return bestIndex;
}

List<List<String>> _trimTable(List<List<String>> rows) {
  if (rows.isEmpty) return const [];
  var lastColumn = 0;
  for (final row in rows) {
    for (var column = row.length - 1; column >= 0; column--) {
      if (row[column].trim().isNotEmpty && column > lastColumn) lastColumn = column;
    }
  }
  final dense = <List<String>>[];
  for (final row in rows) {
    dense.add([
      for (var column = 0; column <= lastColumn; column++) column < row.length ? row[column] : '',
    ]);
  }
  while (dense.isNotEmpty && dense.last.every((cell) => cell.trim().isEmpty)) {
    dense.removeLast();
  }
  while (dense.length > 1 && dense.first.every((cell) => cell.trim().isEmpty)) {
    dense.removeAt(0);
  }
  if (dense.length > 2000) return dense.take(2000).toList();
  return dense;
}

List<_SheetRef> _sheetPaths(Archive archive) {
  final workbook = _xml(archive, 'xl/workbook.xml');
  final rels = _xml(archive, 'xl/_rels/workbook.xml.rels');
  final targets = <String, String>{};
  if (rels != null) {
    for (final rel in rels.findAllElements('Relationship')) {
      final type = _attr(rel, 'Type') ?? '';
      if (!type.endsWith('/worksheet')) continue;
      final id = _attr(rel, 'Id');
      final target = _attr(rel, 'Target');
      if (id == null || target == null) continue;
      targets[id] = _resolvePath('xl', target);
    }
  }
  final sheets = <_SheetRef>[];
  if (workbook != null) {
    for (final sheet in workbook.findAllElements('sheet')) {
      final id = _attr(sheet, 'id');
      final path = id == null ? null : targets[id];
      if (path == null) continue;
      sheets.add(_SheetRef(_attr(sheet, 'name') ?? 'Sheet ${sheets.length + 1}', path));
    }
  }
  if (sheets.isNotEmpty) return sheets;
  final fallback = <_SheetRef>[];
  for (final file in archive.files) {
    if (!file.isFile) continue;
    final name = file.name.replaceAll('\\', '/');
    if (name.contains('xl/worksheets/sheet') && name.endsWith('.xml')) {
      fallback.add(_SheetRef('Sheet ${fallback.length + 1}', name.replaceFirst(RegExp(r'^/'), '')));
    }
  }
  fallback.sort((a, b) => a.path.compareTo(b.path));
  return fallback;
}

List<List<String>> _readSheet(XmlDocument? document, List<String> shared, Set<int> dateStyles) {
  if (document == null) return const [];
  final cells = <int, Map<int, String>>{};
  var maxRow = -1;
  var maxColumn = -1;
  for (final row in document.findAllElements('row')) {
    var fallbackColumn = 0;
    int? currentRow = _parseIndex(_attr(row, 'r'));
    for (final cell in row.childElements) {
      if (cell.name.local != 'c') continue;
      final ref = _attr(cell, 'r') ?? '';
      final column = ref.isEmpty ? fallbackColumn : _columnIndex(ref);
      final rowIndex = currentRow ?? (ref.isEmpty ? 0 : _rowIndex(ref));
      currentRow ??= rowIndex;
      final value = _cellText(cell, shared, dateStyles);
      cells.putIfAbsent(rowIndex, () => {})[column] = value;
      if (column > maxColumn) maxColumn = column;
      if (rowIndex > maxRow) maxRow = rowIndex;
      fallbackColumn = column + 1;
    }
  }
  if (maxRow < 0 || maxColumn < 0) return const [];
  if (maxColumn > 39) maxColumn = 39;
  return [
    for (var row = 0; row <= maxRow; row++)
      [
        for (var column = 0; column <= maxColumn; column++) cells[row]?[column] ?? '',
      ],
  ];
}

String _cellText(XmlElement cell, List<String> shared, Set<int> dateStyles) {
  final type = _attr(cell, 't') ?? 'n';
  if (type == 'inlineStr') {
    return cell.findAllElements('t').map((node) => node.innerText).join();
  }
  final raw = cell.childElements.where((node) => node.name.local == 'v').map((node) => node.innerText).join();
  if (type == 's') {
    final index = int.tryParse(raw);
    if (index == null || index < 0 || index >= shared.length) return '';
    return shared[index];
  }
  if (type == 'b') return raw == '1' ? 'Yes' : 'No';
  if (type == 'str' || type == 'e') return raw;
  final style = int.tryParse(_attr(cell, 's') ?? '');
  if (style != null && dateStyles.contains(style)) {
    final serial = double.tryParse(raw);
    if (serial != null) return _formatExcelDate(serial);
  }
  return _formatNumber(raw);
}

String _formatNumber(String raw) {
  final value = num.tryParse(raw);
  if (value == null) return raw;
  if (value == value.roundToDouble() && raw.contains('.')) return value.round().toString();
  return raw;
}

String _formatExcelDate(double serial) {
  final utc = DateTime.utc(1899, 12, 30).add(Duration(milliseconds: (serial * 86400000).round()));
  final local = DateTime(utc.year, utc.month, utc.day, utc.hour, utc.minute);
  if (serial.abs() < 1) return DateFormat('h:mm a').format(local);
  if (utc.hour == 0 && utc.minute == 0) return DateFormat('d MMM yyyy').format(local);
  return DateFormat('d MMM yyyy, h:mm a').format(local);
}

List<String> _sharedStrings(XmlDocument? document) {
  if (document == null) return const [];
  return [
    for (final item in document.findAllElements('si')) _sharedString(item),
  ];
}

String _sharedString(XmlElement item) {
  final direct = item.childElements.where((node) => node.name.local == 't');
  if (direct.isNotEmpty) return direct.map((node) => node.innerText).join();
  final buffer = StringBuffer();
  for (final run in item.childElements.where((node) => node.name.local == 'r')) {
    for (final text in run.childElements.where((node) => node.name.local == 't')) {
      buffer.write(text.innerText);
    }
  }
  return buffer.toString();
}

Set<int> _dateStyleIndexes(XmlDocument? styles) {
  if (styles == null) return {};
  final formats = <int, String>{};
  for (final format in styles.findAllElements('numFmt')) {
    final id = int.tryParse(_attr(format, 'numFmtId') ?? '');
    if (id == null) continue;
    formats[id] = _attr(format, 'formatCode') ?? '';
  }
  final cellXfs = styles.findAllElements('cellXfs');
  if (cellXfs.isEmpty) return {};
  final indexes = <int>{};
  var index = 0;
  for (final xf in cellXfs.first.childElements) {
    if (xf.name.local != 'xf') continue;
    final id = int.tryParse(_attr(xf, 'numFmtId') ?? '') ?? 0;
    if (_builtinDateIds.contains(id) || _looksLikeDateFormat(formats[id] ?? '')) indexes.add(index);
    index++;
  }
  return indexes;
}

bool _looksLikeDateFormat(String code) {
  if (code.isEmpty) return false;
  final stripped = code.replaceAll(RegExp(r'\[[^\]]*\]'), '').replaceAll(RegExp(r'"[^"]*"'), '');
  return RegExp(r'[ydhs]', caseSensitive: false).hasMatch(stripped);
}

XmlDocument? _xml(Archive archive, String path) {
  final bytes = _archiveFile(archive, path);
  if (bytes == null || bytes.isEmpty) return null;
  return XmlDocument.parse(utf8.decode(bytes, allowMalformed: true));
}

Uint8List? _archiveFile(Archive archive, String path) {
  final target = path.replaceAll('\\', '/').replaceFirst(RegExp(r'^/'), '');
  for (final file in archive.files) {
    if (!file.isFile) continue;
    final name = file.name.replaceAll('\\', '/').replaceFirst(RegExp(r'^/'), '');
    if (name != target) continue;
    final bytes = file.readBytes();
    if (bytes == null) return null;
    return Uint8List.fromList(bytes);
  }
  return null;
}

String _resolvePath(String baseDir, String target) {
  final cleaned = target.replaceAll('\\', '/');
  if (cleaned.startsWith('/')) return cleaned.replaceFirst(RegExp(r'^/'), '');
  final parts = <String>[...baseDir.split('/'), ...cleaned.split('/')];
  final resolved = <String>[];
  for (final part in parts) {
    if (part == '..') {
      if (resolved.isNotEmpty) resolved.removeLast();
    } else if (part.isNotEmpty && part != '.') {
      resolved.add(part);
    }
  }
  return resolved.join('/');
}

String? _attr(XmlElement element, String local) {
  for (final attribute in element.attributes) {
    if (attribute.name.local == local) return attribute.value;
  }
  return null;
}

int? _parseIndex(String? value) {
  final parsed = int.tryParse(value ?? '');
  if (parsed == null || parsed <= 0) return null;
  return parsed - 1;
}

int _columnIndex(String ref) {
  final letters = ref.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
  var index = 0;
  for (final code in letters.codeUnits) {
    index = index * 26 + (code - 64);
  }
  return index <= 0 ? 0 : index - 1;
}

int _rowIndex(String ref) {
  final digits = ref.replaceAll(RegExp(r'[^0-9]'), '');
  final parsed = int.tryParse(digits);
  if (parsed == null || parsed <= 0) return 0;
  return parsed - 1;
}

List<List<String>> _parseDelimited(String text) {
  final lines = const LineSplitter().convert(text);
  if (lines.isEmpty) return const [];
  final delimiter = lines.first.split('\t').length > lines.first.split(',').length ? '\t' : ',';
  return [
    for (final line in lines)
      if (line.trim().isNotEmpty) _splitCsvLine(line, delimiter),
  ];
}

List<String> _splitCsvLine(String line, String delimiter) {
  if (delimiter == '\t') return line.split('\t').map((cell) => cell.trim()).toList();
  final cells = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  for (var index = 0; index < line.length; index++) {
    final char = line[index];
    if (char == '"') {
      if (quoted && index + 1 < line.length && line[index + 1] == '"') {
        buffer.write('"');
        index++;
      } else {
        quoted = !quoted;
      }
    } else if (char == ',' && !quoted) {
      cells.add(buffer.toString().trim());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  cells.add(buffer.toString().trim());
  return cells;
}

class _SheetRef {
  final String name;
  final String path;

  const _SheetRef(this.name, this.path);
}
