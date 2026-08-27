import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/fee_controller.dart';

class PaymentDateSection extends StatelessWidget {
  const PaymentDateSection({super.key});

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
            'Payment Date',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Select the date on which the payment was received',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 20),

          Obx(
            () => InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _selectPaymentDate(context, controller),
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: 'Select payment date',
                  filled: true,
                  fillColor: AppColors.background,
                  suffixIcon: const Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                  ),
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
                child: Text(
                  controller.paymentDate.value.isEmpty
                      ? 'Select payment date'
                      : controller.paymentDate.value,
                  style: TextStyle(
                    fontSize: 13,
                    color: controller.paymentDate.value.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPaymentDate(
    BuildContext context,
    FeeController controller,
  ) async {
    final now = DateTime.now();

    DateTime initialDate = now;

    if (controller.paymentDate.value.isNotEmpty) {
      final parsedDate = DateTime.tryParse(controller.paymentDate.value);

      if (parsedDate != null) {
        initialDate = parsedDate;
      }
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    final formattedDate =
        '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';

    controller.setPaymentDate(formattedDate);
  }
}
