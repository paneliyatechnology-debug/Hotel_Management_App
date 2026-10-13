import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A modern, beautiful, floating SnackBar utility for displaying
/// API response messages, success alerts, and error states.
class AppSnackBar {
  AppSnackBar._();

  static void showSuccess(
    BuildContext context,
    String message, {
    String title = 'Success',
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    _show(
      context: context,
      message: message,
      title: title,
      duration: duration,
      type: _SnackBarType.success,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String title = 'Request Failed',
    Duration duration = const Duration(milliseconds: 4500),
  }) {
    _show(
      context: context,
      message: message,
      title: title,
      duration: duration,
      type: _SnackBarType.error,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String title = 'Notice',
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    _show(
      context: context,
      message: message,
      title: title,
      duration: duration,
      type: _SnackBarType.info,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required String title,
    required Duration duration,
    required _SnackBarType type,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    Color accentColor;
    Color iconBgColor;
    Color borderColor;
    Color glowColor;
    IconData icon;

    switch (type) {
      case _SnackBarType.success:
        accentColor = const Color(0xFF10B981); // Emerald
        iconBgColor = const Color(0xFF10B981).withValues(alpha: 0.16);
        borderColor = const Color(0xFF10B981).withValues(alpha: 0.38);
        glowColor = const Color(0xFF10B981).withValues(alpha: 0.12);
        icon = Icons.check_circle_rounded;
        break;
      case _SnackBarType.error:
        accentColor = const Color(0xFFEF4444); // Crimson Rose
        iconBgColor = const Color(0xFFEF4444).withValues(alpha: 0.16);
        borderColor = const Color(0xFFEF4444).withValues(alpha: 0.38);
        glowColor = const Color(0xFFEF4444).withValues(alpha: 0.12);
        icon = Icons.error_outline_rounded;
        break;
      case _SnackBarType.info:
        accentColor = const Color(0xFF3B82F6); // Blue
        iconBgColor = const Color(0xFF3B82F6).withValues(alpha: 0.16);
        borderColor = const Color(0xFF3B82F6).withValues(alpha: 0.38);
        glowColor = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        icon = Icons.info_outline_rounded;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Premium Dark Slate
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status Icon Badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Icon(icon, color: accentColor, size: 21),
              ),
              const SizedBox(width: 12),

              // Title & Response Message Content
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFF1F5F9), // Slate 100
                        height: 1.3,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Close / Dismiss Button
              InkWell(
                onTap: () => messenger.hideCurrentSnackBar(),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SnackBarType { success, error, info }
