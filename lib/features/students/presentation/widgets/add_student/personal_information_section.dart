import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/student_form_controller.dart';
import 'form_feild.dart';
import 'form_section.dart';
import 'student_photo_picker.dart';

class PersonalInformationSection extends StatelessWidget {
  final StudentFormController controller;

  const PersonalInformationSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Personal Information',
      subtitle: 'Basic information and contact details',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudentPhotoPicker(
  controller: controller,
),

              const SizedBox(width: 28),

              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FormFieldWidget(
                            controller: controller.nameController,
                            label: 'Full Name',
                            hint: 'Enter student name',
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: FormFieldWidget(
                            controller: controller.studentIdController,
                            label: 'Student ID',
                            hint: 'e.g. BSN-001',
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
                            controller: controller.cnicController,
                            label: 'CNIC',
                            hint: 'XXXXX-XXXXXXX-X',
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: FormFieldWidget(
                            controller: controller.phoneController,
                            label: 'Phone Number',
                            hint: '03XX-XXXXXXX',
                            required: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: FormFieldWidget(
                  controller: controller.emailController,
                  label: 'Email',
                  hint: 'student@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: FormFieldWidget(
                  controller: controller.dateOfBirthController,
                  label: 'Date of Birth',
                  hint: 'Select date',
                  suffixIcon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () =>
                      _selectDate(context, controller.dateOfBirthController),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Obx(
                  () => FormDropdownWidget(
                    label: 'Gender',
                    hint: 'Select gender',
                    value: controller.gender.value,
                    options: const ['Male', 'Female'],
                    onChanged: (value) {
                      controller.gender.value = value;
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          FormFieldWidget(
            controller: controller.addressController,
            label: 'Address',
            hint: 'Enter complete residential address',
            maxLines: 3,
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
      firstDate: DateTime(1900),
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
