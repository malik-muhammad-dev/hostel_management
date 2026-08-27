import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/fee_controller.dart';

class BankReceiptSection extends StatelessWidget {
  const BankReceiptSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FeeController>();

    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 20,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bank Payment Receipt',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    controller.receiptAttachmentPath.value ??
                        'Attach the receipt for this bank payment',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            OutlinedButton.icon(
              onPressed: () => _pickReceipt(controller),
              icon: const Icon(Icons.upload_file_outlined, size: 17),
              label: Text(
                controller.receiptAttachmentPath.value == null
                    ? 'Attach Receipt'
                    : 'Change Receipt',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReceipt(FeeController controller) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (files.isEmpty) {
      return;
    }

    final path = files.first.path;

    if (path == null) {
      return;
    }

    controller.setReceiptAttachmentPath(path);
  }
}
