import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// Camera photo of a signed paper, or a finger signature on the digital pad.
enum SignatureMode {
  camera,
  pad,
}

/// Guest signature: capture a photo from the camera, or sign on the digital pad.
class SignaturePadWidget extends StatefulWidget {
  final List<Offset?> initialPoints;
  final String? initialPhotoPath;
  final ValueChanged<List<Offset?>> onSignatureChanged;
  final ValueChanged<String?>? onPhotoChanged;
  final VoidCallback? onCleared;
  final bool isRequired;
  final String signerName;
  final String? title;

  const SignaturePadWidget({
    super.key,
    this.initialPoints = const [],
    this.initialPhotoPath,
    required this.onSignatureChanged,
    this.onPhotoChanged,
    this.onCleared,
    this.isRequired = true,
    this.signerName = '',
    this.title,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  SignatureMode _activeMode = SignatureMode.camera;
  late List<Offset?> _points;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _points = List.from(widget.initialPoints);
    _photoPath = widget.initialPhotoPath;
  }

  @override
  void didUpdateWidget(covariant SignaturePadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPoints != oldWidget.initialPoints) {
      _points = List.from(widget.initialPoints);
    }
    if (widget.initialPhotoPath != oldWidget.initialPhotoPath) {
      _photoPath = widget.initialPhotoPath;
    }
  }

  bool get _hasDrawnSignature => _points.any((p) => p != null);

  bool get _hasSignature => _photoPath != null || _hasDrawnSignature;

  void _clearSignature() {
    setState(() {
      _points.clear();
      _photoPath = null;
    });
    widget.onSignatureChanged([]);
    widget.onPhotoChanged?.call(null);
    widget.onCleared?.call();
  }

  Future<void> _captureSignaturePhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        maxHeight: 900,
        imageQuality: 90,
      );
      if (file == null) return;
      setState(() {
        _photoPath = file.path;
        _points.clear();
      });
      widget.onSignatureChanged(const []);
      widget.onPhotoChanged?.call(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open camera: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSig = _hasSignature;
    final displayName = widget.signerName.trim().isNotEmpty
        ? widget.signerName.trim()
        : 'Niraj Vekariya';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSig ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          width: hasSig ? 1.4 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: hasSig
                ? const Color(0xFF10B981).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------ TOP LUXURY HEADER ROW (RESPONSIVE) ------------------
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFE6FFFA), Color(0xFFCCFBF1)],
                            ),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: const Color(0xFF99F6E4), width: 1),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.draw_rounded,
                              color: Color(0xFF0D9488),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: widget.title ?? 'Main Guest Signature',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              children: [
                                if (widget.isRequired)
                                  const TextSpan(
                                    text: ' *',
                                    style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700),
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$displayName • ${widget.title != null ? "Attached Guest" : "Primary Guest"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildStatusBadge(hasSig, compact: true),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFE6FFFA), Color(0xFFCCFBF1)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF99F6E4), width: 1),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.draw_rounded,
                              color: Color(0xFF0D9488),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: widget.title ?? 'Main Guest Signature',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                  children: [
                                    if (widget.isRequired)
                                      const TextSpan(
                                        text: ' *',
                                        style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700),
                                      ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '$displayName • ${widget.title != null ? "Attached Guest" : "Primary Guest"}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(hasSig),
                ],
              );
            },
          ),

          const SizedBox(height: 8),

          // ------------------ SEGMENTED MODE CONTROLLER ------------------
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentTab(
                    mode: SignatureMode.camera,
                    icon: Icons.photo_camera_rounded,
                    label: 'Camera',
                    sublabel: 'Photo',
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildSegmentTab(
                    mode: SignatureMode.pad,
                    icon: Icons.draw_rounded,
                    label: 'Digital Pad',
                    sublabel: 'Draw',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ------------------ MAIN INTERACTIVE CANVAS CONTAINER ------------------
          CustomPaint(
            painter: _DashedRectPainter(
              color: hasSig ? const Color(0xFF10B981) : const Color(0xFF0D9488).withValues(alpha: 0.6),
              strokeWidth: 1.3,
              radius: 12,
              dash: 6,
              gap: 4,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: hasSig
                    ? const Color(0xFFF0FDF4).withValues(alpha: 0.4)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildActiveModeContent(),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool hasSig, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3.5 : 5,
      ),
      decoration: BoxDecoration(
        color: hasSig ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasSig ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
          width: 1.1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSig ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: compact ? 11 : 13,
            color: hasSig ? const Color(0xFF059669) : const Color(0xFFD97706),
          ),
          SizedBox(width: compact ? 3 : 5),
          Text(
            hasSig ? 'Signed' : (widget.isRequired ? 'Required' : 'Optional'),
            style: GoogleFonts.inter(
              fontSize: compact ? 9.5 : 11,
              fontWeight: FontWeight.w700,
              color: hasSig ? const Color(0xFF065F46) : const Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required SignatureMode mode,
    required IconData icon,
    required String label,
    required String sublabel,
  }) {
    final isSelected = _activeMode == mode;

    return InkWell(
      onTap: () {
        setState(() {
          _activeMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          border: isSelected
              ? Border.all(color: const Color(0xFFE2E8F0), width: 0.8)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              sublabel,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveModeContent() {
    switch (_activeMode) {
      case SignatureMode.camera:
        return _buildCameraContent();
      case SignatureMode.pad:
        return _buildScreenDrawContent(_hasDrawnSignature);
    }
  }

  Future<void> _openSignatureDialog({bool clearFirst = false}) async {
    final result = await showDialog<List<Offset?>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return SignatureCaptureDialog(
          signerName: widget.signerName.isNotEmpty ? widget.signerName : 'Primary Guest',
          title: widget.title ?? 'Main Guest Signature',
          initialPoints: clearFirst ? [] : _points,
        );
      },
    );

    if (result != null) {
      setState(() {
        _points = List.from(result);
        _photoPath = null;
      });
      widget.onPhotoChanged?.call(null);
      widget.onSignatureChanged(List<Offset?>.from(_points));
    }
  }

  /// ----------------- SCREEN DRAW MODE -----------------
  Widget _buildScreenDrawContent(bool hasSig) {
    return Column(
      children: [
        // Canvas Container (Tap opens popup dialog when empty or re-signing)
        GestureDetector(
          onTap: () => _openSignatureDialog(clearFirst: hasSig),
          child: Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasSig ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // Dotted baseline guide
                  Positioned(
                    bottom: 14,
                    left: 18,
                    right: 18,
                    child: Row(
                      children: [
                        Text(
                          'X ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFCBD5E1),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            hasSig ? 'Authorized Guest Signature' : 'Sign on line above',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: hasSig ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Signature verified badge when signed
                  if (hasSig)
                    Positioned(
                      top: 6,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF059669)),
                            const SizedBox(width: 3),
                            Text(
                              'Digital Signature',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  CustomPaint(
                    painter: _SignaturePainter(points: _points, fitToSize: hasSig),
                    size: Size.infinite,
                  ),

                  if (!hasSig)
                    Center(
                      child: ElevatedButton.icon(
                        key: const ValueKey('add_signature_btn'),
                        onPressed: _openSignatureDialog,
                        icon: const Icon(Icons.draw_rounded, size: 15),
                        label: const Text('Add Signature'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        if (hasSig) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF059669)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Signature captured!',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFF059669),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                key: const ValueKey('signature_edit_btn'),
                onPressed: () => _openSignatureDialog(clearFirst: true),
                icon: const Icon(Icons.edit_rounded, size: 12),
                label: const Text('Re-sign'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF99F6E4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  textStyle: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                key: const ValueKey('signature_clear_btn'),
                onTap: _clearSignature,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 12, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _signaturePhoto(String path) {
    final remote = path.trim().toLowerCase().startsWith('http://') || path.trim().toLowerCase().startsWith('https://');
    if (remote) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 140,
        errorBuilder: (_, _, _) => const SizedBox(height: 140),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: 140,
      errorBuilder: (_, _, _) => const SizedBox(height: 140),
    );
  }

  Widget _buildCameraContent() {
    final hasPhoto = _photoPath != null;
    return Column(
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasPhoto ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: hasPhoto
                ? _signaturePhoto(_photoPath!)
                : Center(
                    child: ElevatedButton.icon(
                      key: const ValueKey('capture_signature_camera_btn'),
                      onPressed: _captureSignaturePhoto,
                      icon: const Icon(Icons.photo_camera_rounded, size: 16),
                      label: const Text('Capture from Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
          ),
        ),
        if (hasPhoto) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF059669)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Signature photo captured!',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFF059669),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _captureSignaturePhoto,
                icon: const Icon(Icons.photo_camera_rounded, size: 12),
                label: const Text('Retake'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF99F6E4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  textStyle: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                key: const ValueKey('signature_photo_clear_btn'),
                onTap: _clearSignature,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Custom painter for smooth, anti-aliased signature strokes with optional responsive fitting
class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final bool fitToSize;

  _SignaturePainter({required this.points, this.fitToSize = false});

  @override
  void paint(Canvas canvas, Size size) {
    final validPoints = points.whereType<Offset>().toList();
    if (validPoints.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.6
      ..isAntiAlias = true;

    if (fitToSize && size.width > 0 && size.height > 0) {
      double minX = validPoints.first.dx;
      double maxX = validPoints.first.dx;
      double minY = validPoints.first.dy;
      double maxY = validPoints.first.dy;

      for (final p in validPoints) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }

      final strokeWidth = maxX - minX;
      final strokeHeight = maxY - minY;

      if (strokeWidth > 4 && strokeHeight > 4) {
        final availableW = size.width - 24;
        final availableH = size.height - 20;
        final scaleX = availableW / strokeWidth;
        final scaleY = availableH / strokeHeight;
        final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.1, 1.2);

        // Normalize stroke width so line thickness doesn't become ultra-thin when scaled down
        paint.strokeWidth = 2.6 / scale;

        final targetCenterX = size.width / 2;
        final targetCenterY = size.height / 2;
        final strokeCenterX = minX + strokeWidth / 2;
        final strokeCenterY = minY + strokeHeight / 2;

        canvas.save();
        canvas.translate(targetCenterX, targetCenterY);
        canvas.scale(scale);
        canvas.translate(-strokeCenterX, -strokeCenterY);

        _drawStrokes(canvas, paint, points, dotRadius: 1.4 / scale);

        canvas.restore();
        return;
      }
    }

    // Default 1:1 drawing
    _drawStrokes(canvas, paint, points, dotRadius: 1.4);
  }

  void _drawStrokes(Canvas canvas, Paint paint, List<Offset?> pts, {required double dotRadius}) {
    for (int i = 0; i < pts.length; i++) {
      if (pts[i] == null) continue;

      final isSingleDot = (i == 0 || pts[i - 1] == null) &&
          (i == pts.length - 1 || pts[i + 1] == null);

      if (isSingleDot) {
        canvas.drawCircle(pts[i]!, dotRadius, paint);
      } else if (i < pts.length - 1 && pts[i + 1] != null) {
        canvas.drawLine(pts[i]!, pts[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

/// Full interactive modal pop-up for capturing guest digital signature smoothly
class SignatureCaptureDialog extends StatefulWidget {
  final String signerName;
  final String title;
  final List<Offset?> initialPoints;

  const SignatureCaptureDialog({
    super.key,
    required this.signerName,
    required this.title,
    this.initialPoints = const [],
  });

  @override
  State<SignatureCaptureDialog> createState() => _SignatureCaptureDialogState();
}

class _SignatureCaptureDialogState extends State<SignatureCaptureDialog> {
  late List<Offset?> _dialogPoints;

  @override
  void initState() {
    super.initState();
    _dialogPoints = List.from(widget.initialPoints);
  }

  bool get _hasDrawn => _dialogPoints.any((p) => p != null);

  void _undo() {
    if (_dialogPoints.isEmpty) return;
    setState(() {
      while (_dialogPoints.isNotEmpty && _dialogPoints.last == null) {
        _dialogPoints.removeLast();
      }
      while (_dialogPoints.isNotEmpty && _dialogPoints.last != null) {
        _dialogPoints.removeLast();
      }
    });
  }

  void _clear() {
    setState(() {
      _dialogPoints.clear();
    });
  }

  void _onDone() {
    if (!_hasDrawn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please draw your signature before clicking Done',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF0F766E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.of(context).pop(List<Offset?>.from(_dialogPoints));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 16,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF99F6E4)),
                          ),
                          child: const Icon(
                            Icons.draw_rounded,
                            size: 18,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${widget.signerName} • Sign inside frame',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Drawing Canvas Container
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasDrawn ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Baseline guide
                      Positioned(
                        bottom: 22,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            Text(
                              'X ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1.2,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sign on line above',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Watermark when empty
                      if (!_hasDrawn)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.gesture_rounded,
                                size: 30,
                                color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Draw your signature with finger here',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Instant Zero-Latency Touch Drawing via Listener
                      Listener(
                        key: const ValueKey('dialog_drawing_canvas'),
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (event) {
                          setState(() {
                            _dialogPoints.add(event.localPosition);
                          });
                        },
                        onPointerMove: (event) {
                          setState(() {
                            _dialogPoints.add(event.localPosition);
                          });
                        },
                        onPointerUp: (event) {
                          setState(() {
                            _dialogPoints.add(null);
                          });
                        },
                        onPointerCancel: (event) {
                          setState(() {
                            _dialogPoints.add(null);
                          });
                        },
                        child: CustomPaint(
                          painter: _SignaturePainter(points: _dialogPoints, fitToSize: false),
                          size: Size.infinite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Tool row below canvas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _hasDrawn ? 'Signature stroke detected' : 'Touch & drag finger',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: _hasDrawn ? const Color(0xFF059669) : const Color(0xFF64748B),
                        fontWeight: _hasDrawn ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        key: const ValueKey('dialog_undo_signature_btn'),
                        onPressed: _hasDrawn ? _undo : null,
                        icon: const Icon(Icons.undo_rounded, size: 14),
                        label: const Text('Undo'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          visualDensity: VisualDensity.compact,
                          textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        key: const ValueKey('dialog_clear_signature_btn'),
                        onPressed: _hasDrawn ? _clear : null,
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          visualDensity: VisualDensity.compact,
                          textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Bottom action buttons: Cancel and Done
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    key: const ValueKey('dialog_done_signature_btn'),
                    onPressed: _onDone,
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                      textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws an exact dashed rounded rectangle matching modern luxury aesthetics
class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  _DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.gap = 4.0,
    this.dash = 6.0,
    this.radius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dash : gap;
        if (distance + len > metric.length) {
          if (draw) {
            dashPath.addPath(
              metric.extractPath(distance, metric.length),
              Offset.zero,
            );
          }
          break;
        }
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dash != dash ||
        oldDelegate.radius != radius;
  }
}
