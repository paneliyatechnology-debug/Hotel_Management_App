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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Squircle Mint Icon Container
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 20,
                    color: const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 8),

                // Middle Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Right Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
