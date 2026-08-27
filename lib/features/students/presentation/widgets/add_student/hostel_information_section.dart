import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/student_form_controller.dart';
import 'form_feild.dart';
import 'form_section.dart';

class HostelInformationSection extends StatelessWidget {
  final StudentFormController controller;

  const HostelInformationSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Hostel Information',
      subtitle: 'Room allocation and stay details',
      icon: Icons.home_work_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FormFieldWidget(
                  controller: controller.hostelBlockController,
                  label: 'Hostel / Block',
                  hint: 'Enter hostel or block',
                  required: true,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: FormFieldWidget(
                  controller: controller.roomNumberController,
                  label: 'Room Number',
                  hint: 'Enter room',
                  required: true,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: FormFieldWidget(
                  controller: controller.bedNumberController,
                  label: 'Bed Number',
                  hint: 'Enter bed',
                  required: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: FormFieldWidget(
                  controller: controller.floorController,
                  label: 'Floor',
                  hint: 'Enter floor',
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: FormFieldWidget(
                  controller: controller.checkInDateController,
                  label: 'Check-in Date',
                  hint: 'Select date',
                  suffixIcon: Icons.calendar_today_outlined,
                  required: true,
                  readOnly: true,
                  onTap: () =>
                      _selectDate(context, controller.checkInDateController),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: FormFieldWidget(
                  controller: controller.expectedCheckOutController,
                  label: 'Expected Check-out',
                  hint: 'Select date',
                  suffixIcon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () => _selectDate(
                    context,
                    controller.expectedCheckOutController,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Obx(
                  () => FormDropdownWidget(
                    label: 'Hostel Status',
                    hint: 'Select status',
                    required: true,
                    value: controller.hostelStatus.value,
                    options: const ['Active', 'Inactive'],
                    onChanged: (value) {
                      controller.hostelStatus.value = value;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 18),
              const Expanded(flex: 2, child: SizedBox()),
            ],
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