import '../models/fee_payment_model.dart';
import '../models/fee_transaction_model.dart';
import '../models/student_fee_summary_model.dart';

abstract class FeeDataSource {
  Future<List<FeeTransaction>> getTransactions();

  Future<List<FeePayment>> getPayments();

  /// A single payment by its primary key — used right after recording a
  /// payment to pick up fields the app doesn't set itself (`receiptNo`,
  /// assigned by the database on insert) without re-fetching every
  /// payment/transaction/summary just for that one row. Returns null if
  /// no such payment exists (or it's been soft-deleted).
  Future<FeePayment?> getPaymentById(String id);

  Future<List<StudentFeeSummary>> getStudentFeeSummaries();

  Future<StudentFeeSummary?> getStudentFeeSummary(String studentId);

  Future<void> addPayment(FeePayment payment);

  Future<void> addTransaction(FeeTransaction transaction);

  // ---------------------------------------------------------------------------
  // Records a payment together with its ledger transaction(s) as a single
  // atomic unit — either all of it is saved, or none of it is. This is
  // what FeeController.submitPayment() actually calls (addPayment() and
  // addTransaction() above are otherwise unused single-row helpers).
  //
  // Previously, submitPayment() called addPayment()/addTransaction()
  // separately, one after another, with no atomicity between them — a
  // failure partway through (a dropped connection between steps, a crash)
  // could leave a payment recorded with no matching ledger entry, or a
  // charge posted with no payment against it. That risk was always
  // present but low with purely local SQLite writes; it becomes a real,
  // regularly-possible failure mode once a datasource is talking to a
  // network backend instead.
  // ---------------------------------------------------------------------------
  Future<void> recordPayment({
    required FeePayment payment,
    FeeTransaction? chargeTransaction,
    required FeeTransaction paymentTransaction,
  });
}
