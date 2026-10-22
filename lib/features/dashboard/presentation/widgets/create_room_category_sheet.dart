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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return PopScope(
      canPop: !_isSaving,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
            child: Material(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 44,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color: AppColors.neutral200,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildHeader(),
                            const SizedBox(height: 16),
                            _buildSectionLabel(),
                            const SizedBox(height: 8),
                            _buildDetailsCard(),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              _buildErrorBanner(_errorMessage!),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: _buildActions(),
                    ),
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F7F2),
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.hotel_class_rounded, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Edit Room Category' : 'Create Room Category',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isEdit ? 'Update category name & description' : 'Configure category name & description',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.neutral50,
            side: const BorderSide(color: AppColors.border),
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
          ),
          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSectionLabel() {
    return Row(
      children: [
        const Icon(Icons.assignment_outlined, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          'CATEGORY DETAILS',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.neutral600,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    final name = _nameCtrl.text.trim();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Name *',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral700,
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
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            cursorColor: AppColors.primary,
            decoration: _inputDecoration(
              hint: 'e.g. Deluxe Room, Executive Suite, Family Room',
              prefix: const Icon(Icons.bed_rounded, size: 20, color: AppColors.primary),
              error: _showNameError,
              suffix: name.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              _nameCtrl.clear();
                              setState(() => _showNameError = false);
                              _nameFocus.requestFocus();
                            },
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                    ),
            ),
          ),
          if (_showNameError) ...[
            const SizedBox(height: 6),
            Text(
              'Enter a category name to continue.',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Description (Optional)',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            key: const Key('categoryDescriptionField'),
            controller: _descCtrl,
            focusNode: _descFocus,
            enabled: !_isSaving,
            minLines: 2,
            maxLines: 4,
            maxLength: 240,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            textAlignVertical: TextAlignVertical.top,
            style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textPrimary),
            cursorColor: AppColors.primary,
            decoration: _inputDecoration(
              hint: 'Brief description of category features and amenities...',
            ).copyWith(counterText: ''),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
    bool error = false,
  }) {
    final borderColor = error ? const Color(0xFFDC2626) : AppColors.border;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error ? const Color(0xFFDC2626) : AppColors.primary, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.neutral300),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    _isEdit ? 'Save Changes' : 'Save & Create Category',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
          ),
        ),
      ],
    );
  }
}
