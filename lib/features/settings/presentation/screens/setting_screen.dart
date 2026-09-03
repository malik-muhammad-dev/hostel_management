import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:hostel_management/app/theme/app_colors.dart';
import 'package:hostel_management/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:hostel_management/features/settings/services/data_export_service.dart';
import 'package:hostel_management/features/students/data/repositories/student_repository.dart';
import 'package:hostel_management/features/fees/data/repositories/fee_repository.dart';
import 'package:hostel_management/features/expenses/data/repositories/expense_repository.dart';
import 'package:hostel_management/features/receipts/data/repositories/receipt_repository.dart';

// =============================================================================
// SETTINGS SCREEN
//
// Just the Excel export safety net for now. The old local-SQLite "Cloud
// Backup" card and the one-time Migrate Students/Migrate Fees tools have
// been pulled off this screen on purpose — the migrations already ran
// successfully and running them again would risk duplicating real data,
// and the local SQLite backup stopped covering the features that are now
// on Supabase. Export Data (below) is the one safety net that matters
// right now while the project is on Supabase's free tier.
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

          _ExportDataCard(settingsController: settingsController),
        ],
      ),
    );
  }
}

// =============================================================================
// EXPORT DATA CARD
//
// A second, independent safety net for the free Supabase tier, which has
// NO automatic backups at all (confirmed against Supabase's own pricing —
// daily backups only start on the paid Pro plan). One tap pulls every
// Student, Fee, Expense, and Student Cash record straight from Supabase
// right now and writes it into one .xlsx file, so there's always a
// recent, human-readable copy of the real data sitting on this PC. Only
// ever reads data — nothing here can change or delete anything.
// =============================================================================

class _ExportDataCard extends StatefulWidget {
  final AppSettingsController settingsController;

  const _ExportDataCard({required this.settingsController});

  @override
  State<_ExportDataCard> createState() => _ExportDataCardState();
}

class _ExportDataCardState extends State<_ExportDataCard> {
  late final DataExportService _service = DataExportService(
    studentRepository: Get.find<StudentRepository>(),
    feeRepository: Get.find<FeeRepository>(),
    expenseRepository: Get.find<ExpenseRepository>(),
    receiptRepository: Get.find<ReceiptRepository>(),
  );

  bool _isExporting = false;
  String? _lastExportPath;

  Future<void> _pickFolder() async {
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose a folder for exports',
    );

    if (path == null) return;

    await widget.settingsController.setBackupFolderPath(path);
  }

  Future<String> _resolveDestinationFolder() async {
    final chosenFolder = widget.settingsController.backupFolderPath.value;
    if (chosenFolder != null && chosenFolder.trim().isNotEmpty) {
      return chosenFolder;
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    return p.join(documentsDir.path, 'ONIMS Exports');
  }

  Future<void> _runExport() async {
    setState(() => _isExporting = true);

    try {
      final folder = await _resolveDestinationFolder();
      final path = await _service.exportToExcel(folder);

      if (!mounted) return;

      setState(() => _lastExportPath = path);

      Get.snackbar(
        'Export Complete',
        'Saved to $path',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Export Failed',
          e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
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
                Icons.table_chart_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Export Data (Excel)',
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
            'One tap: pulls every Student, Fee, Expense, and Student Cash '
            'record straight from Supabase right now and saves it as one '
            'Excel file, with each on its own sheet. This is an '
            'independent copy on top of Supabase itself, since the free '
            'Supabase plan does not back up data automatically. This only '
            'ever reads data; nothing here can change or delete anything.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          Obx(() {
            final folder = widget.settingsController.backupFolderPath.value;

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
                      folder ??
                          'No folder chosen — saves into this PC\'s '
                              'Documents folder instead',
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
                onPressed: _pickFolder,
                icon: const Icon(Icons.drive_folder_upload_outlined, size: 17),
                label: Obx(
                  () => Text(
                    widget.settingsController.backupFolderPath.value == null
                        ? 'Choose Folder'
                        : 'Change Folder',
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isExporting ? null : _runExport,
                icon: _isExporting
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.table_chart_outlined, size: 17),
                label: const Text('Export Now'),
              ),
            ],
          ),

          if (_lastExportPath != null) ...[
            const SizedBox(height: 16),
            Text(
              'Last export saved to:\n$_lastExportPath',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}