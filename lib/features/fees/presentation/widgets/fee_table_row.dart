import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'fee_status_badge.dart';

class FeeTableRow extends StatelessWidget {
  final String name;
  final String studentId;
  final String monthlyFee;
  final String paid;
  final String balance;
  final String status;

  const FeeTableRow({
    super.key,
    required this.name,
    required this.studentId,
    required this.monthlyFee,
    required this.paid,
    required this.balance,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'Paid';
    final isOverdue = status == 'Overdue';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
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
              studentId,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              monthlyFee,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              paid,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              balance,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPaid ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),

          SizedBox(
            width: 90,
            child: FeeStatusBadge(
              status: status,
              isPaid: isPaid,
              isOverdue: isOverdue,
            ),
          ),
        ],
      ),
    );
  }
}
