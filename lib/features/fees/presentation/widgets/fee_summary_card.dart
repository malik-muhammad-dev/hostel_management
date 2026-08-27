import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class FeeSummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;

  const FeeSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 19, color: AppColors.primary),
              ),

              const Spacer(),

              const Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            amount,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
