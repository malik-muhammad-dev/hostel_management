import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hostel_management/app/theme/app_colors.dart';
import 'package:hostel_management/features/settings/presentation/controllers/app_settings_controller.dart';



// =============================================================================
// SETTINGS SCREEN
//
// Currently just one card: Cloud Backup. More app-wide settings can land
// here later without needing a new screen/nav entry.
// =============================================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<AppSettingsController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'App-wide configuration',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 24),

          _BackupCard(settingsController: settingsController),
        ],
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  final AppSettingsController settingsController;

  const _BackupCard({required this.settingsController});

  Future<void> _pickFolder(BuildContext context) async {
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose a backup folder',
    );

    if (path == null) return;

    await settingsController.setBackupFolderPath(path);
  }

  Future<void> _backupNow(BuildContext context) async {
    try {
      await settingsController.backupNow();
      if (context.mounted) {
        Get.snackbar(
          'Backup Complete',
          'A fresh backup and report have been saved.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Get.snackbar(
          'Backup Failed',
          e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
        );
      }
    }
  }

  String _formatTimestamp(String? iso) {
    if (iso == null) return 'Never';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;

    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final ampm = parsed.hour >= 12 ? 'PM' : 'AM';

    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/'
        '${parsed.year}, $hour:$minute $ampm';
  }

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
              const Icon(
                Icons.cloud_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Cloud Backup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            'Point this at a folder that a cloud-sync app (Google Drive, '
            'OneDrive, Dropbox) is watching on this PC. Every few hours '
            '(and shortly after the app starts), a backup and a read-only '
            'summary report are saved there automatically — no manual '
            'steps needed once it\'s set up. This never changes anything '
            'in the app\'s own data; it only ever reads from it.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          Obx(() {
            final folder = settingsController.backupFolderPath.value;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 16,
                    color: folder == null
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      folder ?? 'No folder selected — backup is off',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 14),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickFolder(context),
                icon: const Icon(Icons.drive_folder_upload_outlined, size: 17),
                label: Obx(
                  () => Text(
                    settingsController.backupFolderPath.value == null
                        ? 'Choose Folder'
                        : 'Change Folder',
                  ),
                ),
              ),
              Obx(
                () => ElevatedButton.icon(
                  onPressed:
                      settingsController.isBackingUp.value ||
                              settingsController.backupFolderPath.value ==
                                  null
                          ? null
                          : () => _backupNow(context),
                  icon: settingsController.isBackingUp.value
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.backup_outlined, size: 17),
                  label: const Text('Backup Now'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Obx(
            () => Text(
              'Last backup: ${_formatTimestamp(settingsController.lastBackupAt.value)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.border),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.insert_drive_file_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'For someone else to just glance at the data: ',
                      ),
                      TextSpan(
                        text: 'onims_dashboard_report.html',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' is written into the same folder every time. '
                            'Once that folder is synced to their PC too, a '
                            'desktop shortcut pointed at that file opens the '
                            'latest report with one double-click.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}