import '../../models/expense_model.dart';

abstract class ExpenseDataSource {
  Future<List<ExpenseModel>> getExpenses();

  Future<void> addExpense(
    ExpenseModel expense,
  );

  Future<void> updateExpense(
    ExpenseModel expense,
  );

  Future<void> deleteExpense(
    String expenseId,
  );
}