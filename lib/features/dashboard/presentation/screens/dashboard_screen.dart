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
    return 'Rs. ${_formatNumber(amount)}';
  }

  String _formatNumber(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  Future<void> _showEditOpeningBalanceDialog(
    BuildContext context,
    DashboardController controller,
  ) async {
    final textController = TextEditingController(
      text: controller.openingBalance == 0
          ? ''
          : controller.openingBalance.toStringAsFixed(0),
    );

    final errorText = ''.obs;

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Opening Balance'),
          content: Obx(
            () => TextField(
              controller: textController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(),
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                hintText: 'e.g. 20000',
                errorText: errorText.value.isEmpty ? null : errorText.value,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Strip anything that isn't a digit or a decimal point
                // (commas, spaces, "Rs.") before parsing — typing the
                // number WITH commas (e.g. "20,000", which people
                // naturally do) used to silently fail and save 0
                // instead of the intended amount.
                final cleaned = textController.text
                    .replaceAll(RegExp(r'[^0-9.]'), '')
                    .trim();

                final value = double.tryParse(cleaned);

                if (cleaned.isEmpty || value == null) {
                  errorText.value = 'Enter a valid number';
                  return;
                }

                Navigator.of(context).pop(value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await controller.setOpeningBalance(result);
    }
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
            // Every value the cards below need is read here — at the top
            // level of Obx's own builder — never inside the nested
            // LayoutBuilder further down. Obx only tracks reactive reads
            // made synchronously within its own builder call; a value
            // read inside a nested builder (LayoutBuilder, Builder, etc.)
            // runs too late for Obx to register it as a dependency, so
            // the screen silently stops updating for that one value
            // after the first render — exactly what caused both the
            // Opening Balance edit and the Expenses figure to go stale.
            final profit = controller.netProfitThisMonth;
            final isProfitable = profit >= 0;

            final totalWhoOwe = controller.totalStudentsWhoOwe;
            final paid = controller.studentsPaidThisMonth;

            final collected = controller.collectedThisMonth;
            final expected = controller.expectedThisMonth;

            final totalActiveStudents = controller.totalActiveStudents;
            final expensesThisMonth = controller.expensesThisMonth;
            final totalAmount = controller.totalAmount;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 900;

                final cards = [
                  DashboardStatCard(
                    title: 'Active Students',
                    value: '$totalActiveStudents',
                    subtitle: totalWhoOwe == 0
                        ? 'Currently enrolled'
                        : '$paid/$totalWhoOwe paid this month',
                    icon: Icons.people_alt_rounded,
                    accentColor: const Color(0xFF3B7DC4),
                  ),
                  DashboardStatCard(
                    title: 'Collected',
                    value:
                        '${_formatNumber(collected)} / ${_formatNumber(expected)}',
                    subtitle: 'Collected / Expected this month',
                    icon: Icons.payments_rounded,
                    accentColor: AppColors.success,
                  ),
                  DashboardStatCard(
                    title: 'Expenses',
                    value: _formatAmount(expensesThisMonth),
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
                  DashboardStatCard(
                    title: 'Total Amount',
                    value: _formatAmount(totalAmount),
                    subtitle:
                        'Opening balance + collected − expenses (all-time)',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: const Color(0xFF7C5CBF),
                    onEdit: () =>
                        _showEditOpeningBalanceDialog(context, controller),
                  ),
                ];

                if (isNarrow) {
                  // Narrow window — 2 per row, same wrapping style the
                  // old 4-card layout already used, just one extra row
                  // for the 5th card.
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: cards[4]),
                          const SizedBox(width: 16),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                  );
                }

                // Wide window — 3-and-2 across two rows. A single row of
                // all 5 (as the old 4-card layout did on wide screens)
                // gets too cramped to read comfortably.
                return Column(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i != 0) const SizedBox(width: 16),
                          Expanded(child: cards[i]),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: cards[3]),
                        const SizedBox(width: 16),
                        Expanded(child: cards[4]),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
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