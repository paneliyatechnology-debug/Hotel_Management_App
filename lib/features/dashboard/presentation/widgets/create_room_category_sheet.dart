import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../rooms/data/models/room_type_model.dart';

/// Opens the create/edit room category sheet.
/// Returns the API success message, or null if the sheet was dismissed.
Future<String?> showRoomCategoryFormSheet({
  required BuildContext context,
  RoomTypeModel? category,
  required Future<String> Function({
    required String name,
    required String description,
  }) onSubmit,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => RoomCategoryFormSheet(
      category: category,
      onSubmit: onSubmit,
    ),
  );
}

class RoomCategoryFormSheet extends StatefulWidget {
  final RoomTypeModel? category;
  final Future<String> Function({
    required String name,
    required String description,
  }) onSubmit;

  const RoomCategoryFormSheet({
    super.key,
    this.category,
    required this.onSubmit,
  });

  @override
  State<RoomCategoryFormSheet> createState() => _RoomCategoryFormSheetState();
}

class _RoomCategoryFormSheetState extends State<RoomCategoryFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  final _nameFocus = FocusNode();
  final _descFocus = FocusNode();

  bool _isSaving = false;
  bool _showNameError = false;
  String? _errorMessage;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    _descCtrl = TextEditingController(text: widget.category?.description ?? '');
    _nameCtrl.addListener(_rebuild);
    _descCtrl.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_rebuild);
    _descCtrl.removeListener(_rebuild);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();

    if (name.isEmpty) {
      setState(() {
        _showNameError = true;
        _errorMessage = null;
      });
      _nameFocus.requestFocus();
      return;
    }

    setState(() {
      _isSaving = true;
      _showNameError = false;
      _errorMessage = null;
    });

    try {
      final message = await widget.onSubmit(name: name, description: description);
      if (!mounted) return;
      Navigator.of(context).pop(message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool error = false,
  }) {
    final idle = error ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1);
    final focus = error ? const Color(0xFFDC2626) : const Color(0xFF0F766E);
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF94A3B8)),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: idle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: idle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focus, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return PopScope(
      canPop: !_isSaving,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCBD5E1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildHeader(),
                            const SizedBox(height: 14),
                            _buildNameField(),
                            const SizedBox(height: 12),
                            _buildDescriptionField(),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 10),
                              _buildErrorBanner(_errorMessage!),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Icon(
            _isEdit ? Icons.edit_rounded : Icons.auto_awesome_rounded,
            color: const Color(0xFF0F766E),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Edit Room Category' : 'Create Room Category',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isEdit ? 'Update name & description' : 'Add a new room type',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          shape: const CircleBorder(
            side: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category name',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: const Key('categoryNameField'),
          controller: _nameCtrl,
          focusNode: _nameFocus,
          enabled: !_isSaving,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _descFocus.requestFocus(),
          onChanged: (_) {
            if (_showNameError && _nameCtrl.text.trim().isNotEmpty) {
              setState(() => _showNameError = false);
            }
          },
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
          cursorColor: AppColors.primary,
          decoration: _fieldDecoration(
            hint: 'e.g. Deluxe, Family, Executive Suite',
            error: _showNameError,
            prefixIcon: const Icon(Icons.bed_rounded, size: 18, color: Color(0xFF0F766E)),
            suffixIcon: _nameCtrl.text.trim().isEmpty
                ? null
                : IconButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            _nameCtrl.clear();
                            setState(() => _showNameError = false);
                            _nameFocus.requestFocus();
                          },
                    icon: const Icon(Icons.cancel_rounded, size: 16, color: Color(0xFF94A3B8)),
                  ),
          ),
        ),
        if (_showNameError) ...[
          const SizedBox(height: 4),
          Text(
            'Category name is required',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDC2626),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionField() {
    final count = _descCtrl.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Description',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Optional',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            const Spacer(),
            Text(
              '$count/240',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: count > 220 ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          key: const Key('categoryDescriptionField'),
          controller: _descCtrl,
          focusNode: _descFocus,
          enabled: !_isSaving,
          minLines: 2,
          maxLines: 3,
          maxLength: 240,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          textAlignVertical: TextAlignVertical.top,
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.35, color: const Color(0xFF0F172A)),
          cursorColor: AppColors.primary,
          decoration: _fieldDecoration(
            hint: 'Amenities, view, size…',
          ).copyWith(counterText: ''),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  disabledBackgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.45),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isEdit ? 'Save Changes' : 'Save & Create Category',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
