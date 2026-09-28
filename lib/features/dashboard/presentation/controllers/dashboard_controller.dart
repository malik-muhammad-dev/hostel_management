import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../balance/models/balance_addition_model.dart';
import '../../../balance/presentation/controllers/balance_addition_controller.dart';
import '../../../expenses/models/expense_model.dart';
import '../../../expenses/presentation/controllers/expense_controller.dart';
import '../../../fees/data/models/fee_payment_model.dart';
import '../../../fees/presentation/controllers/fee_controller.dart';
import '../../../receipts/presentation/controllers/receipt_controller.dart';
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
  final ReceiptController receiptController = Get.find<ReceiptController>();
  final BalanceAdditionController balanceController =
      Get.find<BalanceAdditionController>();

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // ---------------------------------------------------------------------------
  // Still-loading check — true only on the very first load, before ANY
  // of the four underlying controllers has ever fetched anything. Once
  // real data has loaded once, this stays false forever after, even
  // while a quiet background refresh (from real-time sync) is running —
  // the skeleton should never flash back over data that's already on
  // screen, only stand in before there's anything to show at all.
  // ---------------------------------------------------------------------------

  bool get isInitialLoading {
    final anyLoading = studentController.isLoading.value ||
        feeController.isLoading.value ||
        expenseController.isLoading.value ||
        receiptController.isLoading.value ||
        balanceController.isLoading.value;

    final allEmpty = studentController.students.isEmpty &&
        feeController.payments.isEmpty &&
        feeController.transactions.isEmpty &&
        expenseController.expenses.isEmpty &&
        receiptController.receipts.isEmpty &&
        balanceController.balanceAdditions.isEmpty;

    return anyLoading && allEmpty;
  }

  String _monthKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}';
  }

  String _currentMonth() => _monthKey(DateTime.now());

  // ---------------------------------------------------------------------------
  // Top stat cards
  // ---------------------------------------------------------------------------

  // `StudentController.activeStudents` really means "not Archived" — it
  // deliberately still includes students marked 'Inactive', because
  // other features (Fees, Reports) need to keep showing/collecting from
  // someone who's Inactive, just not Archived. The Dashboard's "current
  // state of the hostel" figures are different: an Inactive student
  // should disappear from here entirely (student count, this month's
  // Collected/Expected, who-owes) until they're made Active again. This
  // filter is local to the Dashboard on purpose — it must NOT replace
  // `activeStudents` itself, which other screens still rely on.
  List<StudentModel> get _dashboardStudents => studentController
      .activeStudents
      .where((student) => student.status != 'Inactive')
      .toList();

  int get totalActiveStudents => _dashboardStudents.length;

  // NOT `_dashboardStudents` here on purpose — this is money the hostel
  // has actually already received. Same principle as allTimeCollected
  // below: if a student paid this month (or any past month, via
  // last6MonthsTrend re-using this same method) and only went Inactive
  // afterwards, that real payment must not retroactively vanish from
  // the month it was actually collected in just because of today's
  // status. Only forward-looking figures (Expected, who-owes, the
  // active count) drop an Inactive student — money already in hand
  // never does.
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
    return _dashboardStudents
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

    return _dashboardStudents
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

  double get allTimeCollected {
    debugPrint(
      '[TOTALS] --- allTimeCollected: ${feeController.payments.length} '
      'payment record(s) in memory ---',
    );

    double sum = 0.0;
    for (final payment in feeController.payments) {
      debugPrint(
        '[TOTALS]   payment id=${payment.id} studentId=${payment.studentId} '
        'feeMonth=${payment.feeMonth} amountReceived=${payment.amountReceived}',
      );
      sum += payment.amountReceived;
    }

    debugPrint('[TOTALS] allTimeCollected TOTAL = $sum');
    return sum;
  }

  double get allTimeExpenses {
    debugPrint(
      '[TOTALS] --- allTimeExpenses: ${expenseController.expenses.length} '
      'expense record(s) in memory ---',
    );

    double sum = 0.0;
    for (final expense in expenseController.expenses) {
      debugPrint(
        '[TOTALS]   expense id=${expense.id} date=${expense.date} '
        'category=${expense.category} amount=${expense.amount}',
      );
      sum += expense.amount;
    }

    debugPrint('[TOTALS] allTimeExpenses TOTAL = $sum');
    return sum;
  }

  double get totalAmount {
    final opening = settingsController.openingBalance.value;
    final collected = allTimeCollected;
    final expenses = allTimeExpenses;
    // Student Cash — client confirmed explicitly: only the "Account"
    // portion counts here, never the "Cash" portion. Real-world reason:
    // an Account-mode Student Cash entry is money genuinely arriving in
    // the hostel's bank account (even though the cashier separately
    // hands out the same amount as physical cash to the student — see
    // ReceiptController.netCashBox for that side of it). A Cash-mode
    // entry never touches this figure at all.
    final studentCashAccount = receiptController.accountReceipts;
    // Balance Additions ("Add to Total Balance") — every entry, Cash or
    // Account, counts fully here: unlike Student Cash above, there's no
    // "hands out physical cash while it lands in the bank" quirk to this
    // one — it's simply money coming in, so both sides add straight
    // through. `opening` itself is untouched by this feature on purpose
    // (see balance_addition_model.dart) — this is on top of it, not a
    // replacement for it.
    final balanceAdded = balanceController.totalAdded;
    final result =
        opening + collected - expenses + studentCashAccount + balanceAdded;

    debugPrint(
      '[TOTALS] totalAmount = openingBalance($opening) '
      '+ allTimeCollected($collected) − allTimeExpenses($expenses) '
      '+ studentCashAccount($studentCashAccount) '
      '+ balanceAdded($balanceAdded) '
      '= $result',
    );
    debugPrint(
      '[TOTALS] for comparison — THIS MONTH ONLY: '
      'collectedThisMonth=$collectedThisMonth, '
      'expensesThisMonth=$expensesThisMonth',
    );

    return result;
  }

  double get openingBalance => settingsController.openingBalance.value;

  // ---------------------------------------------------------------------------
  // Cash / Account — whole-app totals (confirmed with the client,
  // explained with their own worked example: 5 students, 50k total fee,
  // 2 paid by cash / 3 by bank = 20k Cash, 30k Account; then a 500 Rs
  // Student Cash "Account" entry moves Cash to 19,500 and Account to
  // 30,500 while Total Amount goes to 50,500).
  //
  // Two different sources feed each box, and they behave differently —
  // this is intentional, not an inconsistency:
  //
  // - FEE payments: a Cash-method payment adds to Cash; any other method
  //   (bank transfer, online, cheque) adds to Account. Nothing is ever
  //   deducted for fees — paying a fee by bank transfer doesn't involve
  //   the cashier handing out physical cash, so there's no real-world
  //   cash movement to reflect. Cash + Account across Fees always equals
  //   the fee total collected, exactly like the client's example (20k +
  //   30k = 50k).
  //
  // - STUDENT CASH (Receipts) "Account" entries are the one exception:
  //   they add to Account AND subtract from Cash, because that one
  //   specific workflow really does involve the cashier handing out
  //   physical cash while the money lands in the bank (see
  //   ReceiptController.netCashBox). Student Cash "Cash" entries just
  //   add to Cash, same as everywhere else.
  //
  // - EXPENSES subtract from whichever box was actually spent from: an
  //   Account-mode expense (paid out of the bank) reduces Account Box;
  //   a Cash-mode expense (paid out of physical cash on hand) reduces
  //   Cash Box. This is the one place real money leaves either box —
  //   every other line above only ever adds.
  //
  // Total Amount (above) already includes every fee payment regardless
  // of method (via allTimeCollected) plus the Account portion of
  // Student Cash, minus every expense regardless of method (via
  // allTimeExpenses) — that formula was already correct and needed no
  // change here. This section only affects the Cash Box / Account Box
  // split shown on the Dashboard.
  // ---------------------------------------------------------------------------

  double get _feeCashCollected {
    return feeController.payments
        .where((payment) => payment.paymentMethod == PaymentMethod.cash)
        .fold<double>(0.0, (sum, payment) => sum + payment.amountReceived);
  }

  double get _feeNonCashCollected {
    return feeController.payments
        .where((payment) => payment.paymentMethod != PaymentMethod.cash)
        .fold<double>(0.0, (sum, payment) => sum + payment.amountReceived);
  }

  double get _expenseCashPaid {
    return expenseController.expenses
        .where((expense) => expense.paymentMode == ExpensePaymentMode.cash)
        .fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  double get _expenseAccountPaid {
    return expenseController.expenses
        .where((expense) => expense.paymentMode == ExpensePaymentMode.account)
        .fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  // Balance Additions add straight through to whichever box was picked —
  // no cross-box quirk like Student Cash "Account" entries have. See the
  // long comment on totalAmount above for why.
  double get cashBox =>
      _feeCashCollected + receiptController.cashReceipts -
      receiptController.accountReceipts - _expenseCashPaid +
      balanceController.totalCashAdded;

  double get accountBox =>
      _feeNonCashCollected + receiptController.accountReceipts -
      _expenseAccountPaid + balanceController.totalAccountAdded;

  Future<void> setOpeningBalance(double value) {
    debugPrint(
      '[SETTINGS] DashboardController.setOpeningBalance($value) — '
      'this DashboardController: $hashCode, '
      'settingsController: ${settingsController.hashCode}',
    );
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

    final receiptItems = receiptController.receipts.map((receipt) {
      return RecentActivityItem(
        title: (receipt.receivedFrom?.isNotEmpty ?? false)
            ? receipt.receivedFrom!
            : 'Cash Receipt',
        subtitle: 'Student Cash',
        amount: receipt.amount,
        date: receipt.date,
        isIncome: true,
      );
    });

    final balanceItems = balanceController.balanceAdditions.map((addition) {
      return RecentActivityItem(
        title: 'Added to Total Balance',
        subtitle: addition.box.label,
        amount: addition.amount,
        date: addition.date,
        isIncome: true,
      );
    });

    final combined = [
      ...feeItems,
      ...expenseItems,
      ...receiptItems,
      ...balanceItems,
    ]..sort((a, b) => b.date.compareTo(a.date));

    return combined.take(6).toList();
  }

  // ---------------------------------------------------------------------------
  // Add to Total Balance — the Dashboard's "Add" action. Always a new,
  // purely additive entry (see BalanceAdditionController) — never edits
  // or replaces Opening Balance or any past addition.
  // ---------------------------------------------------------------------------

  Future<bool> addToTotalBalance({
    required double amount,
    required BalanceAdditionBox box,
  }) {
    return balanceController.addBalance(amount: amount, box: box);
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