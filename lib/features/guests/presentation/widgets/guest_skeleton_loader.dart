import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class GuestSkeletonLoader extends StatefulWidget {
  final int count;
  const GuestSkeletonLoader({super.key, this.count = 4});

  @override
  State<GuestSkeletonLoader> createState() => _GuestSkeletonLoaderState();
}

class _GuestSkeletonLoaderState extends State<GuestSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = 0.35 + (_animation.value * 0.35);
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: widget.count,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.neutral200.withValues(alpha: opacity),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 130,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.neutral300.withValues(alpha: opacity),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 90,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.neutral200.withValues(alpha: opacity),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.neutral200.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 1,
                    color: AppColors.borderSubtle,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 150,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.neutral200.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.neutral200.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
