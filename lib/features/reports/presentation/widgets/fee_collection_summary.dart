import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class FeeCollectionSummary extends StatelessWidget {
  final double expected;
  final double collected;
  final double outstanding;
  final double collectionRate;

  const FeeCollectionSummary({
    super.key,
    required this.expected,
    required this.collected,
    required this.outstanding,
    required this.collectionRate,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardWidth = width > 900
            ? (width - 36) / 4
            : width > 600
                ? (width - 12) / 2
                : width;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(
              width: cardWidth,
              title: 'Total Expected',
              value: _formatAmount(expected),
              icon: Icons.receipt_long_outlined,
            ),
            _SummaryCard(
              width: cardWidth,
              title: 'Total Collected',
              value: _formatAmount(collected),
              icon: Icons.payments_outlined,
            ),
            _SummaryCard(
              width: cardWidth,
              title: 'Total Outstanding',
              value: _formatAmount(outstanding),
              icon: Icons.pending_actions_outlined,
            ),
            _SummaryCard(
              width: cardWidth,
              title: 'Collection Rate',
              value:
                  '${collectionRate.toStringAsFixed(1)}%',
              icon: Icons.percent_outlined,
            ),
          ],
        );
      },
    );
  }

  String _formatAmount(double amount) {
    return 'Rs. ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        )}';
  }
}

class _SummaryCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}