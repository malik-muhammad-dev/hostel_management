import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hostel_management/core/widgets/month_picker_feild.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../widgets/expense_report_summary.dart';
import '../widgets/expense_report_table.dart';

class ExpenseReportScreen extends StatelessWidget {
  const ExpenseReportScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.find<ExpenseController>();

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
                () => ExpenseReportSummary(
                  total: controller.totalForMonth(
                    controller.selectedMonth.value,
                  ),
                  cash: controller.cashForMonth(
                    controller.selectedMonth.value,
                  ),
                  account: controller.accountForMonth(
                    controller.selectedMonth.value,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => ExpenseReportTable(
                  expenses: controller.expensesForMonth(
                    controller.selectedMonth.value,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                'Expense Report',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Monthly expense summary and records',
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