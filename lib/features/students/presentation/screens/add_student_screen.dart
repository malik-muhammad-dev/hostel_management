import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hostel_management/core/widgets/app_shell.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/student_model.dart';
import '../controllers/student_controller.dart';
import '../controllers/student_document_controller.dart';
import '../controllers/student_form_controller.dart';
import '../controllers/student_service_controller.dart';
import '../widgets/add_student/academic_information_section.dart';
import '../widgets/add_student/guardian_information_section.dart';
import '../widgets/add_student/hostel_information_section.dart';
import '../widgets/add_student/package_information_section.dart';
import '../widgets/add_student/personal_information_section.dart';
import '../widgets/add_student/service_information_section.dart';
import '../widgets/add_student/student_documnet_section.dart';

class AddStudentScreen extends StatelessWidget {
  final StudentModel? student;

  const AddStudentScreen({
    super.key,
    this.student,
  });

  bool get isEditMode => student != null;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StudentFormController>(
      init: StudentFormController(
        initialStudent: student,
      ),
      builder: (formController) {
        final serviceController =
            Get.find<StudentServiceController>();

        final documentController =
            Get.find<StudentDocumentController>();

        // -------------------------------------------------------------------
        // Existing student
        //
        // Load services/documents only when editing an existing student.
        // A new student does not have an ID yet.
        // -------------------------------------------------------------------

        if (student?.id != null &&
            serviceController.selectedStudentId.value != student!.id) {
          serviceController.loadServices(student!.id!);
        }

        if (student?.id != null &&
            documentController.selectedStudentId.value != student!.id) {
          documentController.loadDocuments(student!.id!);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context,
                formController,
                serviceController,
                documentController,
              ),

              const SizedBox(height: 24),

              PersonalInformationSection(
                controller: formController,
              ),

              const SizedBox(height: 24),

              AcademicInformationSection(
                controller: formController,
              ),

              const SizedBox(height: 24),

              GuardianInformationSection(
                controller: formController,
              ),

              const SizedBox(height: 24),

              HostelInformationSection(
                controller: formController,
              ),

              const SizedBox(height: 24),

              PackageInformationSection(
                controller: formController,
              ),

              const SizedBox(height: 24),

              ServicesInformationSection(
                controller: serviceController,
                isNewStudent: !isEditMode,
              ),

              const SizedBox(height: 24),

              StudentDocumentsSection(
                controller: documentController,
                isNewStudent: !isEditMode,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    StudentFormController formController,
    StudentServiceController serviceController,
    StudentDocumentController documentController,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditMode
                    ? 'Edit Student'
                    : 'Add Student',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                isEditMode
                    ? 'Update student profile and fee information'
                    : 'Create a new student profile',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        OutlinedButton(
          onPressed: () {
            // ---------------------------------------------------------------
            // Clear any unfinished services before leaving the form.
            // ---------------------------------------------------------------

            serviceController.clearServices();
            documentController.clearDocuments();

            Get.find<AppShellController>().popPage();
          },
          child: const Text('Cancel'),
        ),

        const SizedBox(width: 10),

        Obx(
          () => ElevatedButton.icon(
            onPressed: formController.isSaving.value
                ? null
                : () => _saveStudent(
                      context,
                      formController,
                      serviceController,
                      documentController,
                    ),
            icon: formController.isSaving.value
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.save_outlined,
                    size: 18,
                  ),
            label: Text(
              isEditMode
                  ? 'Save Changes'
                  : 'Save Student',
            ),
          ),
        ),
      ],
    );
  }

 Future<void> _saveStudent(
  BuildContext context,
  StudentFormController formController,
  StudentServiceController serviceController,
  StudentDocumentController documentController,
) async {
  // -------------------------------------------------------------------------
  // Validate student form
  // -------------------------------------------------------------------------

  final validationMessage = formController.validate();

  if (validationMessage != null) {
    _showMessage(
      context,
      validationMessage,
    );
    return;
  }

  final studentController = Get.find<StudentController>();

  final studentModel = formController.buildStudentModel();

  formController.isSaving.value = true;

  try {
    // -----------------------------------------------------------------------
    // EDIT EXISTING STUDENT
    // -----------------------------------------------------------------------

    if (formController.isEditMode) {
      final success = await studentController.updateStudent(
        studentModel,
      );

      if (!context.mounted) {
        return;
      }

      if (!success) {
        _showMessage(
          context,
          'Unable to update student.',
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Student updated successfully.',
          ),
        ),
      );

      Get.find<AppShellController>().popPage();

      return;
    }

    // -----------------------------------------------------------------------
    // ADD NEW STUDENT
    // -----------------------------------------------------------------------

    final createdStudent = await studentController.addStudent(
      studentModel,
    );

    if (!context.mounted) {
      return;
    }

    if (createdStudent == null) {
      _showMessage(
        context,
        'Unable to add student.',
      );
      return;
    }

    // -----------------------------------------------------------------------
    // StudentController generated the new student ID and returned the
    // created student directly, so we don't need to re-find it by name or
    // roll number (which are not guaranteed to be unique).
    // -----------------------------------------------------------------------

    // -----------------------------------------------------------------------
    // Save draft services only when the student actually has services.
    // -----------------------------------------------------------------------

    if (createdStudent.id != null &&
        serviceController.draftServices.isNotEmpty) {
      final servicesSaved =
          await serviceController.saveDraftServices(
        createdStudent.id!,
      );

      if (!servicesSaved) {
        if (!context.mounted) {
          return;
        }

        _showMessage(
          context,
          'Student was added, but services could not be saved.',
        );

        return;
      }
    }

    // -----------------------------------------------------------------------
    // Save draft documents only when the student actually has documents.
    // -----------------------------------------------------------------------

    if (createdStudent.id != null &&
        documentController.draftDocuments.isNotEmpty) {
      final documentsSaved =
          await documentController.saveDraftDocuments(
        createdStudent.id!,
      );

      if (!documentsSaved) {
        if (!context.mounted) {
          return;
        }

        _showMessage(
          context,
          'Student was added, but documents could not be saved.',
        );

        return;
      }
    }

    // -----------------------------------------------------------------------
    // Student was successfully created.
    //
    // This must happen regardless of whether the student has services.
    // -----------------------------------------------------------------------

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Student added successfully.',
        ),
      ),
    );

    Get.find<AppShellController>().popPage();
  } finally {
    formController.isSaving.value = false;
  }
}
  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}