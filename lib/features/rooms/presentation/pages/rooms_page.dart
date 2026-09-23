import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../check_in_wizard/presentation/bloc/check_in_bloc.dart';
import '../../../check_in_wizard/presentation/bloc/check_in_event.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_event.dart';
import '../../../dashboard/presentation/bloc/dashboard_state.dart';
import '../../../dashboard/presentation/widgets/room_matrix_section.dart';
import '../../data/models/room_model.dart';
import '../widgets/room_status_dialog.dart';

class RoomsPage extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const RoomsPage({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoomMatrixSection(
                rooms: state.filteredRooms,
                searchQuery: state.searchQuery,
                onSearchChanged: (query) {
                  context.read<DashboardBloc>().add(
                        FilterRoomsEvent(
                          searchQuery: query,
                          floor: state.selectedFloor,
                          status: state.selectedStatus,
                        ),
                      );
                },
                selectedFloor: state.selectedFloor,
                onFloorChanged: (floor) {
                  if (floor != null) {
                    context.read<DashboardBloc>().add(
                          FilterRoomsEvent(
                            searchQuery: state.searchQuery,
                            floor: floor,
                            status: state.selectedStatus,
                          ),
                        );
                  }
                },
                selectedStatus: state.selectedStatus,
                onStatusChanged: (status) {
                  if (status != null) {
                    context.read<DashboardBloc>().add(
                          FilterRoomsEvent(
                            searchQuery: state.searchQuery,
                            floor: state.selectedFloor,
                            status: status,
                          ),
                        );
                  }
                },
                onRoomSelected: (RoomModel room) {
                  RoomStatusDialog.show(
                    context: context,
                    room: room,
                    onStatusChanged: (newStatus) {
                      context.read<DashboardBloc>().add(
                            ChangeRoomStatusDashboardEvent(
                              roomId: room.id,
                              newStatus: newStatus,
                            ),
                          );
                    },
                    onCheckIn: () {
                      context.read<CheckInBloc>().add(InitCheckInWizardEvent(preselectedRoom: room));
                      onNavigateTab?.call(2); // Step Check In tab
                    },
                  );
                },
                onQuickCheckIn: (RoomModel room) {
                  context.read<CheckInBloc>().add(InitCheckInWizardEvent(preselectedRoom: room));
                  onNavigateTab?.call(2);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
