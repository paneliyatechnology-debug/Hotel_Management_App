import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../data/models/hotel_stats_model.dart';

class KpiMetricsGrid extends StatelessWidget {
  final HotelStatsModel stats;
  final ValueChanged<String>? onMetricSelected;

  const KpiMetricsGrid({
    super.key,
    required this.stats,
    this.onMetricSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 5;
        double childAspectRatio = 1.6;

        if (constraints.maxWidth < 650) {
          crossAxisCount = 2;
          childAspectRatio = 1.15; // Roomy aspect ratio on mobile
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 3;
          childAspectRatio = 1.35;
        }

        final cards = [
          MetricCard(
            title: 'Available Vacant',
            count: stats.availableVacant,
            subtitle: 'Ready for guest check-in',
            tagLabel: 'Vacant',
            themeColor: AppColors.statusAvailable,
            badgeBgColor: AppColors.statusAvailableBg,
            icon: Icons.check_circle_outline,
            onTap: () => onMetricSelected?.call('Available'),
          ),
          MetricCard(
            title: 'Occupied In-House',
            count: stats.occupiedInHouse,
            subtitle: 'Active guest stay',
            tagLabel: 'In-House',
            themeColor: AppColors.statusOccupied,
            badgeBgColor: AppColors.statusOccupiedBg,
            icon: Icons.person_outline,
            onTap: () => onMetricSelected?.call('Occupied'),
          ),
          MetricCard(
            title: 'Housekeeping Queue',
            count: stats.housekeepingQueue,
            subtitle: 'Linen sanitation buffer',
            tagLabel: 'Cleaning',
            themeColor: AppColors.statusCleaning,
            badgeBgColor: AppColors.statusCleaningBg,
            icon: Icons.cleaning_services_outlined,
            onTap: () => onMetricSelected?.call('Cleaning'),
          ),
          MetricCard(
            title: 'Maintenance / Blocked',
            count: stats.maintenanceBlocked,
            subtitle: 'Out of service repairs',
            tagLabel: 'All Clear',
            themeColor: AppColors.statusMaintenance,
            badgeBgColor: AppColors.statusMaintenanceBg,
            icon: Icons.build_outlined,
            onTap: () => onMetricSelected?.call('Maintenance'),
          ),
          MetricCard(
            title: 'Total In-House Guests',
            count: stats.totalInHouseGuests,
            subtitle: 'Active keycard folios',
            tagLabel: 'Guests',
            themeColor: AppColors.statusGuests,
            badgeBgColor: AppColors.statusGuestsBg,
            icon: Icons.people_alt_outlined,
            onTap: () => onMetricSelected?.call('InHouseFolios'),
          ),
        ];

        if (crossAxisCount == 5) {
          return Row(
            children: cards
                .map((card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: card,
                      ),
                    ))
                .toList(),
          );
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: childAspectRatio,
          children: cards,
        );
      },
    );
  }
}
