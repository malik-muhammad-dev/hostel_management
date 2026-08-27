import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/student_model.dart';
import '../../controllers/student_form_controller.dart';
import 'form_feild.dart';
import 'form_section.dart';

class AcademicInformationSection extends StatelessWidget {
  final StudentFormController controller;

  const AcademicInformationSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Academic Information',
      subtitle: 'Program and academic details',
      icon: Icons.school_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => FormDropdownWidget(
                    label: 'Department',
                    hint: 'Select department',
                    required: true,
                    value: controller.department.value,
                    options: kStudentDepartments,
                    onChanged: (value) {
                      controller.department.value = value;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Obx(
                  () => FormDropdownWidget(
                    label: 'Program',
                    hint: 'Select program',
                    required: true,
                    value: controller.program.value,
                    options: kStudentPrograms,
                    onChanged: (value) {
                      controller.program.value = value;
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: FormFieldWidget(
                  controller: controller.sessionController,
                  label: 'Session / Batch',
                  hint: 'e.g. 2025–2029',
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Obx(
                  () => FormDropdownWidget(
                    label: 'Semester / Year',
                    hint: 'Select semester',
                    value: controller.semester.value,
                    options: kStudentSemesters,
                    onChanged: (value) {
                      controller.semester.value = value;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: FormFieldWidget(
                  controller: controller.admissionDateController,
                  label: 'Admission Date',
                  hint: 'Select date',
                  suffixIcon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () =>
                      _selectDate(context, controller.admissionDateController),
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
                    label: 'Student Status',
                    hint: 'Select status',
                    required: true,
                    value: controller.studentStatus.value,
                    options: const ['Active', 'Inactive'],
                    onChanged: (value) {
                      controller.studentStatus.value = value;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 18),
              const Expanded(child: SizedBox()),
              const SizedBox(width: 18),
              const Expanded(child: SizedBox()),
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