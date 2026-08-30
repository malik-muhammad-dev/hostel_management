import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../students/presentation/controllers/student_controller.dart';
import '../../../students/presentation/controllers/student_service_controller.dart';
import '../../../students/data/models/student_model.dart';
import '../../data/models/fee_payment_model.dart';
import '../../data/models/fee_transaction_model.dart';
import '../../data/models/student_fee_summary_model.dart';
import '../../data/repositories/fee_repository.dart';

class FeeController extends GetxController {
  final FeeRepository repository;

  FeeController(this.repository);

  // ===========================================================================
  // STATE
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // Fee data
  // ---------------------------------------------------------------------------

  final transactions = <FeeTransaction>[].obs;
  final payments = <FeePayment>[].obs;

  // Kept for compatibility with existing architecture/data source.
  // The Fees table does NOT use this list.
  final studentFeeSummaries = <StudentFeeSummary>[].obs;
  final serviceAmountsByStudent = <int, double>{}.obs;

  final isLoading = false.obs;

  // ---------------------------------------------------------------------------
  // Fees table month filter
  // ---------------------------------------------------------------------------

  final feeTableMonth = ''.obs;

  // ---------------------------------------------------------------------------
  // Payment form state
  // ---------------------------------------------------------------------------

  final selectedStudentId = Rxn<int>();
  final selectedFeeMonth = ''.obs;
  final selectedPaymentMethod = Rxn<PaymentMethod>();
  final paymentDate = ''.obs;
  final receiptAttachmentPath = Rxn<String>();

  final amountReceived = 0.0.obs;

  // Backs `selectedDiscount` — kept as its own Rx (mirroring
  // `amountReceived` above) rather than reading discountController.text
  // straight from a getter, because a plain (non-Rx) read inside an Obx
  // does not register as a tracked dependency: the UI would render the
  // discount once and then silently stop updating as the admin types,
  // the same class of bug already found and fixed on the dashboard.
  final discountAmount = 0.0.obs;

  final currentMonthFeeController = TextEditingController();
  final previousBalanceController = TextEditingController();
  final fineController = TextEditingController();
  final discountController = TextEditingController();
  final amountReceivedController = TextEditingController();
  final paymentReferenceController = TextEditingController();
  final notesController = TextEditingController();

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  // Tracks whether the initial "pick a sensible default month" has run
  // yet — this must only happen once, on the very first load. Without
  // this guard, every later loadFeeData() call (e.g. after submitting a
  // payment) would silently reset feeTableMonth back to "latest month
  // with data", overriding whatever month the user had manually
  // switched to.
  bool _hasSetInitialMonth = false;

  @override
  void onInit() {
    super.onInit();

    amountReceivedController.addListener(
      _updateAmountReceived,
    );

    discountController.addListener(
      _updateDiscount,
    );

    loadFeeData();
  }

  @override
  void onClose() {
    amountReceivedController.removeListener(
      _updateAmountReceived,
    );

    discountController.removeListener(
      _updateDiscount,
    );

    currentMonthFeeController.dispose();
    previousBalanceController.dispose();
    fineController.dispose();
    discountController.dispose();
    amountReceivedController.dispose();
    paymentReferenceController.dispose();
    notesController.dispose();

    super.onClose();
  }

  void _updateAmountReceived() {
    amountReceived.value =
        double.tryParse(amountReceivedController.text) ?? 0;
  }

  // Strips anything that isn't a digit or a decimal point before parsing
  // — same fix as the dashboard's Opening Balance field, so typing a
  // comma-formatted discount (e.g. "2,000") doesn't silently parse to 0.
  void _updateDiscount() {
    final cleaned = discountController.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    discountAmount.value = double.tryParse(cleaned) ?? 0;
  }

  // ===========================================================================
  // DATA LOADING
  // ===========================================================================

  Future<void> loadFeeData() async {
    try {
      isLoading.value = true;

      final results = await Future.wait([
        repository.getTransactions(),
        repository.getPayments(),
        repository.getStudentFeeSummaries(),
      ]);

      transactions.assignAll(
        results[0] as List<FeeTransaction>,
      );

      payments.assignAll(
        results[1] as List<FeePayment>,
      );

      studentFeeSummaries.assignAll(
        results[2] as List<StudentFeeSummary>,
      );
await loadStudentServiceAmounts();

      // Pick a sensible default month — but only the very first time
      // data loads. Default to whichever month has the most recent
      // recorded activity (a real hostel is usually looking at "the
      // month we're actively collecting for", not necessarily today's
      // calendar month) — falling back to the current calendar month
      // only when there's no data at all yet (a fresh install).
      if (!_hasSetInitialMonth) {
        feeTableMonth.value = _latestMonthWithData() ?? _currentFeeMonth();
        _hasSetInitialMonth = true;
      }
    } finally {
      isLoading.value = false;
    }
  }

  String? _latestMonthWithData() {
    if (transactions.isEmpty) {
      return null;
    }

    final months = transactions.map((t) => t.feeMonth).toList()..sort();

    return months.last;
  }

  // ===========================================================================
  // FEES TABLE — MONTH
  // ===========================================================================

  String _currentFeeMonth() {
    final now = DateTime.now();

    return _formatFeeMonth(
      now.year,
      now.month,
    );
  }

  // ---------------------------------------------------------------------------
  // Enrollment check — was this student even enrolled during feeMonth?
  //
  // Single source of truth, used everywhere a fee month needs to be
  // checked against a student's enrollment (computeFeeSummaryForMonth,
  // validatePayment, and the Fees table's row filtering) — previously
  // this logic was duplicated in two places and could drift apart.
  // ---------------------------------------------------------------------------

  bool isStudentEnrolledInMonth(StudentModel student, String feeMonth) {
    final enrollmentDate = student.packageStartDate ?? student.admissionDate;

    if (enrollmentDate == null || enrollmentDate.length < 7) {
      // No enrollment date on record — don't block on missing data.
      return true;
    }

    final enrollmentMonth = enrollmentDate.substring(0, 7);

    return feeMonth.compareTo(enrollmentMonth) >= 0;
  }

  String _formatFeeMonth(
    int year,
    int month,
  ) {
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // "All" vs a specific month
  //
  // The Fees table/dashboard defaults to showing everything (latest
  // activity across all months) rather than being locked to one month.
  // Picking a specific month narrows the view; tapping "All" again
  // widens it back out.
  // ---------------------------------------------------------------------------

  final showAllMonths = true.obs;

  void setFeeTableMonth(String value) {
    feeTableMonth.value = value;
    showAllMonths.value = false;
  }

  void showAllFeeRecords() {
    showAllMonths.value = true;
  }

  // ===========================================================================
  // DERIVED FEE SUMMARIES
  //
  // Overall student ledger.
  //
  // This remains cumulative intentionally because dashboard/financial
  // calculations can depend on the complete transaction history.
  // ===========================================================================

  StudentFeeSummary computeFeeSummary(int studentId) {
    final studentTransactions = transactions.where(
      (transaction) => transaction.studentId == studentId,
    );

    final charged = studentTransactions
        .where(
          (transaction) =>
              transaction.type == FeeTransactionType.charge,
        )
        .fold<double>(
          0,
          (sum, transaction) => sum + transaction.debit,
        );

    final submitted = studentTransactions
        .where(
          (transaction) =>
              transaction.type == FeeTransactionType.payment,
        )
        .fold<double>(
          0,
          (sum, transaction) => sum + transaction.credit,
        );

    return StudentFeeSummary(
      studentId: studentId,
      feeCharged: charged,
      feeSubmitted: submitted,
      feePending: charged - submitted,
    );
  }

  // ===========================================================================
  // MONTH-SPECIFIC SUMMARY
  //
  // Used by the main Fees table.
  //
  // Only transactions belonging to the selected fee month are considered.
  // ===========================================================================

  StudentFeeSummary computeFeeSummaryForMonth(
  int studentId,
  String feeMonth,
) {
  final monthTransactions = transactions.where(
    (transaction) =>
        transaction.studentId == studentId &&
        transaction.feeMonth == feeMonth,
  );

  final charged = monthTransactions
      .where(
        (transaction) =>
            transaction.type == FeeTransactionType.charge,
      )
      .fold<double>(
        0.0,
        (sum, transaction) => sum + transaction.debit,
      );

  final submitted = monthTransactions
      .where(
        (transaction) =>
            transaction.type == FeeTransactionType.payment,
      )
      .fold<double>(
        0.0,
        (sum, transaction) => sum + transaction.credit,
      );

  // -------------------------------------------------------------------------
  // Existing charge = historical source of truth.
  //
  // Never recalculate an already-created month's charge from the student's
  // current services.
  // -------------------------------------------------------------------------

  if (charged > 0) {
    return StudentFeeSummary(
      studentId: studentId,
      feeCharged: charged,
      feeSubmitted: submitted,
      feePending: charged - submitted,
    );
  }

  // -------------------------------------------------------------------------
  // No charge exists yet.
  //
  // Before fabricating an expected fee, make sure this month is actually
  // on/after the student's enrollment — otherwise a student who joined
  // in August would incorrectly show as owing July's fee too, just
  // because no real charge transaction exists for July (which is
  // correct — they weren't enrolled yet, so none ever should).
  // -------------------------------------------------------------------------

  final studentController = Get.find<StudentController>();

  final student = studentController.students.firstWhereOrNull(
    (student) => student.id == studentId,
  );

  if (student != null && !isStudentEnrolledInMonth(student, feeMonth)) {
    return StudentFeeSummary(
      studentId: studentId,
      feeCharged: 0,
      feeSubmitted: submitted,
      feePending: 0,
    );
  }

  // -------------------------------------------------------------------------
  // Calculate:
  //
  // Base monthly fee + active services
  // -------------------------------------------------------------------------

  final baseFee =
      student?.netMonthlyFee ??
      student?.monthlyFee ??
      0.0;

  final serviceAmount =
      serviceAmountsByStudent[studentId] ?? 0.0;

  final expectedFee =
      baseFee + serviceAmount;

  return StudentFeeSummary(
    studentId: studentId,
    feeCharged: expectedFee,
    feeSubmitted: submitted,
    feePending: expectedFee - submitted,
  );
}

  /// Kept for API compatibility.
  Future<StudentFeeSummary?> getStudentFeeSummary(
    int studentId,
  ) async {
    return computeFeeSummary(studentId);
  }
Future<void> refreshServiceAmountsForStudent(
  int studentId,
) async {
  final serviceController =
      Get.find<StudentServiceController>();

  final amount =
      await serviceController.getActiveServiceAmountForStudent(
    studentId,
  );

  serviceAmountsByStudent[studentId] = amount;

  serviceAmountsByStudent.refresh();
}
  // ===========================================================================
  // DASHBOARD TOTALS
  //
  // Scoped to the Fees screen's selected month (feeTableMonth) — the same
  // month the records table below is showing — and both computed through
  // computeFeeSummaryForMonth, the exact same function the table rows and
  // the Fee Collection Report already use. One function, one answer:
  // "Total Expected" and "Collected" can no longer disagree about which
  // month (or which students) they're counting, which is what caused
  // Outstanding to go negative before (a flat, not-month-scoped "current
  // configured fee" being compared against a cumulative-across-all-time
  // Collected figure).
  // ===========================================================================

  double get totalExpected {
    final studentController = Get.find<StudentController>();

    if (showAllMonths.value) {
      return studentController.activeStudents
          .where((student) => student.id != null)
          .fold<double>(0.0, (sum, student) {
        final summary = computeFeeSummary(student.id!);
        return sum + summary.feeCharged;
      });
    }

    final month = feeTableMonth.value;

    if (month.isEmpty) return 0.0;

    return studentController.activeStudents
        .where((student) => student.id != null)
        .fold<double>(0.0, (sum, student) {
      final summary = computeFeeSummaryForMonth(student.id!, month);
      return sum + summary.feeCharged;
    });
  }

  double get collected {
    final studentController = Get.find<StudentController>();

    if (showAllMonths.value) {
      return studentController.activeStudents
          .where((student) => student.id != null)
          .fold<double>(0.0, (sum, student) {
        final summary = computeFeeSummary(student.id!);
        return sum + summary.feeSubmitted;
      });
    }

    final month = feeTableMonth.value;

    if (month.isEmpty) return 0.0;

    return studentController.activeStudents
        .where((student) => student.id != null)
        .fold<double>(0.0, (sum, student) {
      final summary = computeFeeSummaryForMonth(student.id!, month);
      return sum + summary.feeSubmitted;
    });
  }

  double get outstanding => totalExpected - collected;

  // TODO: compute overdue from transactions past due date.
  double get overdue => 0;

  // ===========================================================================
  // PAYMENT FORM — SELECTED STUDENT/MONTH
  // ===========================================================================

  FeePayment? get selectedPayment {
    final studentId = selectedStudentId.value;
    final feeMonth = selectedFeeMonth.value;

    if (studentId == null || feeMonth.isEmpty) {
      return null;
    }

    for (final payment in payments) {
      if (payment.studentId == studentId &&
          payment.feeMonth == feeMonth) {
        return payment;
      }
    }

    return null;
  }

  StudentFeeSummary? get selectedFeeSummary {
    final studentId = selectedStudentId.value;

    if (studentId == null) {
      return null;
    }

    return computeFeeSummary(studentId);
  }

  double _chargeForMonth(
    int studentId,
    String feeMonth,
  ) {
    return transactions
        .where(
          (transaction) =>
              transaction.studentId == studentId &&
              transaction.feeMonth == feeMonth &&
              transaction.type == FeeTransactionType.charge,
        )
        .fold<double>(
          0,
          (sum, transaction) => sum + transaction.debit,
        );
  }

  double get selectedCurrentMonthFee {
    final studentId = selectedStudentId.value;
    final feeMonth = selectedFeeMonth.value;

    if (studentId == null || feeMonth.isEmpty) {
      return 0;
    }

    // -------------------------------------------------------------------------
    // Always compute live — never trust a stale FeePayment snapshot here.
    //
    // Previously this returned `selectedPayment.currentMonthFee` whenever
    // ANY payment already existed for this student/month, which silently
    // re-showed the full month fee (and let staff submit a full SECOND
    // payment) even after a partial payment had already been recorded.
    // The actual month charge only ever needs the real charge transaction
    // (or the student's configured fee, before one exists) — it must
    // never be read back from a specific payment's own stored snapshot.
    // -------------------------------------------------------------------------

    final chargeForMonth = _chargeForMonth(
      studentId,
      feeMonth,
    );

    if (chargeForMonth > 0) {
      return chargeForMonth;
    }

    // -------------------------------------------------------------------------
    // No charge yet.
    //
    // Use student's configured fee.
    // -------------------------------------------------------------------------
    final studentController = Get.find<StudentController>();

final student = studentController.students.firstWhereOrNull(
  (student) => student.id == studentId,
);

final baseFee =
    student?.netMonthlyFee ??
    student?.monthlyFee ??
    0.0;

final serviceController =
    Get.find<StudentServiceController>();

final serviceAmount =
    serviceController.selectedStudentId.value == studentId
        ? serviceController.totalActiveServiceAmount
        : 0.0;

return baseFee + serviceAmount;}

  // ---------------------------------------------------------------------------
  // Amount already paid toward the SELECTED student/month, across every
  // payment transaction recorded for it so far (there can be more than
  // one, if the fee was paid in installments). This is what makes a
  // second/third payment on the same month correctly show only the
  // remaining balance, instead of the full month fee all over again.
  // ---------------------------------------------------------------------------

  double get selectedAlreadyPaidThisMonth {
    final studentId = selectedStudentId.value;
    final feeMonth = selectedFeeMonth.value;

    if (studentId == null || feeMonth.isEmpty) {
      return 0;
    }

    return transactions
        .where(
          (transaction) =>
              transaction.studentId == studentId &&
              transaction.feeMonth == feeMonth &&
              transaction.type == FeeTransactionType.payment,
        )
        .fold<double>(0.0, (sum, transaction) => sum + transaction.credit);
  }

  // ---------------------------------------------------------------------------
  // Total unpaid balance carried over from months BEFORE the given
  // month — e.g. if June was only half-paid and July was skipped
  // entirely, opening the payment form for August adds both of their
  // remaining balances here automatically. Recomputed live from
  // transactions every time, so if a student later pays off June in
  // full, it correctly stops contributing to August's rollover — there
  // is nothing to manually "clear" or track separately.
  //
  // This intentionally only rolls forward months that already have a
  // real charge transaction (i.e. a payment was at some point recorded
  // for them) — a month nobody ever touched has no transaction at all
  // to roll forward, which is the one piece of true "auto-billing" this
  // does NOT attempt (a month must be opened/paid at least once before
  // its balance exists to carry forward).
  // ---------------------------------------------------------------------------

  double unpaidBalanceBeforeMonth(int studentId, String feeMonth) {
    final priorMonths = transactions
        .where(
          (transaction) =>
              transaction.studentId == studentId &&
              transaction.feeMonth.compareTo(feeMonth) < 0,
        )
        .map((transaction) => transaction.feeMonth)
        .toSet();

    double total = 0.0;

    for (final month in priorMonths) {
      final summary = computeFeeSummaryForMonth(studentId, month);
      if (summary.feePending > 0) {
        total += summary.feePending;
      }
    }

    return total;
  }

  // ---------------------------------------------------------------------------
  // Fine / Discount are adjustments entered fresh for THIS payment
  // submission — they must default to 0 on a clean form, not echo back
  // whatever was typed into an earlier payment for the same month (that
  // was the other half of the same stale-snapshot bug: reopening the
  // form for a second payment used to silently re-show old fine/discount
  // values as if they applied again). `resetPaymentForm()` below clears
  // discountController/discountAmount for exactly this reason.
  //
  // Fine has no input field yet, so it stays hardcoded at 0. Discount is
  // wired to a real field (see PaymentAmountSection) and is entirely
  // optional — left blank, it parses to 0 and changes nothing.
  // ---------------------------------------------------------------------------

  double get selectedPreviousBalance {
    final studentId = selectedStudentId.value;
    final feeMonth = selectedFeeMonth.value;

    if (studentId == null || feeMonth.isEmpty) {
      return 0;
    }

    return unpaidBalanceBeforeMonth(studentId, feeMonth);
  }

  double get selectedFine => 0;

  double get selectedDiscount => discountAmount.value;

  double get selectedTotalDue {
    final remainingMonthFee =
        (selectedCurrentMonthFee - selectedAlreadyPaidThisMonth)
            .clamp(0.0, double.infinity);

    final total =
        remainingMonthFee +
        selectedPreviousBalance +
        selectedFine -
        selectedDiscount;

    return total < 0 ? 0.0 : total;
  }

  // ===========================================================================
  // PAYMENT FORM FIELD GETTERS
  // ===========================================================================

  double get currentMonthFee =>
      double.tryParse(
        currentMonthFeeController.text,
      ) ??
      0;

  double get previousBalance =>
      double.tryParse(
        previousBalanceController.text,
      ) ??
      0;

  double get fine =>
      double.tryParse(
        fineController.text,
      ) ??
      0;

  double get amountReceivedValue =>
      amountReceived.value;

  double get paymentTotalDue =>
      selectedTotalDue;

  double get paymentRemainingBalance =>
      paymentTotalDue - amountReceivedValue;

  // ===========================================================================
  // PAYMENT SUBMISSION
  // ===========================================================================

  bool _hasMonthlyCharge(
    int studentId,
    String feeMonth,
  ) {
    return transactions.any(
      (transaction) =>
          transaction.studentId == studentId &&
          transaction.feeMonth == feeMonth &&
          transaction.type == FeeTransactionType.charge,
    );
  }

  int _nextId(
    List<dynamic> items,
    int? Function(dynamic) idOf,
  ) {
    if (items.isEmpty) {
      return 1;
    }

    final maxId = items
        .map(
          (item) => idOf(item) ?? 0,
        )
        .reduce(
          (a, b) => a > b ? a : b,
        );

    return maxId + 1;
  }

  Future<bool> submitPayment() async {
    final validationMessage = validatePayment();

    if (validationMessage != null) {
      return false;
    }

    final studentId = selectedStudentId.value!;
    final feeMonth = selectedFeeMonth.value;
    final paymentMethod = selectedPaymentMethod.value!;
    final amount = amountReceivedValue;

    // -------------------------------------------------------------------------
    // 1. Payment record
    // -------------------------------------------------------------------------

    final payment = FeePayment(
      id: _nextId(
        payments,
        (payment) => (payment as FeePayment).id,
      ),
      studentId: studentId,
      feeMonth: feeMonth,
      currentMonthFee: selectedCurrentMonthFee,
      previousBalance: selectedPreviousBalance,
      fine: selectedFine,
      discount: selectedDiscount,
      amountReceived: amount,
      paymentMethod: paymentMethod,
      paymentReference:
          paymentReferenceController.text.trim().isEmpty
              ? null
              : paymentReferenceController.text.trim(),
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      paymentDate: paymentDate.value,
      receiptAttachmentPath: receiptAttachmentPath.value,
    );

    // -------------------------------------------------------------------------
    // 2. Monthly charge
    //
    // Only create the charge once for a student/month.
    // -------------------------------------------------------------------------

    FeeTransaction? chargeTransaction;

    if (!_hasMonthlyCharge(
      studentId,
      feeMonth,
    )) {
      chargeTransaction = FeeTransaction(
        id: _nextId(
          transactions,
          (transaction) =>
              (transaction as FeeTransaction).id,
        ),
        studentId: studentId,
        date: paymentDate.value,
        feeMonth: feeMonth,
        description: 'Monthly Hostel Fee',
        debit: selectedCurrentMonthFee,
        credit: 0,
        balance: selectedTotalDue,
        type: FeeTransactionType.charge,
      );
    }

    // -------------------------------------------------------------------------
    // 3. Payment transaction
    // -------------------------------------------------------------------------

    final pendingIds = [
      ...transactions,
      ?chargeTransaction,
    ];

    final paymentTransaction = FeeTransaction(
      id: _nextId(
        pendingIds,
        (transaction) =>
            (transaction as FeeTransaction).id,
      ),
      studentId: studentId,
      date: paymentDate.value,
      feeMonth: feeMonth,
      description:
          'Fee Payment - ${paymentMethod.name}',
      debit: 0,
      credit: amount,
      balance: selectedTotalDue - amount,
      type: FeeTransactionType.payment,
    );

    // -------------------------------------------------------------------------
    // Persist everything.
    // -------------------------------------------------------------------------

    await repository.addPayment(payment);

    if (chargeTransaction != null) {
      await repository.addTransaction(
        chargeTransaction,
      );
    }

    await repository.addTransaction(
      paymentTransaction,
    );

    await loadFeeData();

    return true;
  }

  Future<void> addPayment(
    FeePayment payment,
  ) async {
    await repository.addPayment(payment);
    await loadFeeData();
  }

  Future<void> addTransaction(
    FeeTransaction transaction,
  ) async {
    await repository.addTransaction(transaction);
    await loadFeeData();
  }
  // ===========================================================================
  // Load Student Services 
  // ===========================================================================
Future<void> loadStudentServiceAmounts() async {
  final studentController = Get.find<StudentController>();
  final serviceController =
      Get.find<StudentServiceController>();

  final studentIds = studentController.activeStudents
      .map((student) => student.id)
      .whereType<int>()
      .toList();

  if (studentIds.isEmpty) {
    serviceAmountsByStudent.clear();
    return;
  }

  final results = await Future.wait(
    studentIds.map(
      (studentId) async {
        final amount =
            await serviceController
                .getActiveServiceAmountForStudent(studentId);

        return MapEntry(studentId, amount);
      },
    ),
  );

  serviceAmountsByStudent.assignAll(
    Map<int, double>.fromEntries(results),
  );
}
  // ===========================================================================
  // PAYMENT FORM — VALIDATION
  // ===========================================================================

  String? validatePayment() {
    if (selectedStudentId.value == null) {
      return 'Please select a student.';
    }

    if (selectedFeeMonth.value.isEmpty) {
      return 'Please select a fee month.';
    }

    // -------------------------------------------------------------------------
    // Never allow charging/paying for a month before this student's
    // enrollment — otherwise a student who joined in August could be
    // (incorrectly) charged for June or July too.
    // -------------------------------------------------------------------------

    final studentForValidation = Get.find<StudentController>()
        .students
        .firstWhereOrNull((s) => s.id == selectedStudentId.value);

    if (studentForValidation != null &&
        !isStudentEnrolledInMonth(
          studentForValidation,
          selectedFeeMonth.value,
        )) {
      return 'This student was not yet enrolled in the selected month.';
    }

    if (selectedPaymentMethod.value == null) {
      return 'Please select a payment method.';
    }

    if (paymentDate.value.isEmpty) {
      return 'Please select a payment date.';
    }

    if (amountReceivedValue <= 0) {
      return 'Please enter a valid payment amount.';
    }

    if (amountReceivedValue > selectedTotalDue) {
      return 'Payment amount cannot be greater than the total due.';
    }

    if (selectedPaymentMethod.value ==
            PaymentMethod.bankTransfer &&
        receiptAttachmentPath.value == null) {
      return 'Please attach the bank payment receipt.';
    }

    return null;
  }

  // ===========================================================================
  // PAYMENT FORM — SETTERS
  // ===========================================================================

Future<void> setPaymentStudent(int? studentId) async {
  selectedStudentId.value = studentId;

  if (studentId == null) {
    return;
  }

  final serviceController =
      Get.find<StudentServiceController>();

  await serviceController.loadServices(studentId);
}

  void setFeeMonth(String value) {
    selectedFeeMonth.value = value;
  }

  void setPaymentMethod(
    PaymentMethod? method,
  ) {
    selectedPaymentMethod.value = method;

    if (method != PaymentMethod.bankTransfer) {
      receiptAttachmentPath.value = null;
    }
  }

  void setPaymentDate(String value) {
    paymentDate.value = value;
  }

  void setReceiptAttachmentPath(
    String? path,
  ) {
    receiptAttachmentPath.value = path;
  }

  void resetPaymentForm() {
    selectedStudentId.value = null;
    selectedFeeMonth.value = '';
    selectedPaymentMethod.value = null;

    amountReceivedController.clear();
    paymentReferenceController.clear();
    notesController.clear();
    discountController.clear();

    paymentDate.value = '';
    receiptAttachmentPath.value = null;
    amountReceived.value = 0;
    discountAmount.value = 0;
  }
}