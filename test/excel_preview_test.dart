import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_pms_system/features/more/presentation/pages/excel_preview_page.dart';

void main() {
  testWidgets('Excel preview shows the GST sheet rows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExcelPreviewPage(bytes: _sampleWorkbook(), fileName: 'gst-report.xlsx'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Excel Preview'), findsOneWidget);
    expect(find.text('Niraj Resort'), findsOneWidget);
    expect(find.text('Nikol, Ahmedabad'), findsOneWidget);
    expect(find.text('27AAAAA0000A1Z5'), findsOneWidget);
    expect(find.text('Invoice'), findsOneWidget);
    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('180.5'), findsWidgets);
    expect(find.text('Download'), findsOneWidget);
  });
}

Uint8List _sampleWorkbook() {
  final archive = Archive()
    ..addFile(ArchiveFile.string('xl/workbook.xml', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets><sheet name="GST" sheetId="1" r:id="rId1"/></sheets>
</workbook>
'''))
    ..addFile(ArchiveFile.string('xl/_rels/workbook.xml.rels', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>
'''))
    ..addFile(ArchiveFile.string('xl/sharedStrings.xml', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <si><t>Invoice</t></si>
  <si><t>Guest</t></si>
  <si><t>Asha Rao</t></si>
</sst>
'''))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet1.xml', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
    <row r="1"><c r="A1" t="inlineStr"><is><t>Niraj Resort - GST report</t></is></c></row>
    <row r="2"><c r="A2" t="inlineStr"><is><t>Nikol, Ahmedabad</t></is></c></row>
    <row r="3"><c r="A3" t="inlineStr"><is><t>GSTIN: 27AAAAA0000A1Z5  PAN: AAAAA0000A</t></is></c></row>
    <row r="4"><c r="A4" t="inlineStr"><is><t>Period: 01-10-2026 to 31-10-2026  Filters: None</t></is></c></row>
    <row r="5"><c r="A5" t="inlineStr"><is><t>Invoice-wise detail</t></is></c></row>
    <row r="6">
      <c r="A6" t="s"><v>0</v></c>
      <c r="B6" t="s"><v>1</v></c>
      <c r="C6" t="inlineStr"><is><t>Tax</t></is></c>
    </row>
    <row r="7">
      <c r="A7"><v>101</v></c>
      <c r="B7" t="s"><v>2</v></c>
      <c r="C7"><v>180.5</v></c>
    </row>
    <row r="8">
      <c r="A8" t="inlineStr"><is><t>Total</t></is></c>
      <c r="C8"><v>180.5</v></c>
    </row>
  </sheetData>
</worksheet>
'''));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
