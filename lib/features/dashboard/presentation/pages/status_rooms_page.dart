import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../check_in_wizard/presentation/bloc/check_in_bloc.dart';
import '../../../check_in_wizard/presentation/bloc/check_in_event.dart';
import '../../../check_in_wizard/presentation/pages/check_in_wizard_page.dart';
import '../../../folios/presentation/widgets/checkout_settlement_dialog.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../data/models/guest_folio_model.dart';
import '../../data/repositories/hotel_admin_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../live/room_live_hub.dart';
import '../widgets/dashboard_shimmer_loader.dart';
import '../widgets/modern_room_bottom_sheet.dart';
import '../../../rooms/presentation/widgets/room_quick_status_dialog.dart';

class StatusRoomsMemory {
  static final Map<String, List<RoomModel>> roomsByStatus = {};

  static void clear() => roomsByStatus.clear();
}

class StatusRoomsPage extends StatefulWidget {
  final String title;
  final String status;
  final HotelAdminRepository? repository;

  const StatusRoomsPage({
    super.key,
    required this.title,
    required this.status,
    this.repository,
  });

  @override
  State<StatusRoomsPage> createState() => _StatusRoomsPageState();
}

class _StatusRoomsPageState extends State<StatusRoomsPage> {
  late final HotelAdminRepository _repo;
  bool _isLoading = true;
  String? _errorMessage;
  List<RoomModel> _rooms = const [];

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? HotelAdminRepository();
    final cached = StatusRoomsMemory.roomsByStatus[widget.status];
    if (cached != null) {
      _rooms = List<RoomModel>.from(cached);
      _isLoading = false;
    }
    _loadRooms(showLoader: cached == null);
    RoomLiveHub.instance.addListener(_onLiveRooms);
  }

  void _onLiveRooms() {
    if (!mounted) return;
    final patch = RoomLiveHub.instance.room;
    final cached = StatusRoomsMemory.roomsByStatus[widget.status];
    if (patch != null && cached != null) {
      List<RoomModel> visible;
      if (patch.removed) {
        visible = cached.where((room) => !patch.matches(room)).toList();
      } else {
        visible = [
          for (final room in patch.apply(List<RoomModel>.from(cached)))
            if (_roomMatchesPage(room)) room,
        ];
        // Room moved onto this status page from another list.
        if (_roomMatchesPageStatus(patch.status) && !visible.any(patch.matches)) {
          final created = patch.toRoomModel();
          if (created != null) visible = [created, ...visible];
        }
      }
      StatusRoomsMemory.roomsByStatus[widget.status] = visible;
      setState(() {
        _rooms = visible;
        _isLoading = false;
      });
      return;
    }
    // No live patch — avoid hammering the rooms API on every hub tick.
  }

  bool _roomMatchesPage(RoomModel room) => _roomMatchesPageStatus(room.status);

  bool _roomMatchesPageStatus(RoomStatus status) {
    switch (widget.status.toUpperCase()) {
      case 'AVAILABLE':
        return status == RoomStatus.available;
      case 'OCCUPIED':
        return status == RoomStatus.occupied;
      case 'CLEANING':
        return status == RoomStatus.cleaning;
      case 'MAINTENANCE':
        return status == RoomStatus.maintenance;
      default:
        return true;
    }
  }

  @override
  void dispose() {
    RoomLiveHub.instance.removeListener(_onLiveRooms);
    super.dispose();
  }

  Future<void> _loadRooms({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final rooms = await _repo.fetchRoomsByStatus(status: widget.status);
      if (!mounted) return;
      StatusRoomsMemory.roomsByStatus[widget.status] = List<RoomModel>.from(rooms);
      setState(() {
        _rooms = rooms;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (StatusRoomsMemory.roomsByStatus.containsKey(widget.status)) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshLists() async {
    if (!mounted) return;
    context.read<DashboardBloc>().add(RefreshDashboardDataEvent());
    await _loadRooms(showLoader: false);
  }

  void _openGuestForm(RoomModel room) {
    context.read<CheckInBloc>().add(InitCheckInWizardEvent(preselectedRoom: room));
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckInWizardPage()),
    ).then((_) {
      if (mounted) _refreshLists();
    });
  }

  void _checkoutOccupiedRoom(RoomModel room) {
    final folio = _checkedInFolioFor(room, context.read<DashboardBloc>().state.folios);
    if (folio == null) {
      AppSnackBar.showError(
        context,
        'No checked-in guest was found for this room.',
        title: 'Checkout',
      );
      return;
    }
    CheckoutSettlementDialog.show(context, folio).then((_) {
      if (mounted) _refreshLists();
    });
  }

  Future<void> _confirmMarkAvailable(RoomModel room) async {
    final confirmed = await showMarkRoomAvailableDialog(
      context,
      roomNumber: room.roomNumber,
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<DashboardBloc>().repository.updateRoomStatus(room.id, RoomStatus.available);
      await _refreshLists();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _onRoomTap(RoomModel room) {
    if (room.status == RoomStatus.available) {
      _openGuestForm(room);
    } else if (room.status == RoomStatus.occupied) {
      _checkoutOccupiedRoom(room);
    } else if (room.status == RoomStatus.cleaning) {
      _confirmMarkAvailable(room);
    }
  }

  GuestFolioModel? _checkedInFolioFor(RoomModel room, List<GuestFolioModel> folios) {
    final roomDigits = room.roomNumber.replaceAll(RegExp(r'[^0-9]'), '');
    for (final folio in folios) {
      if (folio.status != FolioStatus.inHouse) continue;
      final folioId = room.currentGuestFolioId;
      if (folioId != null && folioId.isNotEmpty && (folio.id == folioId || folio.bookingId == folioId)) {
        return folio;
      }
      final folioRoom = folio.assignedRoom.replaceAll(RegExp(r'[^0-9]'), '');
      if (roomDigits.isNotEmpty && folioRoom == roomDigits) return folio;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16.5, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: _isLoading
          ? const StatusRoomsShimmer()
          : _errorMessage != null
              ? _StatusEmptyView(
                  icon: Icons.cloud_off_rounded,
                  color: const Color(0xFF64748B),
                  background: const Color(0xFFF1F5F9),
                  title: 'Could not load rooms',
                  subtitle: _errorMessage!,
                  actionLabel: 'Try again',
                  onAction: _loadRooms,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _loadRooms(showLoader: false),
                  child: _rooms.isEmpty
                      ? _StatusEmptyView(
                          icon: _emptyIcon(widget.status),
                          color: _statusTheme(widget.status).color,
                          background: _statusTheme(widget.status).background,
                          title: _emptyTitle(widget.title),
                          subtitle: _emptySubtitle(widget.status),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                          itemCount: _rooms.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  '${_rooms.length} ${widget.title}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              );
                            }
                            final room = _rooms[index - 1];
                            return _StatusRoomCard(
                              room: room,
                              onTap: () => _onRoomTap(room),
                              onLongPress: () async {
                                if (room.status == RoomStatus.available ||
                                    room.status == RoomStatus.cleaning ||
                                    room.status == RoomStatus.maintenance) {
                                  final updated = await showRoomQuickStatusDialog(
                                    context: context,
                                    room: room,
                                  );
                                  if (updated == true && mounted) {
                                    _refreshLists();
                                  }
                                }
                              },
                            );
                          },
                        ),
                ),
    );
  }
}

class _StatusRoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _StatusRoomCard({
    required this.room,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isOccupied = room.status == RoomStatus.occupied;
    final isCleaning = room.status == RoomStatus.cleaning;
    final isMaintenance = room.status == RoomStatus.maintenance;
    final isAvailable = room.status == RoomStatus.available;

    var squircleBg = const Color(0xFFE6F7F2);
    var squircleColor = const Color(0xFF0F766E);
    var badgeBg = const Color(0xFFECFDF5);
    var badgeColor = const Color(0xFF059669);
    var badgeIcon = Icons.check_circle_rounded;
    var badgeLabel = 'AVAILABLE';

    if (isOccupied) {
      squircleBg = AppColors.primarySurface;
      squircleColor = AppColors.primary;
      badgeBg = AppColors.primarySurface;
      badgeColor = AppColors.primary;
      badgeIcon = Icons.person_rounded;
      badgeLabel = 'OCCUPIED';
    } else if (isCleaning) {
      squircleBg = const Color(0xFFFFFBEB);
      squircleColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFFFBEB);
      badgeColor = const Color(0xFFD97706);
      badgeIcon = Icons.cleaning_services_rounded;
      badgeLabel = 'CLEANING';
    } else if (isMaintenance) {
      squircleBg = const Color(0xFFFEF2F2);
      squircleColor = const Color(0xFFDC2626);
      badgeBg = const Color(0xFFFEF2F2);
      badgeColor = const Color(0xFFDC2626);
      badgeIcon = Icons.build_rounded;
      badgeLabel = 'MAINTENANCE';
    }

    final roomTitle = 'Room #${room.roomNumber.replaceAll('#', '')}';
    final guestName = room.currentGuestName?.trim() ?? '';
    final priceLabel = room.pricePerNight == 0 ? '₹0' : CurrencyFormatter.format(room.pricePerNight);
    final detail = isOccupied && guestName.isNotEmpty ? guestName : room.bedInfoLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(14),
          child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isOccupied) const ColoredBox(color: AppColors.primary, child: SizedBox(width: 3)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: squircleBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hotel_rounded, size: 14, color: squircleColor),
                            Text(
                              room.roomNumber.replaceAll('#', ''),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: squircleColor,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    roomTitle,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(badgeIcon, size: 9, color: badgeColor),
                                      const SizedBox(width: 2),
                                      Text(
                                        badgeLabel,
                                        style: GoogleFonts.inter(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: badgeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              room.floor,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Icon(
                                  isOccupied && guestName.isNotEmpty ? Icons.person_rounded : Icons.bed_outlined,
                                  size: 11,
                                  color: isOccupied ? AppColors.primary : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    detail,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: isOccupied ? FontWeight.w700 : FontWeight.w500,
                                      color: isOccupied ? AppColors.primary : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            priceLabel,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            '/nt',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          isOccupied
                              ? _roomActionButton(
                                  label: 'Checkout',
                                  icon: Icons.arrow_back_rounded,
                                  checkout: true,
                                )
                              : isAvailable
                                  ? _roomActionButton(
                                      label: 'Check In',
                                      icon: Icons.arrow_forward_rounded,
                                      iconAfterLabel: true,
                                    )
                                  : isCleaning
                                      ? _roomActionButton(
                                          label: 'Mark as Available',
                                          icon: Icons.check_circle_rounded,
                                        )
                                      : isMaintenance
                                          ? const SizedBox(height: 30)
                                          : _roomActionButton(
                                              label: 'Manage',
                                              icon: Icons.tune_rounded,
                                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}

Widget _roomActionButton({
  required String label,
  required IconData icon,
  bool iconAfterLabel = false,
  bool checkout = false,
}) {
  final color = checkout ? const Color(0xFFDC2626) : AppColors.primary;
  final foreground = checkout ? const Color(0xFFDC2626) : Colors.white;
  final iconWidget = Icon(icon, size: 12, color: foreground);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: checkout ? Colors.white : AppColors.primary,
      borderRadius: BorderRadius.circular(8),
      border: checkout ? Border.all(color: color, width: 1.2) : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!iconAfterLabel) ...[
          iconWidget,
          const SizedBox(width: 4),
        ],
        Text(
          label,
          maxLines: 1,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: foreground,
          ),
        ),
        if (iconAfterLabel) ...[
          const SizedBox(width: 4),
          iconWidget,
        ],
      ],
    ),
  );
}

class _StatusEmptyView extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusEmptyView({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
        Center(
          child: Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: background,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 48, color: color),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(height: 22),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: onAction,
                            child: Text(
                              actionLabel!,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

({Color color, Color background}) _statusTheme(String status) {
  switch (status.toUpperCase()) {
    case 'OCCUPIED':
      return (color: AppColors.statusOccupied, background: AppColors.statusOccupiedBg);
    case 'CLEANING':
      return (color: AppColors.statusCleaning, background: AppColors.statusCleaningBg);
    case 'MAINTENANCE':
      return (color: AppColors.statusMaintenance, background: AppColors.statusMaintenanceBg);
    default:
      return (color: AppColors.statusAvailable, background: AppColors.statusAvailableBg);
  }
}

IconData _emptyIcon(String status) {
  switch (status.toUpperCase()) {
    case 'OCCUPIED':
      return Icons.hotel_rounded;
    case 'CLEANING':
      return Icons.cleaning_services_rounded;
    case 'MAINTENANCE':
      return Icons.handyman_rounded;
    default:
      return Icons.meeting_room_rounded;
  }
}

String _emptyTitle(String title) {
  return 'No ${title.toLowerCase()} rooms';
}

String _emptySubtitle(String status) {
  switch (status.toUpperCase()) {
    case 'OCCUPIED':
      return 'No guests are staying right now. Occupied rooms will show up here as soon as someone checks in.';
    case 'CLEANING':
      return 'Housekeeping is clear. Rooms that need cleaning will appear here after checkout.';
    case 'MAINTENANCE':
      return 'Every room is in service. Rooms marked out of service will show up on this screen.';
    default:
      return 'Nothing is ready for check-in right now. Available rooms will appear here as soon as they are free.';
  }
}

class StatusRoomsShimmer extends StatelessWidget {
  const StatusRoomsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: const [
          ShimmerBox(width: 88, height: 13, borderRadius: 4),
          SizedBox(height: 10),
          _StatusRoomCardShimmer(),
          _StatusRoomCardShimmer(),
          _StatusRoomCardShimmer(),
          _StatusRoomCardShimmer(),
        ],
      ),
    );
  }
}

class _StatusRoomCardShimmer extends StatelessWidget {
  const _StatusRoomCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          ShimmerBox(width: 46, height: 46, borderRadius: 10),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 118, height: 13, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 64, height: 10, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 148, height: 10, borderRadius: 4),
              ],
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShimmerBox(width: 52, height: 13, borderRadius: 4),
              SizedBox(height: 8),
              ShimmerBox(width: 96, height: 26, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}
