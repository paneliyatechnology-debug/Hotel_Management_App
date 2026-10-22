import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class GuestFolioPdfPreviewPage extends StatefulWidget {
  final Uint8List bytes;
  final String fileName;

  const GuestFolioPdfPreviewPage({
    super.key,
    required this.bytes,
    required this.fileName,
  });

  @override
  State<GuestFolioPdfPreviewPage> createState() => _GuestFolioPdfPreviewPageState();
}

class _GuestFolioPdfPreviewPageState extends State<GuestFolioPdfPreviewPage> {
  static const _storageChannel = MethodChannel('my_own_pms/pdf_storage');
  bool _downloading = false;
  bool _sharing = false;

  String get _safeFileName {
    final raw = widget.fileName.trim().split(RegExp(r'[\\/]')).last;
    final cleaned = raw.replaceAll(RegExp(r'[<>:"|?*]'), '_').trim();
    final name = cleaned.isEmpty ? 'guest-folio.pdf' : cleaned;
    return name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final savedPath = await _savePdfFile();
      if (!mounted) return;
      final savedToDownloads = Platform.isAndroid && !savedPath.contains('/Android/data/');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedToDownloads
                ? 'PDF saved to Downloads'
                : Platform.isAndroid
                    ? 'PDF saved on this device'
                    : 'PDF saved to Files',
          ),
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

  Future<String> _savePdfFile() async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$_safeFileName');
    await tempFile.writeAsBytes(widget.bytes, flush: true);
    if (!Platform.isAndroid) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_safeFileName');
      await tempFile.copy(file.path);
      return file.path;
    }
    try {
      final saved = await _storageChannel.invokeMethod<String>('savePdf', {
        'name': _safeFileName,
        'path': tempFile.path,
      });
      if (saved == null || saved.isEmpty) {
        throw Exception('Could not save the folio PDF.');
      }
      return saved;
    } on MissingPluginException {
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        final file = File('${downloadDir.path}/$_safeFileName');
        await tempFile.copy(file.path);
        return file.path;
      } catch (_) {
        throw Exception('Stop the app and run it again, then download the PDF.');
      }
    }
  }

  String _saveErrorMessage(Object error) {
    if (error is PlatformException) {
      final message = error.message?.trim() ?? '';
      if (message.isNotEmpty) return message;
    }
    if (error is MissingPluginException) {
      return 'Stop the app and run it again, then download the PDF.';
    }
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty || message == 'Exception') return 'Could not save the folio PDF.';
    return message;
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await Printing.sharePdf(bytes: widget.bytes, filename: _safeFileName);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not share the folio PDF.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'Guest Folio',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: PdfPreview(
        build: (_) => widget.bytes,
        pdfFileName: _safeFileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        useActions: false,
        dynamicLayout: false,
        shouldRepaint: false,
        maxPageWidth: 700,
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0F766E)),
        ),
        scrollViewDecoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not preview this PDF.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
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
                    label: Text(
                      'Download',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      side: const BorderSide(color: Color(0xFF0F766E), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _sharing ? null : _share,
                    icon: _sharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                          )
                        : const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                      'Share',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
