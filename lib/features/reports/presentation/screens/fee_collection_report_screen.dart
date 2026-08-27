import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hostel_management/core/widgets/month_picker_feild.dart' show MonthPickerField;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_shell.dart';
import '../controllers/fee_collection_report_controller.dart';
import '../widgets/fee_collection_summary.dart';
import '../widgets/fee_collection_table.dart';

class FeeCollectionReportScreen
    extends StatelessWidget {
  const FeeCollectionReportScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.find<FeeCollectionReportController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
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
                () => FeeCollectionSummary(
                  expected:
                      controller.totalExpected,
                  collected:
                      controller.totalCollected,
                  outstanding:
                      controller.totalOutstanding,
                  collectionRate:
                      controller.collectionRate,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => FeeCollectionTable(
                  students:
                      controller.students,
                  summaries:
                      controller.studentSummaries,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                'Fee Collection Report',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Expected, collected and outstanding fees',
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