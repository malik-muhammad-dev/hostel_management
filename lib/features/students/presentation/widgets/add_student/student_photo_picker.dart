import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../controllers/student_form_controller.dart';

class StudentPhotoPicker extends StatelessWidget {
  final StudentFormController controller;

  const StudentPhotoPicker({
    super.key,
    required this.controller,
  });

  Future<void> _pickPhoto(BuildContext context) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop(
                    ImageSource.gallery,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop(
                    ImageSource.camera,
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final image = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (image == null) {
      return;
    }

    await controller.setSelectedPhoto(
      File(image.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final photo = controller.selectedPhoto.value;

        return Column(
          children: [
            GestureDetector(
              onTap: () => _pickPhoto(context),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: photo == null
                    ? const Icon(
                        Icons.add_a_photo_outlined,
                        size: 28,
                        color: AppColors.textSecondary,
                      )
                    : Image.file(
                        photo,
                        fit: BoxFit.cover,
                        // The stored path may no longer exist on disk —
                        // e.g. app data was wiped/moved — fall back to
                        // the empty state instead of an error screen.
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.add_a_photo_outlined,
                            size: 28,
                            color: AppColors.textSecondary,
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _pickPhoto(context),
              icon: Icon(
                photo == null
                    ? Icons.add_a_photo_outlined
                    : Icons.edit_outlined,
                size: 17,
              ),
              label: Text(
                photo == null
                    ? 'Add Photo'
                    : 'Change Photo',
              ),
            ),
            if (photo != null)
              TextButton(
                onPressed: controller.clearSelectedPhoto,
                child: const Text('Remove'),
              ),
          ],
        );
      },
    );
  }
}