import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../data/repositories/hotel_admin_repository.dart';
import '../widgets/dashboard_shimmer_loader.dart';

class SubscriptionPlansMemory {
  static List<SubscriptionPlan>? plans;
  static bool isTrialUsed = true;

  static void clear() {
    plans = null;
    isTrialUsed = true;
  }
}

class AdminSubscriptionPage extends StatefulWidget {
  final HotelAdminRepository? repository;

  const AdminSubscriptionPage({super.key, this.repository});

  @override
  State<AdminSubscriptionPage> createState() => _AdminSubscriptionPageState();
}

class _AdminSubscriptionPageState extends State<AdminSubscriptionPage> {
  late final HotelAdminRepository _repo;
  bool _isLoading = true;
  String? _errorMessage;
  int? _purchasingPlanId;
  List<SubscriptionPlan> _plans = const [];
  bool _trialUsed = true;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? HotelAdminRepository();
    final cached = SubscriptionPlansMemory.plans;
    if (cached != null) {
      _plans = List<SubscriptionPlan>.from(cached);
      _trialUsed = SubscriptionPlansMemory.isTrialUsed;
      _isLoading = false;
    }
    _loadPlans(showLoader: cached == null);
  }

  Future<void> _loadPlans({bool? showLoader}) async {
    final loader = showLoader ?? (_plans.isEmpty && SubscriptionPlansMemory.plans == null);
    if (loader && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final result = await _repo.fetchSubscriptionPlans();
      SubscriptionPlansMemory.plans = result.plans;
      SubscriptionPlansMemory.isTrialUsed = result.isTrialUsed;
      if (!mounted) return;
      setState(() {
        _plans = result.plans;
        _trialUsed = result.isTrialUsed;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _isLoading = false;
        if (_plans.isEmpty) _errorMessage = message;
      });
    }
  }

  Future<void> _confirmPurchase(SubscriptionPlan plan) async {
    if (_trialBlocked(plan)) return;
    final priceLabel = plan.price <= 0 ? 'Free' : '${CurrencyFormatter.format(plan.price)} / month';
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Purchase ${plan.name}?',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                '$priceLabel • Up to ${plan.maxRooms} rooms • Cash payment',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: Text('Confirm purchase', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: Color(0xFF0F766E)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _purchasingPlanId = plan.id);
    try {
      final purchase = await _repo.purchaseSubscriptionPlan(plan.id);
      if (!mounted) return;
      setState(() => _purchasingPlanId = null);
      await _loadPlans(showLoader: false);
      if (!mounted) return;
      await _showPurchaseSuccess(purchase);
    } catch (e) {
      if (!mounted) return;
      setState(() => _purchasingPlanId = null);
      AppSnackBar.showError(context, e.toString().replaceFirst('Exception: ', ''), title: 'Purchase');
    }
  }

  Future<void> _showPurchaseSuccess(SubscriptionPurchase purchase) {
    final amount = purchase.amount <= 0 ? 'Free' : CurrencyFormatter.format(purchase.amount);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF0F766E), size: 48),
                const SizedBox(height: 10),
                Text(
                  'Plan purchased',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  purchase.planName.isEmpty ? 'Your subscription is active.' : purchase.planName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                _successRow('Amount', amount),
                _successRow('Billing', _label(purchase.billingCycle)),
                _successRow('Payment', _label(purchase.paymentMethod)),
                _successRow('Status', _label(purchase.status)),
                _successRow('Starts', _formatPlanDate(purchase.startsAt)),
                _successRow('Ends', _formatPlanDate(purchase.endsAt)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text('Done', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Subscription Plan',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16.5, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPlans,
          ),
        ],
      ),
      body: _isLoading
          ? const SubscriptionShimmer()
          : _errorMessage != null
              ? _PlansMessage(
                  icon: Icons.cloud_off_rounded,
                  message: _errorMessage!,
                  actionLabel: 'Try again',
                  onAction: _loadPlans,
                )
              : _plans.isEmpty
                  ? const _PlansMessage(
                      icon: Icons.card_membership_outlined,
                      message: 'No monthly plans are available right now.',
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF0F766E),
                      onRefresh: _loadPlans,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        itemCount: _plans.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == 0) return const _PlansHeader();
                          final plan = _plans[index - 1];
                          final isCurrent = plan.isCurrentPlan;
                          final trialBlocked = _trialBlocked(plan);
                          return _PlanCard(
                            plan: plan,
                            isCurrent: isCurrent,
                            trialBlocked: trialBlocked,
                            isPurchasing: _purchasingPlanId == plan.id,
                            onPurchase: !isCurrent && !trialBlocked && _purchasingPlanId == null
                                ? () => _confirmPurchase(plan)
                                : null,
                          );
                        },
                      ),
                    ),
    );
  }

  bool _trialBlocked(SubscriptionPlan plan) {
    if (!plan.isFreeTrial) return false;
    return _trialUsed || plan.isTrialUsed == true;
  }
}

class _PlansHeader extends StatelessWidget {
  const _PlansHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly plans',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the room limit and tools that fit your hotel.',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent;
  final bool trialBlocked;
  final bool isPurchasing;
  final VoidCallback? onPurchase;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.trialBlocked,
    required this.isPurchasing,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = isCurrent || plan.isPopular;
    final priceLabel = plan.price <= 0 ? 'Free' : CurrencyFormatter.format(plan.price);
    final buttonDisabled = isCurrent || trialBlocked;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                ),
                if (isCurrent) ...[
                  const _Badge(label: 'ACTIVE', filled: true),
                  const SizedBox(width: 6),
                ],
                if (plan.badge.trim().isNotEmpty) _Badge(label: plan.badge, filled: highlighted && !isCurrent),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  priceLabel,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: const Color(0xFF0F766E),
                  ),
                ),
                if (plan.price > 0) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '/ month',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ],
            ),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                plan.description,
                style: GoogleFonts.inter(fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Up to ${_roomLabel(plan.maxRooms)}',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F766E)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ButtonStyle(
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return trialBlocked ? const Color(0xFFE2E8F0) : const Color(0xFFECFDF5);
                    }
                    return const Color(0xFF0F766E);
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return trialBlocked ? const Color(0xFF94A3B8) : const Color(0xFF047857);
                    }
                    return Colors.white;
                  }),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
                onPressed: buttonDisabled ? null : onPurchase,
                child: isPurchasing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isCurrent
                            ? 'Active plan'
                            : 'Purchase plan',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
            if (plan.features.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final feature in plan.features) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF0F766E)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: GoogleFonts.inter(fontSize: 13, height: 1.35, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _roomLabel(int rooms) {
    final text = rooms.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]},');
    return '$text rooms';
  }
}

Widget _successRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        ),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
      ],
    ),
  );
}

String _label(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return '—';
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

String _formatPlanDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw.isEmpty ? '—' : raw;
  return DateFormat('d MMM yyyy').format(parsed.toLocal());
}

class _Badge extends StatelessWidget {
  final String label;
  final bool filled;
  final bool muted;

  const _Badge({required this.label, required this.filled, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final background = muted
        ? const Color(0xFFF1F5F9)
        : filled
            ? const Color(0xFF0F766E)
            : const Color(0xFFECFDF5);
    final border = muted
        ? const Color(0xFFCBD5E1)
        : filled
            ? const Color(0xFF0F766E)
            : const Color(0xFFA7F3D0);
    final textColor = muted
        ? const Color(0xFF64748B)
        : filled
            ? Colors.white
            : const Color(0xFF047857);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: textColor,
        ),
      ),
    );
  }
}

class _PlansMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PlansMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF94A3B8), size: 42),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
