import '../../models/expense_model.dart';

abstract class ExpenseDataSource {
  Future<List<ExpenseModel>> getExpenses();

  /// A single expense by its primary key — used right after saving one
  /// to pick up `voucherNo` (assigned by the database on insert) without
  /// re-fetching every expense just for that one row. Returns null if no
  /// such expense exists (or it's been soft-deleted).
  Future<ExpenseModel?> getExpenseById(String id);

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