import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fee_payment_model.dart';
import '../models/fee_transaction_model.dart';
import '../models/student_fee_summary_model.dart';
import 'fee_data_source.dart';

// =============================================================================
// SUPABASE FEE DATA SOURCE
//
// Second feature swapped over per the migration design spec's delivery
// order (Students → Fees → Expenses → Receipts → Settings → Auth).
//
// Notes:
// - `id` is always a client-generated UUID, assigned by FeeController
//   before any write — same as every other feature.
// - Ordering: uses `created_at` (see the ALTER TABLE note delivered
//   alongside this file), not `id` — same reasoning as Students/rowid.
// - `updated_at` is set explicitly on every write, never relied on as a
//   database default, because Postgres only applies a column default on
//   INSERT, never on UPDATE. `created_at` is likewise set explicitly on
//   insert rather than left to its own default, so a single value is
//   used consistently for both this row's created_at and updated_at.
// - recordPayment() calls the `record_fee_payment` Postgres function
//   (see the SQL delivered alongside this file) instead of doing 2-3
//   separate REST calls — that function runs as one database
//   transaction, so a payment and its ledger entries are always saved
//   together or not at all, even over a network connection that can
//   fail partway through a sequence of separate calls.
// - getStudentFeeSummaries()/getStudentFeeSummary(): same as the SQLite
//   version, these aren't backed by a real table — a summary is an
//   aggregate over fee_transactions. Supabase's REST API doesn't do
//   GROUP BY aggregation directly, so this fetches the (already
//   filtered, usually small) transaction set and aggregates in Dart —
//   the exact same charge/payment math the SQLite version did in SQL.
// =============================================================================

class SupabaseFeeDataSource implements FeeDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<FeeTransaction>> getTransactions() async {
    final rows = await _client
        .from('fee_transactions')
        .select()
        .isFilter('deleted_at', null)
        .order('created_at', ascending: true);

    return rows
        .map((row) => FeeTransaction.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  @override
  Future<List<FeePayment>> getPayments() async {
    final rows = await _client
        .from('fee_payments')
        .select()
        .isFilter('deleted_at', null)
        .order('created_at', ascending: true);

    return rows
        .map((row) => FeePayment.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  @override
  Future<FeePayment?> getPaymentById(String id) async {
    // A lookup by primary key — Postgres serves this off the table's own
    // index, so it stays fast no matter how many payments have piled up
    // over time, unlike getPayments() above which fetches everything.
    final rows = await _client
        .from('fee_payments')
        .select()
        .eq('id', id)
        .isFilter('deleted_at', null)
        .limit(1);

    if (rows.isEmpty) return null;
    return FeePayment.fromMap(Map<String, Object?>.from(rows.first));
  }

  // -----------------------------------------------------------------------
  // WARNING — STALE, PRE-DISCOUNT-FIX LOGIC, still actually called.
  //
  // `_summarize()` below only has fee_transactions to work with — it has
  // no access to fee_payments.discount — so feeCharged/feePending here
  // are the OLD, undiscounted figures: the exact phantom-balance bug
  // that was fixed everywhere the app actually READS FROM (FeeController
  // computes its own summaries live via computeFeeSummary()/
  // computeFeeSummaryForMonth(), which DO correctly net out discounts).
  //
  // getStudentFeeSummaries() IS called — every time FeeController.
  // loadFeeData() runs (initial load, every realtime-sync tick, every
  // post-payment background reload) — but only to populate
  // `studentFeeSummaries`, an Rx list confirmed unread by any screen
  // today (kept "for API compatibility"). So there's no money-display
  // bug live right now, but two real costs: (1) it silently refetches
  // ALL of fee_transactions a second time on every load, on top of the
  // identical fetch already done for `transactions` in the same
  // Future.wait — wasted network/DB load that grows with data; (2) it's
  // a landmine — the moment anyone wires `studentFeeSummaries` (or
  // `getStudentFeeSummary()`) into a widget "for consistency," the
  // phantom-balance bug comes right back. Fix properly (net out
  // discount here too, and drop the duplicate fetch) before ever using
  // this for anything user-facing.
  // -----------------------------------------------------------------------

  @override
  Future<List<StudentFeeSummary>> getStudentFeeSummaries() async {
    final transactions = await getTransactions();
    return _summarize(transactions).values.toList();
  }

  @override
  Future<StudentFeeSummary?> getStudentFeeSummary(String studentId) async {
    final rows = await _client
        .from('fee_transactions')
        .select()
        .eq('student_id', studentId)
        .isFilter('deleted_at', null);

    final transactions = rows
        .map((row) => FeeTransaction.fromMap(Map<String, Object?>.from(row)))
        .toList();

    if (transactions.isEmpty) {
      return StudentFeeSummary(
        studentId: studentId,
        feeCharged: 0,
        feeSubmitted: 0,
        feePending: 0,
      );
    }

    return _summarize(transactions)[studentId];
  }

  Map<String, StudentFeeSummary> _summarize(
    List<FeeTransaction> transactions,
  ) {
    final charged = <String, double>{};
    final submitted = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type == FeeTransactionType.charge) {
        charged[transaction.studentId] =
            (charged[transaction.studentId] ?? 0) + transaction.debit;
      } else {
        submitted[transaction.studentId] =
            (submitted[transaction.studentId] ?? 0) + transaction.credit;
      }
    }

    final studentIds = {...charged.keys, ...submitted.keys};

    return {
      for (final studentId in studentIds)
        studentId: StudentFeeSummary(
          studentId: studentId,
          feeCharged: charged[studentId] ?? 0,
          feeSubmitted: submitted[studentId] ?? 0,
          feePending: (charged[studentId] ?? 0) - (submitted[studentId] ?? 0),
        ),
    };
  }

  @override
  Future<void> addPayment(FeePayment payment) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final map = payment.toMap()
      ..['created_at'] = nowIso
      ..['updated_at'] = nowIso
      ..['deleted_at'] = null;

    await _client.from('fee_payments').insert(map);
  }

  @override
  Future<void> addTransaction(FeeTransaction transaction) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final map = transaction.toMap()
      ..['created_at'] = nowIso
      ..['updated_at'] = nowIso
      ..['deleted_at'] = null;

    await _client.from('fee_transactions').insert(map);
  }

  @override
  Future<void> recordPayment({
    required FeePayment payment,
    FeeTransaction? chargeTransaction,
    required FeeTransaction paymentTransaction,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    Map<String, Object?> withTimestamps(Map<String, Object?> map) {
      return map
        ..['created_at'] = nowIso
        ..['updated_at'] = nowIso;
    }

    await _client.rpc(
      'record_fee_payment',
      params: {
        'p_payment': withTimestamps(payment.toMap()),
        'p_charge_transaction': chargeTransaction == null
            ? null
            : withTimestamps(chargeTransaction.toMap()),
        'p_payment_transaction': withTimestamps(paymentTransaction.toMap()),
      },
    );
  }

  @override
  Future<void> updateMonthlyCharge({
    required String transactionId,
    required double newDebit,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    // `.eq('type', 'charge')` is a belt-and-braces check, not the primary
    // guard — `transactionId` alone already identifies exactly one row.
    // It just guarantees this can never touch a payment-type row even if
    // a wrong id were ever passed in.
    await _client
        .from('fee_transactions')
        .update({'debit': newDebit, 'updated_at': nowIso})
        .eq('id', transactionId)
        .eq('type', 'charge');
  }
}
