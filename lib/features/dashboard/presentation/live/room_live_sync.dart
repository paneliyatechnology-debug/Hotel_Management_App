import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/socket/room_live_socket.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../data/models/admin_dashboard_model.dart';
import '../../data/models/room_live_update.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../live/room_live_hub.dart';
import '../pages/admin_rooms_tariffs_page.dart';
import '../pages/hotel_admin_dashboard_view.dart';
import '../pages/status_rooms_page.dart';

class RoomLiveBinder extends StatefulWidget {
  final Widget child;

  const RoomLiveBinder({super.key, required this.child});

  @override
  State<RoomLiveBinder> createState() => _RoomLiveBinderState();
}

class _RoomLiveBinderState extends State<RoomLiveBinder> with WidgetsBindingObserver {
  final RoomLiveSocket _socket = RoomLiveSocket();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _socket.onEvent = _onSocketEvent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _connectIfSignedIn();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _socket.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    _connectIfSignedIn();
  }

  void _connectIfSignedIn() {
    final auth = context.read<AuthBloc>().state;
    if (!auth.isAuthenticated) return;
    _socket.setDashboardRange(RoomLiveSocket.dashboardRangeForRole(auth.user?.role ?? ''));
    _socket.connect(context.read<AuthBloc>().repository);
  }

  void _onSocketEvent(String name, dynamic data) {
    if (!mounted) return;
    final bloc = context.read<DashboardBloc>();
    bloc.repository.acceptRemoteRoomStatuses();
    switch (name) {
      case 'room:status':
      case 'room:status_breakdown':
        for (final update in parseRoomLivePayload(data)) {
          if (update.isEmpty) continue;
          applyLiveRoomData(update, bloc.state.allRooms);
          bloc.add(LiveRoomSyncEvent(update));
        }
      case 'room:category_counts':
        bloc.add(ApplyCategoryCountsEvent(data));
      case 'booking:updated':
        bloc.add(ApplyLiveBookingEvent(data));
      case 'dashboard:updated':
        _applyDashboardSnapshot(data);
        bloc.add(ApplyLiveDashboardEvent(data));
      default:
        return;
    }
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      context.read<DashboardBloc>().add(QuietRefreshLiveRoomsEvent());
      RoomLiveHub.instance.requestRefresh();
    });
  }

  void _applyDashboardSnapshot(dynamic data) {
    final payload = socketObject(data);
    if (payload == null) return;
    final body = payload['data'] is Map ? Map<String, dynamic>.from(payload['data'] as Map) : payload;
    if (!body.containsKey('kpis') && !body.containsKey('hotel')) return;
    AdminDashboardMemory.snapshot = AdminDashboardSnapshot.fromJson(body);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, next) => previous.status != next.status || previous.token != next.token,
      listener: (context, state) {
        if (state.isAuthenticated) {
          _socket.setDashboardRange(RoomLiveSocket.dashboardRangeForRole(state.user?.role ?? ''));
          _socket.connect(context.read<AuthBloc>().repository);
          return;
        }
        if (state.status == AuthStatus.unauthenticated) {
          _socket.disconnect();
          RoomLiveHub.instance.clear();
        }
      },
      child: widget.child,
    );
  }
}

void applyLiveRoomData(RoomLiveUpdate update, List<RoomModel> knownRooms) {
  final patch = update.room;
  RoomModel? previous;
  if (patch != null) {
    previous = _findRoom(patch, knownRooms) ??
        _findRoom(patch, RoomsDirectoryMemory.rooms ?? const []) ??
        _findRoom(patch, StatusRoomsMemory.roomsByStatus.values.expand((rooms) => rooms));
    if (previous != null) {
      if (patch.removed) {
        final directory = RoomsDirectoryMemory.rooms;
        if (directory != null) {
          RoomsDirectoryMemory.rooms = directory.where((room) => !patch.matches(room)).toList();
        }
        for (final rooms in StatusRoomsMemory.roomsByStatus.values) {
          rooms.removeWhere(patch.matches);
        }
      } else {
      final updated = patch.apply([previous]).single;
      final directory = RoomsDirectoryMemory.rooms;
      if (directory != null) {
        RoomsDirectoryMemory.rooms = patch.apply(directory);
      }
      for (final rooms in StatusRoomsMemory.roomsByStatus.values) {
        rooms.removeWhere(patch.matches);
      }
      StatusRoomsMemory.roomsByStatus[patch.cacheKey]?.insert(0, updated);
      }
    }
  }

  final snapshot = AdminDashboardMemory.snapshot;
  final breakdown = update.breakdown;
  if (snapshot == null) return;
  if (breakdown != null) {
    AdminDashboardMemory.snapshot = snapshot.withRoomCounts(
      availableRooms: breakdown.available,
      occupiedRooms: breakdown.occupied,
      reservedRooms: breakdown.reserved,
      cleaningRooms: breakdown.cleaning,
      maintenanceRooms: breakdown.maintenance,
      blockedRooms: breakdown.blocked,
      inHouseGuests: breakdown.guests,
    );
    return;
  }
  if (patch != null && !patch.removed && previous != null && previous.status != patch.status) {
    AdminDashboardMemory.snapshot = snapshot.withRoomCounts(
      availableRooms: _shift(snapshot.availableRooms, RoomStatus.available, previous.status, patch.status),
      occupiedRooms: _shift(snapshot.occupiedRooms, RoomStatus.occupied, previous.status, patch.status),
      cleaningRooms: _shift(snapshot.cleaningRooms, RoomStatus.cleaning, previous.status, patch.status),
      maintenanceRooms: _shift(snapshot.maintenanceRooms, RoomStatus.maintenance, previous.status, patch.status),
    );
  }
}

RoomModel? _findRoom(RoomPatch patch, Iterable<RoomModel> rooms) {
  for (final room in rooms) {
    if (patch.matches(room)) return room;
  }
  return null;
}

int _shift(int value, RoomStatus slot, RoomStatus from, RoomStatus to) {
  var next = value;
  if (slot == from) next -= 1;
  if (slot == to) next += 1;
  return next < 0 ? 0 : next;
}
