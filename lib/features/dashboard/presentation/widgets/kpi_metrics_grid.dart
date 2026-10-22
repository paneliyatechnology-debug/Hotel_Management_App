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
        final isMobile = constraints.maxWidth < 650;

        final availableCard = MetricCard(
          title: 'Available Vacant',
          displayTitle: 'Available',
          count: stats.availableVacant,
          subtitle: 'Ready for check-in',
          tagLabel: 'Vacant',
          themeColor: AppColors.statusAvailable,
          badgeBgColor: AppColors.statusAvailableBg,
          icon: Icons.hotel_rounded,
          onTap: () => onMetricSelected?.call('Available'),
        );

        final occupiedCard = MetricCard(
          title: 'Occupied / Booked',
          displayTitle: 'Occupied',
          count: stats.occupiedInHouse,
          subtitle: 'Guests staying',
          tagLabel: 'In-House',
          themeColor: AppColors.statusOccupied,
          badgeBgColor: AppColors.statusOccupiedBg,
          icon: Icons.people_alt_rounded,
          onTap: () => onMetricSelected?.call('Occupied'),
        );

        final housekeepingCard = MetricCard(
          title: 'Housekeeping Queue',
          displayTitle: 'Housekeeping',
          count: stats.housekeepingQueue,
          subtitle: 'Rooms to clean',
          tagLabel: 'Cleaning',
          themeColor: AppColors.statusCleaning,
          badgeBgColor: AppColors.statusCleaningBg,
          icon: Icons.cleaning_services_rounded,
          onTap: () => onMetricSelected?.call('Cleaning'),
        );

        final maintenanceCard = MetricCard(
          title: 'Maintenance / Blocked',
          displayTitle: 'Maintenance',
          count: stats.maintenanceBlocked,
          subtitle: 'Out of service',
          tagLabel: 'Blocked',
          themeColor: AppColors.statusMaintenance,
          badgeBgColor: AppColors.statusMaintenanceBg,
          icon: Icons.build_rounded,
          onTap: () => onMetricSelected?.call('Maintenance'),
        );

        final inHouseGuestCard = MetricCard(
          title: 'Total In-House Guests',
          count: stats.totalInHouseGuests,
          subtitle: 'Active keycard folios',
          tagLabel: 'Guests',
          themeColor: AppColors.statusGuests,
          badgeBgColor: AppColors.statusGuestsBg,
          icon: Icons.people_alt_outlined,
          onTap: () => onMetricSelected?.call('InHouseFolios'),
        );

        // Desktop layout (5 in a row)
        if (!isMobile) {
          final allCards = [
            availableCard,
            occupiedCard,
            housekeepingCard,
            maintenanceCard,
            inHouseGuestCard,
          ];

          if (constraints.maxWidth >= 1100) {
            return Row(
              children: allCards
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
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: allCards,
          );
        }

        // Mobile 2026 Layout: 2x2 Room Status Grid
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.35,
          children: [
            availableCard,
            occupiedCard,
            housekeepingCard,
            maintenanceCard,
          ],
        );
      },
    );
  }
}

