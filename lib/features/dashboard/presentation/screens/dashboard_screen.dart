import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../balance/models/balance_addition_model.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_greeting_banner.dart';
import '../widgets/dashboard_skeleton.dart';
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

  // ---------------------------------------------------------------------------
  // "Add to Total Balance" — always adds a brand-new entry on top of
  // whatever Cash Box / Account Box / Total Amount already show; never
  // edits or replaces Opening Balance or any past addition. See
  // DashboardController.addToTotalBalance / balance_addition_model.dart
  // for the full reasoning.
  // ---------------------------------------------------------------------------

  Future<void> _showAddToTotalBalanceDialog(
    BuildContext context,
    DashboardController controller,
  ) async {
    final textController = TextEditingController();
    final errorText = ''.obs;
    final selectedBox = Rxn<BalanceAdditionBox>();

    final result = await showDialog<_BalanceAdditionInput>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add to Total Balance'),
          content: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(),
                  decoration: InputDecoration(
                    prefixText: 'Rs. ',
                    hintText: 'e.g. 2000',
                    errorText:
                        errorText.value.isEmpty ? null : errorText.value,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add to:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<BalanceAdditionBox>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Cash'),
                        value: BalanceAdditionBox.cash,
                        groupValue: selectedBox.value,
                        onChanged: (value) => selectedBox.value = value,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<BalanceAdditionBox>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Account'),
                        value: BalanceAdditionBox.account,
                        groupValue: selectedBox.value,
                        onChanged: (value) => selectedBox.value = value,
                      ),
                    ),
                  ],
                ),
              ],
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

                if (cleaned.isEmpty || value == null || value <= 0) {
                  errorText.value = 'Enter a valid amount';
                  return;
                }

                if (selectedBox.value == null) {
                  errorText.value = 'Select Cash or Account';
                  return;
                }

                Navigator.of(context).pop(
                  _BalanceAdditionInput(
                    amount: value,
                    box: selectedBox.value!,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final success = await controller.addToTotalBalance(
        amount: result.amount,
        box: result.box,
      );

      // Without this, a failed save (network drop, etc.) would close the
      // dialog looking exactly like a successful one — Cash/Account/
      // Total Amount just silently wouldn't have actually moved.
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't add to Total Balance — check your connection and try again.",
            ),
          ),
        );
      }
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
          // Everything below is skeleton-loaded on the very first fetch —
          // see DashboardController.isInitialLoading for exactly when
          // that is (and, just as importantly, when it stops being true
          // for good).
          // -----------------------------------------------------------------
          Obx(() {
            if (controller.isInitialLoading) {
              return const DashboardSkeleton();
            }

            return _DashboardContent(
              controller: controller,
              formatAmount: _formatAmount,
              formatNumber: _formatNumber,
              onAddToTotalBalance: () =>
                  _showAddToTotalBalanceDialog(context, controller),
            );
          }),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardController controller;
  final String Function(double) formatAmount;
  final String Function(double) formatNumber;
  final VoidCallback onAddToTotalBalance;

  const _DashboardContent({
    required this.controller,
    required this.formatAmount,
    required this.formatNumber,
    required this.onAddToTotalBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            final cash = controller.cashBox;
            final account = controller.accountBox;

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
                    '${formatNumber(collected)} / ${formatNumber(expected)}',
                subtitle: 'Collected / Expected this month',
                icon: Icons.payments_rounded,
                accentColor: AppColors.success,
              ),
              DashboardStatCard(
                title: 'Expenses',
                value: formatAmount(expensesThisMonth),
                subtitle: 'This month',
                icon: Icons.receipt_long_rounded,
                accentColor: AppColors.accentGold,
              ),
              DashboardStatCard(
                title: 'Net Profit',
                // Not .abs() — a losing month is genuinely negative, and
                // the icon/subtitle/color already flag "Running at a
                // loss," but the number itself used to print identically
                // to a same-size PROFIT month (e.g. "Rs. 15,000" either
                // way). _formatNumber's toStringAsFixed(0) + comma regex
                // handles a leading "-" correctly on its own.
                value: formatAmount(profit),
                subtitle: isProfitable ? 'In profit' : 'Running at a loss',
                icon: isProfitable
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                accentColor:
                    isProfitable ? AppColors.primary : AppColors.error,
              ),
              DashboardStatCard(
                title: 'Total Amount',
                value: formatAmount(totalAmount),
                subtitle:
                    'Opening balance + collected − expenses + Student Cash (Account) + Added Balance',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: const Color(0xFF7C5CBF),
                onEdit: onAddToTotalBalance,
              ),
              DashboardStatCard(
                title: 'Total Cash',
                value: formatAmount(cash),
                subtitle: 'All-time, Fees + Student Cash − Cash expenses',
                icon: Icons.payments_outlined,
                accentColor: const Color(0xFF0E8A8A),
              ),
              DashboardStatCard(
                title: 'Total Account',
                value: formatAmount(account),
                subtitle: 'All-time, Fees + Student Cash − Account expenses',
                icon: Icons.account_balance_outlined,
                accentColor: const Color(0xFF0E8A8A),
              ),
            ];

            // A Wrap, not manually-indexed Rows — this card count has
            // changed three times now (4 → 5 → 6 → 7) as features were
            // added, and each time meant hand-editing row groupings and
            // risking an off-by-one. A Wrap lays out any number of cards
            // correctly on its own: 2 per row narrow, 3 per row wide,
            // same visual result as before.
            return LayoutBuilder(
              builder: (context, constraints) {
                // Tightened from 16 — smaller gaps between the now-
                // smaller cards, and a 4th column on a wide desktop
                // window so all 7 cards fit in 2 rows instead of 3,
                // both in service of the same "no scrolling" request.
                const spacing = 12.0;
                final columns = constraints.maxWidth < 900
                    ? 2
                    : constraints.maxWidth < 1300
                        ? 3
                        : 4;
                final cardWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final card in cards)
                      SizedBox(width: cardWidth, child: card),
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
    );
  }
}

// Just carries the two picks back out of showDialog in one round trip —
// no meaning outside this file.
class _BalanceAdditionInput {
  final double amount;
  final BalanceAdditionBox box;

  const _BalanceAdditionInput({required this.amount, required this.box});
}