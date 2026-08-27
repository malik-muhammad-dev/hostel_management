import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/expense_controller.dart';
import '../../models/expense_model.dart';

class ExpensePaymentMethod extends StatelessWidget {
  final ExpenseController controller;

  const ExpensePaymentMethod({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _PaymentOption(
                  title: 'Cash',
                  icon: Icons.payments_outlined,
                  selected: controller.paymentMode.value ==
                      ExpensePaymentMode.cash,
                  onTap: () {
                    controller.setPaymentMode(
                      ExpensePaymentMode.cash,
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _PaymentOption(
                  title: 'Account',
                  icon: Icons.account_balance_outlined,
                  selected: controller.paymentMode.value ==
                      ExpensePaymentMode.account,
                  onTap: () {
                    controller.setPaymentMode(
                      ExpensePaymentMode.account,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryLight
              : AppColors.background,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 19,
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}