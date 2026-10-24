import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/data/models/guest_folio_model.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_state.dart';
import '../widgets/guest_folio_details_view.dart';

class InHouseGuestDetailsPage extends StatefulWidget {
  final String folioId;
  final bool isEmbedded;
  final VoidCallback? onClose;
  final int initialTabIndex;

  const InHouseGuestDetailsPage({
    super.key,
    required this.folioId,
    this.isEmbedded = false,
    this.onClose,
    this.initialTabIndex = 0,
  });

  @override
  State<InHouseGuestDetailsPage> createState() => _InHouseGuestDetailsPageState();
}

class _InHouseGuestDetailsPageState extends State<InHouseGuestDetailsPage> {
  GuestFolioModel? _loadedFolio;

  String _appBarTitle(GuestFolioModel? folio, {String fallback = 'Guest Details'}) {
    if (folio == null) return fallback;
    final name = folio.guestName.trim();
    final rawRoom = folio.assignedRoom.replaceAll(RegExp(r'^(Room\s*#?|#)'), '').trim();
    final room = rawRoom.isNotEmpty ? 'Room #$rawRoom' : '';
    if (name.isNotEmpty && room.isNotEmpty) return '$name • $room';
    if (name.isNotEmpty) return name;
    if (room.isNotEmpty) return room;
    return fallback;
  }

  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      surfaceTintColor: Colors.white,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back',
        onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _embeddedShell({required PreferredSizeWidget appBar, required Widget body}) {
    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: SizedBox(height: kToolbarHeight + 1, child: appBar),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final folioList = state.folios.where((f) => f.id == widget.folioId).toList();
        if (folioList.isEmpty) {
          final emptyBody = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                Text(
                  'Folio Not Found',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'The selected folio was not found or has been removed.',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );

          if (widget.isEmbedded) {
            return _embeddedShell(appBar: _buildAppBar('Guest Details'), body: emptyBody);
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: _buildAppBar('Guest Details'),
            body: emptyBody,
          );
        }

        final folio = _loadedFolio ?? folioList.first;
        final body = GuestFolioDetailsView(
          folio: folio,
          isDialog: false,
          onClose: widget.onClose ?? () => Navigator.of(context).maybePop(),
          initialTabIndex: widget.initialTabIndex,
          onFolioLoaded: (loaded) {
            if (mounted) setState(() => _loadedFolio = loaded);
          },
        );

        final appBar = _buildAppBar(_appBarTitle(folio));

        if (widget.isEmbedded) {
          return _embeddedShell(appBar: appBar, body: body);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: appBar,
          body: body,
        );
      },
    );
  }
}
