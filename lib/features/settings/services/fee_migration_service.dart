import 'package:supabase_flutter/supabase_flutter.dart';

import '../../fees/data/datasources/sqlite_fee_data_source.dart';

// =============================================================================
// FEE MIGRATION SERVICE
//
// One-time utility: copies every fee transaction and fee payment already
// in local SQLite into Supabase. Same purpose and same care as
// StudentMigrationService — see that file for the full reasoning on why
// ids are preserved exactly and why created_at is synthetic.
//
// Unlike normal ongoing writes (which go through
// SupabaseFeeDataSource.recordPayment(), one atomic payment at a time),
// this migration is a bulk copy of records that were already committed
// locally — there's no "payment + its transaction(s)" pairing logic to
// re-run, just every existing row, faithfully copied. Inserted in
// batches (not one row at a time) for speed, and NOT through the
// record_fee_payment() database function, which exists for the ongoing
// one-payment-at-a-time write path, not bulk historical import.
// =============================================================================

class FeeMigrationResult {
  final int localTransactionCount;
  final int migratedTransactionCount;
  final int localPaymentCount;
  final int migratedPaymentCount;
  final List<String> failures;

  const FeeMigrationResult({
    required this.localTransactionCount,
    required this.migratedTransactionCount,
    required this.localPaymentCount,
    required this.migratedPaymentCount,
    required this.failures,
  });

  bool get isFullSuccess =>
      failures.isEmpty &&
      migratedTransactionCount == localTransactionCount &&
      migratedPaymentCount == localPaymentCount;
}

class FeeMigrationService {
  static const _batchSize = 200;

  SupabaseClient get _client => Supabase.instance.client;

  Future<int> countExistingSupabaseTransactions() async {
    final rows = await _client.from('fee_transactions').select('id');
    return rows.length;
  }

  Future<int> countExistingSupabasePayments() async {
    final rows = await _client.from('fee_payments').select('id');
    return rows.length;
  }

  Future<FeeMigrationResult> migrateLocalFeesToSupabase() async {
    final localDataSource = SqliteFeeDataSource();

    final localTransactions = await localDataSource.getTransactions();
    final localPayments = await localDataSource.getPayments();

    final failures = <String>[];

    final migratedTransactions = await _migrateInBatches(
      table: 'fee_transactions',
      count: localTransactions.length,
      buildRow: (index) {
        final transaction = localTransactions[index];
        final timestampIso = _syntheticTimestamp(
          index,
          localTransactions.length,
        );

        return transaction.toMap()
          ..['created_at'] = timestampIso
          ..['updated_at'] = timestampIso
          ..['deleted_at'] = null;
      },
      describeRow: (index) {
        final transaction = localTransactions[index];
        return '${transaction.feeMonth} ${transaction.type.name} '
            '(id: ${transaction.id})';
      },
      onFailure: failures.add,
    );

    final migratedPayments = await _migrateInBatches(
      table: 'fee_payments',
      count: localPayments.length,
      buildRow: (index) {
        final payment = localPayments[index];
        final timestampIso = _syntheticTimestamp(index, localPayments.length);

        return payment.toMap()
          ..['created_at'] = timestampIso
          ..['updated_at'] = timestampIso
          ..['deleted_at'] = null;
      },
      describeRow: (index) {
        final payment = localPayments[index];
        return '${payment.feeMonth} payment (id: ${payment.id})';
      },
      onFailure: failures.add,
    );

    return FeeMigrationResult(
      localTransactionCount: localTransactions.length,
      migratedTransactionCount: migratedTransactions,
      localPaymentCount: localPayments.length,
      migratedPaymentCount: migratedPayments,
      failures: failures,
    );
  }

  /// Strictly increasing, one second apart, in original local order —
  /// same reasoning as StudentMigrationService: there's no real
  /// historical "when was this recorded" to draw from, so this preserves
  /// relative order honestly without claiming a false precise date.
  String _syntheticTimestamp(int index, int total) {
    final base = DateTime.now().toUtc().subtract(Duration(seconds: total));
    return base.add(Duration(seconds: index)).toIso8601String();
  }

  Future<int> _migrateInBatches({
    required String table,
    required int count,
    required Map<String, Object?> Function(int index) buildRow,
    required String Function(int index) describeRow,
    required void Function(String) onFailure,
  }) async {
    var migrated = 0;

    for (var start = 0; start < count; start += _batchSize) {
      final end = (start + _batchSize > count) ? count : start + _batchSize;
      final batch = [for (var i = start; i < end; i++) buildRow(i)];

      try {
        await _client.from(table).insert(batch);
        migrated += batch.length;
      } catch (e) {
        // A batch failure doesn't tell us which row in it was the
        // problem, so fall back to inserting this batch one row at a
        // time — slower, but pinpoints exactly which record failed
        // and lets every other row in the batch still go through.
        for (var i = start; i < end; i++) {
          try {
            await _client.from(table).insert(buildRow(i));
            migrated++;
          } catch (rowError) {
            onFailure('${describeRow(i)} — $rowError');
          }
        }
      }
    }

    return migrated;
  }
}