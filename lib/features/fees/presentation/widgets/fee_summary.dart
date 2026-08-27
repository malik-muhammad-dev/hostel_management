import 'package:flutter/material.dart';

import 'fee_summary_card.dart';

class FeeSummary extends StatelessWidget {
  final double totalExpected;
  final double collected;
  final double outstanding;
  final double overdue;
  final String monthLabel;

  const FeeSummary({
    super.key,
    required this.totalExpected,
    required this.collected,
    required this.outstanding,
    required this.overdue,
    required this.monthLabel,
  });

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');

    return 'Rs. $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FeeSummaryCard(
            title: 'Total Expected',
            amount: _formatAmount(totalExpected),
            subtitle: monthLabel,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: FeeSummaryCard(
            title: 'Collected',
            amount: _formatAmount(collected),
            subtitle: monthLabel,
            icon: Icons.payments_outlined,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: FeeSummaryCard(
            title: 'Outstanding',
            amount: _formatAmount(outstanding),
            subtitle: 'Pending balance',
            icon: Icons.pending_actions_outlined,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: FeeSummaryCard(
            title: 'Overdue',
            amount: _formatAmount(overdue),
            subtitle: 'Past due date',
            icon: Icons.warning_amber_rounded,
          ),
        ),
      ],
    );
  }
}