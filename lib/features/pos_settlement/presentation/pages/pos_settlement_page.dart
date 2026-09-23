import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';

class PosSettlementPage extends StatelessWidget {
  const PosSettlementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Point of Sale (POS) & Invoice Settlement',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Post room service, restaurant dining, laundry, and mini-bar charges directly to guest folios.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              CustomButton(
                text: '+ Post New Room Charge',
                icon: Icons.add,
                variant: ButtonVariant.primary,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add charge to folio dialog.')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // POS Terminal Cards
          Row(
            children: [
              Expanded(
                child: _buildPosCard(
                  title: 'Restaurant & In-Room Dining',
                  ordersCount: 4,
                  amount: '₹3,450',
                  icon: Icons.restaurant,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildPosCard(
                  title: 'Laundry & Housekeeping Services',
                  ordersCount: 1,
                  amount: '₹600',
                  icon: Icons.local_laundry_service_outlined,
                  color: AppColors.statusCleaning,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildPosCard(
                  title: 'Mini-Bar & Beverage Requisitions',
                  ordersCount: 2,
                  amount: '₹1,200',
                  icon: Icons.local_bar_outlined,
                  color: AppColors.statusGuests,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPosCard({
    required String title,
    required int ordersCount,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '$ordersCount Active Orders Posted Today',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
