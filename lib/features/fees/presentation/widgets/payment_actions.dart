import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PaymentActions extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  const PaymentActions({super.key, this.onCancel, this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),

        const SizedBox(width: 12),

        ElevatedButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Record Payment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
