import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

enum ButtonVariant { primary, secondary, outlined, ghost, white }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = 42,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Border? border;

    switch (variant) {
      case ButtonVariant.primary:
        bgColor = AppColors.primary;
        textColor = Colors.white;
        border = null;
        break;
      case ButtonVariant.secondary:
        bgColor = AppColors.accentGreen;
        textColor = Colors.white;
        border = null;
        break;
      case ButtonVariant.outlined:
        bgColor = Colors.transparent;
        textColor = AppColors.textPrimary;
        border = Border.all(color: AppColors.border, width: 1.2);
        break;
      case ButtonVariant.ghost:
        bgColor = Colors.transparent;
        textColor = AppColors.textSecondary;
        border = null;
        break;
      case ButtonVariant.white:
        bgColor = Colors.white;
        textColor = AppColors.primaryDark;
        border = Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3), width: 1);
        break;
    }

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: border,
            ),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 16, color: textColor),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
