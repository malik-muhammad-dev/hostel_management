import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../core/database/app_database.dart';
import '../models/app_user_model.dart';
import 'auth_data_source.dart';

class SqliteAuthDataSource implements AuthDataSource {
  Future<Database> get _db async => AppDatabase.instance.database;

  @override
  Future<AppUser?> getUserByUsername(String username) async {
    final db = await _db;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  @override
  Future<void> addUser(AppUser user) async {
    final db = await _db;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<int> countUsers() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}