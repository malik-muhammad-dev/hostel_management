import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/app_shell.dart';
import '../controllers/expense_controller.dart';
import 'expense_voucher_dialog.dart';

class ExpenseFormActions extends StatelessWidget {
  final ExpenseController controller;

  const ExpenseFormActions({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: controller.isSaving.value
                ? null
                : () {
                    controller.clearForm();
                    Get.find<AppShellController>().popPage();
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: controller.isSaving.value
                ? null
                : () => _save(context),
            icon: controller.isSaving.value
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.save_outlined,
                    size: 18,
                  ),
            label: Text(
              controller.isEditMode
                  ? 'Update Expense'
                  : 'Save Expense',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final validationMessage = controller.validate();

    if (validationMessage != null) {
      _showMessage(
        context,
        validationMessage,
      );
      return;
    }

    if (controller.isEditMode) {
      final success = await controller.updateExpense();

      if (!context.mounted) {
        return;
      }

      if (!success) {
        _showMessage(context, 'Unable to update expense.');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense updated successfully.')),
      );

      Get.find<AppShellController>().popPage();
      return;
    }

    final createdExpense = await controller.addExpense();

    if (!context.mounted) {
      return;
    }

    if (createdExpense == null) {
      _showMessage(context, 'Unable to save expense.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense added successfully.')),
    );

    await showExpenseVoucherDialog(context, expense: createdExpense);

    if (context.mounted) {
      Get.find<AppShellController>().popPage();
    }
  }

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}