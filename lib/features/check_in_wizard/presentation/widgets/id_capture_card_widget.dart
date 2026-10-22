import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class TwoButtonIdCaptureSection extends StatelessWidget {
  final BuildContext context;
  final String? frontPhotoUrl;
  final String? backPhotoUrl;
  final VoidCallback onCaptureFront;
  final VoidCallback onCaptureBack;
  final VoidCallback onGalleryFront;
  final VoidCallback onGalleryBack;
  final VoidCallback onRemoveFront;
  final VoidCallback onRemoveBack;
  final String guestName;
  final String idType;
  final String idNumber;

  const TwoButtonIdCaptureSection({
    super.key,
    required this.context,
    required this.frontPhotoUrl,
    required this.backPhotoUrl,
    required this.onCaptureFront,
    required this.onCaptureBack,
    required this.onGalleryFront,
    required this.onGalleryBack,
    required this.onRemoveFront,
    required this.onRemoveBack,
    required this.guestName,
    required this.idType,
    required this.idNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: IdCardButtonSlot(
            title: 'Front ID',
            isBackSide: false,
            photoUrl: frontPhotoUrl,
            onCameraTap: onCaptureFront,
            onGalleryTap: onGalleryFront,
            onRemoveTap: onRemoveFront,
            guestName: guestName,
            idType: idType,
            idNumber: idNumber,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: IdCardButtonSlot(
            title: 'Back ID',
            isBackSide: true,
            photoUrl: backPhotoUrl,
            onCameraTap: onCaptureBack,
            onGalleryTap: onGalleryBack,
            onRemoveTap: onRemoveBack,
            guestName: guestName,
            idType: idType,
            idNumber: idNumber,
          ),
        ),
      ],
    );
  }
}

class IdCardButtonSlot extends StatelessWidget {
  final String title;
  final bool isBackSide;
  final String? photoUrl;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onRemoveTap;
  final String guestName;
  final String idType;
  final String idNumber;

  const IdCardButtonSlot({
    super.key,
    required this.title,
    required this.isBackSide,
    required this.photoUrl,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onRemoveTap,
    required this.guestName,
    required this.idType,
    required this.idNumber,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = photoUrl != null && photoUrl!.isNotEmpty;
    final bool isRealFile = hasImage &&
        !kIsWeb &&
        photoUrl != 'scanned_aadhaar.png' &&
        photoUrl != 'scanned_aadhaar_back.png' &&
        File(photoUrl!).existsSync();

    if (!hasImage) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCameraTap,
            borderRadius: BorderRadius.circular(10),
            splashColor: AppColors.primary.withValues(alpha: 0.12),
            highlightColor: AppColors.primary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Tap to capture',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 3),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onGalleryTap,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.photo_library_outlined,
                          size: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final displayName = guestName.trim().isNotEmpty ? guestName.toUpperCase() : 'GUEST DOCUMENT';
    final displayIdNum = idNumber.trim().isNotEmpty ? idNumber : '5421-9876-1234';

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isRealFile)
              GestureDetector(
                onTap: () => showFullScreenImageModal(context, photoUrl!, idType, displayName, isBackSide: isBackSide),
                child: Image.file(
                  File(photoUrl!),
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: 300,
                      height: 180,
                      child: buildOriginalDocumentImageCard(
                        idType: idType,
                        guestName: displayName,
                        idNumber: displayIdNum,
                        isBackSide: isBackSide,
                      ),
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => showFullScreenImageModal(context, photoUrl!, idType, displayName, isBackSide: isBackSide),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: 300,
                    height: 180,
                    child: buildOriginalDocumentImageCard(
                      idType: idType,
                      guestName: displayName,
                      idNumber: displayIdNum,
                      isBackSide: isBackSide,
                    ),
                  ),
                ),
              ),
            Container(
              color: Colors.black54,
            ),
            Positioned(
              top: 4,
              left: 5,
              right: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 10, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onRemoveTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 4,
              left: 5,
              right: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                    child: InkWell(
                      onTap: onCameraTap,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              'Retake',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showFullScreenImageModal(context, photoUrl!, idType, displayName, isBackSide: isBackSide),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.fullscreen_rounded, size: 12, color: Colors.white),
                      ),
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
}

bool isRemoteProofPath(String path) {
  final value = path.trim().toLowerCase();
  return value.startsWith('http://') || value.startsWith('https://');
}

bool isStoredProofFile(String path) {
  if (path.trim().isEmpty || isRemoteProofPath(path)) return false;
  return !kIsWeb &&
      path != 'scanned_aadhaar.png' &&
      path != 'scanned_aadhaar_back.png' &&
      File(path).existsSync();
}

Widget proofImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  if (isRemoteProofPath(path)) {
    return Image.network(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFF1E293B),
        child: Icon(Icons.badge_rounded, color: Colors.white54, size: 24),
      ),
    );
  }
  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (_, _, _) => const ColoredBox(
      color: Color(0xFF1E293B),
      child: Icon(Icons.badge_rounded, color: Colors.white54, size: 24),
    ),
  );
}

void showFullScreenImageModal(
  BuildContext context,
  String photoUrl,
  String idType,
  String guestName, {
  bool isBackSide = false,
}) {
  final bool isRealFile = isRemoteProofPath(photoUrl) || isStoredProofFile(photoUrl);

  final sideText = isBackSide ? 'Back Side' : 'Front Side';

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$idType ($sideText)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          guestName.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF334155)),
            // Image Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: isRealFile
                    ? proofImage(
                        photoUrl,
                        fit: BoxFit.contain,
                      )
                    : buildOriginalDocumentImageCard(
                        idType: idType,
                        guestName: guestName,
                        idNumber: '5421-9876-1234',
                        isBackSide: isBackSide,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Close Preview'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildOriginalDocumentImageCard({
  required String idType,
  required String guestName,
  required String idNumber,
  bool isBackSide = false,
}) {
  if (isBackSide) {
    return _buildAadhaarBackCard(guestName, idNumber);
  }
  return _buildAadhaarFrontCard(guestName, idNumber);
}

Widget _buildAadhaarFrontCard(String guestName, String idNumber) {
  return Container(
    height: 180,
    decoration: BoxDecoration(
      color: const Color(0xFFFDFCF9),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
                stops: [0.33, 0.66, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, size: 15, color: Color(0xFF1E293B)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'भारत सरकार',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                            Text(
                              'GOVERNMENT OF INDIA',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: 0.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.fingerprint_rounded, size: 20, color: Color(0xFFDC2626)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFF94A3B8), width: 1.0),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.person, size: 30, color: Color(0xFF64748B)),
                      Positioned(
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'VERIFIED',
                            style: GoogleFonts.inter(fontSize: 5, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guestName.isNotEmpty ? guestName : 'NIRAJ VEKARIYA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'DOB: 14/08/1995 • MALE',
                        style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        idNumber.isNotEmpty ? idNumber : '5421 9876 1234',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
            child: Text(
              'आधार - आम आदमी का अधिकार',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildAadhaarBackCard(String guestName, String idNumber) {
  return Container(
    height: 180,
    decoration: BoxDecoration(
      color: const Color(0xFFFDFCF9),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
                stops: [0.33, 0.66, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, size: 15, color: Color(0xFF1E293B)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'भारतीय विशिष्ट पहचान प्राधिकरण',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                            Text(
                              'UNIQUE IDENTIFICATION AUTHORITY OF INDIA',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: 0.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'BACK SIDE',
                    style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.w800, color: const Color(0xFF0284C7)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'पता / Address:',
                        style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'S/O Ramesh Kumar, House No. 42/B, Green Park Extension, New Delhi - 110016',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 8, height: 1.2, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_in_talk_rounded, size: 9, color: Color(0xFF0D9488)),
                          const SizedBox(width: 3),
                          Text(
                            'UIDAI Helpline: 1947',
                            style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.w600, color: const Color(0xFF0D9488)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF94A3B8), width: 1.0),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, size: 38, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
            child: Text(
              'मेरा आधार, मेरी पहचान',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
            ),
          ),
        ],
      ),
    ),
  );
}
