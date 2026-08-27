import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class FeeTableHeader extends StatelessWidget {
  const FeeTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      color: AppColors.background,
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Student', style: feeHeaderStyle)),
          Expanded(flex: 2, child: Text('Student ID', style: feeHeaderStyle)),
          Expanded(flex: 2, child: Text('Monthly Fee', style: feeHeaderStyle)),
          Expanded(flex: 2, child: Text('Paid', style: feeHeaderStyle)),
          Expanded(flex: 2, child: Text('Balance', style: feeHeaderStyle)),
          SizedBox(width: 90, child: Text('Status', style: feeHeaderStyle)),
        ],
      ),
    );
  }
}

const feeHeaderStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);
