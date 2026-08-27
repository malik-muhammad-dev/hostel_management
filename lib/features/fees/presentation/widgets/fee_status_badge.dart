import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class FeeStatusBadge extends StatelessWidget {
  final String status;
  final bool isPaid;
  final bool isOverdue;

  const FeeStatusBadge({
    super.key,
    required this.status,
    required this.isPaid,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isPaid ? AppColors.primaryLight : AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPaid
              ? AppColors.primary
              : isOverdue
              ? Colors.red
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}
