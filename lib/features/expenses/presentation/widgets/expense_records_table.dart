import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../models/expense_model.dart';
import '../controllers/expense_controller.dart';
import 'expense_voucher_dialog.dart';

class ExpenseRecordsTable extends StatelessWidget {
  final ExpenseController controller;

  const ExpenseRecordsTable({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(
            height: 1,
            color: AppColors.border,
          ),
          const _TableHeader(),
          Obx(
            () => _buildRows(controller.selectedMonth.value),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense Records',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'View recorded hostel expenses',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // OutlinedButton.icon(
          //   onPressed: () {},
          //   icon: const Icon(
          //     Icons.filter_list_rounded,
          //     size: 17,
          //   ),
          //   label: const Text('Filter'),
          // ),
          // const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () {
              Get.find<AppShellController>()
                  .openAddExpense();
            },
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
            ),
            label: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildRows(String month) {
    final monthExpenses = controller.expensesForMonth(month);

    if (monthExpenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 40,
        ),
        child: Center(
          child: Text(
            'No expenses recorded for this month.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: monthExpenses
          .map(
            (expense) => _ExpenseRow(
              expense: expense,
              onDelete: () => _deleteExpense(
                expense.id,
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _deleteExpense(int? expenseId) async {
    if (expenseId == null) {
      return;
    }

    await controller.deleteExpense(expenseId);
  }
}

// =============================================================================
// TABLE HEADER
// =============================================================================

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 13,
      ),
      color: AppColors.background,
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Date',
              style: _expenseHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Category',
              style: _expenseHeaderStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Description',
              style: _expenseHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Amount',
              style: _expenseHeaderStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Payment Method',
              style: _expenseHeaderStyle,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              'Action',
              style: _expenseHeaderStyle,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EXPENSE ROW
// =============================================================================

class _ExpenseRow extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onDelete;

  const _ExpenseRow({
    required this.expense,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(expense.date),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              expense.category,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              expense.description ?? '-',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(expense.amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _PaymentBadge(
              paymentMode: expense.paymentMode,
            ),
          ),
          SizedBox(
            width: 70,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete();
                } else if (value == 'voucher') {
                  showExpenseVoucherDialog(context, expense: expense);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'voucher',
                  child: Text('View Voucher'),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              child: const Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} '
        '${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );

    return 'Rs. $formatted';
  }
}

// =============================================================================
// PAYMENT BADGE
// =============================================================================

class _PaymentBadge extends StatelessWidget {
  final ExpensePaymentMode paymentMode;

  const _PaymentBadge({
    required this.paymentMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        paymentMode.label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

const _expenseHeaderStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);