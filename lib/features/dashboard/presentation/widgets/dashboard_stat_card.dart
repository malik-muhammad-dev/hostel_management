import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  // Optional — when set, a small pencil/edit button is shown in the
  // card's top-right corner. Only the "Total Amount" card uses this (to
  // let the opening balance be set/updated); every other card leaves
  // this null and renders exactly as before.
  final VoidCallback? onEdit;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.accentColor = AppColors.primary,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // A soft tint of the card's own accent color — this is what
        // gives each card its own "personality" (blue-ish, green-ish,
        // gold-ish...) rather than every card looking identical except
        // for the small icon.
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),

              if (onEdit != null)
                IconButton(
                  tooltip: 'Set opening balance',
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: accentColor,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}