import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hostel_management/core/widgets/app_shell.dart';

import '../../../../app/theme/app_colors.dart';

class FinancialReportsScreen extends StatelessWidget {
  const FinancialReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 24),

          const _FinancialReportList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Reports',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Review fees, payments, expenses and financial performance',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _FinancialReportList extends StatelessWidget {
  const _FinancialReportList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FinancialReportTile(
          title: 'Fee Collection Report',
          description:
              'View expected fees, collected amounts and outstanding balances',
          icon: Icons.payments_outlined,
          onTap: () {
            Get.find<AppShellController>().openFeeCollectionReport();
          },
        ),
        SizedBox(height: 12),
        _FinancialReportTile(
          title: 'Outstanding Fees Report',
          description: 'View students with unpaid or partially paid fees',
          icon: Icons.pending_actions_outlined,
        ),
        SizedBox(height: 12),
        _FinancialReportTile(
          title: 'Payment History',
          description:
              'Review all fee payments received during a selected period',
          icon: Icons.history_rounded,
        ),
        SizedBox(height: 12),
        _FinancialReportTile(
          title: 'Expense Report',
          description: 'Review hostel expenses and spending by category',
          icon: Icons.receipt_long_outlined,
        ),
        SizedBox(height: 12),
        _FinancialReportTile(
          title: 'Outstanding Bills Report',
          description: 'View bills with remaining unpaid balances',
          icon: Icons.account_balance_outlined,
        ),
        SizedBox(height: 12),
        _FinancialReportTile(
          title: 'Income vs Expenses',
          description: 'Compare received fee income with hostel expenses',
          icon: Icons.bar_chart_rounded,
        ),
      ],
    );
  }
}

class _FinancialReportTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;

  const _FinancialReportTile({
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 21, color: AppColors.primary),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
