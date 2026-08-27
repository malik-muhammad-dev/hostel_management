import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/fee_payment_model.dart';

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentMethod?> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    // Fee Collector role can only ever record cash payments — every
    // other method (bank transfer, online, cheque) is hidden entirely
    // rather than just disabled, so there's nothing to accidentally pick.
    final items = authController.isFeeCollector
        ? const [
            DropdownMenuItem(
              value: PaymentMethod.cash,
              child: Text('Cash'),
            ),
          ]
        : const [
            DropdownMenuItem(value: PaymentMethod.cash, child: Text('Cash')),
            DropdownMenuItem(
              value: PaymentMethod.bankTransfer,
              child: Text('Bank Transfer'),
            ),
            DropdownMenuItem(
              value: PaymentMethod.onlinePayment,
              child: Text('Online Payment'),
            ),
            DropdownMenuItem(
              value: PaymentMethod.cheque,
              child: Text('Cheque'),
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 7),

        DropdownButtonFormField<PaymentMethod>(
          initialValue: selectedMethod,
          decoration: InputDecoration(
            hintText: 'Select payment method',
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}