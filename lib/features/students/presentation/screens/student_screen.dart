import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hostel_management/core/widgets/app_shell.dart';

import '../../../../app/theme/app_colors.dart';
import '../widgets/student_filter_bar.dart';
import '../widgets/student_search_bar.dart';
import '../widgets/student_table.dart';

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 28),

          const StudentSearchBar(),

          const SizedBox(height: 16),

          const StudentFilterBar(),

          const SizedBox(height: 24),

          const StudentTable(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Students',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Manage and view all hostel students',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        ElevatedButton.icon(
          onPressed: () {
            Get.find<AppShellController>().openAddStudent();
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Student'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}