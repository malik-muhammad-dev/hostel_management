import 'package:get/get.dart';

import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../fees/presentation/controllers/fee_controller.dart';
import '../../../settings/presentation/controllers/app_settings_controller.dart';
import '../../../students/data/models/student_model.dart';
import '../../../students/presentation/controllers/student_controller.dart';

// =============================================================================
// DASHBOARD CONTROLLER
//
// Pure computation over data already loaded by StudentController,
// FeeController, and ExpenseController — same pattern as ReportsController.
// No datasource/repository of its own, and deliberately does NOT read or
// write FeeController.feeTableMonth/showAllMonths (the Fees screen's own
// filter state) — the Dashboard has its own independent "current month"
// so switching months here never affects the Fees screen, and vice versa.
// =============================================================================

class DashboardController extends GetxController {
  final StudentController studentController = Get.find<StudentController>();
  final FeeController feeController = Get.find<FeeController>();
  final ExpenseController expenseController = Get.find<ExpenseController>();
  final AppSettingsController settingsController =
      Get.find<AppSettingsController>();

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _monthKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}';
  }

  String _currentMonth() => _monthKey(DateTime.now());

  // ---------------------------------------------------------------------------
  // Top stat cards
  // ---------------------------------------------------------------------------

  int get totalActiveStudents => studentController.activeStudents.length;

  double _collectedForMonth(String month) {
    return studentController.activeStudents
        .where((student) => student.id != null)
        .fold<double>(0.0, (sum, student) {
      final summary = feeController.computeFeeSummaryForMonth(
        student.id!,
        month,
      );
      return sum + summary.feeSubmitted;
    });
  }

  double get collectedThisMonth => _collectedForMonth(_currentMonth());

  double get expensesThisMonth =>
      expenseController.totalForMonth(_currentMonth());

  double get netProfitThisMonth => collectedThisMonth - expensesThisMonth;

  double get expectedThisMonth {
    final month = _currentMonth();
    return studentController.activeStudents
        .where((student) => student.id != null)
        .fold<double>(0.0, (sum, student) {
      final summary = feeController.computeFeeSummaryForMonth(
        student.id!,
        month,
      );
      return sum + summary.feeCharged;
    });
  }

  /// Percentage (0-100) of this month's expected fee that's actually
  /// been collected so far. Used for the greeting banner's gauge.
  double get collectionRatePercent {
    final expected = expectedThisMonth;
    if (expected <= 0) return 0;
    final rate = (collectedThisMonth / expected) * 100;
    return rate.clamp(0, 100);
  }

  // ---------------------------------------------------------------------------
  // Students who owe this month — paid vs total.
  //
  // "Owe this month" = active students actually enrolled by this month
  // (same enrollment check FeeController already uses everywhere else —
  // one definition of "owes", not a second one invented here). "Paid" =
  // that student's balance for this month is fully cleared.
  // ---------------------------------------------------------------------------

  List<StudentModel> get _studentsWhoOweThisMonth {
    final month = _currentMonth();

    return studentController.activeStudents
        .where(
          (student) =>
              student.id != null &&
              feeController.isStudentEnrolledInMonth(student, month),
        )
        .toList();
  }

  int get totalStudentsWhoOwe => _studentsWhoOweThisMonth.length;

  int get studentsPaidThisMonth {
    final month = _currentMonth();

    return _studentsWhoOweThisMonth.where((student) {
      final summary = feeController.computeFeeSummaryForMonth(
        student.id!,
        month,
      );
      final balance = summary.feePending < 0 ? 0.0 : summary.feePending;
      return balance <= 0;
    }).length;
  }

  // ---------------------------------------------------------------------------
  // Total Amount — Opening Balance + all-time collected − all-time
  // expenses.
  //
  // Deliberately NOT scoped to active students or to any single month —
  // this answers "how much money does the hostel actually have right
  // now," so it counts every payment ever recorded (even one from a
  // student who has since become inactive/archived — that money was
  // still genuinely received) and every expense ever recorded.
  // ---------------------------------------------------------------------------

  double get allTimeCollected => feeController.payments.fold<double>(
        0.0,
        (sum, payment) => sum + payment.amountReceived,
      );

  double get allTimeExpenses => expenseController.expenses.fold<double>(
        0.0,
        (sum, expense) => sum + expense.amount,
      );

  double get totalAmount =>
      settingsController.openingBalance.value +
      allTimeCollected -
      allTimeExpenses;

  double get openingBalance => settingsController.openingBalance.value;

  Future<void> setOpeningBalance(double value) {
    return settingsController.setOpeningBalance(value);
  }

  // ---------------------------------------------------------------------------
  // Expense breakdown (current month) — feeds the pie chart
  // ---------------------------------------------------------------------------

  Map<String, double> get expenseBreakdownThisMonth {
    final month = _currentMonth();
    final monthExpenses = expenseController.expensesForMonth(month);

    final Map<String, double> byCategory = {};
    for (final expense in monthExpenses) {
      byCategory[expense.category] =
          (byCategory[expense.category] ?? 0) + expense.amount;
    }

    return byCategory;
  }

  // ---------------------------------------------------------------------------
  // 6-month trend — Collected vs Expenses, feeds the bar chart
  // ---------------------------------------------------------------------------

  List<MonthlyTrendPoint> get last6MonthsTrend {
    final now = DateTime.now();
    final points = <MonthlyTrendPoint>[];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i);
      final month = _monthKey(date);

      points.add(
        MonthlyTrendPoint(
          monthLabel: _monthNames[date.month - 1],
          collected: _collectedForMonth(month),
          expenses: expenseController.totalForMonth(month),
        ),
      );
    }

    return points;
  }

  // ---------------------------------------------------------------------------
  // Recent activity — latest fee payments + expenses, combined
  // ---------------------------------------------------------------------------

  List<RecentActivityItem> get recentActivity {
    final feeItems = feeController.payments.map((payment) {
      final student = studentController.students.firstWhereOrNull(
        (student) => student.id == payment.studentId,
      );

      return RecentActivityItem(
        title: student?.name ?? 'Unknown Student',
        subtitle: 'Fee Payment',
        amount: payment.amountReceived,
        date: DateTime.tryParse(payment.paymentDate) ?? DateTime.now(),
        isIncome: true,
      );
    });

    final expenseItems = expenseController.expenses.map((expense) {
      return RecentActivityItem(
        title: expense.category,
        subtitle: (expense.description?.isNotEmpty ?? false)
            ? expense.description!
            : 'Expense',
        amount: expense.amount,
        date: expense.date,
        isIncome: false,
      );
    });

    final combined = [...feeItems, ...expenseItems]
      ..sort((a, b) => b.date.compareTo(a.date));

    return combined.take(6).toList();
  }
}

class MonthlyTrendPoint {
  final String monthLabel;
  final double collected;
  final double expenses;

  const MonthlyTrendPoint({
    required this.monthLabel,
    required this.collected,
    required this.expenses,
  });
}

class RecentActivityItem {
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final bool isIncome;

  const RecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.isIncome,
  });
}