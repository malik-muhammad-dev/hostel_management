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

  // Optional — when set, a small info icon appears next to the title.
  // Hovering/long-pressing it shows this text. Added specifically for
  // "Total Amount," whose number legitimately differs from Total Cash +
  // Total Account (client kept asking where the gap came from) — this
  // gives a hover-away explanation with the actual live breakdown,
  // instead of the client having to ask each time. Any other card can
  // use it too; leaving it null renders exactly as before.
  final String? infoTooltip;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.accentColor = AppColors.primary,
    this.onEdit,
    this.infoTooltip,
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
                Tooltip(
                  message: 'Add to Total Balance',
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 26,
                      height: 26,
                      // A filled icon on a solid tinted background — the
                      // old plain IconButton used an *outline* icon with
                      // no background at all, which on this card's very
                      // light tint was just a thin stroke of near-white
                      // on near-white and was genuinely hard to see, even
                      // though the tap target underneath it still worked.
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_circle,
                        size: 16,
                        color: accentColor,
                      ),
                    ),
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

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              if (infoTooltip != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: infoTooltip!,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.info_outline,
                    size: 13,
                    color: accentColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
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