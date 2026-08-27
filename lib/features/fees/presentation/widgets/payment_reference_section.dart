import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/fee_controller.dart';
import 'payment_feild.dart';

class PaymentReferenceSection extends StatelessWidget {
  const PaymentReferenceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FeeController>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Reference',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Add a reference or note related to this payment',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: PaymentField(
                  label: 'Payment Reference',
                  hint: 'e.g. Transaction ID',
                  controller: controller.paymentReferenceController,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: PaymentField(
                  label: 'Notes',
                  hint: 'Optional payment notes',
                  controller: controller.notesController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
