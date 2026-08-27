import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hostel_management/features/expenses/presentation/widgets/expense_month_selector.dart' show ExpenseMonthSelector;

import '../controllers/expense_controller.dart';
import '../widgets/expense_page_header.dart';
import '../widgets/expense_records_table.dart';
import '../widgets/expense_summary.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExpensePageHeader(),
          const SizedBox(height: 24),
          ExpenseMonthSelector(controller: controller),
          const SizedBox(height: 24),
          ExpenseSummary(
            controller: controller,
          ),
          const SizedBox(height: 24),
          ExpenseRecordsTable(
            controller: controller,
          ),
        ],
      ),
    );
  }
}