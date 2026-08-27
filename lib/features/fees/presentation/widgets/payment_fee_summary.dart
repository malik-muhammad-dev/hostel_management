import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'fee_summary_line.dart';

class PaymentFeeSummary extends StatelessWidget {
  final double currentMonthFee;
  final double alreadyPaidThisMonth;
  final double previousBalance;
  final double fine;
  final double discount;
  final double totalDue;

  const PaymentFeeSummary({
    super.key,
    required this.currentMonthFee,
    required this.alreadyPaidThisMonth,
    required this.previousBalance,
    required this.fine,
    required this.discount,
    required this.totalDue,
  });

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');

    return 'Rs. $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Summary',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 20),

          FeeSummaryLine(
            label: 'Current Month Fee',
            amount: _formatAmount(currentMonthFee),
          ),

          // Only shown when something has already been paid toward this
          // month — makes it obvious to staff why the remaining Total Due
          // is less than the full Current Month Fee, instead of it just
          // silently being a smaller number.
          if (alreadyPaidThisMonth > 0) ...[
            const SizedBox(height: 12),
            FeeSummaryLine(
              label: 'Already Paid This Month',
              amount: '- ${_formatAmount(alreadyPaidThisMonth)}',
            ),
          ],

          const SizedBox(height: 12),

          FeeSummaryLine(
            label: 'Previous Balance',
            amount: _formatAmount(previousBalance),
          ),

          const SizedBox(height: 12),

          FeeSummaryLine(label: 'Fine', amount: _formatAmount(fine)),

          const SizedBox(height: 12),

          FeeSummaryLine(
            label: 'Discount',
            amount: '- ${_formatAmount(discount)}',
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.border),
          ),

          FeeSummaryLine(
            label: 'Total Due',
            amount: _formatAmount(totalDue),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}