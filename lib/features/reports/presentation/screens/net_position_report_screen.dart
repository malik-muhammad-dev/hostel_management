import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hostel_management/core/widgets/month_picker_feild.dart';
import 'package:hostel_management/features/reports/presentation/controllers/report_controller.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_shell.dart';

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