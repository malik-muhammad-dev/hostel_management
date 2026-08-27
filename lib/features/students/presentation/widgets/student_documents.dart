import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hostel_management/features/students/data/models/student_document%20model.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/student_document_controller.dart';

class StudentDocuments extends StatelessWidget {
  final int studentId;

  const StudentDocuments({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudentDocumentController>();

    if (controller.selectedStudentId.value != studentId) {
      controller.loadDocuments(studentId);
    }

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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Documents',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Student documents and attachments',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _uploadOtherDocument(context, controller),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Upload Document'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Obx(() {
            final documents = controller.documents;

            if (documents.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No documents attached yet.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: documents
                  .map(
                    (document) => _DocumentItem(
                      document: document,
                      onDelete: document.id == null
                          ? null
                          : () => controller.deleteDocument(document.id!),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _uploadOtherDocument(
    BuildContext context,
    StudentDocumentController controller,
  ) async {
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

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result.isEmpty) return;

    final file = result.first;

    final success = await controller.setDocument(
      studentId: studentId,
      title: name.trim(),
      fileName: file.name,
      filePath: file.path,
    );

    if (!success) {
      Get.snackbar(
        'Document',
        'Unable to upload document.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _DocumentItem extends StatelessWidget {
  final StudentDocumentModel document;
  final VoidCallback? onDelete;

  const _DocumentItem({required this.document, this.onDelete});

  String get _fileType {
    final name = document.fileName.toLowerCase();
    if (name.endsWith('.pdf')) return 'PDF';
    if (name.endsWith('.doc') || name.endsWith('.docx')) return 'Document';
    return 'Image';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
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
            child: const Icon(
              Icons.description_outlined,
              size: 19,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_fileType • ${document.fileName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Remove document',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}