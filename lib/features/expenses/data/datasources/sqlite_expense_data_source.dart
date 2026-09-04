import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../models/expense_model.dart';
import 'expense_data_source.dart';

class SqliteExpenseDataSource implements ExpenseDataSource {
  Future<Database> get _db async => AppDatabase.instance.database;

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    final db = await _db;
    // Ordered by rowid, not `id` — `id` is now a UUID with no ordering
    // meaning, but every ordinary SQLite table keeps an implicit
    // auto-incrementing `rowid` (this one isn't WITHOUT ROWID), so it
    // still reflects insertion order the way the old integer `id` did.
    final rows = await db.query('expenses', orderBy: 'rowid ASC');
    return rows.map(ExpenseModel.fromMap).toList();
  }

  @override
  Future<ExpenseModel?> getExpenseById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return ExpenseModel.fromMap(rows.first);
  }

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    final db = await _db;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    if (expense.id == null) return;

    final db = await _db;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    final db = await _db;
    await db.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
  }
}