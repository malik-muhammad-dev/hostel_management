import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/app_database.dart';
import 'app_settings_data_source.dart';

// =============================================================================
// SUPABASE APP SETTINGS DATA SOURCE
//
// Opening Balance and the Late Fine rule are genuinely hostel-wide
// numbers — every PC that runs this app has to see the same figures, so
// those now live in Supabase (table `app_settings`, single shared row
// id = 1 — the same table the original migration design already created,
// just never wired up here until now).
//
// Backup Folder Path and Last Backup At are the ONE deliberate exception
// kept on local SQLite instead of Supabase: a backup folder is a path on
// ONE specific PC's disk (e.g. "C:\Users\Ali\Backups"). Sharing that
// through Supabase would mean every other PC tries to write its automatic
// backups into a folder that only exists on whichever machine set it
// last — silently breaking backups everywhere else. So those two fields
// keep reading/writing the local `app_settings` row that already exists
// on disk (see AppDatabase) — this is correct behavior, not a leftover
// gap like Opening Balance was.
//
// Postgres `numeric` columns (opening_balance, fine_amount) come back
// from Supabase's REST API as JSON strings, not JSON numbers — same
// quirk handled elsewhere in this app (see fee_payment_model.dart) —
// so both are parsed defensively below.
// =============================================================================

double _parseDouble(Object? value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

class SupabaseAppSettingsDataSource implements AppSettingsDataSource {
  SupabaseClient get _client => Supabase.instance.client;
  Future<Database> get _localDb async => AppDatabase.instance.database;

  Future<Map<String, Object?>> _row() async {
    final rows = await _client
        .from('app_settings')
        .select()
        .eq('id', 1)
        .limit(1);

    return rows.isEmpty ? const {} : Map<String, Object?>.from(rows.first);
  }

  @override
  Future<double> getOpeningBalance() async {
    final row = await _row();
    return _parseDouble(row['opening_balance'], 0.0);
  }

  @override
  Future<void> setOpeningBalance(double value) async {
    // upsert(), not update(): app_settings' single row (id = 1) is
    // expected to already exist from the schema's one-time seed insert,
    // but PostgREST's .update() matches-zero-rows silently — it does NOT
    // throw if that row is ever missing. That would mean this write
    // silently does nothing while the UI reports success. upsert()
    // guarantees the value is actually persisted either way.
    await _client.from('app_settings').upsert({
      'id': 1,
      'opening_balance': value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ---------------------------------------------------------------------------
  // Late Fine rule
  // ---------------------------------------------------------------------------

  @override
  Future<double> getFineAmount() async {
    final row = await _row();
    return _parseDouble(row['fine_amount'], 100.0);
  }

  @override
  Future<int> getFineDueDay() async {
    final row = await _row();
    return (row['fine_due_day'] as num?)?.toInt() ?? 9;
  }

  @override
  Future<String?> getFineEffectiveFrom() async {
    final row = await _row();
    return row['fine_effective_from'] as String?;
  }

  @override
  Future<void> setFineRule({
    required double amount,
    required int dueDay,
  }) async {
    // upsert(), same reasoning as setOpeningBalance() above.
    await _client.from('app_settings').upsert({
      'id': 1,
      'fine_amount': amount,
      'fine_due_day': dueDay,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ---------------------------------------------------------------------------
  // Backup — deliberately local. See file header.
  // ---------------------------------------------------------------------------

  Future<Map<String, Object?>> _localRow() async {
    final db = await _localDb;
    final rows = await db.query(
      'app_settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    return rows.isEmpty ? const {} : rows.first;
  }

  @override
  Future<String?> getBackupFolderPath() async {
    final row = await _localRow();
    return row['backup_folder_path'] as String?;
  }

  @override
  Future<void> setBackupFolderPath(String? path) async {
    final db = await _localDb;
    await db.update(
      'app_settings',
      {'backup_folder_path': path},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  @override
  Future<String?> getLastBackupAt() async {
    final row = await _localRow();
    return row['last_backup_at'] as String?;
  }

  @override
  Future<void> setLastBackupAt(String value) async {
    final db = await _localDb;
    await db.update(
      'app_settings',
      {'last_backup_at': value},
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
