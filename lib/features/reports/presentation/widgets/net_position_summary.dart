import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class NetPositionSummary extends StatelessWidget {
  final double income;
  final double expenses;
  final double netPosition;

  const NetPositionSummary({
    super.key,
    required this.income,
    required this.expenses,
    required this.netPosition,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardWidth = width > 700
            ? (width - 24) / 3
            : width;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(
              width: cardWidth,
              title: 'Income',
              value: _formatAmount(income),
              icon: Icons.arrow_downward_rounded,
            ),
            _SummaryCard(
              width: cardWidth,
              title: 'Expenses',
              value: _formatAmount(expenses),
              icon: Icons.arrow_upward_rounded,
            ),
            _SummaryCard(
              width: cardWidth,
              title: 'Net Position',
              value: _formatAmount(netPosition),
              icon: Icons.account_balance_wallet_outlined,
              valueColor: netPosition >= 0
                  ? AppColors.primary
                  : Colors.red,
            ),
          ],
        );
      },
    );
  }

  String _formatAmount(double amount) {
    return 'Rs. ${amount.abs().toStringAsFixed(0).replaceAllMapped(
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
  final Color? valueColor;

  const _SummaryCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    this.valueColor,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: valueColor ??
                          AppColors.textPrimary,
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