import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../data/models/admin_models.dart';
import '../../data/repositories/hotel_admin_repository.dart';

class AdminStaffManagementPage extends StatefulWidget {
  final HotelAdminRepository? repository;

  const AdminStaffManagementPage({super.key, this.repository});

  @override
  State<AdminStaffManagementPage> createState() => _AdminStaffManagementPageState();
}

class _AdminStaffManagementPageState extends State<AdminStaffManagementPage>
    with TickerProviderStateMixin {
  late final HotelAdminRepository _repo;
  bool _isLoading = true;
  String? _errorMessage;
  List<StaffMemberModel> _staffList = [];
  String _searchQuery = '';
  String _statusFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _switchingIds = {}; // tracks in-flight toggle requests
  late AnimationController _listAnimController;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? HotelAdminRepository();
    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadStaff();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _repo.fetchStaffMembers();
      if (mounted) {
        setState(() {
          _staffList = list;
          _isLoading = false;
        });
        _listAnimController.forward(from: 0);
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

  List<StaffMemberModel> get _filteredStaff {
    return _staffList.where((s) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          s.phone.contains(_searchQuery) ||
          s.employeeId.toLowerCase().contains(q);
      final matchesStatus = _statusFilter == 'ALL' ||
          (_statusFilter == 'ACTIVE' && s.isActive) ||
          (_statusFilter == 'INACTIVE' && !s.isActive);
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _toggleStatus(StaffMemberModel staff) async {
    // Prevent double-tap while request is in-flight
    if (_switchingIds.contains(staff.id)) return;

    final newStatus = staff.isActive ? 'INACTIVE' : 'ACTIVE';
    final idx = _staffList.indexWhere((s) => s.id == staff.id);
    if (idx == -1) return;

    // ── 1. Optimistic UI: flip switch instantly ──────────────────
    final updated = StaffMemberModel(
      id: staff.id,
      name: staff.name,
      email: staff.email,
      phone: staff.phone,
      role: staff.role,
      employeeId: staff.employeeId,
      status: newStatus,
      shift: staff.shift,
      mustChangePassword: staff.mustChangePassword,
      failedLoginAttempts: staff.failedLoginAttempts,
    );
    setState(() {
      _staffList[idx] = updated;
      _switchingIds.add(staff.id); // lock this switch
    });

    // ── 2. Call PUT /admin/receptionists/:id/status ─────────────
    try {
      final responseMessage = await _repo.updateStaffStatus(staff.id, newStatus);
      if (mounted) {
        setState(() => _switchingIds.remove(staff.id));
        _showToast(responseMessage, isError: false);
      }
    } catch (e) {
      // ── 3. Revert if API fails ───────────────────────────────
      if (mounted) {
        setState(() {
          _staffList[idx] = staff; // restore original
          _switchingIds.remove(staff.id); // unlock
        });
        _showToast(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }


  void _showToast(String message, {bool isError = false}) {
    if (isError) {
      AppSnackBar.showError(context, message);
    } else {
      AppSnackBar.showSuccess(context, message);
    }
  }

  Future<void> _deleteStaff(StaffMemberModel staff) async {
    bool isDeleting = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_remove_outlined, color: Color(0xFFDC2626), size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Remove Staff Member?',
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to remove ${staff.name}? Staff member will be soft-deleted (deactivated) and past audit logs preserved.',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isDeleting ? null : () => Navigator.of(dialogCtx).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                        ),
                        onPressed: isDeleting
                            ? null
                            : () async {
                                setDialogState(() => isDeleting = true);
                                try {
                                  final responseMessage = await _repo.deleteStaffMember(staff.id);
                                  if (dialogCtx.mounted) {
                                    Navigator.of(dialogCtx).pop();
                                  }
                                  if (mounted) {
                                    _showToast(responseMessage, isError: false);
                                    _loadStaff();
                                  }
                                } catch (e) {
                                  setDialogState(() => isDeleting = false);
                                  if (mounted) {
                                    _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
                                  }
                                }
                              },
                        child: isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text('Remove', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showStaffFormModal({StaffMemberModel? staff}) async {
    final isEdit = staff != null;
    final nameCtrl = TextEditingController(text: staff?.name ?? '');
    final emailCtrl = TextEditingController(text: staff?.email ?? '');
    final phoneCtrl = TextEditingController(text: staff?.phone ?? '');
    String selectedShift = staff?.shift ?? 'Morning (07:00 - 15:00)';
    String selectedRole = staff?.role ?? 'RECEPTIONIST';
    bool isSaving = false;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
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
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Edit Staff Member' : 'Onboard New Staff',
                                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                              ),
                              Text(
                                isEdit
                                    ? 'Update contact & assignment details'
                                    : 'Auto-generates login credentials via email',
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _divider(),
                    const SizedBox(height: 16),

                    // Full Name
                    _label('Staff Full Name *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        hint: 'e.g. Ramesh Patel',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),

                    const SizedBox(height: 14),

                    // Email
                    _label('Login Email *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isEdit,
                      decoration: _inputDecoration(
                        hint: 'staff@yourhotel.com',
                        icon: Icons.email_outlined,
                        disabled: isEdit,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    if (!isEdit)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          'Credentials will be emailed to this address',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF0F766E)),
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Phone
                    _label('Contact Phone * (10 digits)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: _inputDecoration(
                        hint: '9820155667',
                        icon: Icons.phone_outlined,
                      ),
                      validator: (v) {
                        final d = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                        if (d.isEmpty) return 'Phone is required';
                        if (d.length != 10) return 'Must be exactly 10 digits';
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Role
                    _label('Assigned Operational Role *'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: _inputDecoration(hint: '', icon: Icons.badge_outlined),
                      dropdownColor: Colors.white,
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                      items: const [
                        DropdownMenuItem(
                          value: 'RECEPTIONIST',
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: Color(0xFF0F766E), size: 8),
                              SizedBox(width: 8),
                              Text('Front Desk Receptionist (RECEPTIONIST)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'MANAGER',
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: Color(0xFF7C3AED), size: 8),
                              SizedBox(width: 8),
                              Text('Front Office Manager (MANAGER)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'SUPERVISOR',
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: Color(0xFFD97706), size: 8),
                              SizedBox(width: 8),
                              Text('Shift Supervisor (SUPERVISOR)'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedRole = val);
                      },
                    ),

                    const SizedBox(height: 14),

                    // Shift
                    _label('Duty Shift Roster'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedShift,
                      decoration: _inputDecoration(hint: '', icon: Icons.schedule_rounded),
                      dropdownColor: Colors.white,
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                      items: const [
                        DropdownMenuItem(
                          value: 'Morning (07:00 - 15:00)',
                          child: Text('Morning Shift (07:00 AM - 03:00 PM)'),
                        ),
                        DropdownMenuItem(
                          value: 'Evening (15:00 - 23:00)',
                          child: Text('Evening Shift (03:00 PM - 11:00 PM)'),
                        ),
                        DropdownMenuItem(
                          value: 'Night (23:00 - 07:00)',
                          child: Text('Night Shift (11:00 PM - 07:00 AM)'),
                        ),
                        DropdownMenuItem(
                          value: 'General (09:00 - 18:00)',
                          child: Text('General Shift (09:00 AM - 06:00 PM)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedShift = val);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ?? false)) return;

                                final name = nameCtrl.text.trim();
                                final email = emailCtrl.text.trim();
                                final phone = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

                                setModalState(() => isSaving = true);
                                try {
                                  String responseMsg;
                                  if (isEdit) {
                                    final result = await _repo.updateStaffMember(
                                      staff.id,
                                      name: name,
                                      email: email,
                                      phone: phone,
                                      role: selectedRole,
                                      shift: selectedShift,
                                    );
                                    responseMsg = result.message;
                                  } else {
                                    final result = await _repo.createStaffMember(
                                      name: name,
                                      email: email,
                                      phone: phone,
                                      role: selectedRole,
                                      shift: selectedShift,
                                    );
                                    responseMsg = result.message;
                                  }
                                  if (mounted && ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                    _showToast(responseMsg, isError: false);
                                    _loadStaff();
                                  }
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  if (mounted) {
                                    _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isEdit ? Icons.save_rounded : Icons.person_add_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEdit ? 'Save Changes' : 'Onboard Staff',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool disabled = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, size: 18, color: disabled ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
      filled: true,
      fillColor: disabled ? const Color(0xFFF8FAFC) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.8),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
      );

  Widget _divider() => Container(height: 1, color: const Color(0xFFF1F5F9));

  @override
  Widget build(BuildContext context) {
    final activeCount = _staffList.where((s) => s.isActive).length;
    final inactiveCount = _staffList.where((s) => !s.isActive).length;
    final totalCount = _staffList.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Staff Management',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadStaff,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: Text('Add Staff', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
        onPressed: () => _showStaffFormModal(),
      ),

      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  color: const Color(0xFF0F766E),
                  onRefresh: _loadStaff,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                    children: [
                      // ── Stats Banner ──────────────────────────────
                      _buildStatsBanner(activeCount, inactiveCount, totalCount),

                      const SizedBox(height: 8),

                      // ── Search ────────────────────────────────────
                      _buildSearchField(),

                      const SizedBox(height: 6),

                      // ── Filter Chips ──────────────────────────────
                      _buildFilterRow(activeCount, inactiveCount, totalCount),

                      const SizedBox(height: 8),

                      // ── Staff Cards ───────────────────────────────
                      if (_filteredStaff.isEmpty)
                        _buildEmptyState()
                      else
                        ..._filteredStaff.asMap().entries.map((entry) {
                          final i = entry.key;
                          final staff = entry.value;
                          return AnimatedOpacity(
                            opacity: 1,
                            duration: Duration(milliseconds: 300 + i * 60),
                            child: _buildStaffCard(staff),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              color: Color(0xFF0F766E),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading staff directory...',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Color(0xFFDC2626), size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load staff',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadStaff,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Try Again', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBanner(int active, int inactive, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Directory',
                  style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                ),
                Text(
                  total == 0 ? 'No staff yet' : '$total Total Member${total != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          // Mini stats
          _statChip('$active', 'Active', const Color(0xFF0F766E), const Color(0xFFECFDF5)),
          const SizedBox(width: 6),
          if (inactive > 0)
            _statChip('$inactive', 'Off', const Color(0xFF64748B), const Color(0xFFF1F5F9)),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val.trim()),
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: 'Search by name, email, or EMP ID...',
        hintStyle: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterRow(int active, int inactive, int total) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('ALL', 'All ($total)'),
          const SizedBox(width: 8),
          _filterChip('ACTIVE', 'Active ($active)'),
          const SizedBox(width: 8),
          _filterChip('INACTIVE', 'Inactive ($inactive)'),
        ],
      ),
    );
  }

  Widget _filterChip(String filter, String label) {
    final isSelected = _statusFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search_rounded, color: Color(0xFF94A3B8), size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            _searchQuery.isNotEmpty ? 'No staff match your search' : 'No staff members yet',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different name, email, or EMP ID'
                : 'Tap "Add Staff" to onboard your first team member',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(StaffMemberModel staff) {
    final initial = staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S';
    final avatarColor = staff.isActive ? const Color(0xFF0F766E) : const Color(0xFF64748B);
    final avatarBg = staff.isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: staff.isActive ? const Color(0xFFD1FAE5) : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Row 1: Avatar | Name+EMP+Role | Toggle ──────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Compact Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: avatarColor.withValues(alpha: 0.25), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: avatarColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Name + EMP badge + Role pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              staff.name,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 5),
                          if (staff.employeeId.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                staff.employeeId,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      _roleBadge(staff.role),
                    ],
                  ),
                ),

                // Compact Toggle (no label)
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: staff.isActive,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF059669),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFCBD5E1),
                    onChanged: _switchingIds.contains(staff.id)
                        ? null
                        : (val) async {
                            await _toggleStatus(staff);
                          },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ── Row 2: Contact Info (single compact row) ─────────
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 11, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Expanded(
                  flex: 5,
                  child: Text(
                    staff.email,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.phone_outlined, size: 11, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Text(
                  staff.phone,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
              ],
            ),

            const SizedBox(height: 2),

            // Shift row
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 11, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    staff.shift,
                    style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            // ── Row 3: Action Buttons ─────────────────────────────
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: OutlinedButton.icon(
                      onPressed: () => _showStaffFormModal(staff: staff),
                      icon: const Icon(Icons.edit_rounded, size: 12),
                      label: Text('Edit', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        backgroundColor: const Color(0xFFF0F9FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteStaff(staff),
                      icon: const Icon(Icons.delete_outline_rounded, size: 12),
                      label: Text('Remove', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        backgroundColor: const Color(0xFFFFF5F5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    final colors = {
      'RECEPTIONIST': (const Color(0xFF0F766E), const Color(0xFFECFDF5)),
      'MANAGER': (const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
      'SUPERVISOR': (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
    };
    final pair = colors[role] ?? (const Color(0xFF475569), const Color(0xFFF1F5F9));
    final label = role == 'RECEPTIONIST' ? 'RECEPTIONIST' : role;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: pair.$2,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, color: pair.$1),
      ),
    );
  }
}
