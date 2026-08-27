import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class FeeSummaryLine extends StatelessWidget {
  final String label;
  final String amount;
  final bool emphasized;

  const FeeSummaryLine({
    super.key,
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasized ? 14 : 13,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: emphasized ? 15 : 13,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
