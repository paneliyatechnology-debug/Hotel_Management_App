import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/models/hotel_me_model.dart';
import '../../data/repositories/hotel_admin_repository.dart';
import '../widgets/dashboard_shimmer_loader.dart';

class HotelSettingsMemory {
  static MyHotelProfile? profile;

  static void clear() => profile = null;
}

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
  bool _gstEnabled = true;
  String _mobileNumber = '';
  String _email = '';
  String _ownerName = '';
  String _logoUrl = '';
  String? _logoPath;

  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'India');
  final _pincodeCtrl = TextEditingController();
  final _checkInCtrl = TextEditingController(text: '14:00');
  final _checkOutCtrl = TextEditingController(text: '12:00');
  final _timezoneCtrl = TextEditingController(text: 'Asia/Kolkata');
  final _currencyCtrl = TextEditingController(text: 'INR');
  final _graceCtrl = TextEditingController(text: '10');
  final _taxCtrl = TextEditingController(text: '18');
  final _gstNumberCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _amenitiesCtrl = TextEditingController();
  final _policiesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? HotelAdminRepository();
    final cached = HotelSettingsMemory.profile;
    if (cached != null) {
      _apply(cached.hotel, cached.phone);
      _email = cached.email;
      _ownerName = cached.ownerName;
      _logoUrl = cached.hotel.logoUrl;
      _isLoading = false;
    }
    _loadHotel();
  }

  @override
  void dispose() {
    for (final controller in [
      _nameCtrl,
      _typeCtrl,
      _websiteCtrl,
      _addressCtrl,
      _cityCtrl,
      _stateCtrl,
      _countryCtrl,
      _pincodeCtrl,
      _checkInCtrl,
      _checkOutCtrl,
      _timezoneCtrl,
      _currencyCtrl,
      _graceCtrl,
      _taxCtrl,
      _gstNumberCtrl,
      _panCtrl,
      _bankNameCtrl,
      _holderCtrl,
      _accountCtrl,
      _ifscCtrl,
      _branchCtrl,
      _upiCtrl,
      _amenitiesCtrl,
      _policiesCtrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadHotel() async {
    final firstLoad = HotelSettingsMemory.profile == null && _nameCtrl.text.trim().isEmpty && _mobileNumber.isEmpty;
    if (firstLoad && mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final profile = await _repo.fetchMyHotelProfile();
      HotelSettingsMemory.profile = profile;
      if (!mounted) return;
      setState(() {
        _apply(profile.hotel, profile.phone);
        _email = profile.email;
        _ownerName = profile.ownerName;
        _logoUrl = profile.hotel.logoUrl;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _apply(HotelMeProfile profile, String phone) {
    _nameCtrl.text = profile.name;
    _typeCtrl.text = profile.hotelType;
    _websiteCtrl.text = profile.website;
    _addressCtrl.text = profile.address;
    _cityCtrl.text = profile.city;
    _stateCtrl.text = profile.state;
    _countryCtrl.text = profile.country;
    _pincodeCtrl.text = profile.pincode;
    _checkInCtrl.text = profile.checkInTime;
    _checkOutCtrl.text = profile.checkOutTime;
    _timezoneCtrl.text = profile.timezone;
    _currencyCtrl.text = profile.currency;
    _graceCtrl.text = profile.lateCheckoutGraceMinutes;
    _taxCtrl.text = profile.taxPercentage;
    _gstNumberCtrl.text = profile.gstNumber;
    _panCtrl.text = profile.panNumber;
    _bankNameCtrl.text = profile.bankName;
    _holderCtrl.text = profile.bankAccountHolder;
    _accountCtrl.text = profile.bankAccountNumber;
    _ifscCtrl.text = profile.bankIfscCode;
    _branchCtrl.text = profile.bankBranch;
    _upiCtrl.text = profile.upiId;
    _amenitiesCtrl.text = profile.amenities.join(', ');
    _policiesCtrl.text = profile.policies.join(', ');
    _gstEnabled = profile.gstEnabled;
    _mobileNumber = phone;
  }

  HotelMeProfile _profileFromForm() {
    return HotelMeProfile(
      name: _nameCtrl.text,
      address: _addressCtrl.text,
      city: _cityCtrl.text,
      state: _stateCtrl.text,
      country: _countryCtrl.text,
      pincode: _pincodeCtrl.text,
      gstNumber: _gstNumberCtrl.text,
      panNumber: _panCtrl.text,
      bankName: _bankNameCtrl.text,
      bankAccountHolder: _holderCtrl.text,
      bankAccountNumber: _accountCtrl.text,
      bankIfscCode: _ifscCtrl.text,
      bankBranch: _branchCtrl.text,
      hotelType: _typeCtrl.text,
      website: _websiteCtrl.text,
      checkInTime: _checkInCtrl.text,
      checkOutTime: _checkOutCtrl.text,
      timezone: _timezoneCtrl.text,
      currency: _currencyCtrl.text,
      taxPercentage: _taxCtrl.text,
      gstEnabled: _gstEnabled,
      upiId: _upiCtrl.text,
      lateCheckoutGraceMinutes: _graceCtrl.text,
      amenities: _splitList(_amenitiesCtrl.text),
      policies: _splitList(_policiesCtrl.text),
      logoUrl: _logoUrl,
    );
  }

  List<String> _splitList(String raw) {
    return raw.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppSnackBar.showError(context, 'Enter the hotel name');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final message = await _repo.updateHotelMe(_profileFromForm(), logoPath: _logoPath);
      HotelSettingsMemory.profile = MyHotelProfile(
        hotel: _profileFromForm(),
        phone: _mobileNumber,
        email: _email,
        ownerName: _ownerName,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackBar.showSuccess(context, message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null || !mounted) return;
    setState(() => _logoPath = file.path);
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final parts = controller.text.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    final hour = picked.hour.toString().padLeft(2, '0');
    final minute = picked.minute.toString().padLeft(2, '0');
    setState(() => controller.text = '$hour:$minute');
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
          ? const SettingsShimmer()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      Text(
                        'Update your hotel details. Mobile number stays locked.',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 14),
                      _SettingsCard(
                        title: 'Hotel',
                        icon: Icons.apartment_rounded,
                        child: Column(
                          children: [
                            _logoPicker(),
                            const SizedBox(height: 14),
                            _field(_nameCtrl, 'Hotel name'),
                            const SizedBox(height: 12),
                            _lockedRow('Owner name', _ownerName),
                            const SizedBox(height: 10),
                            _lockedRow('Hotel email', _email),
                            const SizedBox(height: 10),
                            _lockedRow('Mobile number', _mobileNumber),
                            const SizedBox(height: 10),
                            _field(_typeCtrl, 'Hotel type', hint: 'Resort'),
                            const SizedBox(height: 10),
                            _field(_websiteCtrl, 'Website', hint: 'https://'),
                            const SizedBox(height: 10),
                            _field(_addressCtrl, 'Address'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _field(_cityCtrl, 'City')),
                                const SizedBox(width: 10),
                                Expanded(child: _field(_stateCtrl, 'State')),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _field(_countryCtrl, 'Country')),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _field(
                                    _pincodeCtrl,
                                    'Pincode',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        title: 'Operating Timings',
                        icon: Icons.schedule_rounded,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _timeTile('Check-in', _checkInCtrl)),
                                const SizedBox(width: 10),
                                Expanded(child: _timeTile('Check-out', _checkOutCtrl)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _field(_timezoneCtrl, 'Timezone', hint: 'Asia/Kolkata'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _field(_currencyCtrl, 'Currency', hint: 'INR')),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _field(
                                    _graceCtrl,
                                    'Late checkout minutes',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        title: 'Tax & GST Invoicing',
                        icon: Icons.receipt_long_rounded,
                        child: Column(
                          children: [
                            _field(
                              _taxCtrl,
                              'GST %',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _gstEnabled ? 'GST enabled' : 'GST off',
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                  ),
                                ),
                                Switch(
                                  value: _gstEnabled,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: const Color(0xFF0F766E),
                                  onChanged: (value) => setState(() => _gstEnabled = value),
                                ),
                              ],
                            ),
                            _field(_gstNumberCtrl, 'GST number'),
                            const SizedBox(height: 10),
                            _field(_panCtrl, 'PAN number'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        title: 'Bank details',
                        icon: Icons.account_balance_rounded,
                        child: Column(
                          children: [
                            _field(_bankNameCtrl, 'Bank name'),
                            const SizedBox(height: 10),
                            _field(_holderCtrl, 'Account holder'),
                            const SizedBox(height: 10),
                            _field(
                              _accountCtrl,
                              'Account number',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                            const SizedBox(height: 10),
                            _field(_ifscCtrl, 'Bank IFSC', textCapitalization: TextCapitalization.characters),
                            const SizedBox(height: 10),
                            _field(_branchCtrl, 'Bank branch'),
                            const SizedBox(height: 10),
                            _field(_upiCtrl, 'Hotel UPI ID', hint: 'hotel@upi'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        title: 'Amenities & policies',
                        icon: Icons.rule_rounded,
                        child: Column(
                          children: [
                            _field(_amenitiesCtrl, 'Amenities', hint: 'Free WiFi, Air Conditioning'),
                            const SizedBox(height: 10),
                            _field(_policiesCtrl, 'Policies', hint: 'Valid Government ID required at check-in'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text('Save Hotel Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _logoPicker() {
    final hasLogo = _logoPath != null || _logoUrl.isNotEmpty;
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _pickLogo,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _logoPreview(),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hotel logo',
                      style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasLogo ? 'Tap to change the logo' : 'Add a square logo for bills and the app',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF64748B), height: 1.35),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasLogo ? 'Change logo' : 'Upload logo',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F766E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoPreview() {
    if (_logoPath != null) {
      return Image.file(File(_logoPath!), fit: BoxFit.cover, width: 84, height: 84);
    }
    if (_logoUrl.isNotEmpty) {
      return Image.network(
        _logoUrl,
        fit: BoxFit.cover,
        width: 84,
        height: 84,
        errorBuilder: (_, __, ___) => _logoPlaceholder(),
      );
    }
    return _logoPlaceholder();
  }

  Widget _logoPlaceholder() {
    return const ColoredBox(
      color: Color(0xFFE6F7F2),
      child: Center(
        child: Icon(Icons.apartment_rounded, color: Color(0xFF0F766E), size: 32),
      ),
    );
  }

  Widget _lockedRow(String label, String value) {
    final shown = value.trim().isEmpty ? 'Not set' : value.trim();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text(shown, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
            ],
          ),
        ),
        const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
      ],
    );
  }

  Widget _timeTile(String label, TextEditingController controller) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _pickTime(controller),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text(
                controller.text.isEmpty ? '--:--' : controller.text,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
        hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.4)),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF0F766E)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
