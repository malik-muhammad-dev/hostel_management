import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/fee_controller.dart';
import 'payment_feild.dart';

class PaymentAmountSection extends StatelessWidget {
  const PaymentAmountSection({super.key});

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
            'Payment Amount',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Enter the amount received from the student',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: PaymentField(
                  label: 'Amount Received',
                  hint: 'Enter amount',
                  controller: controller.amountReceivedController,
                  keyboardType: TextInputType.number,
                ),
              ),

              const SizedBox(width: 18),

              // Optional — entirely at the admin's discretion. Left blank,
              // it parses to 0 and the Total Due / Remaining Balance are
              // unaffected.
              Expanded(
                child: PaymentField(
                  label: 'Discount (optional)',
                  hint: 'e.g. 2000',
                  controller: controller.discountController,
                  keyboardType: TextInputType.number,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Obx(
                  () => PaymentField(
                    label: 'Remaining Balance',
                    hint: _formatAmount(controller.paymentRemainingBalance),
                    enabled: false,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');

    return 'Rs. $formatted';
  }
}