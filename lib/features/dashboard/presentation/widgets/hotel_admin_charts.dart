import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/hotel_stats_model.dart';

// ============================================================================
// 1. LIVE ROOM OCCUPANCY DONUT CARD
// ============================================================================
class LiveRoomOccupancyDonutCard extends StatelessWidget {
  final HotelStatsModel stats;
  final int totalRooms;

  const LiveRoomOccupancyDonutCard({
    super.key,
    required this.stats,
    this.totalRooms = 4,
  }) : super();

  @override
  Widget build(BuildContext context) {
    final effectiveTotal = totalRooms > 0
        ? totalRooms
        : (stats.availableVacant +
            stats.occupiedInHouse +
            stats.housekeepingQueue +
            stats.maintenanceBlocked);
    final total = effectiveTotal > 0 ? effectiveTotal : 4;
    final occupied = stats.occupiedInHouse;
    final available = stats.availableVacant > 0 ? stats.availableVacant : (total - occupied);
    final cleaning = stats.housekeepingQueue;
    final maintenance = stats.maintenanceBlocked;

    final occupancyPct = total > 0 ? ((occupied / total) * 100).round() : 0;
    final availablePct = total > 0 ? ((available / total) * 100).round() : 100;
    final cleaningPct = total > 0 ? ((cleaning / total) * 100).round() : 0;
    final maintenancePct = total > 0 ? ((maintenance / total) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.bed_rounded, color: Color(0xFF0284C7), size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Live Room Occupancy',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.show_chart_rounded, size: 11, color: Color(0xFF059669)),
                    const SizedBox(width: 4),
                    Text(
                      '$occupancyPct% Occupied',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 3),
          Text(
            'Real-time room status breakdown',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 18),

          // Donut Chart Graphic
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _DonutChartPainter(
                      occupiedPct: occupied / total,
                      availablePct: available / total,
                      cleaningPct: cleaning / total,
                      maintenancePct: maintenance / total,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$occupancyPct%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'OCCUPANCY',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$total Total Rooms',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2x2 Legend Breakdown Grid matching screenshot
          Row(
            children: [
              Expanded(
                child: _buildLegendItem(
                  color: const Color(0xFF3B82F6),
                  label: 'Occupied',
                  count: '$occupied ($occupancyPct%)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLegendItem(
                  color: const Color(0xFF10B981),
                  label: 'Available',
                  count: '$available ($availablePct%)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildLegendItem(
                  color: const Color(0xFFF59E0B),
                  label: 'Cleaning',
                  count: '$cleaning ($cleaningPct%)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLegendItem(
                  color: const Color(0xFFEF4444),
                  label: 'Maintenance',
                  count: '$maintenance ($maintenancePct%)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              count,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double occupiedPct;
  final double availablePct;
  final double cleaningPct;
  final double maintenancePct;

  _DonutChartPainter({
    required this.occupiedPct,
    required this.availablePct,
    required this.cleaningPct,
    required this.maintenancePct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -math.pi / 2;

    void drawSegment(double pct, Color color) {
      if (pct <= 0) return;
      final sweepAngle = pct * 2 * math.pi;
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    // Draw Available first (usually largest) then occupied, cleaning, maintenance
    drawSegment(availablePct, const Color(0xFF10B981));
    drawSegment(occupiedPct, const Color(0xFF3B82F6));
    drawSegment(cleaningPct, const Color(0xFFF59E0B));
    drawSegment(maintenancePct, const Color(0xFFEF4444));
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

// ============================================================================
// 2. REVENUE & COLLECTION DYNAMICS SPLINE AREA CARD
// ============================================================================
class RevenueDynamicsSplineCard extends StatelessWidget {
  final String total7DayCollection;
  final String upiPercentage;
  final String cashPercentage;
  final String projectedMonthEnd;
  final String weeklyGrowth;

  const RevenueDynamicsSplineCard({
    super.key,
    this.total7DayCollection = '₹21,000',
    this.upiPercentage = '98% UPI',
    this.cashPercentage = '32% Cash',
    this.projectedMonthEnd = '₹0',
    this.weeklyGrowth = '+14.8% vs last week',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.insights_rounded, color: Color(0xFF059669), size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Revenue & Collection Dynamics',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: Text(
                      upiPercentage,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      cashPercentage,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 3),
          Text(
            '7-Day Total Collection: $total7DayCollection',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 16),

          // Custom Spline Chart
          SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(
              painter: _SplineChartPainter(),
            ),
          ),

          const SizedBox(height: 12),

          // Footer metrics row (responsive Wrap)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Projected Month End: $projectedMonthEnd',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_upward_rounded, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 2),
                  Text(
                    weeklyGrowth,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Today'];
    final dataPoints = [0.45, 0.45, 0.45, 0.45, 0.45, 0.45, 0.45]; // straight or gentle wave

    final width = size.width;
    final height = size.height - 24; // reserve 24 for labels
    final step = width / (dataPoints.length - 1);

    final path = Path();
    final fillPath = Path();

    final points = <Offset>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * step;
      final y = height * (1 - dataPoints[i]);
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
      fillPath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    // Fill with soft purple-to-cyan gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF6366F1).withOpacity(0.22),
          const Color(0xFF38BDF8).withOpacity(0.04),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    // Draw glowing data point dots
    final dotBgPaint = Paint()..color = Colors.white;
    final dotRingPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    for (final pt in points) {
      canvas.drawCircle(pt, 4.5, dotBgPaint);
      canvas.drawCircle(pt, 4.5, dotRingPaint);
    }

    // Draw day labels
    final textStyle = GoogleFonts.inter(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF94A3B8),
    );

    for (int i = 0; i < days.length; i++) {
      final textSpan = TextSpan(text: days[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final x = (i * step) - (textPainter.width / 2);
      textPainter.paint(canvas, Offset(x.clamp(0.0, width - textPainter.width), height + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 3. DAILY REVENUE GOAL RADIAL GAUGE CARD
// ============================================================================
class DailyRevenueGoalCard extends StatelessWidget {
  final int percentage;
  final String achievedAmount;
  final String targetAmount;

  const DailyRevenueGoalCard({
    super.key,
    this.percentage = 53,
    this.achievedAmount = '₹18,500',
    this.targetAmount = '₹35,000 / Day',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Daily Revenue Goal',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 10, color: Color(0xFFD97706)),
                    const SizedBox(width: 3),
                    Text(
                      'In Progress',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 3),
          Text(
            'Target: $targetAmount',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 12),

          // Semi-circular Arc Gauge
          Center(
            child: SizedBox(
              width: 180,
              height: 100,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  CustomPaint(
                    size: const Size(180, 100),
                    painter: _RadialArcGaugePainter(percentage: percentage),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percentage%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '$achievedAmount Achieved',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialArcGaugePainter extends CustomPainter {
  final int percentage;

  _RadialArcGaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 14;
    const strokeWidth = 14.0;

    // Background track arc
    final trackPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    // Progress Arc with vibrant amber gradient
    final progressFraction = (percentage / 100).clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFF59E0B),
          Color(0xFFF97316),
        ],
      ).createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi * progressFraction, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RadialArcGaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}

// ============================================================================
// 4. WEEKLY RECEPTION TRAFFIC PAIRED BAR CARD
// ============================================================================
class WeeklyReceptionTrafficCard extends StatefulWidget {
  const WeeklyReceptionTrafficCard({super.key});

  @override
  State<WeeklyReceptionTrafficCard> createState() => _WeeklyReceptionTrafficCardState();
}

class _WeeklyReceptionTrafficCardState extends State<WeeklyReceptionTrafficCard> {
  bool _isWeekly = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Color(0xFF6366F1), size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Weekly Reception Traffic',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Segmented Toggle Weekly / Hourly
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleBtn('Weekly', _isWeekly, () => setState(() => _isWeekly = true)),
                    _buildToggleBtn('Hourly', !_isWeekly, () => setState(() => _isWeekly = false)),
                  ],
                ),
              ),
            ],
          ),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '7-Day guest check-in vs check-out volume',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
              // Legend ● In  ● Out
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('In', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF475569))),
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEC4899),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('Out', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF475569))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Paired Bar Chart
          SizedBox(
            height: 120,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildDayBars('Mon', inVal: 0.25, outVal: 0.15),
                _buildDayBars('Tue', inVal: 0.35, outVal: 0.2),
                _buildDayBars('Wed', inVal: 0.40, outVal: 0.3),
                _buildDayBars('Thu', inVal: 0.50, outVal: 0.38),
                _buildDayBars('Fri', inVal: 0.75, outVal: 0.65, isPeak: true),
                _buildDayBars('Sat', inVal: 0.90, outVal: 0.85, isPeak: true),
                _buildDayBars('Sun', inVal: 0.82, outVal: 0.92, isPeak: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildDayBars(String day, {required double inVal, required double outVal, bool isPeak = false}) {
    const maxHeight = 85.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isPeak)
          const Text('🔥', style: TextStyle(fontSize: 10))
        else
          const SizedBox(height: 14),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // In Bar (Blue)
            Container(
              width: 8,
              height: (inVal * maxHeight).clamp(10.0, maxHeight),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 3),
            // Out Bar (Pink)
            Container(
              width: 8,
              height: (outVal * maxHeight).clamp(10.0, maxHeight),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: isPeak ? FontWeight.w700 : FontWeight.w500,
            color: isPeak ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
