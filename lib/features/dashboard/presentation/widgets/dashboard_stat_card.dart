import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  // Optional — when set, a small "add" button is shown in the card's
  // top-right corner. Only the "Total Amount" card uses this (to open
  // "Add to Total Balance"); every other card leaves this null and
  // renders exactly as before.
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
      // Shrunk from 20 all round — client asked for smaller Dashboard
      // cards so the whole board fits on screen without scrolling. Every
      // size below (icon box, icon, spacing, font sizes) was scaled down
      // together with this, not just the padding, so the card still
      // looks proportioned rather than merely cropped.
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        // A soft tint of the card's own accent color — this is what
        // gives each card its own "personality" (blue-ish, green-ish,
        // gold-ish...) rather than every card looking identical except
        // for the small icon.
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 17),
              ),

              if (onEdit != null)
                IconButton(
                  tooltip: 'Add to Total Balance',
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: accentColor,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 1),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}