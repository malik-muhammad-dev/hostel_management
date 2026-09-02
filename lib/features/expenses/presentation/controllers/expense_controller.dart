import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/expense_repository.dart';
import '../../models/expense_model.dart';

class ExpenseController extends GetxController {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final ExpenseRepository repository;

  ExpenseController(this.repository);

  // ===========================================================================
  // FORM CONTROLLERS
  // ===========================================================================

  final dateController = TextEditingController();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final customCategoryController = TextEditingController();

  final category = Rxn<String>();

  bool get isCustomCategory => category.value == 'Custom';

  // ===========================================================================
  // PAYMENT METHOD
  // ===========================================================================

  final paymentMode = Rxn<ExpensePaymentMode>();

  // ===========================================================================
  // EXPENSE DATA
  // ===========================================================================

  final expenses = <ExpenseModel>[].obs;

  // ===========================================================================
  // UI STATE
  // ===========================================================================

  final isSaving = false.obs;
  final isLoading = false.obs;

  // ===========================================================================
  // EDITING
  // ===========================================================================

  final editingExpense = Rxn<ExpenseModel>();

  bool get isEditMode => editingExpense.value != null;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void onInit() {
    super.onInit();

    dateController.text = _formatDate(
      DateTime.now(),
    );

    selectedMonth.value = _monthKey(DateTime.now());

    loadExpenses();
  }

  @override
  void onClose() {
    dateController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    customCategoryController.dispose();

    super.onClose();
  }

  // ===========================================================================
  // LOAD EXPENSES
  // ===========================================================================

  Future<void> loadExpenses() async {
    try {
      isLoading.value = true;

      final result = await repository.getExpenses();

      expenses.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // DATE
  // ===========================================================================

  void setDate(DateTime date) {
    dateController.text = _formatDate(date);
  }

  DateTime? get selectedDate {
    final value = dateController.text.trim();

    if (value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  void setCategory(String? value) {
    category.value = value;
    if (value != 'Custom') {
      customCategoryController.clear();
    }
  }

  // ===========================================================================
  // PAYMENT MODE
  // ===========================================================================

  void setPaymentMode(
    ExpensePaymentMode? mode,
  ) {
    paymentMode.value = mode;
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  String? validate() {
    // -------------------------------------------------------------------------
    // Date
    // -------------------------------------------------------------------------

    final dateText = dateController.text.trim();

    if (dateText.isEmpty) {
      return 'Please select an expense date.';
    }

    final date = DateTime.tryParse(dateText);

    if (date == null) {
      return 'Please enter a valid expense date.';
    }

    // -------------------------------------------------------------------------
    // Category
    // -------------------------------------------------------------------------

    if (category.value == null) {
      return 'Please select a category.';
    }

    if (category.value == 'Custom' &&
        customCategoryController.text.trim().isEmpty) {
      return 'Please enter the custom category name.';
    }

    // -------------------------------------------------------------------------
    // Amount
    // -------------------------------------------------------------------------

    final amountText = amountController.text.trim();

    if (amountText.isEmpty) {
      return 'Please enter the total amount.';
    }

    final amount = double.tryParse(amountText);

    if (amount == null) {
      return 'Please enter a valid amount.';
    }

    if (amount <= 0) {
      return 'Total amount must be greater than zero.';
    }

    // -------------------------------------------------------------------------
    // Payment mode
    // -------------------------------------------------------------------------

    if (paymentMode.value == null) {
      return 'Please select a payment method.';
    }

    return null;
  }

  // ===========================================================================
  // BUILD MODEL
  // ===========================================================================

  ExpenseModel? buildExpenseModel() {
    final validationMessage = validate();

    if (validationMessage != null) {
      return null;
    }

    final date = selectedDate;

    final amount = double.tryParse(
      amountController.text.trim(),
    );

    final mode = paymentMode.value;

    if (date == null || amount == null || mode == null) {
      return null;
    }

    final description =
        descriptionController.text.trim();

    final resolvedCategory = category.value == 'Custom'
        ? customCategoryController.text.trim()
        : category.value!;

    return ExpenseModel(
      id: editingExpense.value?.id,
      date: date,
      category: resolvedCategory,
      amount: amount,
      description:
          description.isEmpty ? null : description,
      paymentMode: mode,
    );
  }

  // ===========================================================================
  // ADD EXPENSE
  // ===========================================================================

  Future<ExpenseModel?> addExpense() async {
    final expense = buildExpenseModel();

    if (expense == null) {
      return null;
    }

    try {
      isSaving.value = true;

      final savedExpense = expense.copyWith(
        id: const Uuid().v4(),
      );

      debugPrint(
        '[DEBUG] addExpense: about to insert id=${savedExpense.id}, '
        'category=${savedExpense.category}, amount=${savedExpense.amount}',
      );

      await repository.addExpense(
        savedExpense,
      );

      debugPrint('[DEBUG] addExpense: repository.addExpense() completed without throwing');

      expenses.add(savedExpense);

      clearForm();

      return savedExpense;
    } catch (e, stackTrace) {
      debugPrint('[DEBUG] addExpense failed: $e');
      debugPrint('[DEBUG] stackTrace: $stackTrace');
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  // ===========================================================================
  // UPDATE EXPENSE
  // ===========================================================================

  Future<bool> updateExpense() async {
    final expense = buildExpenseModel();

    if (expense == null || expense.id == null) {
      return false;
    }

    try {
      isSaving.value = true;

      await repository.updateExpense(
        expense,
      );

      final index = expenses.indexWhere(
        (item) => item.id == expense.id,
      );

      if (index == -1) {
        return false;
      }

      expenses[index] = expense;

      clearForm();

      return true;
    } catch (e) {
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ===========================================================================
  // DELETE EXPENSE
  // ===========================================================================

  Future<bool> deleteExpense(
    String expenseId,
  ) async {
    try {
      isLoading.value = true;

      final exists = expenses.any(
        (expense) => expense.id == expenseId,
      );

      if (!exists) {
        return false;
      }

      await repository.deleteExpense(
        expenseId,
      );

      expenses.removeWhere(
        (expense) => expense.id == expenseId,
      );

      return true;
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // EDIT EXPENSE
  // ===========================================================================

  void editExpense(
    ExpenseModel expense,
  ) {
    editingExpense.value = expense;

    dateController.text =
        _formatDate(expense.date);

    amountController.text =
        expense.amount.toStringAsFixed(2);

    descriptionController.text =
        expense.description ?? '';

    paymentMode.value =
        expense.paymentMode;

    // A stored category that isn't one of the fixed options must have
    // been entered as "Custom" originally — reselect Custom and put the
    // actual value back into the custom field, rather than silently
    // losing it or crashing the dropdown on an unrecognized value.
    final knownCategories = kExpenseCategories.where((c) => c != 'Custom');
    if (knownCategories.contains(expense.category)) {
      category.value = expense.category;
      customCategoryController.clear();
    } else {
      category.value = 'Custom';
      customCategoryController.text = expense.category;
    }
  }

  // ===========================================================================
  // CLEAR FORM
  // ===========================================================================

  void clearForm() {
    editingExpense.value = null;

    dateController.text =
        _formatDate(DateTime.now());

    amountController.clear();

    descriptionController.clear();

    customCategoryController.clear();

    category.value = null;

    paymentMode.value = null;
  }

  // ===========================================================================
  // MONTH FILTER
  //
  // Stored as "YYYY-MM" (e.g. "2026-08") — the same format used by the
  // Fees feature's month filter/selector, so any future cross-feature
  // reporting (e.g. Reports: income vs expenses for a given month) can
  // compare the two directly without a format mismatch.
  // ===========================================================================

  final selectedMonth = ''.obs;

  void setSelectedMonth(String month) {
    selectedMonth.value = month;
  }

  String _monthKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}';
  }

  List<ExpenseModel> expensesForMonth(String month) {
    return expenses
        .where((expense) => _monthKey(expense.date) == month)
        .toList();
  }

  double totalForMonth(String month) {
    return expensesForMonth(month).fold<double>(
      0.0,
      (total, expense) => total + expense.amount,
    );
  }

  double cashForMonth(String month) {
    return expensesForMonth(month)
        .where(
          (expense) => expense.paymentMode == ExpensePaymentMode.cash,
        )
        .fold<double>(0.0, (total, expense) => total + expense.amount);
  }

  double accountForMonth(String month) {
    return expensesForMonth(month)
        .where(
          (expense) => expense.paymentMode == ExpensePaymentMode.account,
        )
        .fold<double>(0.0, (total, expense) => total + expense.amount);
  }

  // ===========================================================================
  // SUMMARY
  //
  // All-time totals — kept for completeness/future use, but the Expenses
  // screen itself displays the month-scoped totals above by default.
  // ===========================================================================

  double get totalExpenses {
    return expenses.fold<double>(
      0.0,
      (total, expense) =>
          total + expense.amount,
    );
  }

  double get cashExpenses {
    return expenses
        .where(
          (expense) =>
              expense.paymentMode ==
              ExpensePaymentMode.cash,
        )
        .fold<double>(
          0.0,
          (total, expense) =>
              total + expense.amount,
        );
  }

  double get accountExpenses {
    return expenses
        .where(
          (expense) =>
              expense.paymentMode ==
              ExpensePaymentMode.account,
        )
        .fold<double>(
          0.0,
          (total, expense) =>
              total + expense.amount,
        );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}