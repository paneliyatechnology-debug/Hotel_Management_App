import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/repositories/authenticated_http_client.dart';
import '../models/payment_method_model.dart';

class PaymentMethodsRepository {
  static PaymentMethodsRepository? _instance;

  final http.Client _client;
  List<PaymentMethodModel>? _cache;
  Future<List<PaymentMethodModel>>? _inFlight;

  factory PaymentMethodsRepository({
    http.Client? client,
    AuthRepository? authRepository,
  }) {
    if (_instance == null || client != null || authRepository != null) {
      _instance = PaymentMethodsRepository._(
        client: client,
        authRepository: authRepository,
      );
    }
    return _instance!;
  }

  PaymentMethodsRepository._({
    http.Client? client,
    AuthRepository? authRepository,
  }) : _client = client ??
            AuthenticatedHttpClient(
              authRepository: authRepository ?? AuthRepository(),
            );

  /// GET /api/v1/payment-methods — cached for the session.
  Future<List<PaymentMethodModel>> fetchPaymentMethods({bool forceRefresh = false}) {
    if (!forceRefresh && _cache != null && _cache!.isNotEmpty) {
      return Future.value(List<PaymentMethodModel>.from(_cache!));
    }
    final pending = _inFlight;
    if (!forceRefresh && pending != null) return pending;

    final run = _load();
    _inFlight = run;
    return run.whenComplete(() {
      if (identical(_inFlight, run)) _inFlight = null;
    });
  }

  Future<List<PaymentMethodModel>> _load() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.paymentMethodsUrl),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _useFallback();
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return _useFallback();
      final root = Map<String, dynamic>.from(decoded);
      if (root['success'] == false) return _useFallback();

      final data = root['data'];
      List<dynamic> rawList = const [];
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final methods = map['payment_methods'] ?? map['paymentMethods'];
        if (methods is List) rawList = methods;
      } else if (data is List) {
        rawList = data;
      }

      final parsed = rawList
          .whereType<Map>()
          .map((e) => PaymentMethodModel.fromJson(Map<String, dynamic>.from(e)))
          .where((m) => m.name.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      if (parsed.isEmpty) return _useFallback();
      _cache = parsed;
      return List<PaymentMethodModel>.from(parsed);
    } catch (_) {
      return _useFallback();
    }
  }

  List<PaymentMethodModel> _useFallback() {
    _cache ??= List<PaymentMethodModel>.from(PaymentMethodModel.fallback);
    return List<PaymentMethodModel>.from(_cache!);
  }

  void clearCache() {
    _cache = null;
  }
}
