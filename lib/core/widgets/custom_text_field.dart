import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final Widget? labelWidget;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    this.label = '',
    this.labelWidget,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelWidget != null) ...[
          labelWidget!,
          const SizedBox(height: 6),
        ] else if (label.isNotEmpty) ...[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF94A3B8),
            ),
            helperText: helperText,
            helperStyle: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
            errorText: errorText,
            errorStyle: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFDC2626),
            ),
            prefixIcon: prefixIcon != null
                ? Container(
                    margin: const EdgeInsets.only(left: 8, right: 6, top: 4, bottom: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(prefixIcon, size: 16, color: const Color(0xFF64748B)),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
