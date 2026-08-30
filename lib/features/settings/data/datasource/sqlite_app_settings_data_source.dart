import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import 'app_settings_data_source.dart';

class SqliteAppSettingsDataSource implements AppSettingsDataSource {
  Future<Database> get _db async => AppDatabase.instance.database;

  @override
  Future<double> getOpeningBalance() async {
    final db = await _db;

    final rows = await db.query(
      'app_settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    // The row is always inserted by AppDatabase's migration, so this
    // empty-check is just a defensive fallback, not the expected path.
    if (rows.isEmpty) return 0.0;

    return (rows.first['opening_balance'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<void> setOpeningBalance(double value) async {
    final db = await _db;

    await db.update(
      'app_settings',
      {'opening_balance': value},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ---------------------------------------------------------------------------
  // Late Fine rule
  // ---------------------------------------------------------------------------

  Future<Map<String, Object?>> _row() async {
    final db = await _db;

    final rows = await db.query(
      'app_settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    return rows.isEmpty ? const {} : rows.first;
  }

  @override
  Future<double> getFineAmount() async {
    final row = await _row();
    return (row['fine_amount'] as num?)?.toDouble() ?? 100.0;
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
    final db = await _db;

    await db.update(
      'app_settings',
      {
        'fine_amount': amount,
        'fine_due_day': dueDay,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ---------------------------------------------------------------------------
  // Backup
  // ---------------------------------------------------------------------------

  @override
  Future<String?> getBackupFolderPath() async {
    final row = await _row();
    return row['backup_folder_path'] as String?;
  }

  @override
  Future<void> setBackupFolderPath(String? path) async {
    final db = await _db;

    await db.update(
      'app_settings',
      {'backup_folder_path': path},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  @override
  Future<String?> getLastBackupAt() async {
    final row = await _row();
    return row['last_backup_at'] as String?;
  }

  @override
  Future<void> setLastBackupAt(String value) async {
    final db = await _db;

    await db.update(
      'app_settings',
      {'last_backup_at': value},
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}