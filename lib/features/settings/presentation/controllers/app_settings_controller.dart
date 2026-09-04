import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../../../../core/database/app_database.dart';
import '../../data/repositories/app_settings_repository.dart';
import '../../services/backup_report_generator.dart';

class AppSettingsController extends GetxController {
  final AppSettingsRepository repository;

  AppSettingsController(this.repository);

  final openingBalance = 0.0.obs;
  final isLoading = false.obs;

  // ---------------------------------------------------------------------------
  // Late Fine rule — see AppSettingsDataSource for what each field means.
  // Defaults here (100 / day 9) only matter for the brief window before
  // loadFineSettings() finishes; the real values always come from the DB.
  // ---------------------------------------------------------------------------

  final fineAmount = 100.0.obs;
  final fineDueDay = 9.obs;
  final fineEffectiveFrom = Rxn<String>();

  // ---------------------------------------------------------------------------
  // Backup — see "AUTO-BACKUP" section below for the full design notes.
  // ---------------------------------------------------------------------------

  final backupFolderPath = Rxn<String>();
  final lastBackupAt = Rxn<String>();
  final isBackingUp = false.obs;

  Timer? _autoBackupTimer;

  static const _reportFileName = 'onims_dashboard_report.html';
  static const _autoBackupInterval = Duration(hours: 3);
  static const _firstAutoBackupDelay = Duration(seconds: 15);

  @override
  void onInit() {
    super.onInit();
    debugPrint('[SETTINGS] AppSettingsController created: $hashCode');
    loadOpeningBalance();
    loadFineSettings();
    loadBackupSettings();
  }

  @override
  void onClose() {
    _autoBackupTimer?.cancel();
    super.onClose();
  }

  Future<void> loadOpeningBalance() async {
    try {
      isLoading.value = true;
      final loaded = await repository.getOpeningBalance();
      debugPrint('[SETTINGS] loadOpeningBalance() read from DB: $loaded');
      openingBalance.value = loaded;
    } finally {
      isLoading.value = false;
    }
  }

  /// Called from the dashboard's "edit" dialog on the Total Amount card.
  Future<void> setOpeningBalance(double value) async {
    debugPrint(
      '[SETTINGS] setOpeningBalance($value) called on controller $hashCode '
      '— current value before write: ${openingBalance.value}',
    );

    await repository.setOpeningBalance(value);

    final verifyRead = await repository.getOpeningBalance();
    debugPrint('[SETTINGS] after DB write, re-read from DB: $verifyRead');

    openingBalance.value = value;

    debugPrint(
      '[SETTINGS] openingBalance.value is now: ${openingBalance.value}',
    );
  }

  // ---------------------------------------------------------------------------
  // Late Fine rule
  // ---------------------------------------------------------------------------

  Future<void> loadFineSettings() async {
    fineAmount.value = await repository.getFineAmount();
    fineDueDay.value = await repository.getFineDueDay();
    fineEffectiveFrom.value = await repository.getFineEffectiveFrom();
  }

  /// Called from the Fees screen's "Late Fine Rule" edit dialog.
  /// [dueDay] is restricted to 1-28 at the dialog's validation layer so
  /// it's always a valid day in every month, including February.
  Future<void> setFineRule({
    required double amount,
    required int dueDay,
  }) async {
    await repository.setFineRule(amount: amount, dueDay: dueDay);
    fineAmount.value = amount;
    fineDueDay.value = dueDay;
  }

  // ===========================================================================
  // AUTO-BACKUP
  //
  // What this does: every `_autoBackupInterval` while the app is open
  // (plus once shortly after launch, so a short session still gets one),
  // writes a timestamped SQLite snapshot AND a static HTML report into
  // whatever local folder the admin picked in Settings (typically one a
  // cloud-sync app like Google Drive is watching) — with zero admin
  // action needed once the folder is set. The client's own login/PC
  // keeps working exactly as before regardless of whether any of this
  // succeeds.
  //
  // Why this can't touch the admin's real data, by construction:
  // - `AppDatabase.backupTo()` uses `VACUUM INTO`, which only reads the
  //   live database and writes a brand-new file elsewhere — it has no
  //   code path that can modify or delete anything in `students`,
  //   `fee_payments`, `fee_transactions`, or `expenses`. See that
  //   method's own comment for the full explanation.
  // - `BackupReportGenerator` only reads from already-loaded controllers
  //   to build an HTML string — it holds no reference to any repository
  //   or datasource, so it has no way to write to the database even by
  //   accident.
  // - `_runAutoBackup()` below never lets an exception escape. A backup
  //   failing for any reason (folder unplugged, disk full, permission
  //   denied) only means the owner's cloud copy stays stale until the
  //   next attempt — it can never interrupt or corrupt what the admin is
  //   doing on the live app.
  // ===========================================================================

  // NOTE — auto-backup is deliberately NOT armed here anymore.
  //
  // `backupFolderPath` is still loaded/stored because the Settings
  // screen's "Export Data" feature (the current, correct,
  // Supabase-reading export) legitimately reuses the same stored folder
  // path as its remembered destination. But this local SQLite database
  // has been stale for every Supabase-migrated feature since the
  // migration — a "backup" of it no longer reflects the client's real
  // data — and the old "Cloud Backup" card that used to expose/control
  // this auto-backup timer was intentionally removed from the UI (see
  // setting_screen.dart's header comment). Before this fix, simply
  // picking an export folder in the new Export Data card silently
  // re-armed a 3-hour recurring timer that kept writing increasingly
  // stale/misleading .db snapshots, with no remaining way to see or turn
  // it off. `backupNow()`/`_runAutoBackup()`/the Timer machinery below
  // are kept in place (unreachable, on purpose) rather than deleted, the
  // same way other confirmed-dead code in this app has been handled.
  Future<void> loadBackupSettings() async {
    backupFolderPath.value = await repository.getBackupFolderPath();
    lastBackupAt.value = await repository.getLastBackupAt();
  }

  /// Called from the Settings screen's Export Data folder picker to
  /// remember the chosen destination folder. Does NOT arm the local
  /// SQLite auto-backup timer — see the note on loadBackupSettings()
  /// above for why.
  Future<void> setBackupFolderPath(String? path) async {
    await repository.setBackupFolderPath(path);
    backupFolderPath.value = path;
  }

  // Dead code, kept on purpose: nothing calls this anymore now that
  // loadBackupSettings()/setBackupFolderPath() no longer arm it (see the
  // note above). Left in place, along with backupNow()/_runAutoBackup()/
  // the Timer field, rather than deleted, in case auto-backup is ever
  // reintroduced with a real UI to control it.
  // ignore: unused_element
  void _scheduleAutoBackup() {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = null;

    final folder = backupFolderPath.value;
    if (folder == null || folder.trim().isEmpty) {
      return;
    }

    Timer(_firstAutoBackupDelay, _runAutoBackup);
    _autoBackupTimer = Timer.periodic(
      _autoBackupInterval,
      (_) => _runAutoBackup(),
    );
  }

  Future<void> _runAutoBackup() async {
    try {
      debugPrint('[AUTO-BACKUP] running at ${DateTime.now()}');
      await backupNow();
      debugPrint('[AUTO-BACKUP] completed successfully');
    } catch (e, stackTrace) {
      // Deliberately swallowed — see the class-level comment above.
      // Nothing about a failed background backup should ever surface
      // to the admin or interrupt their work.
      debugPrint('[AUTO-BACKUP] failed (non-fatal, live data unaffected): $e');
      debugPrint('$stackTrace');
    }
  }

  /// Runs one backup immediately. Used by both the Settings screen's
  /// "Backup Now" button (where callers are expected to catch and show
  /// the thrown message) and `_runAutoBackup()` above (which swallows
  /// everything). Returns the path of the .db snapshot that was written.
  Future<String> backupNow() async {
    final folder = backupFolderPath.value;

    if (folder == null || folder.trim().isEmpty) {
      throw Exception('Choose a backup folder first.');
    }

    if (!await Directory(folder).exists()) {
      throw Exception(
        'That backup folder no longer exists. Please choose it again.',
      );
    }

    isBackingUp.value = true;

    try {
      // Millisecond-precision timestamp in the filename — VACUUM INTO
      // refuses to overwrite an existing file, so this also guarantees
      // two backups taken close together never collide.
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[:.]'), '-');

      final fileName = 'onims_hostel_backup_$timestamp.db';
      final destinationPath = p.join(folder, fileName);

      await AppDatabase.instance.backupTo(destinationPath);

      // The HTML report is a nice-to-have on top of the real backup —
      // if generating it fails for any reason, the .db snapshot above
      // has already succeeded and must not be reported as a failure.
      try {
        await _writeReport(folder);
      } catch (e, stackTrace) {
        debugPrint(
          '[BACKUP] report generation failed (db backup still succeeded): $e',
        );
        debugPrint('$stackTrace');
      }

      final now = DateTime.now().toIso8601String();
      await repository.setLastBackupAt(now);
      lastBackupAt.value = now;

      return destinationPath;
    } finally {
      isBackingUp.value = false;
    }
  }

  /// Overwrites the SAME fixed filename every time (unlike the
  /// timestamped .db snapshots) — the owner's desktop shortcut always
  /// points at this one path, so it "just works" on every refresh
  /// without anyone ever having to pick the latest file.
  Future<void> _writeReport(String folderPath) async {
    final html = BackupReportGenerator().generate();
    final reportFile = File(p.join(folderPath, _reportFileName));
    await reportFile.writeAsString(html, flush: true);
  }
}