import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hostel_management/core/widgets/app_shell.dart';
import 'package:hostel_management/app/theme/app_colors.dart';
import 'package:hostel_management/features/reports/presentation/screens/expense_report_screen.dart';
import 'package:hostel_management/features/reports/presentation/screens/net_position_report_screen.dart';


import 'fee_collection_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          const _ReportCategories(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Review fee collection, expenses and financial position',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ReportCategories extends StatelessWidget {
  const _ReportCategories();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: [
        _ReportCategoryCard(
          title: 'Fee Collection Report',
          description:
              'Expected, collected and outstanding student fees',
          icon: Icons.payments_outlined,
          onTap: () {
            Get.find<AppShellController>().pushPage(
              const FeeCollectionReportScreen(),
            );
          },
        ),
        _ReportCategoryCard(
          title: 'Expense Report',
          description:
              'Monthly expenses by cash and account',
          icon: Icons.receipt_long_outlined,
          onTap: () {
            Get.find<AppShellController>().pushPage(
              const ExpenseReportScreen(),
            );
          },
        ),
        _ReportCategoryCard(
          title: 'Financial Summary',
          description:
              'Monthly income, expenses and net position',
          icon: Icons.account_balance_wallet_outlined,
          onTap: () {
            Get.find<AppShellController>().pushPage(
              const NetPositionReportScreen(),
            );
          },
        ),
      ],
    );
  }
}

class _ReportCategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ReportCategoryCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 21,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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