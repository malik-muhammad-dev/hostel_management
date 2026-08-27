import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../controllers/student_form_controller.dart';
import 'form_feild.dart';
import 'form_section.dart';

class PackageInformationSection extends StatelessWidget {
  final StudentFormController controller;

  const PackageInformationSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Fee Information',
      subtitle: 'Configure the student\'s monthly hostel fee',
      icon: Icons.payments_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The monthly fee is used when recording student payments.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: FormFieldWidget(
                  controller: controller.packageStartDateController,
                  label: 'Package Start Date',
                  hint: 'Select date',
                  suffixIcon: Icons.calendar_today_outlined,
                  required: true,
                  readOnly: true,
                  onTap: () => _selectDate(
                    context,
                    controller.packageStartDateController,
                  ),
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: FormFieldWidget(
                  controller: controller.monthlyFeeController,
                  label: 'Monthly Fee',
                  hint: '13000',
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: FormFieldWidget(
                  controller: controller.netMonthlyFeeController,
                  label: 'Net Monthly Fee',
                  hint: '13000',
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Monthly Fee is the standard fee for this student. '
                    'Net Monthly Fee is the actual monthly amount used '
                    'for fee calculation and may be adjusted by an admin.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    controller.text = _formatDate(selectedDate);
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
