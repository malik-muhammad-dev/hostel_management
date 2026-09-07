import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_error_logger.dart';
import '../../../../core/realtime/realtime_table_sync.dart';
import '../../../students/presentation/controllers/student_controller.dart';
import '../../../students/presentation/controllers/student_service_controller.dart';
import '../../../students/data/models/student_model.dart';
import '../../../settings/presentation/controllers/app_settings_controller.dart';
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
  final serviceAmountsByStudent = <String, double>{}.obs;

  final isLoading = false.obs;

  // ---------------------------------------------------------------------------
  // Fees table month filter
  // ---------------------------------------------------------------------------

  final feeTableMonth = ''.obs;

  // ---------------------------------------------------------------------------
  // Payment form state
  // ---------------------------------------------------------------------------

  final selectedStudentId = Rxn<String>();
  final selectedFeeMonth = ''.obs;
  final selectedPaymentMethod = Rxn<PaymentMethod>();
  final paymentDate = ''.obs;
  final receiptAttachmentPath = Rxn<String>();

  final amountReceived = 0.0.obs;

  // True for the duration of a submitPayment() call — lets
  // record_payment_screen.dart disable its Save button and show a
  // spinner while a save is actually in flight, and also lets
  // submitPayment() itself refuse a second, overlapping call outright
  // (see submitPayment()). Two overlapping calls used to both pass
  // validation against the same stale local numbers and both go on to
  // create their own charge+payment — this is what actually let a
  // student's month get double-charged.
  final isSubmittingPayment = false.obs;

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

  // ---------------------------------------------------------------------------
  // Realtime — reloads from Supabase whenever fee_transactions or
  // fee_payments changes, from this PC or any other one. See
  // RealtimeTableSync for why this exists and why it just re-runs
  // loadFeeData() rather than merging rows.
  // ---------------------------------------------------------------------------

  late final RealtimeTableSync _realtimeSync;

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

    _realtimeSync = RealtimeTableSync(
      tables: const ['fee_transactions', 'fee_payments'],
      onChange: loadFeeData,
    );
  }

  @override
  void onClose() {
    _realtimeSync.dispose();

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

  // [notifyOnFailure] is false when this is called right after this
  // controller's own successful write (submitPayment/addPayment/
  // addTransaction all reload immediately afterward, just to pick up
  // DB-assigned values like receipt_no). A transient failure on THAT
  // specific reload must not show "Couldn't load Fees" — the money was
  // already recorded successfully; a scary snackbar right after a
  // successful save would look like the save itself failed and risks
  // staff re-entering the same payment as a duplicate. The initial
  // load (onInit) and the realtime-sync-triggered reload both keep the
  // default of true, since those genuinely are "couldn't load" cases.
  Future<void> loadFeeData({bool notifyOnFailure = true}) async {
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
    } catch (e, stackTrace) {
      // Was try/finally only, with no catch — harmless while this read
      // from local SQLite, but Fees is about to read from Supabase over
      // the network. Without this, a failed fetch (no internet, a bad
      // key, an RLS issue) would throw uncaught and leave the screen
      // stuck on its loading spinner with no visible error — whatever
      // fee data was already loaded just stays as it is.
      debugPrint('[DEBUG] loadFeeData failed: $e');
      debugPrint('[DEBUG] stackTrace: $stackTrace');
      AppErrorLogger.log('FeeController.loadFeeData', e, stackTrace);
      if (notifyOnFailure) {
        AppErrorLogger.notifyLoadFailure('Fees');
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

  /// Public wrapper around [_currentFeeMonth] — the current calendar
  /// month in the same 'YYYY-MM' format every fee month is stored in.
  /// Exposed for screens/dialogs outside this controller that need to
  /// know "which month counts as current" (e.g. deciding whether a
  /// month's charge is still correctable).
  String get currentFeeMonth => _currentFeeMonth();

  /// The existing charge transaction for [studentId] in the current
  /// calendar month, or null if no charge has been created for it yet
  /// (a fresh, not-yet-billed month — nothing to correct, because
  /// nothing's been locked in).
  FeeTransaction? currentMonthChargeFor(String studentId) {
    final month = _currentFeeMonth();

    return transactions.firstWhereOrNull(
      (t) =>
          t.studentId == studentId &&
          t.feeMonth == month &&
          t.type == FeeTransactionType.charge,
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

  // ---------------------------------------------------------------------------
  // Discount given to a student is recorded on the FeePayment row itself
  // (FeePayment.discount) — it never reduces a charge transaction's
  // `debit`, because a discount can be granted on ANY installment of a
  // month, not only the one that creates the charge. So every summary
  // below that reports what a student truly owes must separately pull
  // and subtract the discount total from `payments`, not just sum
  // `transactions`. Skipping this step used to leave a permanent phantom
  // balance — exactly the amount of every discount ever given — sitting
  // on a fully-paid student forever, rolling into next month's
  // previousBalance and able to trigger a late fine on a student who
  // paid in full. See computeFeeSummaryForMonth's `charged > 0` branch
  // below for the month-scoped version of this same fix.
  // ---------------------------------------------------------------------------

  double _totalDiscountForStudent(String studentId) {
    return payments
        .where((payment) => payment.studentId == studentId)
        .fold<double>(0.0, (sum, payment) => sum + payment.discount);
  }

  double _totalDiscountForMonth(String studentId, String feeMonth) {
    return payments
        .where(
          (payment) =>
              payment.studentId == studentId && payment.feeMonth == feeMonth,
        )
        .fold<double>(0.0, (sum, payment) => sum + payment.discount);
  }

  StudentFeeSummary computeFeeSummary(String studentId) {
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

    // Net of every discount ever given to this student — see the note
    // above. Without this, a discounted student shows as permanently
    // owing exactly their discount amount, forever.
    final netCharged = charged - _totalDiscountForStudent(studentId);
    final feeCharged = netCharged < 0 ? 0.0 : netCharged;

    return StudentFeeSummary(
      studentId: studentId,
      feeCharged: feeCharged,
      feeSubmitted: submitted,
      feePending: feeCharged - submitted,
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
  String studentId,
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
  //
  // Net of every discount given for THIS month (across every installment
  // payment recorded for it, not just one) — see _totalDiscountForMonth's
  // comment above computeFeeSummary. Without this, a discount collected
  // correctly at payment time still left the ledger thinking the
  // discounted amount was never paid: it rolled into next month's
  // previousBalance, and could trigger a late fine on a student who had
  // actually paid their (discounted) fee in full.
  // -------------------------------------------------------------------------

  if (charged > 0) {
    final netCharged = charged - _totalDiscountForMonth(studentId, feeMonth);
    final feeCharged = netCharged < 0 ? 0.0 : netCharged;

    return StudentFeeSummary(
      studentId: studentId,
      feeCharged: feeCharged,
      feeSubmitted: submitted,
      feePending: feeCharged - submitted,
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
    String studentId,
  ) async {
    return computeFeeSummary(studentId);
  }
Future<void> refreshServiceAmountsForStudent(
  String studentId,
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

  // Total Late Fine currently owed, summed across the same set of
  // students/months the two figures above are scoped to. Always
  // evaluated against the fee-month "as of today" (`_currentFeeMonth()`)
  // rather than "all months ever" — a fine is a today-relative concept,
  // not a historical ledger total.
  double get overdue {
    final studentController = Get.find<StudentController>();
    final activeStudents = studentController.activeStudents
        .where((student) => student.id != null);

    if (showAllMonths.value) {
      final currentMonth = _currentFeeMonth();
      return activeStudents.fold<double>(
        0.0,
        (sum, student) => sum + totalFineOwed(student.id!, currentMonth),
      );
    }

    final month = feeTableMonth.value;
    if (month.isEmpty) return 0.0;

    // A specific month is selected — match totalExpected/collected's
    // scoping (that month only, not the cumulative stack) so the three
    // figures stay comparable side by side.
    return activeStudents.fold<double>(
      0.0,
      (sum, student) => sum + fineForSingleMonth(student.id!, month),
    );
  }

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
    String studentId,
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

  double unpaidBalanceBeforeMonth(String studentId, String feeMonth) {
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
  // Fine / Discount are adjustments shown fresh for THIS payment — they
  // must default to 0 on a clean form, not echo back whatever applied to
  // an earlier payment for the same month (that was the other half of
  // the same stale-snapshot bug: reopening the form for a second payment
  // used to silently re-show old fine/discount values as if they applied
  // again). `resetPaymentForm()` below clears discountController/
  // discountAmount for exactly this reason.
  //
  // Discount is wired to a real field (see PaymentAmountSection) and is
  // entirely optional — left blank, it parses to 0 and changes nothing.
  // Fine is NOT admin-entered at all — see `selectedFine` / the "LATE
  // FINE" section below for why it's computed automatically instead.
  // ---------------------------------------------------------------------------

  double get selectedPreviousBalance {
    final studentId = selectedStudentId.value;
    final feeMonth = selectedFeeMonth.value;

    if (studentId == null || feeMonth.isEmpty) {
      return 0;
    }

    return unpaidBalanceBeforeMonth(studentId, feeMonth);
  }

  // ===========================================================================
  // LATE FINE
  //
  // The client's rule: once a month's fine due day (Settings, default
  // the 9th) has passed and that month is still unpaid, a fine (Settings,
  // default Rs. 100) applies — automatically, without the admin having
  // to remember to add it. This exists precisely because the admin
  // forgetting was the original problem being solved.
  //
  // Computed live from today's real date every time, the same
  // self-healing approach as Previous Balance / Total Amount elsewhere
  // in this app: pay a month off, or change the fine amount/due day in
  // Settings, and every screen immediately reflects the new reality —
  // there is no stored "fine" row to fall out of sync and nothing to
  // manually clear.
  //
  // Stacks across every unpaid month whose due day has passed (a student
  // 3 months behind shows 3x the fine) — mirroring exactly how Previous
  // Balance already rolls forward unpaid months. Only counts months
  // on/after `fineEffectiveFrom` (stamped once, to the month this
  // feature was installed) so switching it on never back-fines a student
  // for months that came and went before the rule existed.
  // ===========================================================================

  DateTime? _parseFeeMonth(String feeMonth) {
    final parts = feeMonth.split('-');
    if (parts.length != 2) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return null;

    return DateTime(year, month);
  }

  /// Fine owed for exactly ONE month — 0 unless that month's fine due
  /// date has already passed and the month still has a pending balance.
  ///
  /// Note: "still has a pending balance" is judged from the month's base
  /// fee vs. what's been collected for it (the same `feePending` the
  /// rest of the app already uses) — a payment that covers the base fee
  /// in full is enough to stop that month from being counted as unpaid
  /// here, even in the rare case the fine portion specifically wasn't
  /// separately collected. Deliberately not persisting fine into the
  /// charge transaction itself to get exact tracking of that edge case —
  /// doing so would change `chargeTransaction.debit`, which Total
  /// Expected/dashboard totals already rely on being just the base fee.
  double fineForSingleMonth(String studentId, String feeMonth) {
    final settings = Get.find<AppSettingsController>();

    final effectiveFrom = settings.fineEffectiveFrom.value;
    if (effectiveFrom != null &&
        effectiveFrom.length >= 7 &&
        feeMonth.compareTo(effectiveFrom.substring(0, 7)) < 0) {
      return 0;
    }

    final parsed = _parseFeeMonth(feeMonth);
    if (parsed == null) return 0;

    final dueDate = DateTime(parsed.year, parsed.month, settings.fineDueDay.value);
    if (!DateTime.now().isAfter(dueDate)) return 0;

    final summary = computeFeeSummaryForMonth(studentId, feeMonth);
    if (summary.feePending <= 0) return 0;

    return settings.fineAmount.value;
  }

  /// Total fine owed by a student across every unpaid month from their
  /// enrollment (or `fineEffectiveFrom`, whichever is later) up to and
  /// including [uptoFeeMonth].
  double totalFineOwed(String studentId, String uptoFeeMonth) {
    final upto = _parseFeeMonth(uptoFeeMonth);
    if (upto == null) return 0;

    final studentController = Get.find<StudentController>();
    final student = studentController.students
        .firstWhereOrNull((student) => student.id == studentId);
    if (student == null) return 0;

    DateTime cursor = upto;

    final enrollmentDate = student.packageStartDate ?? student.admissionDate;
    if (enrollmentDate != null && enrollmentDate.length >= 7) {
      final enrollYear = int.tryParse(enrollmentDate.substring(0, 4));
      final enrollMonth = int.tryParse(enrollmentDate.substring(5, 7));
      if (enrollYear != null && enrollMonth != null) {
        cursor = DateTime(enrollYear, enrollMonth);
      }
    }

    double total = 0;

    // Safety cap — 120 months (10 years) is far more than any real
    // enrollment span, and stops a malformed date from ever spinning
    // this into an unbounded loop.
    var guard = 0;

    while (!cursor.isAfter(upto) && guard < 120) {
      total += fineForSingleMonth(
        studentId,
        _formatFeeMonth(cursor.year, cursor.month),
      );
      cursor = DateTime(cursor.year, cursor.month + 1);
      guard++;
    }

    return total;
  }

  double get selectedFine {
    final studentId = selectedStudentId.value;
    final feeMonth = selectedFeeMonth.value;

    if (studentId == null || feeMonth.isEmpty) {
      return 0;
    }

    return totalFineOwed(studentId, feeMonth);
  }

  double get selectedDiscount => discountAmount.value;

  double get selectedTotalDue {
    final studentId = selectedStudentId.value;
    final feeMonth = selectedFeeMonth.value;

    // Discount already granted on an EARLIER installment of this same
    // month (resetPaymentForm() clears the discount field between
    // installments, so `selectedDiscount` below only ever knows about
    // THIS form's own entry, not any prior one). Without netting this
    // out too, opening the form for a 2nd/3rd installment overstates
    // what's left to collect by exactly the earlier discount — and
    // since this is also the number `validatePayment()` caps the
    // collectable amount against, it would let staff overcharge a
    // discounted student on their next installment.
    final priorDiscountThisMonth = (studentId == null || feeMonth.isEmpty)
        ? 0.0
        : _totalDiscountForMonth(studentId, feeMonth);

    final remainingMonthFee =
        (selectedCurrentMonthFee -
                selectedAlreadyPaidThisMonth -
                priorDiscountThisMonth)
            .clamp(0.0, double.infinity);

    final total =
        remainingMonthFee +
        selectedPreviousBalance +
        selectedFine -
        selectedDiscount;

    return total < 0 ? 0.0 : total;
  }

  // ===========================================================================
  // RECEIPT FIGURES — for a specific PAST payment (used by ReceiptGenerator)
  //
  // FeePayment.totalDue/remainingBalance (fee_payment_model.dart) only
  // know about their own row: `currentMonthFee` is always the FULL month
  // fee, and `discount` is only whatever was entered on that one
  // installment. That's correct for a month paid in a single payment,
  // but wrong the moment a month is paid in two or more installments —
  // the 2nd receipt would print "Total Due: [full fee]" and a
  // "Remaining" that ignores the first installment already collected,
  // overstating what's still owed by exactly what was already paid.
  //
  // These two methods compute the real figures AS THEY STOOD AT THE TIME
  // OF [payment] — not "as of right now". This matters because a receipt
  // can be reopened/reprinted long after later installments were paid
  // (see StudentFeePayments' "View Receipt" on any historical row): a
  // straight "sum everything for this month" would make an old partial-
  // payment receipt show "Remaining: 0" once a later installment
  // eventually clears the month, which misrepresents what was actually
  // still owed at the moment that payment was made and printed.
  //
  // `payments` is loaded from Supabase ordered by created_at ascending
  // (see SupabaseFeeDataSource), and the post-save fast-path merge in
  // _submitPaymentUnsafe() only ever appends a brand-new row to the end
  // — so list position IS chronological order, and "every payment up to
  // and including this one" can be read directly off that list position
  // without needing a stored timestamp on the model.
  // ===========================================================================

  /// Every payment recorded for [payment]'s student/month, up to and
  /// including [payment] itself, in chronological order.
  List<FeePayment> _paymentsUpToAndIncluding(FeePayment payment) {
    final monthPayments = payments
        .where(
          (p) =>
              p.studentId == payment.studentId &&
              p.feeMonth == payment.feeMonth,
        )
        .toList();

    final cutoffIndex = monthPayments.indexWhere((p) => p.id == payment.id);

    if (cutoffIndex == -1) {
      // [payment] isn't in `payments` yet — only possible in the narrow
      // instant between the DB write and the fast-path merge finishing
      // (see _submitPaymentUnsafe()). It's always the most recent
      // payment when that happens, so treat it as such.
      return [...monthPayments, payment];
    }

    return monthPayments.sublist(0, cutoffIndex + 1);
  }

  /// The true total due for the month [payment] belongs to, as it stood
  /// at the time [payment] was made: the month's charge, net of every
  /// discount given up to and including [payment] (not the whole
  /// month's discount total, which could include LATER installments),
  /// plus the previous-months balance and fine already correctly fixed
  /// on [payment]'s own row at the time it was recorded.
  double totalDueForPayment(FeePayment payment) {
    final grossCharge = _chargeForMonth(payment.studentId, payment.feeMonth);
    final charge = grossCharge > 0 ? grossCharge : payment.currentMonthFee;

    final discountUpToThisPayment = _paymentsUpToAndIncluding(
      payment,
    ).fold<double>(0.0, (sum, p) => sum + p.discount);

    final netCharge = charge - discountUpToThisPayment;
    final feeCharged = netCharge < 0 ? 0.0 : netCharge;

    return feeCharged + payment.previousBalance + payment.fine;
  }

  /// What was genuinely still owed immediately after [payment] was
  /// recorded — every payment for that month up to and including
  /// [payment] subtracted from the true total due (as it stood at that
  /// same point) above. Deliberately does NOT reflect payments made
  /// LATER than [payment] — see the section note above for why.
  double remainingBalanceForPayment(FeePayment payment) {
    final paidUpToThisPayment = _paymentsUpToAndIncluding(
      payment,
    ).fold<double>(0.0, (sum, p) => sum + p.amountReceived);

    final remaining = totalDueForPayment(payment) - paidUpToThisPayment;
    return remaining < 0 ? 0.0 : remaining;
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
    String studentId,
    String feeMonth,
  ) {
    return transactions.any(
      (transaction) =>
          transaction.studentId == studentId &&
          transaction.feeMonth == feeMonth &&
          transaction.type == FeeTransactionType.charge,
    );
  }

  // Returns the payment record that was just created (with its real,
  // persisted UUID id already on it — generated below, before saving),
  // or null if validation failed OR the save itself failed. The caller
  // no longer needs to guess which payment was "just created" by
  // searching for the highest id afterward — that trick relied on ids
  // being sequential integers, which stopped being true the moment ids
  // became UUIDs.
  Future<FeePayment?> submitPayment() async {
    final validationMessage = validatePayment();

    if (validationMessage != null) {
      return null;
    }

    // -------------------------------------------------------------------
    // Refuse a second call while one is already in flight.
    //
    // record_payment_screen.dart disables its Save button while
    // isSubmittingPayment is true, which handles a normal double-tap.
    // This is the backup for everything that check can't catch — e.g.
    // the button re-enabling before this flag flips back (a GetX rebuild
    // gap), or any other future caller. Without this, two overlapping
    // calls both read the same not-yet-updated local transactions list,
    // both decide "no charge yet for this month" is true, and both go on
    // to create their own charge+payment — exactly how a student's month
    // ended up double-charged.
    // -------------------------------------------------------------------

    if (isSubmittingPayment.value) {
      return null;
    }

    isSubmittingPayment.value = true;

    try {
      return await _submitPaymentUnsafe();
    } catch (e, stackTrace) {
      // This method used to have no try/catch around the actual save at
      // all — harmless while every write was local SQLite, but this is
      // the single highest-stakes place in the whole app to leave
      // unguarded now that it writes to Supabase over the network: it's
      // literally recording money received. A dropped connection here
      // needs to fail visibly (record_payment_screen.dart already shows
      // an error and lets the form be retried) instead of throwing
      // uncaught mid-payment.
      debugPrint('[DEBUG] submitPayment failed: $e');
      debugPrint('[DEBUG] stackTrace: $stackTrace');
      AppErrorLogger.log('FeeController.submitPayment', e, stackTrace);
      return null;
    } finally {
      isSubmittingPayment.value = false;
    }
  }

  Future<FeePayment?> _submitPaymentUnsafe() async {
    final studentId = selectedStudentId.value!;
    final feeMonth = selectedFeeMonth.value;
    final paymentMethod = selectedPaymentMethod.value!;
    final amount = amountReceivedValue;

    // -------------------------------------------------------------------------
    // 1. Payment record
    // -------------------------------------------------------------------------

    final payment = FeePayment(
      id: const Uuid().v4(),
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
        id: const Uuid().v4(),
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

    final paymentTransaction = FeeTransaction(
      id: const Uuid().v4(),
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
    // Persist everything — as one atomic unit (see FeeDataSource.
    // recordPayment()). Previously these were 3 separate sequential
    // writes with nothing tying them together; a failure partway through
    // could leave a payment recorded with no matching ledger entry.
    // -------------------------------------------------------------------------

    await repository.recordPayment(
      payment: payment,
      chargeTransaction: chargeTransaction,
      paymentTransaction: paymentTransaction,
    );

    // The payment is already safely recorded at this point — everything
    // below is just cosmetic follow-up (picking up the DB-assigned
    // receipt number, refreshing the rest of the screen). None of it is
    // allowed to turn a successful save into an apparent failure, so
    // it's deliberately isolated in its own try/catch rather than
    // sharing the one around this whole method: if this fails (e.g. the
    // network drops in the instant after the write went through), the
    // caller must still see the payment as saved — just with the
    // receipt PDF falling back to "RCPT-PENDING" instead of the real
    // number, not an "unable to save" message for money that was, in
    // fact, saved.
    FeePayment? freshPayment;

    try {
      // `payment` above is the pre-insert local copy — it never carries
      // `receiptNo` (that's assigned by Postgres itself on insert, see
      // receipt_voucher_numbers.sql), so the receipt PDF shown right
      // after recording a payment (the most common time it's ever
      // printed) needs the real, saved row back. This USED to call the
      // full loadFeeData() (every transaction, every payment, every
      // student's summary, service amounts — everything) just to learn
      // one row's number, which is why saving a payment felt slow.
      // Fetching that one row by id uses the same index Postgres
      // already has on the primary key — fast regardless of how much
      // data the hostel has accumulated.
      freshPayment = await repository.getPaymentById(payment.id!);

      if (freshPayment != null) {
        final index = payments.indexWhere((p) => p.id == freshPayment!.id);
        if (index == -1) {
          payments.add(freshPayment);
        } else {
          payments[index] = freshPayment;
        }
      }

      // `transactions` needs the same immediate update `payments` just
      // got above — chargeTransaction/paymentTransaction were already
      // built in memory before recordPayment() saved them, so this is
      // just appending what's already known, no extra fetch needed.
      // Without this, the receipt shown immediately below (before the
      // unawaited loadFeeData() background reload finishes) would
      // compute totalDueForPayment()/remainingBalanceForPayment() from
      // a `transactions` list that doesn't yet contain THIS payment —
      // showing the full month fee as still owed even though the
      // student just paid, on the very receipt handed to them.
      // Guarded the same way as the `payments` merge above — a realtime
      // sync echo of this exact write (RealtimeTableSync, 400ms
      // debounce) could in principle land between the DB write above and
      // these lines and already reassign `transactions` via its own
      // loadFeeData(). Checking by id first avoids adding a duplicate on
      // top of that.
      if (chargeTransaction != null &&
          !transactions.any((t) => t.id == chargeTransaction!.id)) {
        transactions.add(chargeTransaction);
      }
      if (!transactions.any((t) => t.id == paymentTransaction.id)) {
        transactions.add(paymentTransaction);
      }
    } catch (e, stackTrace) {
      AppErrorLogger.log(
        'FeeController._submitPaymentUnsafe (post-save fetch)',
        e,
        stackTrace,
      );
    }

    // The rest of the screen (transactions, student summaries, service
    // amounts) still needs refreshing — deliberately NOT awaited, so the
    // receipt shows immediately instead of waiting on it. Realtime sync
    // (RealtimeTableSync on fee_transactions/fee_payments) would pick
    // this up on its own shortly anyway; this just isn't worth making
    // the person who just took a payment sit and wait for. loadFeeData()
    // handles its own errors internally, so nothing further to guard
    // here.
    // ignore: unawaited_futures
    loadFeeData(notifyOnFailure: false);

    return freshPayment ?? payment;
  }

  Future<void> addPayment(
    FeePayment payment,
  ) async {
    await repository.addPayment(payment);
    await loadFeeData(notifyOnFailure: false);
  }

  Future<void> addTransaction(
    FeeTransaction transaction,
  ) async {
    await repository.addTransaction(transaction);
    await loadFeeData(notifyOnFailure: false);
  }

  // ===========================================================================
  // CORRECTING AN ALREADY-CREATED MONTH'S CHARGE
  //
  // The ONLY supported way to change what a student was charged for a
  // month after the charge transaction already exists. Deliberately
  // narrow: refuses once that month has no pending balance left (fully
  // paid/settled), so a past, reconciled month stays exactly as
  // permanent as it always has been — this only ever touches a month
  // that's still open (unpaid or partially paid). Every other screen's
  // "existing charge = historical source of truth" behavior
  // (computeFeeSummary/computeFeeSummaryForMonth) is completely
  // unaffected by this existing; it simply changes what that "historical
  // truth" actually is, once, on purpose.
  //
  // Returns null on success, or a message to show the admin on failure.
  // ===========================================================================

  Future<String?> updateMonthlyCharge({
    required String studentId,
    required String feeMonth,
    required double newAmount,
  }) async {
    if (newAmount < 0) {
      return 'Amount cannot be negative.';
    }

    final existing = transactions.firstWhereOrNull(
      (t) =>
          t.studentId == studentId &&
          t.feeMonth == feeMonth &&
          t.type == FeeTransactionType.charge,
    );

    if (existing == null || existing.id == null) {
      return 'No charge has been created for this month yet — nothing to correct.';
    }

    // Checked against the CURRENT (pre-correction) charge — this is
    // exactly the same "is this month still open" question every other
    // screen already answers via computeFeeSummaryForMonth, so this
    // can never disagree with what the Fees table/student page are
    // showing right now.
    final summaryBeforeCorrection = computeFeeSummaryForMonth(
      studentId,
      feeMonth,
    );

    if (summaryBeforeCorrection.feePending <= 0) {
      return 'This month is already fully paid and can\'t be corrected here.';
    }

    try {
      await repository.updateMonthlyCharge(
        transactionId: existing.id!,
        newDebit: newAmount,
      );

      final index = transactions.indexWhere((t) => t.id == existing.id);
      if (index != -1) {
        transactions[index] = FeeTransaction(
          id: existing.id,
          studentId: existing.studentId,
          date: existing.date,
          feeMonth: existing.feeMonth,
          description: existing.description,
          debit: newAmount,
          credit: existing.credit,
          balance: existing.balance,
          type: existing.type,
        );
      }

      // Deliberately not awaited — the local list is already corrected
      // above for an instant UI update; this just catches up anything
      // else (other students' summaries, realtime sync to other PCs)
      // in the background, the same pattern every other write here
      // follows.
      // ignore: unawaited_futures
      loadFeeData(notifyOnFailure: false);

      return null;
    } catch (e, stackTrace) {
      AppErrorLogger.log('FeeController.updateMonthlyCharge', e, stackTrace);
      return 'Something went wrong correcting this month\'s charge. Please try again.';
    }
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
      .whereType<String>()
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
    Map<String, double>.fromEntries(results),
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

    // Was required for Bank Transfer (blocked submission with "Please
    // attach the bank payment receipt." if nothing was attached) — no
    // longer enforced. Staff can still attach one via the Bank Payment
    // Receipt section if they have it; it's just optional now, same as
    // every other payment method.

    return null;
  }

  // ===========================================================================
  // PAYMENT FORM — SETTERS
  // ===========================================================================

Future<void> setPaymentStudent(String? studentId) async {
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