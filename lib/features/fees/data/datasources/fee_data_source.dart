import '../models/fee_payment_model.dart';
import '../models/fee_transaction_model.dart';
import '../models/student_fee_summary_model.dart';

abstract class FeeDataSource {
  Future<List<FeeTransaction>> getTransactions();

  Future<List<FeePayment>> getPayments();

  Future<List<StudentFeeSummary>> getStudentFeeSummaries();

  Future<StudentFeeSummary?> getStudentFeeSummary(int studentId);

  Future<void> addPayment(FeePayment payment);

  Future<void> addTransaction(FeeTransaction transaction);
}
