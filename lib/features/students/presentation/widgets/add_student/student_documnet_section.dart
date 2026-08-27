import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../controllers/student_document_controller.dart';
import 'form_section.dart';

// =============================================================================
// STUDENT DOCUMENTS SECTION
//
// Named (required) documents — CNIC, Admission Form, College/Student
// Card, Medical Certificate — plus any number of custom documents added
// via "Add Other Document". Backed by StudentDocumentController:
// - New student (isNewStudent == true): documents go into
//   controller.draftDocuments until the student is saved and gets an id.
// - Existing student: documents are saved directly via controller.setDocument.
// =============================================================================

const _namedDocumentTitles = [
  'CNIC',
  'Admission Form',
  'College / Student Card',
  'Medical Certificate',
];

const _requiredDocumentTitles = {'CNIC', 'Admission Form'};

class StudentDocumentsSection extends StatelessWidget {
  final StudentDocumentController controller;
  final bool isNewStudent;

  const StudentDocumentsSection({
    super.key,
    required this.controller,
    required this.isNewStudent,
  });

  Future<void> _pickAndAttach({
    required BuildContext context,
    required String title,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result.isEmpty) return;

    final file = result.first;
    final isRequired = _requiredDocumentTitles.contains(title);

    bool success;

    if (isNewStudent) {
      success = controller.setDraftDocument(
        title: title,
        fileName: file.name,
        filePath: file.path,
        isRequired: isRequired,
        replaceByTitle: true,
      );
    } else {
      final studentId = controller.selectedStudentId.value;

      if (studentId == null) {
        Get.snackbar(
          'Document',
          'Student ID could not be determined.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      success = await controller.setDocument(
        studentId: studentId,
        title: title,
        fileName: file.name,
        filePath: file.path,
        isRequired: isRequired,
      );
    }

    if (!success) {
      Get.snackbar(
        'Document',
        'Unable to attach document.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _addOtherDocument(BuildContext context) async {
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Document'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Document Name',
              hintText: 'e.g. Scholarship Form',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = nameController.text.trim();
                if (value.isEmpty) return;
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
    });

    if (name == null || name.trim().isEmpty) return;
    if (!context.mounted) return;

    await _pickAndAttach(context: context, title: name.trim());
  }

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Student Documents',
      subtitle: 'Attach documents related to this student',
      icon: Icons.folder_outlined,
      child: Obx(() {
        final named = isNewStudent
            ? controller.draftDocuments
            : controller.documents;

        final others = isNewStudent
            ? controller.otherDraftDocuments
            : controller.otherDocuments;

        String? fileNameFor(String title) {
          return named
              .firstWhereOrNull((doc) => doc.title == title)
              ?.fileName;
        }

        return Column(
          children: [
            for (final title in _namedDocumentTitles) ...[
              DocumentUploadItem(
                title: title,
                subtitle: _subtitleFor(title),
                required: _requiredDocumentTitles.contains(title),
                attachedFileName: fileNameFor(title),
                onAttach: () => _pickAndAttach(context: context, title: title),
                onRemove: () {
                  if (isNewStudent) {
                    controller.removeDraftDocumentByTitle(title);
                  } else {
                    final doc = controller.documentByTitle(title);
                    if (doc?.id != null) {
                      controller.deleteDocument(doc!.id!);
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
            ],

            if (others.isNotEmpty) ...[
              ...others.map(
                (document) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DocumentUploadItem(
                    title: document.title,
                    subtitle: 'Custom document',
                    attachedFileName: document.fileName,
                    onAttach: () {},
                    onRemove: () {
                      if (isNewStudent) {
                        controller.removeDraftDocumentByTitle(document.title);
                      } else if (document.id != null) {
                        controller.deleteDocument(document.id!);
                      }
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 4),

            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _addOtherDocument(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Other Document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _subtitleFor(String title) {
    switch (title) {
      case 'CNIC':
        return 'Student identity document';
      case 'Admission Form':
        return 'College admission document';
      case 'College / Student Card':
        return 'Valid college identification';
      case 'Medical Certificate':
        return 'Medical or health-related document';
      default:
        return 'Optional document';
    }
  }
}

// =============================================================================
// Document upload item (unchanged visual component)
// =============================================================================

class DocumentUploadItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool required;
  final VoidCallback onAttach;
  final String? attachedFileName;
  final VoidCallback? onRemove;

  const DocumentUploadItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.required = false,
    required this.onAttach,
    this.attachedFileName,
    this.onRemove,
  });

  bool get _isAttached => attachedFileName != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isAttached ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isAttached
                  ? Icons.check_circle_outline
                  : Icons.description_outlined,
              size: 19,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (required)
                      const Text(
                        ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _isAttached ? attachedFileName! : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: _isAttached
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_isAttached && onRemove != null)
            IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
            )
          else
            OutlinedButton.icon(
              onPressed: onAttach,
              icon: const Icon(Icons.upload_file_outlined, size: 17),
              label: const Text('Attach'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}