import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../models/receipt_model.dart';
import 'receipt_data_source.dart';

class SqliteReceiptDataSource implements ReceiptDataSource {
  Future<Database> get _db async => AppDatabase.instance.database;

  @override
  Future<List<ReceiptModel>> getReceipts() async {
    final db = await _db;
    final rows = await db.query('cash_receipts', orderBy: 'id ASC');
    return rows.map(ReceiptModel.fromMap).toList();
  }

  @override
  Future<void> addReceipt(ReceiptModel receipt) async {
    final db = await _db;
    await db.insert(
      'cash_receipts',
      receipt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateReceipt(ReceiptModel receipt) async {
    if (receipt.id == null) return;

    final db = await _db;
    await db.update(
      'cash_receipts',
      receipt.toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  @override
  Future<void> deleteReceipt(String receiptId) async {
    final db = await _db;
    await db.delete('cash_receipts', where: 'id = ?', whereArgs: [receiptId]);
  }
}