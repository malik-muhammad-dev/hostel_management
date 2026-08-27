import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hostel_management/core/widgets/app_shell.dart';
import 'package:hostel_management/features/students/presentation/controllers/student_controller.dart';
import 'package:hostel_management/features/students/presentation/screens/add_student_screen.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/student_model.dart';
import '../widgets/student_documents.dart';
import '../widgets/student_fee_payments.dart';
import '../widgets/student_history.dart';
import '../widgets/student_package_service.dart';

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  int selectedTab = 0;

  Widget _buildTabContent() {
    final studentController = Get.find<StudentController>();
    final student = studentController.selectedStudent.value;

    if (student == null) {
      return const SizedBox.shrink();
    }

    switch (selectedTab) {
      case 0:
        return const _OverviewSection();

      case 1:
        return StudentDocuments(studentId: student.id!);

      case 2:
        return StudentPackageServices(student: student);

      case 3:
  return StudentFeePayments(
    studentId: student.id!,
  );

      case 4:
    return StudentHistory(
      studentId: student.id!,
    );

      default:
        return const _OverviewSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentController = Get.find<StudentController>();
    final student = studentController.selectedStudent.value;

    if (student == null) {
      return const Center(
        child: Text(
          'No student selected.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------------
          // Back
          // -------------------------------------------------------------------
          GestureDetector(
            onTap: () {
              Get.find<AppShellController>().popPage();
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Students',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // -------------------------------------------------------------------
          // Profile Header
          // -------------------------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _buildStudentSubtitle(student),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _ActiveStatus(isActive: student.status == 'Active'),
                    ],
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: () {
                    Get.find<AppShellController>().pushPage(
                      AddStudentScreen(student: student),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded, size: 17),
                  label: const Text('Edit Student'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                OutlinedButton.icon(
                  onPressed: () => _confirmArchiveStudent(context, student),
                  icon: const Icon(
                    Icons.archive_outlined,
                    size: 17,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // Tabs
          // -------------------------------------------------------------------
          _ProfileTabs(
            selectedIndex: selectedTab,
            onTabChanged: (index) {
              setState(() {
                selectedTab = index;
              });
            },
          ),

          const SizedBox(height: 24),

          _buildTabContent(),
        ],
      ),
    );
  }

  String _buildStudentSubtitle(dynamic student) {
    final parts = <String>[];

    if (student.rollNumber != null && student.rollNumber!.trim().isNotEmpty) {
      parts.add(student.rollNumber!);
    }

    if (student.program != null && student.program!.trim().isNotEmpty) {
      parts.add(student.program!);
    }

    if (student.semester != null && student.semester!.trim().isNotEmpty) {
      parts.add(student.semester!);
    }

    return parts.isEmpty ? 'Student' : parts.join('  •  ');
  }

  // ---------------------------------------------------------------------------
  // Archive (soft delete) confirmation
  //
  // This never hard-deletes — it marks the student as 'Archived', which
  // hides them from the default list while keeping their fee/payment/
  // service history intact.
  // ---------------------------------------------------------------------------

  Future<void> _confirmArchiveStudent(
    BuildContext context,
    StudentModel student,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Student'),
          content: Text(
            'Are you sure you want to delete ${student.name}? '
            'Their fee, payment and service records will be kept, '
            'but they will no longer appear in the student list. '
            'This can only be undone by an administrator.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || student.id == null) return;

    final studentController = Get.find<StudentController>();
    final success = await studentController.archiveStudent(student.id!);

    if (!context.mounted) return;

    if (success) {
      Get.snackbar(
        'Student Deleted',
        '${student.name} has been removed from the active list.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.find<AppShellController>().popPage();
    } else {
      Get.snackbar(
        'Error',
        'Unable to delete ${student.name}. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

// =============================================================================
// Status
// =============================================================================

class _ActiveStatus extends StatelessWidget {
  final bool isActive;

  const _ActiveStatus({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          isActive ? 'Active Student' : 'Inactive Student',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Tabs
// =============================================================================

class _ProfileTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const _ProfileTabs({required this.selectedIndex, required this.onTabChanged});

  static const tabs = [
    (title: 'Overview', icon: Icons.person_outline_rounded),
    (title: 'Documents', icon: Icons.folder_outlined),
    (title: 'Package & Services', icon: Icons.inventory_2_outlined),
    (title: 'Fees & Payments', icon: Icons.payments_outlined),
    (title: 'History', icon: Icons.history_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(index),
              child: _ProfileTab(
                title: tab.title,
                icon: tab.icon,
                selected: selectedIndex == index,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;

  const _ProfileTab({
    required this.title,
    required this.icon,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 17,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Overview
// =============================================================================

class _OverviewSection extends StatelessWidget {
  const _OverviewSection();

  @override
  Widget build(BuildContext context) {
    final studentController = Get.find<StudentController>();
    final student = studentController.selectedStudent.value;

    if (student == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------------------------------
        // Personal
        // ---------------------------------------------------------------------
        _InfoCard(
          title: 'Personal Information',
          icon: Icons.person_outline_rounded,
          children: [
            _InfoItem(label: 'Full Name', value: student.name),
            _InfoItem(label: 'Student ID', value: _display(student.rollNumber)),
            _InfoItem(label: 'CNIC', value: _display(student.cnic)),
            _InfoItem(label: 'Phone', value: _display(student.phone)),
            _InfoItem(label: 'Email', value: _display(student.email)),
            _InfoItem(
              label: 'Date of Birth',
              value: _display(student.dateOfBirth),
            ),
            _InfoItem(label: 'Gender', value: _display(student.gender)),
            _InfoItem(label: 'Address', value: _display(student.address)),
          ],
        ),

        const SizedBox(height: 20),

        // ---------------------------------------------------------------------
        // Academic
        // ---------------------------------------------------------------------
        _InfoCard(
          title: 'Academic Information',
          icon: Icons.school_outlined,
          children: [
            _InfoItem(label: 'Department', value: _display(student.department)),
            _InfoItem(label: 'Program', value: _display(student.program)),
            _InfoItem(label: 'Student ID', value: _display(student.rollNumber)),
            _InfoItem(label: 'Semester', value: _display(student.semester)),
            _InfoItem(label: 'Session', value: _display(student.session)),
            _InfoItem(
              label: 'Admission Date',
              value: _display(student.admissionDate),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ---------------------------------------------------------------------
        // Guardian
        // ---------------------------------------------------------------------
        // ---------------------------------------------------------------------
        // Guardian
        // ---------------------------------------------------------------------
        _InfoCard(
          title: 'Guardian Information',
          icon: Icons.family_restroom_rounded,
          children: [
            _InfoItem(
              label: 'Guardian Name',
              value: _display(student.guardianName),
            ),
            _InfoItem(
              label: 'Relationship',
              value: _display(student.guardianRelationship),
            ),
            _InfoItem(
              label: 'Primary Contact',
              value: _display(student.guardianPrimaryContact),
            ),
            _InfoItem(
              label: 'Alternate Contact',
              value: _display(student.guardianAlternateContact),
            ),
            _InfoItem(label: 'CNIC', value: _display(student.guardianCnic)),
            _InfoItem(
              label: 'Occupation',
              value: _display(student.guardianOccupation),
            ),
            _InfoItem(
              label: 'Address',
              value: _display(student.guardianAddress),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ---------------------------------------------------------------------
        // Hostel
        // ---------------------------------------------------------------------
        _InfoCard(
          title: 'Hostel Information',
          icon: Icons.apartment_rounded,
          children: [
            _InfoItem(
              label: 'Hostel Block',
              value: _display(student.hostelBlock),
            ),
            _InfoItem(
              label: 'Room Number',
              value: _display(student.roomNumber),
            ),
            _InfoItem(label: 'Bed Number', value: _display(student.bedNumber)),
            _InfoItem(label: 'Floor', value: _display(student.floor)),
            _InfoItem(
              label: 'Check-in Date',
              value: _display(student.checkInDate),
            ),
            _InfoItem(
              label: 'Expected Check-out',
              value: _display(student.expectedCheckOut),
            ),
            _InfoItem(
              label: 'Occupancy Status',
              value: _display(student.hostelStatus),
            ),
          ],
        ),
      ],
    );
  }

  static String _display(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    return value;
  }
}

// =============================================================================
// Information Card
// =============================================================================

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 48) / 3;

              return Wrap(
                spacing: 24,
                runSpacing: 22,
                children: children.map((child) {
                  return SizedBox(width: itemWidth, child: child);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Information Item
// =============================================================================

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}