import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/expense_controller.dart';

class ExpenseSummary extends StatelessWidget {
  final ExpenseController controller;

  const ExpenseSummary({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final month = controller.selectedMonth.value;
        final monthLabel = _formatMonthLabel(month);

        return Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Expenses',
                amount: _formatAmount(
                  controller.totalForMonth(month),
                ),
                subtitle: monthLabel,
                icon: Icons.receipt_long_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                title: 'Cash Expenses',
                amount: _formatAmount(
                  controller.cashForMonth(month),
                ),
                subtitle: monthLabel,
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                title: 'Account Expenses',
                amount: _formatAmount(
                  controller.accountForMonth(month),
                ),
                subtitle: monthLabel,
                icon: Icons.account_balance_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatMonthLabel(String value) {
    final parts = value.split('-');
    if (parts.length != 2) return 'Selected month';

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return 'Selected month';
    }

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return '${months[month - 1]} $year';
  }

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );

    return 'Rs. $formatted';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;

  const _SummaryCard({
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
        border: Border.all(
          color: AppColors.border,
        ),
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
                child: Icon(
                  icon,
                  size: 19,
                  color: AppColors.primary,
                ),
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