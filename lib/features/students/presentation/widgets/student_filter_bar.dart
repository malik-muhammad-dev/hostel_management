import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/student_model.dart';
import '../controllers/student_controller.dart';

class StudentFilterBar extends StatelessWidget {
  const StudentFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentController>();

    return Obx(
      () => Row(
        children: [
          _FilterDropdown(
            label: 'Department',
            value: controller.selectedDepartment.value,
            items: const ['All Departments', ...kStudentDepartments],
            onChanged: controller.setDepartment,
          ),

          const SizedBox(width: 12),

          _FilterDropdown(
            label: 'Program',
            value: controller.selectedProgram.value,
            items: const ['All Programs', ...kStudentPrograms],
            onChanged: controller.setProgram,
          ),

          const SizedBox(width: 12),

          _FilterDropdown(
            label: 'Semester',
            value: controller.selectedSemester.value,
            items: const ['All Semesters', ...kStudentSemesters],
            onChanged: controller.setSemester,
          ),

          const SizedBox(width: 12),

          _FilterDropdown(
            label: 'Status',
            value: controller.selectedStatus.value,
            items: const ['All Status', 'Active', 'Inactive', 'Archived'],
            onChanged: controller.setStatus,
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary,
        ),
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        items: items
            .map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }
}