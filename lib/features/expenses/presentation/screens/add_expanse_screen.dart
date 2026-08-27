import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/expense_controller.dart';
import '../widgets/expense_form.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ExpenseForm(
        controller: controller,
      ),
    );
  }
}