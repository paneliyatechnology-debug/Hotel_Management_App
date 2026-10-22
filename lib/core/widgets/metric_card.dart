import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final int count;
  final String subtitle;
  final String tagLabel;
  final Color themeColor;
  final Color badgeBgColor;
  final IconData icon;
  final String? displayTitle;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.count,
    required this.subtitle,
    required this.tagLabel,
    required this.themeColor,
    required this.badgeBgColor,
    required this.icon,
    this.displayTitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = displayTitle ?? title;
    final keepsOriginalTitle = label.toUpperCase() == title.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: themeColor.withValues(alpha: 0.22)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 16, color: themeColor),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, size: 16, color: themeColor),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1.05,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    height: 1.2,
                  ),
                ),
                if (!keepsOriginalTitle)
                  Opacity(
                    opacity: 0,
                    child: SizedBox(
                      width: 0,
                      height: 0,
                      child: Text(title.toUpperCase()),
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
