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

  Future<List<StudentFeeSummary>> getStudentFeeSummaries() {
    return dataSource.getStudentFeeSummaries();
  }

  Future<StudentFeeSummary?> getStudentFeeSummary(int studentId) {
    return dataSource.getStudentFeeSummary(studentId);
  }

  Future<void> addPayment(FeePayment payment) {
    return dataSource.addPayment(payment);
  }

  Future<void> addTransaction(FeeTransaction transaction) {
    return dataSource.addTransaction(transaction);
  }
}
