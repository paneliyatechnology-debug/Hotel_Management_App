import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class InHouseSkeletonLoader extends StatefulWidget {
  const InHouseSkeletonLoader({super.key});

  @override
  State<InHouseSkeletonLoader> createState() => _InHouseSkeletonLoaderState();
}

class _InHouseSkeletonLoaderState extends State<InHouseSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.70).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.neutral200.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          _shimmerBox(width: 140, height: 24, borderRadius: 6),
          const SizedBox(height: 6),
          _shimmerBox(width: 220, height: 14, borderRadius: 4),
          const SizedBox(height: 16),

          // KPI Cards shimmer
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _shimmerBox(width: 38, height: 38, borderRadius: 10),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _shimmerBox(width: 60, height: 10),
                            const SizedBox(height: 6),
                            _shimmerBox(width: 80, height: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _shimmerBox(width: 38, height: 38, borderRadius: 10),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _shimmerBox(width: 60, height: 10),
                            const SizedBox(height: 6),
                            _shimmerBox(width: 80, height: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar shimmer
          _shimmerBox(width: double.infinity, height: 46, borderRadius: 12),
          const SizedBox(height: 14),

          // Filter chips shimmer
          Row(
            children: [
              _shimmerBox(width: 65, height: 32, borderRadius: 16),
              const SizedBox(width: 8),
              _shimmerBox(width: 90, height: 32, borderRadius: 16),
              const SizedBox(width: 8),
              _shimmerBox(width: 95, height: 32, borderRadius: 16),
              const SizedBox(width: 8),
              _shimmerBox(width: 110, height: 32, borderRadius: 16),
            ],
          ),
          const SizedBox(height: 16),

          // Card shimmers
          ...List.generate(2, (index) => _buildCardShimmer()),
        ],
      ),
    );
  }

  Widget _buildCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerBox(width: 44, height: 44, borderRadius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 120, height: 14),
                    const SizedBox(height: 6),
                    _shimmerBox(width: 80, height: 11),
                  ],
                ),
              ),
              _shimmerBox(width: 75, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 14),
          Row(
            children: [
              _shimmerBox(width: 32, height: 32, borderRadius: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 140, height: 14),
                    const SizedBox(height: 4),
                    _shimmerBox(width: 90, height: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _shimmerBox(width: double.infinity, height: 28, borderRadius: 6),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(width: 100, height: 20),
              _shimmerBox(width: 80, height: 32, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}
