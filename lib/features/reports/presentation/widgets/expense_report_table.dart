import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../expenses/models/expense_model.dart';

class ExpenseReportTable extends StatelessWidget {
  final List<ExpenseModel> expenses;

  const ExpenseReportTable({
    super.key,
    required this.expenses,
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
          _buildTableHeader(),
          _buildRows(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.centerLeft,
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
              'Expenses recorded for the selected month',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Date',
              style: _headerStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Description',
              style: _headerStyle,
            ),
          ),
          Expanded(
            child: Text(
              'Amount',
              style: _headerStyle,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'Payment',
              style: _headerStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRows() {
    if (expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No expenses found for this month.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: expenses.map(_buildRow).toList(),
    );
  }

  Widget _buildRow(ExpenseModel expense) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              _formatDate(expense.date),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              expense.description?.trim().isNotEmpty == true
                  ? expense.description!
                  : '-',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              _formatAmount(expense.amount),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              expense.paymentMode.label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatAmount(double amount) {
    return 'Rs. ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        )}';
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
}