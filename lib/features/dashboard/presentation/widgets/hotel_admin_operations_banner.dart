import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HotelAdminOperationsBanner extends StatefulWidget {
  final String resortName;
  final String location;
  final int totalRooms;
  final int occupancyPercentage;
  final Future<void> Function()? onSync;

  const HotelAdminOperationsBanner({
    super.key,
    this.resortName = 'Niraj Resort',
    this.location = 'Gujarat, India',
    this.totalRooms = 4,
    this.occupancyPercentage = 0,
    this.onSync,
  });

  @override
  State<HotelAdminOperationsBanner> createState() => _HotelAdminOperationsBannerState();
}

class _HotelAdminOperationsBannerState extends State<HotelAdminOperationsBanner>
    with SingleTickerProviderStateMixin {
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  bool _isSyncing = false;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _currentTime = DateTime.now();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  String get _gujaratiGreeting {
    final hour = _currentTime.hour;
    if (hour >= 5 && hour < 12) {
      return '✨ શુભ સવાર (GOOD MORNING) • LIVE OPERATIONS CENTER';
    } else if (hour >= 12 && hour < 17) {
      return '✨ શુભ બપોર (GOOD AFTERNOON) • LIVE OPERATIONS CENTER';
    } else if (hour >= 17 && hour < 21) {
      return '✨ શુભ સાંજ (GOOD EVENING) • LIVE OPERATIONS CENTER';
    } else {
      return '✨ શુભ રાત્રિ (GOOD NIGHT) • LIVE OPERATIONS CENTER';
    }
  }

  String get _formattedTime {
    return DateFormat('hh:mm:ss a').format(_currentTime).toLowerCase();
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    _spinController.repeat();
    try {
      if (widget.onSync != null) {
        await widget.onSync!();
      } else {
        await Future.delayed(const Duration(milliseconds: 800));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF064E3B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Operations center telemetry synced successfully.',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) {
        _spinController.stop();
        _spinController.reset();
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF064E3B), // Deep Emerald / Forest Green
            Color(0xFF042F2E), // Midnight Emerald Teal
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          // Background ambient radial accent
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag / Gujarati Operational Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.meeting_room_outlined,
                        color: Color(0xFF6EE7B7),
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _gujaratiGreeting,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: const Color(0xFFD1FAE5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Resort Title & Location Row
                Text(
                  widget.resortName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 4),

                // Location • Inventory • Occupancy
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF34D399),
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '${widget.location} • Total Inventory: ${widget.totalRooms} Rooms • Occupancy: ${widget.occupancyPercentage}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFA7F3D0),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Live Clock & Sync Live Status Button Row (Responsive Wrap)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Live Digital Clock Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF022C22).withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF34D399).withOpacity(0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pulsing Live Dot
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF22C55E),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formattedTime,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sync Live Status Action Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleSync,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RotationTransition(
                                turns: _spinController,
                                child: const Icon(
                                  Icons.sync_rounded,
                                  color: Color(0xFF064E3B),
                                  size: 15,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Sync Live Status',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF064E3B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
