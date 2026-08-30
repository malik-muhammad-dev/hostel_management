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
}