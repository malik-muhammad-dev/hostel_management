import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PaymentActions extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  // True while a save is actually in flight (FeeController.
  // isSubmittingPayment). Both buttons are disabled and the submit
  // button shows a spinner instead of its icon+label — the same pattern
  // already used for Save on the Add/Edit Student form and the "Correct
  // Amount" dialog. Without this, nothing stopped the button from being
  // tapped a second time while the first tap's request was still on its
  // way to (or back from) the server, which is exactly how a student's
  // month ended up double-charged.
  final bool isSubmitting;

  const PaymentActions({
    super.key,
    this.onCancel,
    this.onSubmit,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: isSubmitting ? null : onCancel,
          child: const Text('Cancel'),
        ),

        const SizedBox(width: 12),

        ElevatedButton.icon(
          onPressed: isSubmitting ? null : onSubmit,
          icon: isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: Text(isSubmitting ? 'Saving...' : 'Record Payment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
