import '../datasources/fee_data_source.dart';
import '../models/fee_payment_model.dart';
import '../models/fee_transaction_model.dart';
import '../models/student_fee_summary_model.dart';

class FeeRepository {
  final FeeDataSource dataSource;

  FeeRepository(this.dataSource);

  Future<List<FeeTransaction>> getTransactions() {
    return dataSource.getTransactions();
  }

  Future<List<FeePayment>> getPayments() {
    return dataSource.getPayments();
  }

  Future<FeePayment?> getPaymentById(String id) {
    return dataSource.getPaymentById(id);
  }

  Future<List<StudentFeeSummary>> getStudentFeeSummaries() {
    return dataSource.getStudentFeeSummaries();
  }

  Future<StudentFeeSummary?> getStudentFeeSummary(String studentId) {
    return dataSource.getStudentFeeSummary(studentId);
  }

  Future<void> addPayment(FeePayment payment) {
    return dataSource.addPayment(payment);
  }

  Future<void> addTransaction(FeeTransaction transaction) {
    return dataSource.addTransaction(transaction);
  }

  Future<void> recordPayment({
    required FeePayment payment,
    FeeTransaction? chargeTransaction,
    required FeeTransaction paymentTransaction,
  }) {
    return dataSource.recordPayment(
      payment: payment,
      chargeTransaction: chargeTransaction,
      paymentTransaction: paymentTransaction,
    );
  }
}
