import 'package:flutter/material.dart';
import '../../../dashboard/data/models/guest_folio_model.dart';
import 'guest_folio_details_view.dart';

class GuestFolioDetailsDialog extends StatelessWidget {
  final GuestFolioModel folio;

  const GuestFolioDetailsDialog({
    super.key,
    required this.folio,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Responsive bounded height that fits mobile and desktop screens without overflow
    final dialogHeight = (screenHeight * 0.86).clamp(440.0, 750.0);

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SizedBox(
          height: dialogHeight,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GuestFolioDetailsView(
              folio: folio,
              isDialog: true,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}
