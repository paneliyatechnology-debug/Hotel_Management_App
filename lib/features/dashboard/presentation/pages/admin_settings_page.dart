import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/hotel_admin_repository.dart';

class AdminSettingsPage extends StatefulWidget {
  final HotelAdminRepository? repository;

  const AdminSettingsPage({super.key, this.repository});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  late final HotelAdminRepository _repo;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Controllers
  final _checkInTimeCtrl = TextEditingController(text: '14:00');
  final _checkOutTimeCtrl = TextEditingController(text: '12:00');
  final _timezoneCtrl = TextEditingController(text: 'Asia/Kolkata');
  final _upiIdCtrl = TextEditingController();
  final _beneficiaryCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();

  bool _gstEnabled = true;
  int _defaultGstRate = 18;
  bool _taxInclusive = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? HotelAdminRepository();
    _loadSettings();
  }

  @override
  void dispose() {
    _checkInTimeCtrl.dispose();
    _checkOutTimeCtrl.dispose();
    _timezoneCtrl.dispose();
    _upiIdCtrl.dispose();
    _beneficiaryCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _gstinCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _repo.fetchHotelProfile();
      final settings = profile['settings'] as Map<String, dynamic>? ?? {};
      final bank = settings['bankDetails'] as Map<String, dynamic>? ?? {};

      if (mounted) {
        setState(() {
          _checkInTimeCtrl.text = settings['checkInTime'] as String? ?? '14:00';
          _checkOutTimeCtrl.text = settings['checkOutTime'] as String? ?? '12:00';
          _timezoneCtrl.text = settings['timezone'] as String? ?? 'Asia/Kolkata';
          _upiIdCtrl.text = settings['upiId'] as String? ?? '';
          _gstinCtrl.text = settings['gstin'] as String? ?? '';
          _gstEnabled = settings['gstEnabled'] as bool? ?? true;
          _defaultGstRate = (settings['defaultGstRate'] as num?)?.toInt() ?? 18;
          _taxInclusive = settings['taxInclusive'] as bool? ?? false;

          _beneficiaryCtrl.text = bank['beneficiaryName'] as String? ?? '';
          _bankNameCtrl.text = bank['bankName'] as String? ?? '';
          _accountNumberCtrl.text = bank['accountNumber'] as String? ?? '';
          _ifscCtrl.text = bank['ifscCode'] as String? ?? '';

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

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _repo.updateHotelSettings(
        checkInTime: _checkInTimeCtrl.text.trim(),
        checkOutTime: _checkOutTimeCtrl.text.trim(),
        timezone: _timezoneCtrl.text.trim(),
        upiId: _upiIdCtrl.text.trim(),
        beneficiaryName: _beneficiaryCtrl.text.trim(),
        bankName: _bankNameCtrl.text.trim(),
        accountNumber: _accountNumberCtrl.text.trim(),
        ifscCode: _ifscCtrl.text.trim(),
        gstEnabled: _gstEnabled,
        defaultGstRate: _defaultGstRate,
        gstin: _gstinCtrl.text.trim(),
        taxInclusive: _taxInclusive,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0F766E),
            content: Text('Hotel settings and billing details saved successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Hotel Settings & Policies',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
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
                        ElevatedButton(onPressed: _loadSettings, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Section 1: Timings
                    _buildSectionHeader('Operating Timings', Icons.schedule_rounded),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _checkInTimeCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Check-In Time',
                                    hintText: '14:00',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _checkOutTimeCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Check-Out Time',
                                    hintText: '12:00',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _timezoneCtrl,
                            decoration: InputDecoration(
                              labelText: 'Timezone',
                              hintText: 'Asia/Kolkata',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 2: GST & Taxes
                    _buildSectionHeader('Tax & GST Invoicing', Icons.receipt_long_rounded),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Enable GST Compliance', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text('Generates SAC code and tax breakdowns', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _gstEnabled,
                                activeColor: const Color(0xFF0F766E),
                                onChanged: (val) => setState(() => _gstEnabled = val),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          TextField(
                            controller: _gstinCtrl,
                            decoration: InputDecoration(
                              labelText: 'Hotel GSTIN',
                              hintText: 'e.g., 24AAACH7409R1ZZ',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Prices are Tax-Inclusive', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text('Base tariff includes taxes', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _taxInclusive,
                                activeColor: const Color(0xFF0F766E),
                                onChanged: (val) => setState(() => _taxInclusive = val),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 3: Bank & UPI Details
                    _buildSectionHeader('Bank & UPI Invoicing Details', Icons.account_balance_rounded),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _upiIdCtrl,
                            decoration: InputDecoration(
                              labelText: 'UPI ID for Dynamic QR',
                              hintText: 'e.g., hotel.resort@okhdfcbank',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _beneficiaryCtrl,
                            decoration: InputDecoration(
                              labelText: 'Beneficiary Name',
                              hintText: 'e.g., Niraj Resort Private Limited',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _bankNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Bank Name',
                              hintText: 'e.g., HDFC Bank',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _accountNumberCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Account Number',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _ifscCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'IFSC Code',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving ? null : _saveSettings,
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Save Hotel Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0F766E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
