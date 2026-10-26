import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/room_model.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_event.dart';

/// Shows a quick status change dialog on long press of a room card.
///
/// Behavior:
/// - If current status is [RoomStatus.available]: shows 2 buttons: "Cleaning" & "Maintenance"
/// - If current status is [RoomStatus.cleaning]: shows 2 buttons: "Available" & "Maintenance"
/// - If current status is [RoomStatus.maintenance]: shows 2 buttons: "Available" & "Cleaning"
///
/// On tap, triggers PATCH /api/v1/rooms/:id/status with the chosen status payload.
Future<bool?> showRoomQuickStatusDialog({
  required BuildContext context,
  required RoomModel room,
}) {
  final dashboardBloc = context.read<DashboardBloc>();

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => BlocProvider<DashboardBloc>.value(
      value: dashboardBloc,
      child: _RoomQuickStatusDialog(room: room),
    ),
  );
}

class _RoomQuickStatusDialog extends StatefulWidget {
  final RoomModel room;

  const _RoomQuickStatusDialog({required this.room});

  @override
  State<_RoomQuickStatusDialog> createState() => _RoomQuickStatusDialogState();
}

class _RoomQuickStatusDialogState extends State<_RoomQuickStatusDialog> {
  RoomStatus? _loadingStatus;
  String? _errorMessage;

  List<({RoomStatus status, String title, IconData icon, Color color})>
      get _availableActions {
    final current = widget.room.status;

    final cleaningOption = (
      status: RoomStatus.cleaning,
      title: 'Cleaning',
      icon: Icons.cleaning_services_rounded,
      color: const Color(0xFFD97706),
    );

    final maintenanceOption = (
      status: RoomStatus.maintenance,
      title: 'Maintenance',
      icon: Icons.build_rounded,
      color: const Color(0xFFDC2626),
    );

    final availableOption = (
      status: RoomStatus.available,
      title: 'Available',
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF0F766E),
    );

    switch (current) {
      case RoomStatus.available:
        return [cleaningOption, maintenanceOption];
      case RoomStatus.cleaning:
        return [availableOption, maintenanceOption];
      case RoomStatus.maintenance:
        return [availableOption, cleaningOption];
      case RoomStatus.occupied:
        return [cleaningOption, maintenanceOption];
    }
  }

  Future<void> _updateStatus(RoomStatus targetStatus) async {
    setState(() {
      _loadingStatus = targetStatus;
      _errorMessage = null;
    });

    try {
      final repo = context.read<DashboardBloc>().repository;
      await repo.updateRoomStatus(widget.room.id, targetStatus);

      if (!mounted) return;
      context.read<DashboardBloc>().add(RefreshDashboardDataEvent());

      final cleanRoom = widget.room.roomNumber.replaceAll('#', '').replaceAll('Room', '').trim();
      final statusName = switch (targetStatus) {
        RoomStatus.available => 'AVAILABLE',
        RoomStatus.cleaning => 'CLEANING',
        RoomStatus.maintenance => 'MAINTENANCE',
        RoomStatus.occupied => 'OCCUPIED',
      };

      Navigator.of(context).pop(true);
      AppSnackBar.showSuccess(
        context,
        'Room #$cleanRoom status changed to $statusName successfully!',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingStatus = null;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      AppSnackBar.showError(context, _errorMessage ?? 'Failed to update status');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanRoom = widget.room.roomNumber.replaceAll('#', '').replaceAll('Room', '').trim();
    final actions = _availableActions;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Icon, Room Title, and Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCCFBF1), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 22,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room #$cleanRoom Status',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            Text(
                              'Current: ',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            StatusBadge.fromRoomStatus(widget.room.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                    onPressed: _loadingStatus != null ? null : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'Change room status to:',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),

              const SizedBox(height: 10),

              // The 2 Status Action Buttons
              ...actions.map((action) {
                final isLoading = _loadingStatus == action.status;
                final isDisabled = _loadingStatus != null && !isLoading;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      key: Key('quick_status_${action.status.name}'),
                      onPressed: isDisabled || isLoading ? null : () => _updateStatus(action.status),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(action.icon, size: 20, color: Colors.white),
                      label: Text(
                        action.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: action.color,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: action.color.withValues(alpha: 0.5),
                        elevation: 1,
                        shadowColor: action.color.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              if (_errorMessage != null) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFDC2626)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 4),

              // Cancel button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: _loadingStatus != null ? null : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
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
