import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_greeting_banner.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/expense_breakdown.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/revenue_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return 'Rs. $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -----------------------------------------------------------------
          // Greeting banner — time-based greeting + collection-rate gauge
          // -----------------------------------------------------------------
          DashboardGreetingBanner(controller: controller),

          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // Stat cards
          // -----------------------------------------------------------------
          Obx(() {
            final profit = controller.netProfitThisMonth;
            final isProfitable = profit >= 0;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 900;

                final cards = [
                  DashboardStatCard(
                    title: 'Active Students',
                    value: '${controller.totalActiveStudents}',
                    subtitle: 'Currently enrolled',
                    icon: Icons.people_alt_rounded,
                    accentColor: const Color(0xFF3B7DC4),
                  ),
                  DashboardStatCard(
                    title: 'Collected',
                    value: _formatAmount(controller.collectedThisMonth),
                    subtitle: 'This month',
                    icon: Icons.payments_rounded,
                    accentColor: AppColors.success,
                  ),
                  DashboardStatCard(
                    title: 'Expenses',
                    value: _formatAmount(controller.expensesThisMonth),
                    subtitle: 'This month',
                    icon: Icons.receipt_long_rounded,
                    accentColor: AppColors.accentGold,
                  ),
                  DashboardStatCard(
                    title: 'Net Profit',
                    value: _formatAmount(profit.abs()),
                    subtitle: isProfitable ? 'In profit' : 'Running at a loss',
                    icon: isProfitable
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    accentColor:
                        isProfitable ? AppColors.primary : AppColors.error,
                  ),
                ];

                if (isNarrow) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[1]),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: cards[2]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[3]),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i != 0) const SizedBox(width: 16),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              },
            );
          }),

          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // Trend chart + Expense breakdown
          // -----------------------------------------------------------------
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;

              if (isNarrow) {
                return Column(
                  children: [
                    RevenueChart(controller: controller),
                    const SizedBox(height: 24),
                    ExpenseBreakdown(controller: controller),
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: RevenueChart(controller: controller),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: ExpenseBreakdown(controller: controller),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // Recent activity
          // -----------------------------------------------------------------
          RecentTransactions(controller: controller),
        ],
      ),
    );
  }
}