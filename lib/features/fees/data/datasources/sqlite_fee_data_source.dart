import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/fee_payment_model.dart';
import '../models/fee_transaction_model.dart';
import '../models/student_fee_summary_model.dart';
import 'fee_data_source.dart';

// =============================================================================
// SQLITE FEE DATA SOURCE
//
// Real persistence, swapped in for MockFeeDataSource once verified.
//
// Note on IDs: FeeController._nextId() already assigns the id (max
// existing id + 1) before calling addTransaction()/addPayment() — this
// datasource does NOT rely on SQLite's own AUTOINCREMENT, it inserts
// whatever id is already on the model. Same pattern as
// SqliteStudentDataSource, for the same reason: keeps the already-tested
// controller logic completely untouched during this migration.
//
// Note on getStudentFeeSummaries()/getStudentFeeSummary(): these are not
// backed by a separate table — there is no "student_fee_summary" table
// in the schema, because a summary is just an aggregate over
// fee_transactions. Computing it here with SQL SUM/GROUP BY keeps this
// datasource's contract genuinely correct (rather than a stub that
// silently does nothing), even though the Fees screen itself derives
// summaries locally in FeeController from the transactions it already
// has loaded.
// =============================================================================

class SqliteFeeDataSource implements FeeDataSource {
  Future<Database> get _db async => AppDatabase.instance.database;

  @override
  Future<List<FeeTransaction>> getTransactions() async {
    final db = await _db;
    final rows = await db.query('fee_transactions', orderBy: 'id ASC');
    return rows.map(FeeTransaction.fromMap).toList();
  }

  @override
  Future<List<FeePayment>> getPayments() async {
    final db = await _db;
    final rows = await db.query('fee_payments', orderBy: 'id ASC');
    return rows.map(FeePayment.fromMap).toList();
  }

  @override
  Future<List<StudentFeeSummary>> getStudentFeeSummaries() async {
    final db = await _db;

    final rows = await db.rawQuery('''
      SELECT
        student_id,
        SUM(CASE WHEN type = 'charge' THEN debit ELSE 0 END) AS charged,
        SUM(CASE WHEN type = 'payment' THEN credit ELSE 0 END) AS submitted
      FROM fee_transactions
      GROUP BY student_id
    ''');

    return rows.map((row) {
      final charged = (row['charged'] as num?)?.toDouble() ?? 0.0;
      final submitted = (row['submitted'] as num?)?.toDouble() ?? 0.0;

      return StudentFeeSummary(
        studentId: row['student_id'] as int,
        feeCharged: charged,
        feeSubmitted: submitted,
        feePending: charged - submitted,
      );
    }).toList();
  }

  @override
  Future<StudentFeeSummary?> getStudentFeeSummary(int studentId) async {
    final db = await _db;

    final rows = await db.rawQuery(
      '''
      SELECT
        SUM(CASE WHEN type = 'charge' THEN debit ELSE 0 END) AS charged,
        SUM(CASE WHEN type = 'payment' THEN credit ELSE 0 END) AS submitted
      FROM fee_transactions
      WHERE student_id = ?
      ''',
      [studentId],
    );

    final charged = (rows.first['charged'] as num?)?.toDouble() ?? 0.0;
    final submitted = (rows.first['submitted'] as num?)?.toDouble() ?? 0.0;

    return StudentFeeSummary(
      studentId: studentId,
      feeCharged: charged,
      feeSubmitted: submitted,
      feePending: charged - submitted,
    );
  }

  @override
  Future<void> addPayment(FeePayment payment) async {
    final db = await _db;
    await db.insert(
      'fee_payments',
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> addTransaction(FeeTransaction transaction) async {
    final db = await _db;
    await db.insert(
      'fee_transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }
}