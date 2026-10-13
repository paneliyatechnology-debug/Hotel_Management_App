import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/admin_models.dart';
import '../../data/repositories/hotel_admin_repository.dart';

class AdminRevenueReportsPage extends StatefulWidget {
  final HotelAdminRepository? repository;

  const AdminRevenueReportsPage({super.key, this.repository});

  @override
  State<AdminRevenueReportsPage> createState() => _AdminRevenueReportsPageState();
}

class _AdminRevenueReportsPageState extends State<AdminRevenueReportsPage> {
  late final HotelAdminRepository _repo;
  bool _isLoading = true;
  String? _errorMessage;

  RevenueDetailsData _revenueData = const RevenueDetailsData();
  Map<String, dynamic> _reportsData = {};

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? HotelAdminRepository();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repo.fetchRevenueDetails(),
        _repo.fetchReports(),
      ]);

      if (mounted) {
        setState(() {
          _revenueData = results[0] as RevenueDetailsData;
          _reportsData = results[1] as Map<String, dynamic>;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Revenue Reports & Analytics',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReports,
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
                        ElevatedButton(onPressed: _loadReports, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF0F766E),
                  onRefresh: _loadReports,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Total Revenue Hero Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF064E3B), Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'AUDITED REVENUE',
                                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                                  ),
                                ),
                                if (_revenueData.dateRangeLabel.isNotEmpty)
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white12,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _revenueData.dateRangeLabel,
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              CurrencyFormatter.format(_revenueData.totalRevenue),
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              '${_revenueData.totalTransactions} Total Processed Folio Transactions',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Revenue Category Breakdown
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
                              'Revenue Stream Breakdown',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 14),
                            _buildBreakdownItem(
                              label: 'Room Bookings & Stay',
                              amount: _revenueData.breakdown.roomBooking,
                              total: _revenueData.totalRevenue,
                              color: const Color(0xFF0F766E),
                            ),
                            const SizedBox(height: 10),
                            _buildBreakdownItem(
                              label: 'Food & Dining Service',
                              amount: _revenueData.breakdown.foodRestaurant,
                              total: _revenueData.totalRevenue,
                              color: const Color(0xFF6366F1),
                            ),
                            const SizedBox(height: 10),
                            _buildBreakdownItem(
                              label: 'Extra Services & Amenities',
                              amount: _revenueData.breakdown.extraServices,
                              total: _revenueData.totalRevenue,
                              color: const Color(0xFFD97706),
                            ),
                          ],
                        ),
                      ),

                      if (_reportsData['paymentBreakdown'] is List) ...[
                        const SizedBox(height: 18),
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
                                'Payment Channels Volume',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 14),
                              ...((_reportsData['paymentBreakdown'] as List).map((item) {
                                final method = item['_id'] as String? ?? 'OTHER';
                                final tot = (item['total'] as num?)?.toDouble() ?? 0;
                                final count = (item['count'] as num?)?.toInt() ?? 0;
                                final isUpi = method.toUpperCase() == 'UPI';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isUpi ? const Color(0xFFEEF2FF) : const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isUpi ? Icons.qr_code_rounded : Icons.payments_rounded,
                                          color: isUpi ? const Color(0xFF4F46E5) : const Color(0xFF059669),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              method.toUpperCase(),
                                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF0F172A)),
                                            ),
                                            Text(
                                              '$count transactions settled',
                                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(tot),
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                );
                              })),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Transactions List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Audited Transaction Ledger',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                          ),
                          Text(
                            '${_revenueData.transactions.length} records',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ..._revenueData.transactions.map((t) => _buildTransactionRow(t)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBreakdownItem({
    required String label,
    required double amount,
    required double total,
    required Color color,
  }) {
    final pct = total > 0 ? (amount / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF475569)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(CurrencyFormatter.format(amount), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionRow(AdminPaymentTransaction t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.receiptNumber.isNotEmpty ? t.receiptNumber : t.transactionId,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF0F172A)),
                ),
                Text(
                  t.guestName.isNotEmpty ? '${t.guestName} • Room ${t.roomNumber}' : (t.formattedDate.isNotEmpty ? t.formattedDate : t.date),
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(t.total > 0 ? t.total : t.amount),
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF0F766E)),
              ),
              Text(
                t.paymentMethod.toUpperCase(),
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
