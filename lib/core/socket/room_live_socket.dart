import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../features/auth/data/repositories/auth_repository.dart';

/// Live hotel socket — same host Postman uses: `https://api.myownpms.com`.
///
/// Flutter (dart:io) only supports the WebSocket transport. Polling/XHR does
/// not work on mobile, which is why Postman + website worked while the app did not.
///
/// Token is sent as `auth.token`, Bearer header, query, and accessToken cookie.
/// The server joins the hotel room from that token. No hotel_id is sent.
/// After connect the client emits `dashboard:subscribe`.
class RoomLiveSocket {
  io.Socket? _socket;
  AuthRepository? _repository;
  String? _token;
  int _generation = 0;
  bool _refreshing = false;
  Timer? _keepAlive;

  void Function(String event, dynamic data)? onEvent;

  static const liveEvents = [
    'room:status',
    'room:status_breakdown',
    'room:category_counts',
    'booking:updated',
    'dashboard:updated',
  ];

  /// Same URL as Postman `{{baseUrl}}` → https://api.myownpms.com
  static const String socketUrl = 'https://api.myownpms.com';

  String _dateRange = 'today';

  bool get isConnected => _socket?.connected == true;

  static String dashboardRangeForRole(String role) {
    switch (role.trim().toUpperCase()) {
      case 'RECEPTIONIST':
      case 'MANAGER':
      case 'HOUSEKEEPING':
      case 'ACCOUNTANT':
        return 'today';
      default:
        return 'this_month';
    }
  }

  void setDashboardRange(String range) {
    const allowed = {'today', 'this_week', 'this_month', 'this_year'};
    if (!allowed.contains(range)) return;
    _dateRange = range;
    _subscribeDashboard();
  }

  bool get _skipNetwork {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  Future<void> connect(AuthRepository repository) async {
    if (_skipNetwork) return;
    final generation = ++_generation;
    _repository = repository;
    final token = await repository.getValidAccessToken();
    if (generation != _generation) return;
    if (token == null || token.isEmpty) {
      debugPrint('[RoomLiveSocket] skip connect: no access token');
      return;
    }

    if (_token == token && _socket != null && _socket!.connected) {
      _subscribeDashboard();
      _startKeepAlive();
      return;
    }

    await _close(clearRepository: false);
    if (generation != _generation) return;

    final refreshToken = await repository.getSavedRefreshToken();
    if (generation != _generation) return;

    final cookie = <String>[
      'accessToken=$token',
      'token=$token',
      if (refreshToken != null && refreshToken.isNotEmpty) 'refreshToken=$refreshToken',
    ].join('; ');

    // Match Postman: Socket.IO → https://api.myownpms.com (default /socket.io/).
    // Flutter mobile requires websocket transport (polling is not supported on dart:io).
    debugPrint('[RoomLiveSocket] connecting websocket → $socketUrl');

    final socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .disableAutoConnect()
          .enableForceNew()
          .enableForceNewConnection()
          .enableWithCredentials()
          .setTransports(['websocket'])
          .setPath('/socket.io/')
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(8000)
          .setReconnectionAttempts(999)
          .setTimeout(20000)
          .setAuthFn((callback) {
            final live = _token ?? token;
            callback({
              'token': live,
              'accessToken': live,
            });
          })
          .setQuery({
            'token': token,
            'accessToken': token,
          })
          .setExtraHeaders({
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Cookie': cookie,
          })
          .build(),
    );

    _socket = socket;
    _token = token;

    for (final name in liveEvents) {
      socket.on(name, (dynamic data) => _emit(name, data));
    }
    socket.onConnect((_) {
      debugPrint('[RoomLiveSocket] connected → $socketUrl');
      _subscribeDashboard();
      _startKeepAlive();
    });
    socket.onReconnect((_) {
      debugPrint('[RoomLiveSocket] reconnected → $socketUrl');
      _subscribeDashboard();
      _startKeepAlive();
    });
    socket.onDisconnect((reason) {
      debugPrint('[RoomLiveSocket] disconnected: $reason');
      if (_repository != null) _refreshAfterError();
    });
    socket.on('connect_error', (error) {
      debugPrint('[RoomLiveSocket] connect_error: $error');
      _refreshAfterError();
    });
    socket.on('error', (error) {
      debugPrint('[RoomLiveSocket] error: $error');
    });
    socket.connect();
  }

  void _emit(String name, dynamic data) {
    final payload = _unwrapPayload(data);
    debugPrint('[RoomLiveSocket] event=$name payload=$payload');
    onEvent?.call(name, payload);
  }

  void _subscribeDashboard() {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    socket.emit('dashboard:subscribe', {'date_range': _dateRange});
    debugPrint('[RoomLiveSocket] dashboard:subscribe date_range=$_dateRange');
  }

  void _startKeepAlive() {
    _keepAlive?.cancel();
    _keepAlive = Timer.periodic(const Duration(seconds: 25), (_) async {
      final repository = _repository;
      if (repository == null) return;
      final socket = _socket;
      if (socket == null || !socket.connected) {
        await connect(repository);
        return;
      }
      try {
        final fresh = await repository.getValidAccessToken();
        if (fresh != null && fresh.isNotEmpty) {
          _token = fresh;
        }
      } catch (_) {}
      _subscribeDashboard();
    });
  }

  dynamic _unwrapPayload(dynamic data) {
    if (data is List) {
      if (data.isEmpty) return null;
      return data.first;
    }
    return data;
  }

  Future<void> disconnect() async {
    _generation++;
    _repository = null;
    await _close(clearRepository: true);
  }

  Future<void> _close({required bool clearRepository}) async {
    _keepAlive?.cancel();
    _keepAlive = null;
    final socket = _socket;
    _socket = null;
    _token = null;
    if (clearRepository) _repository = null;
    try {
      socket?.clearListeners();
      socket?.disconnect();
      socket?.dispose();
    } catch (_) {}
  }

  Future<void> _refreshAfterError() async {
    final repository = _repository;
    if (repository == null || _refreshing || _skipNetwork) return;
    _refreshing = true;
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (_repository == null) return;
      if (_socket?.connected == true) {
        _subscribeDashboard();
        return;
      }
      await connect(repository);
    } catch (_) {
      // Next sign-in reconnects.
    } finally {
      _refreshing = false;
    }
  }
}
