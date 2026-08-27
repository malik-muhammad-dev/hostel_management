import 'package:flutter/material.dart';
import 'package:hostel_management/features/expenses/presentation/widgets/expense_category_feild.dart';
import 'package:hostel_management/features/expenses/presentation/widgets/expense_date_feild.dart' show ExpenseDateField;

import '../../../../app/theme/app_colors.dart';
import '../controllers/expense_controller.dart';
import 'expense_form_actions.dart';
import 'expense_payment_method.dart';

class ExpenseForm extends StatelessWidget {
  final ExpenseController controller;

  const ExpenseForm({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ExpenseFormHeader(),

          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ExpenseDateField(
                  controller: controller.dateController,
                  onDateSelected: controller.setDate,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _AmountField(
                  controller: controller.amountController,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _DescriptionField(
            controller: controller.descriptionController,
          ),

          const SizedBox(height: 18),

          ExpenseCategoryField(controller: controller),

          const SizedBox(height: 18),

          ExpensePaymentMethod(
            controller: controller,
          ),

          const SizedBox(height: 28),

          const Divider(
            height: 1,
            color: AppColors.border,
          ),

          const SizedBox(height: 20),

          ExpenseFormActions(
            controller: controller,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// FORM HEADER
// =============================================================================

class _ExpenseFormHeader extends StatelessWidget {
  const _ExpenseFormHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _HeaderIcon(),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Expense Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Enter the basic information for this expense',
                style: TextStyle(
                  fontSize: 11,
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

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Icon(
        Icons.receipt_long_outlined,
        size: 20,
        color: AppColors.primary,
      ),
    );
  }
}

// =============================================================================
// AMOUNT FIELD
// =============================================================================

class _AmountField extends StatelessWidget {
  final TextEditingController controller;

  const _AmountField({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _ExpenseTextField(
      controller: controller,
      label: 'Total Amount',
      hint: 'Enter total amount',
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      prefixText: 'Rs. ',
    );
  }
}

// =============================================================================
// DESCRIPTION FIELD
// =============================================================================

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const _DescriptionField({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _ExpenseTextField(
      controller: controller,
      label: 'Description',
      hint: 'Enter expense description',
      maxLines: 3,
    );
  }
}

// =============================================================================
// SHARED TEXT FIELD
// =============================================================================

class _ExpenseTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? prefixText;

  const _ExpenseTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            filled: true,
            fillColor: AppColors.background,
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}