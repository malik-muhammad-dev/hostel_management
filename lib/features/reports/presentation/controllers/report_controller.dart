import 'package:get/get.dart';

import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../fees/presentation/controllers/fee_controller.dart';
import '../../../students/presentation/controllers/student_controller.dart';

class ReportsController extends GetxController {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final FeeController feeController =
      Get.find<FeeController>();

  final ExpenseController expenseController =
      Get.find<ExpenseController>();

  final StudentController studentController =
      Get.find<StudentController>();

  // ===========================================================================
  // SELECTED MONTH
  //
  // Always stored as YYYY-MM.
  // Example: 2026-08
  // ===========================================================================

  final selectedMonth = ''.obs;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void onInit() {
    super.onInit();

    selectedMonth.value = _currentMonth();
  }

  // ===========================================================================
  // MONTH
  // ===========================================================================

  void setSelectedMonth(String month) {
    selectedMonth.value = month;
  }

  String _currentMonth() {
    final now = DateTime.now();

    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}';
  }

  // ===========================================================================
  // MONTHLY INCOME
  //
  // Income comes from fees actually submitted/collected during the
  // selected month.
  //
  // We deliberately do NOT use FeeController.collected here because
  // that value is cumulative and this report is month-scoped.
  // ===========================================================================

  double get totalIncome {
    final month = selectedMonth.value;

    if (month.isEmpty) {
      return 0.0;
    }

    return studentController.activeStudents.fold<double>(
      0.0,
      (total, student) {
        if (student.id == null) {
          return total;
        }

        final summary =
            feeController.computeFeeSummaryForMonth(
          student.id!,
          month,
        );

        return total + summary.feeSubmitted;
      },
    );
  }

  // ===========================================================================
  // MONTHLY EXPENSES
  // ===========================================================================

  double get totalExpenses {
    final month = selectedMonth.value;

    if (month.isEmpty) {
      return 0.0;
    }

    return expenseController.totalForMonth(month);
  }

  // ===========================================================================
  // NET POSITION
  // ===========================================================================

  double get netPosition {
    return totalIncome - totalExpenses;
  }
}