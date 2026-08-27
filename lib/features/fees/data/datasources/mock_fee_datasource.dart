import '../models/fee_payment_model.dart';
import '../models/fee_transaction_model.dart';
import '../models/student_fee_summary_model.dart';
import 'fee_data_source.dart';

class MockFeeDataSource implements FeeDataSource {
  final List<FeeTransaction> _transactions = [
    // -------------------------------------------------------------------------
    // Student 1 - Ayesha
    // -------------------------------------------------------------------------
    const FeeTransaction(
      id: 1,
      studentId: 1,
      date: '2026-08-01',
      feeMonth: 'August 2026',
      description: 'Monthly Hostel Fee',
      debit: 15000,
      credit: 0,
      balance: 15000,
      type: FeeTransactionType.charge,
    ),

    const FeeTransaction(
      id: 2,
      studentId: 1,
      date: '2026-08-05',
      feeMonth: 'August 2026',
      description: 'Fee Payment',
      debit: 0,
      credit: 10000,
      balance: 5000,
      type: FeeTransactionType.payment,
    ),

    // -------------------------------------------------------------------------
    // Student 2 - Sara
    // -------------------------------------------------------------------------
    const FeeTransaction(
      id: 3,
      studentId: 2,
      date: '2026-08-01',
      feeMonth: 'August 2026',
      description: 'Monthly Hostel Fee',
      debit: 25000,
      credit: 0,
      balance: 25000,
      type: FeeTransactionType.charge,
    ),

    const FeeTransaction(
      id: 4,
      studentId: 2,
      date: '2026-08-08',
      feeMonth: 'August 2026',
      description: 'Fee Payment',
      debit: 0,
      credit: 15000,
      balance: 10000,
      type: FeeTransactionType.payment,
    ),

    // -------------------------------------------------------------------------
    // Student 3 - Hamza
    // -------------------------------------------------------------------------
    const FeeTransaction(
      id: 5,
      studentId: 3,
      date: '2026-08-01',
      feeMonth: 'August 2026',
      description: 'Monthly Hostel Fee',
      debit: 18000,
      credit: 0,
      balance: 18000,
      type: FeeTransactionType.charge,
    ),

    const FeeTransaction(
      id: 6,
      studentId: 3,
      date: '2026-08-10',
      feeMonth: 'August 2026',
      description: 'Fee Payment',
      debit: 0,
      credit: 8000,
      balance: 10000,
      type: FeeTransactionType.payment,
    ),

    // -------------------------------------------------------------------------
    // Student 4 - Ali
    // -------------------------------------------------------------------------
    const FeeTransaction(
      id: 7,
      studentId: 4,
      date: '2026-08-01',
      feeMonth: 'August 2026',
      description: 'Monthly Hostel Fee',
      debit: 30000,
      credit: 0,
      balance: 30000,
      type: FeeTransactionType.charge,
    ),

    const FeeTransaction(
      id: 8,
      studentId: 4,
      date: '2026-08-12',
      feeMonth: 'August 2026',
      description: 'Fee Payment',
      debit: 0,
      credit: 25000,
      balance: 5000,
      type: FeeTransactionType.payment,
    ),
  ];

  final List<FeePayment> _payments = [
    // -------------------------------------------------------------------------
    // Student 1 - Ayesha
    // -------------------------------------------------------------------------
    const FeePayment(
      id: 1,
      studentId: 1,
      feeMonth: 'August 2026',
      currentMonthFee: 15000,
      previousBalance: 0,
      fine: 0,
      discount: 0,
      amountReceived: 10000,
      paymentMethod: PaymentMethod.cash,
      paymentReference: 'PAY-001',
      notes: 'Partial payment',
      paymentDate: '2026-08-05',
    ),

    // -------------------------------------------------------------------------
    // Student 2 - Sara
    // -------------------------------------------------------------------------
    const FeePayment(
      id: 2,
      studentId: 2,
      feeMonth: 'August 2026',
      currentMonthFee: 25000,
      previousBalance: 5000,
      fine: 1000,
      discount: 2000,
      amountReceived: 15000,
      paymentMethod: PaymentMethod.bankTransfer,
      paymentReference: 'BANK-002',
      notes: 'Bank transfer with partial payment',
      paymentDate: '2026-08-08',
    ),

    // -------------------------------------------------------------------------
    // Student 3 - Hamza
    // -------------------------------------------------------------------------
    const FeePayment(
      id: 3,
      studentId: 3,
      feeMonth: 'August 2026',
      currentMonthFee: 18000,
      previousBalance: 0,
      fine: 500,
      discount: 500,
      amountReceived: 8000,
      paymentMethod: PaymentMethod.onlinePayment,
      paymentReference: 'ONLINE-003',
      notes: 'Online payment with partial payment',
      paymentDate: '2026-08-10',
    ),

    // -------------------------------------------------------------------------
    // Student 4 - Ali
    // -------------------------------------------------------------------------
    const FeePayment(
      id: 4,
      studentId: 4,
      feeMonth: 'August 2026',
      currentMonthFee: 30000,
      previousBalance: 0,
      fine: 0,
      discount: 0,
      amountReceived: 25000,
      paymentMethod: PaymentMethod.cheque,
      paymentReference: 'CHQ-004',
      notes: 'Cheque payment',
      paymentDate: '2026-08-12',
    ),
  ];

  final List<StudentFeeSummary> _summaries = [
    // -------------------------------------------------------------------------
    // Student 1 - Ayesha
    // -------------------------------------------------------------------------
    const StudentFeeSummary(
      studentId: 1,
      feeCharged: 15000,
      feeSubmitted: 10000,
      feePending: 5000,
    ),

    // -------------------------------------------------------------------------
    // Student 2 - Sara
    // -------------------------------------------------------------------------
    const StudentFeeSummary(
      studentId: 2,
      feeCharged: 25000,
      feeSubmitted: 15000,
      feePending: 10000,
    ),

    // -------------------------------------------------------------------------
    // Student 3 - Hamza
    // -------------------------------------------------------------------------
    const StudentFeeSummary(
      studentId: 3,
      feeCharged: 18000,
      feeSubmitted: 8000,
      feePending: 10000,
    ),

    // -------------------------------------------------------------------------
    // Student 4 - Ali
    // -------------------------------------------------------------------------
    const StudentFeeSummary(
      studentId: 4,
      feeCharged: 30000,
      feeSubmitted: 25000,
      feePending: 5000,
    ),
  ];

  @override
  Future<List<FeeTransaction>> getTransactions() async {
    return List.unmodifiable(_transactions);
  }

  @override
  Future<List<FeePayment>> getPayments() async {
    return List.unmodifiable(_payments);
  }

  @override
  Future<List<StudentFeeSummary>> getStudentFeeSummaries() async {
    return List.unmodifiable(_summaries);
  }

  @override
  Future<StudentFeeSummary?> getStudentFeeSummary(int studentId) async {
    for (final summary in _summaries) {
      if (summary.studentId == studentId) {
        return summary;
      }
    }

    return null;
  }

  @override
  Future<void> addPayment(FeePayment payment) async {
    _payments.add(payment);
  }

  @override
  Future<void> addTransaction(FeeTransaction transaction) async {
    _transactions.add(transaction);
  }
}
