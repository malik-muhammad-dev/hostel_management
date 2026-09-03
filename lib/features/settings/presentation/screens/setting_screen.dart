import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hostel_management/app/theme/app_colors.dart';
import 'package:hostel_management/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:hostel_management/features/settings/services/student_migration_service.dart';
import 'package:hostel_management/features/settings/services/fee_migration_service.dart';
import 'package:hostel_management/features/students/presentation/controllers/student_controller.dart';
import 'package:hostel_management/features/fees/presentation/controllers/fee_controller.dart';



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

          const SizedBox(height: 24),

          const _MigrateStudentsCard(),

          const SizedBox(height: 24),

          const _MigrateFeesCard(),
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

// =============================================================================
// MIGRATE STUDENTS CARD
//
// One-time utility: copies every student already in the local database
// into Supabase, keeping their exact same ids (see StudentMigrationService
// for why that matters). Meant to be used once, early in the Supabase
// migration, before Fees/Expenses/Receipts are also moved over — not a
// button that needs pressing again afterward.
// =============================================================================

class _MigrateStudentsCard extends StatefulWidget {
  const _MigrateStudentsCard();

  @override
  State<_MigrateStudentsCard> createState() => _MigrateStudentsCardState();
}

class _MigrateStudentsCardState extends State<_MigrateStudentsCard> {
  final _service = StudentMigrationService();
  bool _isMigrating = false;

  Future<void> _showResultDialog(StudentMigrationResult result) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          result.isFullSuccess ? 'Migration Complete' : 'Migration Finished With Issues',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Local students: ${result.localCount}\n'
                'Migrated to Supabase: ${result.migratedCount}',
              ),
              if (result.failures.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Failed:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ...result.failures.map(
                  (failure) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      failure,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _runMigration() async {
    setState(() => _isMigrating = true);

    try {
      final existingCount = await _service.countExistingSupabaseStudents();

      if (!mounted) return;

      if (existingCount > 0) {
        final proceedAnyway = await _confirm(
          title: 'Supabase Already Has Students',
          message:
              'Supabase already contains $existingCount student(s) — '
              'likely test entries from earlier. Running this migration '
              'now will add every local student on top of those without '
              'checking for overlap, which can leave duplicates. Delete '
              'any test students from Supabase\'s Table Editor first if '
              'you want a clean result.\n\n'
              'Continue anyway?',
          confirmLabel: 'Continue Anyway',
        );

        if (!proceedAnyway) {
          setState(() => _isMigrating = false);
          return;
        }
      }

      if (!mounted) return;

      final proceed = await _confirm(
        title: 'Migrate Students to Supabase',
        message:
            'This copies every student currently in your local database '
            'to Supabase, using their exact same IDs so fees and other '
            'records still line up correctly.\n\n'
            'This only reads local data — nothing on this PC is changed '
            'or deleted. Continue?',
        confirmLabel: 'Migrate',
      );

      if (!proceed) {
        setState(() => _isMigrating = false);
        return;
      }

      final result = await _service.migrateLocalStudentsToSupabase();

      if (Get.isRegistered<StudentController>()) {
        await Get.find<StudentController>().loadStudents();
      }

      await _showResultDialog(result);
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Migration Failed',
          e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMigrating = false);
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
                Icons.cloud_upload_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Migrate Students to Supabase',
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
            'One-time step: copies every student already in this app\'s '
            'local database into Supabase. Meant to be run once, before '
            'Fees/Expenses/Receipts are also moved to Supabase — not '
            'something to run repeatedly.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _isMigrating ? null : _runMigration,
            icon: _isMigrating
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_upload_outlined, size: 17),
            label: const Text('Migrate Students Now'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MIGRATE FEES CARD
//
// Same one-time-utility pattern as _MigrateStudentsCard, for fee
// transactions and fee payments. Run this AFTER Migrate Students —
// fee_transactions/fee_payments reference students by id, and the
// student rows need to already exist in Supabase for that to hold up.
// =============================================================================

class _MigrateFeesCard extends StatefulWidget {
  const _MigrateFeesCard();

  @override
  State<_MigrateFeesCard> createState() => _MigrateFeesCardState();
}

class _MigrateFeesCardState extends State<_MigrateFeesCard> {
  final _service = FeeMigrationService();
  bool _isMigrating = false;

  Future<void> _showResultDialog(FeeMigrationResult result) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          result.isFullSuccess ? 'Migration Complete' : 'Migration Finished With Issues',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Local transactions: ${result.localTransactionCount}\n'
                'Migrated transactions: ${result.migratedTransactionCount}\n\n'
                'Local payments: ${result.localPaymentCount}\n'
                'Migrated payments: ${result.migratedPaymentCount}',
              ),
              if (result.failures.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Failed:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ...result.failures.map(
                  (failure) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      failure,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _runMigration() async {
    setState(() => _isMigrating = true);

    try {
      final existingTransactions =
          await _service.countExistingSupabaseTransactions();
      final existingPayments = await _service.countExistingSupabasePayments();

      if (!mounted) return;

      if (existingTransactions > 0 || existingPayments > 0) {
        final proceedAnyway = await _confirm(
          title: 'Supabase Already Has Fee Records',
          message:
              'Supabase already contains $existingTransactions '
              'transaction(s) and $existingPayments payment(s). Running '
              'this migration now will add every local record on top of '
              'those without checking for overlap, which can leave '
              'duplicates.\n\n'
              'Continue anyway?',
          confirmLabel: 'Continue Anyway',
        );

        if (!proceedAnyway) {
          setState(() => _isMigrating = false);
          return;
        }
      }

      if (!mounted) return;

      final proceed = await _confirm(
        title: 'Migrate Fees to Supabase',
        message:
            'This copies every fee transaction and fee payment currently '
            'in your local database to Supabase, using their exact same '
            'IDs and matching the students already migrated there.\n\n'
            'This only reads local data — nothing on this PC is changed '
            'or deleted. Continue?',
        confirmLabel: 'Migrate',
      );

      if (!proceed) {
        setState(() => _isMigrating = false);
        return;
      }

      final result = await _service.migrateLocalFeesToSupabase();

      if (Get.isRegistered<FeeController>()) {
        await Get.find<FeeController>().loadFeeData();
      }

      await _showResultDialog(result);
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Migration Failed',
          e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMigrating = false);
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
                Icons.cloud_upload_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'Migrate Fees to Supabase',
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
            'One-time step: copies every fee transaction and fee payment '
            'already in this app\'s local database into Supabase. Run '
            'this only after Migrate Students has completed successfully '
            '— fee records reference students by id.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _isMigrating ? null : _runMigration,
            icon: _isMigrating
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_upload_outlined, size: 17),
            label: const Text('Migrate Fees Now'),
          ),
        ],
      ),
    );
  }
}