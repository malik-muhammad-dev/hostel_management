import '../../models/expense_model.dart';
import 'expense_data_source.dart';

class MockExpenseDataSource implements ExpenseDataSource {
  final List<ExpenseModel> _expenses = [];

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    return List<ExpenseModel>.from(_expenses);
  }

  @override
  Future<void> addExpense(
    ExpenseModel expense,
  ) async {
    _expenses.add(expense);
  }

  @override
  Future<void> updateExpense(
    ExpenseModel expense,
  ) async {
    if (expense.id == null) {
      throw Exception(
        'Expense ID is required for update.',
      );
    }

    final index = _expenses.indexWhere(
      (item) => item.id == expense.id,
    );

    if (index == -1) {
      throw Exception(
        'Expense not found.',
      );
    }

    _expenses[index] = expense;
  }

  @override
  Future<void> deleteExpense(
    String expenseId,
  ) async {
    _expenses.removeWhere(
      (expense) => expense.id == expenseId,
    );
  }
}