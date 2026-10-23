import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

/// Live hotel socket.
///
/// The signed-in access token is sent as `auth.token`, a Bearer header, and
/// the accessToken cookie. The server joins this hotel from that token.
/// No hotel id is sent. After connect, the client subscribes with
/// `dashboard:subscribe`.
class RoomLiveSocket {
  io.Socket? _socket;
  AuthRepository? _repository;
  String? _token;
  int _generation = 0;
  bool _refreshing = false;
  bool _closing = false;

  void Function(String event, dynamic data)? onEvent;

  static const liveEvents = [
    'room:status',
    'room:status_breakdown',
    'room:category_counts',
    'booking:updated',
    'dashboard:updated',
  ];

  String _dateRange = 'today';

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
    final socket = _socket;
    if (socket != null && socket.connected) {
      socket.emit('dashboard:subscribe', {'date_range': _dateRange});
    }
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
    if (token == null || token.isEmpty) return;
    if (_token == token && _socket != null && _socket!.connected) return;

    await _close();
    if (generation != _generation) return;

    final refreshToken = await repository.getSavedRefreshToken();
    if (generation != _generation) return;

    final cookie = <String>[
      'accessToken=$token',
      if (refreshToken != null && refreshToken.isNotEmpty) 'refreshToken=$refreshToken',
    ].join('; ');

    final socket = io.io(
      ApiConstants.socketOrigin,
      io.OptionBuilder()
          .disableAutoConnect()
          .enableForceNew()
          .setTransports(['polling'])
          .setUpgrade(false)
          .setPath('/socket.io/')
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(100)
          .setTimeout(20000)
          .setAuth({
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
      socket.on(name, (dynamic data) => onEvent?.call(name, data));
    }
    socket.onConnect((_) {
      socket.emit('dashboard:subscribe', {'date_range': _dateRange});
    });
    socket.on('connect_error', (_) => _refreshAfterError());
    socket.connect();
  }

  Future<void> disconnect() async {
    _generation++;
    _repository = null;
    await _close();
  }

  Future<void> _close() async {
    final socket = _socket;
    _socket = null;
    _token = null;
    _closing = true;
    socket?.dispose();
    _closing = false;
  }

  Future<void> _refreshAfterError() async {
    final repository = _repository;
    if (repository == null || _refreshing || _skipNetwork) return;
    _refreshing = true;
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (_repository == null || _socket?.connected == true) return;
      await connect(repository);
    } catch (_) {
      // The next sign-in can reconnect.
    } finally {
      _refreshing = false;
    }
  }
}
