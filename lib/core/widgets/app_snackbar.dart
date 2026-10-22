import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A top toast that stays above modal sheets.
class AppSnackBar {
  AppSnackBar._();

  static OverlayEntry? _entry;

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
    _entry?.remove();
    _entry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _TopToast(
        message: message,
        title: title,
        duration: duration,
        type: type,
        onClose: () {
          if (entry.mounted) entry.remove();
          if (identical(_entry, entry)) _entry = null;
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

enum _SnackBarType { success, error, info }

class _TopToast extends StatefulWidget {
  final String message;
  final String title;
  final Duration duration;
  final _SnackBarType type;
  final VoidCallback onClose;

  const _TopToast({
    required this.message,
    required this.title,
    required this.duration,
    required this.type,
    required this.onClose,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _controller.forward();
    Future<void>.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted || _closing) return;
    _closing = true;
    await _controller.reverse();
    if (mounted) widget.onClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor;
    final IconData icon;
    switch (widget.type) {
      case _SnackBarType.success:
        accentColor = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        break;
      case _SnackBarType.error:
        accentColor = const Color(0xFFEF4444);
        icon = Icons.error_outline_rounded;
        break;
      case _SnackBarType.info:
        accentColor = const Color(0xFF3B82F6);
        icon = Icons.info_outline_rounded;
        break;
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: FadeTransition(
              opacity: _controller,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentColor.withValues(alpha: 0.38), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: accentColor, size: 21),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFF1F5F9),
                                height: 1.3,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: _dismiss,
                        icon: Icon(Icons.close_rounded, size: 18, color: Colors.white.withValues(alpha: 0.45)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
