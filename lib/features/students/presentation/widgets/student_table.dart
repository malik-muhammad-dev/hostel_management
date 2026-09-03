import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hostel_management/core/widgets/app_shell.dart';
import 'package:hostel_management/features/students/presentation/controllers/student_controller.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_box.dart';
import 'student_table_row.dart';

// =============================================================================
// STUDENT TABLE
//
// Takes the controller directly (rather than a plain list) so pagination
// state (currentPage/totalPages) and the rendered rows always come from
// the same source and can never drift apart.
// =============================================================================

class StudentTable extends StatelessWidget {
  const StudentTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentController>();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Obx(() => _buildRows(controller)),
          Obx(() => _buildFooter(controller)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 55),
          Expanded(flex: 3, child: Text('Student', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Roll No.', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Program', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Contact', style: _headerStyle)),
          SizedBox(width: 90, child: Text('Status', style: _headerStyle)),
          SizedBox(width: 30),
        ],
      ),
    );
  }

  Widget _buildRows(StudentController controller) {
    final pageStudents = controller.paginatedStudents;

    // Shimmer only on the very first load (nothing fetched yet) — never
    // over a page that already has real students on it, even while a
    // quiet background refresh from real-time sync is running.
    if (controller.isLoading.value && pageStudents.isEmpty) {
      return const TableSkeleton(
        columnFlexes: [3, 2, 2, 2],
        trailingWidth: 90,
      );
    }

    if (pageStudents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Center(
          child: Text(
            'No students found.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: pageStudents
          .map(
            (student) => StudentTableRow(
              name: student.name,
              studentId: student.rollNumber ?? '-',
              program: student.program ?? '-',
              contact: student.phone ?? '-',
              isActive: student.status == 'Active',
              onTap: () {
                final appShellController = Get.find<AppShellController>();
                controller.selectStudent(student);
                appShellController.openStudentDetail();
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildFooter(StudentController controller) {
    final total = controller.filteredStudents.length;
    final totalPages = controller.totalPages;
    final page = controller.currentPage.value.clamp(1, totalPages);

    final rangeStart = total == 0 ? 0 : (page - 1) * StudentController.pageSize + 1;
    final rangeEnd = (page * StudentController.pageSize).clamp(0, total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Text(
            total == 0
                ? 'No students'
                : 'Showing $rangeStart–$rangeEnd of $total students',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          const Spacer(),

          IconButton(
            tooltip: 'Previous page',
            onPressed: page > 1 ? controller.previousPage : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),

          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$page',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Text(
            'of $totalPages',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          IconButton(
            tooltip: 'Next page',
            onPressed: page < totalPages ? controller.nextPage : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);