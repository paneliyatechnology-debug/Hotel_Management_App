import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ShimmerPulse extends InheritedWidget {
  final double opacity;

  const ShimmerPulse({super.key, required this.opacity, required super.child});

  static double of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShimmerPulse>()?.opacity ?? 0.55;
  }

  @override
  bool updateShouldNotify(ShimmerPulse oldWidget) => opacity != oldWidget.opacity;
}

/// Gray bar that pulses with the same colors as the guest list skeleton.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final BoxShape shape;
  final bool strong;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
    this.shape = BoxShape.rectangle,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = ShimmerPulse.of(context);
    final base = strong ? AppColors.neutral300 : AppColors.neutral200;
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: base.withValues(alpha: opacity),
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Pulses child bars the same way the guest list skeleton does.
class ShimmerWrapper extends StatefulWidget {
  final Widget child;

  const ShimmerWrapper({super.key, required this.child});

  @override
  State<ShimmerWrapper> createState() => _ShimmerWrapperState();
}

class _ShimmerWrapperState extends State<ShimmerWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + (_controller.value * 0.35);
        return ShimmerPulse(opacity: opacity, child: widget.child);
      },
    );
  }
}

BoxDecoration _skeletonCardDecoration({double radius = 14}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.borderSubtle),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/// Shimmer loader for TAB 0: Front Desk Dashboard
/// Exactly mirrors the modern 2026 UI layout with:
/// - Hero Welcome Banner
/// - 4 KPI metric cards + 2 wide cards
/// - Room Categories & Live Inventory cards
/// - Recent Check-In & Check-Out folios section
class DashboardShimmerLoader extends StatelessWidget {
  const DashboardShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [

          // 2. LIVE METRICS OVERVIEW Header Shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 140, height: 12, borderRadius: 4),
                ShimmerBox(width: 80, height: 10, borderRadius: 4),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. 2x2 KPI Metrics Grid Shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildKpiCardShimmer()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKpiCardShimmer()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildKpiCardShimmer()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKpiCardShimmer()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 4. Room Categories & Live Inventory Header & Cards Shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 180, height: 12, borderRadius: 4),
                const SizedBox(height: 10),
                _buildCategoryCardShimmer(),
                const SizedBox(height: 10),
                _buildCategoryCardShimmer(),
                const SizedBox(height: 10),
                _buildCategoryCardShimmer(),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 5. Recent Check-In & Check-Out Section Shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    ShimmerBox(width: 160, height: 12, borderRadius: 4),
                    ShimmerBox(width: 70, height: 22, borderRadius: 8),
                  ],
                ),
                const SizedBox(height: 10),
                // Filter chips
                Row(
                  children: const [
                    ShimmerBox(width: 55, height: 28, borderRadius: 14),
                    SizedBox(width: 8),
                    ShimmerBox(width: 90, height: 28, borderRadius: 14),
                    SizedBox(width: 8),
                    ShimmerBox(width: 95, height: 28, borderRadius: 14),
                  ],
                ),
                const SizedBox(height: 12),
                _buildGuestFolioCardShimmer(),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKpiCardShimmer() {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(width: 85, height: 10, borderRadius: 4),
              ShimmerBox(width: 26, height: 26, shape: BoxShape.circle),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              ShimmerBox(width: 32, height: 24, borderRadius: 4),
              ShimmerBox(width: 48, height: 18, borderRadius: 6),
            ],
          ),
          const ShimmerBox(width: 80, height: 9, borderRadius: 3),
        ],
      ),
    );
  }

  Widget _buildCategoryCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const ShimmerBox(width: 34, height: 34, borderRadius: 8),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 110, height: 13, borderRadius: 4),
                    SizedBox(height: 3),
                    ShimmerBox(width: 160, height: 10, borderRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const ShimmerBox(width: 55, height: 16, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              ShimmerBox(width: 58, height: 18, borderRadius: 6),
              SizedBox(width: 6),
              ShimmerBox(width: 58, height: 18, borderRadius: 6),
              SizedBox(width: 6),
              ShimmerBox(width: 58, height: 18, borderRadius: 6),
              Spacer(),
              ShimmerBox(width: 50, height: 14, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestFolioCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerBox(width: 32, height: 32, shape: BoxShape.circle),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 120, height: 13, borderRadius: 3),
                    SizedBox(height: 3),
                    ShimmerBox(width: 150, height: 9, borderRadius: 3),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const ShimmerBox(width: 68, height: 18, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(width: 160, height: 12, borderRadius: 4),
              ShimmerBox(width: 14, height: 14, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _SkeletonCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: _skeletonCardDecoration(radius: radius),
      child: child,
    );
  }
}

/// Matches the Daily Collections hero, three totals, and ledger rows.
class DailyCollectionsShimmer extends StatelessWidget {
  const DailyCollectionsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _SkeletonCard(
            radius: 16,
            padding: const EdgeInsets.all(18),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 20, height: 20, borderRadius: 6, strong: true),
                    SizedBox(width: 8),
                    ShimmerBox(width: 160, height: 13, borderRadius: 4),
                    Spacer(),
                    ShimmerBox(width: 78, height: 20, borderRadius: 20),
                  ],
                ),
                SizedBox(height: 14),
                ShimmerBox(width: 140, height: 28, borderRadius: 6, strong: true),
                SizedBox(height: 8),
                ShimmerBox(width: 220, height: 12, borderRadius: 4),
                SizedBox(height: 16),
                ShimmerBox(height: 42, borderRadius: 10),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 78, borderRadius: 14)),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(height: 78, borderRadius: 14)),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(height: 78, borderRadius: 14)),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(4, (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: _SkeletonCard(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      ShimmerBox(width: 36, height: 36, borderRadius: 10),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(width: 120, height: 13, borderRadius: 4, strong: true),
                            SizedBox(height: 6),
                            ShimmerBox(width: 80, height: 11, borderRadius: 4),
                          ],
                        ),
                      ),
                      ShimmerBox(width: 64, height: 14, borderRadius: 4, strong: true),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

/// Matches the revenue hero and the breakdown card.
class RevenueReportsShimmer extends StatelessWidget {
  const RevenueReportsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          _SkeletonCard(
            radius: 16,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 130, height: 12, borderRadius: 4),
                    ShimmerBox(width: 72, height: 20, borderRadius: 20),
                  ],
                ),
                SizedBox(height: 14),
                ShimmerBox(width: 160, height: 32, borderRadius: 6, strong: true),
                SizedBox(height: 8),
                ShimmerBox(width: 210, height: 12, borderRadius: 4),
              ],
            ),
          ),
          SizedBox(height: 18),
          _SkeletonCard(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 180, height: 14, borderRadius: 4, strong: true),
                SizedBox(height: 16),
                ShimmerBox(height: 12, borderRadius: 4),
                SizedBox(height: 8),
                ShimmerBox(height: 8, borderRadius: 6),
                SizedBox(height: 16),
                ShimmerBox(height: 12, borderRadius: 4),
                SizedBox(height: 8),
                ShimmerBox(height: 8, borderRadius: 6),
                SizedBox(height: 16),
                ShimmerBox(height: 12, borderRadius: 4),
                SizedBox(height: 8),
                ShimmerBox(height: 8, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Matches the monthly subscription plan cards.
class SubscriptionShimmer extends StatelessWidget {
  const SubscriptionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          ShimmerBox(width: 140, height: 18, borderRadius: 6, strong: true),
          SizedBox(height: 8),
          ShimmerBox(width: 240, height: 12, borderRadius: 4),
          SizedBox(height: 16),
          _PlanCardShimmer(),
          SizedBox(height: 12),
          _PlanCardShimmer(),
          SizedBox(height: 12),
          _PlanCardShimmer(),
        ],
      ),
    );
  }
}

class _PlanCardShimmer extends StatelessWidget {
  const _PlanCardShimmer();

  @override
  Widget build(BuildContext context) {
    return const _SkeletonCard(
      radius: 18,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 150, height: 16, borderRadius: 4, strong: true),
              ShimmerBox(width: 72, height: 20, borderRadius: 20),
            ],
          ),
          SizedBox(height: 12),
          ShimmerBox(width: 110, height: 26, borderRadius: 6, strong: true),
          SizedBox(height: 10),
          ShimmerBox(height: 12, borderRadius: 4),
          SizedBox(height: 14),
          ShimmerBox(height: 12, borderRadius: 4),
          SizedBox(height: 8),
          ShimmerBox(width: 200, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Matches the settings section headers and form fields.
class SettingsShimmer extends StatelessWidget {
  const SettingsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          ShimmerBox(width: 140, height: 14, borderRadius: 4, strong: true),
          SizedBox(height: 10),
          _SkeletonCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: ShimmerBox(height: 48, borderRadius: 10)),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 48, borderRadius: 10)),
                  ],
                ),
                SizedBox(height: 12),
                ShimmerBox(height: 48, borderRadius: 10),
              ],
            ),
          ),
          SizedBox(height: 20),
          ShimmerBox(width: 160, height: 14, borderRadius: 4, strong: true),
          SizedBox(height: 10),
          _SkeletonCard(
            child: Column(
              children: [
                ShimmerBox(height: 44, borderRadius: 10),
                SizedBox(height: 12),
                ShimmerBox(height: 44, borderRadius: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loader for TAB 1: Rooms Tab
class RoomsShimmerLoader extends StatelessWidget {
  const RoomsShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // Header
          const ShimmerBox(width: 180, height: 18, borderRadius: 4),
          const SizedBox(height: 6),
          const ShimmerBox(width: 240, height: 11, borderRadius: 4),
          const SizedBox(height: 14),

          // Search Bar
          const ShimmerBox(height: 44, borderRadius: 12),
          const SizedBox(height: 12),

          // Filter Chips
          Row(
            children: const [
              ShimmerBox(width: 70, height: 32, borderRadius: 16),
              SizedBox(width: 8),
              ShimmerBox(width: 85, height: 32, borderRadius: 16),
              SizedBox(width: 8),
              ShimmerBox(width: 75, height: 32, borderRadius: 16),
              SizedBox(width: 8),
              ShimmerBox(width: 70, height: 32, borderRadius: 16),
            ],
          ),
          const SizedBox(height: 16),

          // Room Cards
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 125,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 120, height: 14, borderRadius: 4),
                      ShimmerBox(width: 60, height: 14, borderRadius: 4),
                    ],
                  ),
                  const ShimmerBox(width: 160, height: 10, borderRadius: 4),
                  Row(
                    children: const [
                      Expanded(child: ShimmerBox(height: 24, borderRadius: 8)),
                      SizedBox(width: 6),
                      Expanded(child: ShimmerBox(height: 24, borderRadius: 8)),
                      SizedBox(width: 6),
                      Expanded(child: ShimmerBox(height: 24, borderRadius: 8)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 100, height: 12, borderRadius: 4),
                      ShimmerBox(width: 70, height: 12, borderRadius: 4),
                    ],
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

/// Shimmer loader for TAB 2: In-House Guests Tab
class InHouseShimmerLoader extends StatelessWidget {
  const InHouseShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // Header
          const ShimmerBox(width: 160, height: 18, borderRadius: 4),
          const SizedBox(height: 6),
          const ShimmerBox(width: 220, height: 11, borderRadius: 4),
          const SizedBox(height: 14),

          // 4 KPI Summary Cards
          Row(
            children: [
              Expanded(child: _buildInHouseKpiCardShimmer()),
              const SizedBox(width: 10),
              Expanded(child: _buildInHouseKpiCardShimmer()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildInHouseKpiCardShimmer()),
              const SizedBox(width: 10),
              Expanded(child: _buildInHouseKpiCardShimmer()),
            ],
          ),
          const SizedBox(height: 14),

          // Search Bar
          const ShimmerBox(height: 44, borderRadius: 12),
          const SizedBox(height: 12),

          // Filter Chips
          Row(
            children: const [
              ShimmerBox(width: 60, height: 28, borderRadius: 14),
              SizedBox(width: 8),
              ShimmerBox(width: 85, height: 28, borderRadius: 14),
              SizedBox(width: 8),
              ShimmerBox(width: 90, height: 28, borderRadius: 14),
            ],
          ),
          const SizedBox(height: 14),

          // Folio Cards
          ...List.generate(2, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const ShimmerBox(width: 38, height: 38, shape: BoxShape.circle),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerBox(width: 110, height: 14, borderRadius: 4),
                            SizedBox(height: 5),
                            ShimmerBox(width: 140, height: 10, borderRadius: 4),
                          ],
                        ),
                      ),
                      const ShimmerBox(width: 65, height: 20, borderRadius: 6),
                    ],
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 130, height: 11, borderRadius: 4),
                      ShimmerBox(width: 55, height: 16, borderRadius: 6),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 85, height: 11, borderRadius: 4),
                      ShimmerBox(width: 70, height: 11, borderRadius: 4),
                    ],
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInHouseKpiCardShimmer() {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          ShimmerBox(width: 70, height: 9, borderRadius: 3),
          ShimmerBox(width: 45, height: 20, borderRadius: 4),
          ShimmerBox(width: 80, height: 8, borderRadius: 2),
        ],
      ),
    );
  }
}
