import 'package:get/get.dart';

import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../fees/presentation/controllers/fee_controller.dart';
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