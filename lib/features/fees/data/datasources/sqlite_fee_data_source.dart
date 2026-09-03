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
// Note on IDs: the `id` column is now a client-generated UUID (TEXT
// PRIMARY KEY, no AUTOINCREMENT), the same as every other table.
// FeeController assigns the id (a v4 UUID) before calling
// addTransaction()/addPayment() — this datasource just inserts whatever
// id is already on the model, it never relies on SQLite to generate or
// return one. Same pattern as SqliteStudentDataSource.
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
    // Ordered by rowid, not the `id` column — `id` is a UUID now (no
    // ordering meaning at all), but every ordinary SQLite table still
    // keeps an implicit, auto-incrementing `rowid` behind the scenes
    // unless declared WITHOUT ROWID (this one isn't), so `rowid` still
    // reflects insertion order exactly the way the old integer `id` did.
    final rows = await db.query('fee_transactions', orderBy: 'rowid ASC');
    return rows.map(FeeTransaction.fromMap).toList();
  }

  @override
  Future<List<FeePayment>> getPayments() async {
    final db = await _db;
    final rows = await db.query('fee_payments', orderBy: 'rowid ASC');
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
        studentId: row['student_id'] as String,
        feeCharged: charged,
        feeSubmitted: submitted,
        feePending: charged - submitted,
      );
    }).toList();
  }

  @override
  Future<StudentFeeSummary?> getStudentFeeSummary(String studentId) async {
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

  @override
  Future<void> recordPayment({
    required FeePayment payment,
    FeeTransaction? chargeTransaction,
    required FeeTransaction paymentTransaction,
  }) async {
    final db = await _db;

    // db.transaction() gives SQLite's own atomicity — either every insert
    // below commits together, or (on any error) none of them do. See the
    // note on FeeDataSource.recordPayment() for why this matters.
    await db.transaction((txn) async {
      await txn.insert(
        'fee_payments',
        payment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      if (chargeTransaction != null) {
        await txn.insert(
          'fee_transactions',
          chargeTransaction.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      await txn.insert(
        'fee_transactions',
        paymentTransaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }
}