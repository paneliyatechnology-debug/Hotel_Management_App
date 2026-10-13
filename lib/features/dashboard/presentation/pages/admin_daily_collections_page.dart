import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/admin_models.dart';
import '../../data/repositories/hotel_admin_repository.dart';

class AdminDailyCollectionsPage extends StatefulWidget {
  final HotelAdminRepository? repository;

  const AdminDailyCollectionsPage({super.key, this.repository});

  @override
  State<AdminDailyCollectionsPage> createState() => _AdminDailyCollectionsPageState();
}

class _AdminDailyCollectionsPageState extends State<AdminDailyCollectionsPage> {
  late final HotelAdminRepository _repo;
  bool _isLoading = true;
  String? _errorMessage;
  DailyCollectionsTelemetry _telemetry = const DailyCollectionsTelemetry();
  List<AdminPaymentTransaction> _transactions = [];
  String _selectedMethod = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? HotelAdminRepository();
    _loadCollections();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _repo.fetchDailyCollections(
        paymentMethod: _selectedMethod,
        query: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _telemetry = res['telemetry'] as DailyCollectionsTelemetry;
          _transactions = res['transactions'] as List<AdminPaymentTransaction>;
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

  Future<void> _showHandoverModal() async {
    final notesController = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Color(0xFF047857), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash Drawer Handover',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Settle front desk cash to hotel vault',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cash in Front Desk Drawer:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                        Text(
                          CurrencyFormatter.format(_telemetry.cashInDrawer),
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F766E)),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Post-Handover Counter Balance:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                        Text(
                          '₹0 (Balanced)',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Handover Audit Notes / Receiver Name',
                  hintText: 'e.g., Handed over to GM at shift close',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064E3B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            final res = await _repo.settleHandover(notes: notesController.text.trim());
                            if (mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF064E3B),
                                  content: Text(res['message'] ?? 'Cash drawer successfully settled to vault!'),
                                ),
                              );
                              _loadCollections();
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Confirm Vault Handover', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Daily Collections & Handover',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadCollections,
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
                        ElevatedButton(
                          onPressed: _loadCollections,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF0F766E),
                  onRefresh: _loadCollections,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1. Primary Handover Action Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF064E3B), Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF064E3B).withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.point_of_sale_rounded, color: Color(0xFF6EE7B7), size: 20),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Front Desk Cash Drawer',
                                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF047857).withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_telemetry.unsettledCount} Unsettled',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              CurrencyFormatter.format(_telemetry.cashInDrawer),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Physical cash awaiting vault handover deposit',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.lock_clock_rounded, size: 18),
                                label: Text(
                                  'Handover Cash to Vault',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                onPressed: _showHandoverModal,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 2. Telemetry Grid (3 Cards)
                      Row(
                        children: [
                          Expanded(
                            child: _buildTelemetryCard(
                              title: 'UPI Receipts',
                              value: CurrencyFormatter.format(_telemetry.todayUpi),
                              subtitle: 'Digital direct',
                              icon: Icons.qr_code_rounded,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTelemetryCard(
                              title: 'Today Gross',
                              value: CurrencyFormatter.format(_telemetry.todayGross),
                              subtitle: 'Cash + UPI intake',
                              icon: Icons.trending_up_rounded,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTelemetryCard(
                        title: 'Total Historical Vault Settled',
                        value: CurrencyFormatter.format(_telemetry.totalVaultSettled),
                        subtitle: 'Verified deposited cash',
                        icon: Icons.security_rounded,
                        color: const Color(0xFF0284C7),
                      ),

                      const SizedBox(height: 24),

                      // 3. Transactions Section Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Recent Receipts Log',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                          ),
                          Text(
                            '${_transactions.length} records',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('ALL', 'All Receipts'),
                            const SizedBox(width: 8),
                            _buildFilterChip('CASH', 'Cash Only'),
                            const SizedBox(width: 8),
                            _buildFilterChip('UPI', 'UPI Gateway'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Transactions List
                      if (_transactions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Center(
                            child: Text(
                              'No receipts recorded for this filter.',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ..._transactions.map((t) => _buildTransactionCard(t)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFilterChip(String method, String label) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMethod = method);
        _loadCollections();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(AdminPaymentTransaction t) {
    final isCash = t.paymentMethod.toUpperCase() == 'CASH';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCash ? const Color(0xFFECFDF5) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCash ? Icons.payments_rounded : Icons.qr_code_rounded,
              color: isCash ? const Color(0xFF059669) : const Color(0xFF4F46E5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        t.receiptNumber.isNotEmpty ? t.receiptNumber : t.transactionId,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isCash ? const Color(0xFFD1FAE5) : const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t.paymentMethod.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isCash ? const Color(0xFF065F46) : const Color(0xFF3730A3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  t.guestName.isNotEmpty ? '${t.guestName} • Room ${t.roomNumber}' : (t.description.isNotEmpty ? t.description : 'Room settlement'),
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  t.formattedDate.isNotEmpty ? t.formattedDate : t.date,
                  style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(t.total > 0 ? t.total : t.amount),
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  t.status.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF059669)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
