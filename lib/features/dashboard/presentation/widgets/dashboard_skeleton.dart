import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_box.dart';

// =============================================================================
// DASHBOARD SKELETON
//
// Shown only on the very first load — before StudentController,
// FeeController, ExpenseController, and ReceiptController have fetched
// anything yet (see DashboardController.isInitialLoading). Once any real
// data has ever loaded, this never shows again, even during a quiet
// background refresh from real-time sync.
//
// Loosely mirrors the real layout (7 stat cards, a chart row, a short
// list) so the page doesn't visibly jump around once the real content
// swaps in — it doesn't need to be pixel-perfect, just the same shape.
// =============================================================================

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stat cards
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 16.0;
            final columns = constraints.maxWidth < 900 ? 2 : 3;
            final cardWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (int i = 0; i < 7; i++)
                  SizedBox(
                    width: cardWidth,
                    child: const _StatCardSkeleton(),
                  ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // Trend chart + expense breakdown
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;

            final chart = AppShimmer(
              child: Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );

            final breakdown = AppShimmer(
              child: Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );

            if (isNarrow) {
              return Column(
                children: [
                  chart,
                  const SizedBox(height: 24),
                  breakdown,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: chart),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: breakdown),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Recent activity
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: TableSkeleton(
            columnFlexes: const [4, 2],
            hasAvatar: false,
            trailingWidth: 70,
            rowCount: 5,
          ),
        ),
      ],
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            const SizedBox(height: 16),
            const ShimmerBox(width: 90, height: 20),
            const SizedBox(height: 8),
            const ShimmerBox(width: 110, height: 13),
            const SizedBox(height: 6),
            const ShimmerBox(width: 130, height: 11),
          ],
        ),
      ),
    );
  }
}