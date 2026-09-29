import 'package:get/get.dart';

import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
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

  // Reused only for the "All-Time" section below (lifetimeTotalAmount and
  // its breakdown) — not for anything month-scoped above, which already
  // has its own independent logic.
  final DashboardController dashboardController =
      Get.find<DashboardController>();

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

  // ===========================================================================
  // ALL-TIME TOTAL (moved here from the Dashboard)
  //
  // This used to be the Dashboard's headline "Total Amount" card. The
  // client kept reading "Total Amount" as "how much money do I have
  // right now," but this figure is actually a lifetime running total
  // (opening balance + everything ever collected − everything ever
  // spent) — it only ever grows, and drifts further from "cash on hand"
  // every month. The Dashboard's "Total Amount" card now shows Cash +
  // Account instead (what's actually on hand today), and this lifetime
  // figure lives here as a historical record instead, correctly filed
  // under Reports rather than competing with the "right now" numbers on
  // the Dashboard.
  //
  // Reuses DashboardController's own getters rather than recomputing the
  // formula here, so this can never drift from what the Dashboard used
  // to show.
  // ===========================================================================

  double get lifetimeTotalAmount => dashboardController.totalAmount;

  double get lifetimeOpeningBalance => dashboardController.openingBalance;

  double get lifetimeCollected => dashboardController.allTimeCollected;

  double get lifetimeExpenses => dashboardController.allTimeExpenses;

  double get lifetimeStudentCashAccount =>
      dashboardController.studentCashAccountTotal;

  double get lifetimeBalanceAdded => dashboardController.balanceAddedTotal;
}