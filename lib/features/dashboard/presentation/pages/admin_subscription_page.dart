import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/hotel_admin_repository.dart';

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
  Map<String, dynamic> _subData = {};

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? HotelAdminRepository();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _repo.fetchHotelProfile();
      if (mounted) {
        setState(() {
          _subData = profile['subscription'] as Map<String, dynamic>? ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showExtensionDialog() async {
    final daysCtrl = TextEditingController(text: '30');
    final reasonCtrl = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.extension_rounded, color: Color(0xFF0F766E), size: 22),
              const SizedBox(width: 8),
              Text('Request Trial Extension', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Days Requested',
                  hintText: 'e.g., 30',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason / Business Justification',
                  hintText: 'e.g., Evaluating high-season multi-floor management...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final days = int.tryParse(daysCtrl.text.trim()) ?? 30;
                      final reason = reasonCtrl.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please state a reason for extension.')),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);
                      setDialogState(() => isSubmitting = true);
                      try {
                        final res = await _repo.requestTrialExtension(
                          requestedDays: days,
                          reason: reason,
                        );
                        if (mounted) {
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF0F766E),
                              content: Text(res['message'] ?? 'Trial extension requested successfully!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(backgroundColor: Colors.red, content: Text(e.toString().replaceAll('Exception: ', ''))),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = _subData['plan'] as String? ?? 'PREMIUM';
    final status = _subData['status'] as String? ?? 'TRIAL';
    final daysLeft = (_subData['daysLeft'] as num?)?.toInt() ?? 0;
    final totalDays = (_subData['totalDays'] as num?)?.toInt() ?? 365;
    final elapsedDays = (_subData['elapsedDays'] as num?)?.toInt() ?? 0;
    final elapsedPercentage = (_subData['elapsedPercentage'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Subscription & Plan',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSubscription,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadSubscription, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF0F766E),
                  onRefresh: _loadSubscription,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Plan Hero Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$plan PLAN',
                                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: GoogleFonts.inter(color: const Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '$daysLeft Days Left',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Elapsed $elapsedDays days of $totalDays total allocated days',
                              style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (elapsedPercentage / 100).clamp(0.0, 1.0),
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Features Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Included Platform Features',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 14),
                            _buildFeatureRow('Unlimited Room Inventory & Floor Levels'),
                            _buildFeatureRow('Multi-User Role Front Desk Onboarding'),
                            _buildFeatureRow('GST Automated Invoicing & Folio Split Settlements'),
                            _buildFeatureRow('Cash Drawer Shift Handover to Vault'),
                            _buildFeatureRow('KYC Identity Scan & Guest Directory'),
                            _buildFeatureRow('Live Financial Revenue Telemetry & Reports'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.timer_rounded, size: 20),
                          label: Text(
                            'Request Trial Extension',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          onPressed: _showExtensionDialog,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }
}
