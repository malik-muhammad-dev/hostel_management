import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hostel_management/core/widgets/month_picker_feild.dart';
import 'package:hostel_management/features/reports/presentation/controllers/report_controller.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../dashboard/presentation/widgets/dashboard_stat_card.dart';

import '../widgets/net_position_summary.dart';

class NetPositionReportScreen extends StatelessWidget {
  const NetPositionReportScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.find<ReportsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Obx(
                () => MonthPickerField(
                  label: 'Report Month',
                  value:
                      controller.selectedMonth.value,
                  onChanged:
                      controller.setSelectedMonth,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => NetPositionSummary(
                  income:
                      controller.totalIncome,
                  expenses:
                      controller.totalExpenses,
                  netPosition:
                      controller.netPosition,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'All-Time',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Historical totals since the hostel started — these '
                'never reset, unlike the month above.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => _buildAllTimeCard(controller)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // "Total Collected (All-Time)" — this is the figure that used to be the
  // Dashboard's headline "Total Amount" card. It moved here because it's
  // a lifetime running total (only ever grows), not a "right now" figure —
  // see the long comment on ReportsController.lifetimeTotalAmount for the
  // full reasoning.
  // ---------------------------------------------------------------------------

  Widget _buildAllTimeCard(ReportsController controller) {
    final total = controller.lifetimeTotalAmount;
    final opening = controller.lifetimeOpeningBalance;
    final collected = controller.lifetimeCollected;
    final expenses = controller.lifetimeExpenses;
    final studentCashAccount = controller.lifetimeStudentCashAccount;
    final balanceAdded = controller.lifetimeBalanceAdded;

    final tooltip = 'How Rs. ${_formatNumber(total)} is worked out:\n'
        'Opening balance: Rs. ${_formatNumber(opening)}\n'
        '+ Collected (all-time): Rs. ${_formatNumber(collected)}\n'
        '− Expenses (all-time): Rs. ${_formatNumber(expenses)}\n'
        '+ Student Cash (Account): Rs. ${_formatNumber(studentCashAccount)}\n'
        '+ Added Balance: Rs. ${_formatNumber(balanceAdded)}\n\n'
        'This is every rupee the hostel has taken in since the '
        'beginning — not what\'s currently on hand. For that, see the '
        'Dashboard\'s Total Amount card (Cash + Account).';

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 700
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;

        return SizedBox(
          width: cardWidth,
          child: DashboardStatCard(
            title: 'Total Collected (All-Time)',
            value: 'Rs. ${_formatNumber(total)}',
            subtitle: 'Every rupee taken in since day one',
            icon: Icons.account_balance_wallet_rounded,
            accentColor: const Color(0xFF7C5CBF),
            infoTooltip: tooltip,
          ),
        );
      },
    );
  }

  String _formatNumber(double amount) {
    final sign = amount < 0 ? '-' : '';
    return '$sign${amount.abs().toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        )}';
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            Get.find<AppShellController>()
                .popPage();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Summary',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Monthly income, expenses and net position',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}