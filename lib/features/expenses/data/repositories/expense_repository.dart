import '../datasources/expense_data_source.dart';
import '../../models/expense_model.dart';

class ExpenseRepository {
  final ExpenseDataSource dataSource;

  ExpenseRepository(
    this.dataSource,
  );

  Future<List<ExpenseModel>> getExpenses() {
    return dataSource.getExpenses();
  }

  Future<void> addExpense(
    ExpenseModel expense,
  ) {
    return dataSource.addExpense(
      expense,
    );
  }

  Future<void> updateExpense(
    ExpenseModel expense,
  ) {
    return dataSource.updateExpense(
      expense,
    );
  }

  Future<void> deleteExpense(
    String expenseId,
  ) {
    return dataSource.deleteExpense(
      expenseId,
    );
  }
}