import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/realtime/realtime_table_sync.dart';
import '../../../students/data/models/student_model.dart';
import '../../../students/presentation/controllers/student_controller.dart';
import '../../data/repositories/receipt_repository.dart';
import '../../models/receipt_model.dart';

class ReceiptController extends GetxController {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final ReceiptRepository repository;
  final StudentController studentController = Get.find<StudentController>();

  ReceiptController(this.repository);

  // ===========================================================================
  // FORM CONTROLLERS
  // ===========================================================================

  final dateController = TextEditingController();
  final amountController = TextEditingController();

  /// Only used when [receivedFromType] is `faculty` — the free-typed
  /// name field. When it's `student`, the name comes from whichever
  /// student is picked in [selectedStudentId] instead.
  final receivedFromController = TextEditingController();

  final notesController = TextEditingController();

  final paymentMode = Rxn<ReceiptPaymentMode>();

  // ===========================================================================
  // WHO THIS CASH IS FOR — Student or Faculty
  // ===========================================================================

  final receivedFromType = Rxn<ReceivedFromType>();
  final selectedStudentId = Rxn<String>();

  void setReceivedFromType(ReceivedFromType? type) {
    receivedFromType.value = type;

    // Switching type clears whatever the other type had filled in, so a
    // half-picked student doesn't silently linger after switching to
    // Faculty (and vice versa).
    if (type == ReceivedFromType.faculty) {
      selectedStudentId.value = null;
    } else if (type == ReceivedFromType.student) {
      receivedFromController.clear();
    }
  }

  void setSelectedStudent(String? studentId) {
    selectedStudentId.value = studentId;
  }

  // ===========================================================================
  // RECEIPT DATA
  // ===========================================================================

  final receipts = <ReceiptModel>[].obs;

  // ===========================================================================
  // UI STATE
  // ===========================================================================

  final isSaving = false.obs;
  final isLoading = false.obs;

  // ===========================================================================
  // EDITING
  // ===========================================================================

  final editingReceipt = Rxn<ReceiptModel>();

  bool get isEditMode => editingReceipt.value != null;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // Realtime — reloads from Supabase whenever `cash_receipts` changes,
  // from this PC or any other one. See RealtimeTableSync for why this
  // exists and why it just re-runs loadReceipts() rather than merging
  // rows.
  // ---------------------------------------------------------------------------

  late final RealtimeTableSync _realtimeSync;

  @override
  void onInit() {
    super.onInit();

    dateController.text = _formatDate(DateTime.now());
    selectedMonth.value = _monthKey(DateTime.now());

    loadReceipts();

    _realtimeSync = RealtimeTableSync(
      tables: const ['cash_receipts'],
      onChange: loadReceipts,
    );
  }

  @override
  void onClose() {
    _realtimeSync.dispose();

    dateController.dispose();
    amountController.dispose();
    receivedFromController.dispose();
    notesController.dispose();

    super.onClose();
  }

  // ===========================================================================
  // LOAD RECEIPTS
  // ===========================================================================

  Future<void> loadReceipts() async {
    try {
      isLoading.value = true;

      final result = await repository.getReceipts();

      receipts.assignAll(result);
    } catch (e, stackTrace) {
      // Was try/finally only, with no catch — harmless while this read
      // from local SQLite, but Receipts is about to read from Supabase
      // over the network. Without this, a failed fetch would throw
      // uncaught and leave the screen stuck loading with no visible
      // error — whatever receipts were already loaded just stay as-is.
      debugPrint('[RECEIPTS] loadReceipts failed: $e');
      debugPrint('$stackTrace');
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

  // ===========================================================================
  // PAYMENT MODE
  // ===========================================================================

  void setPaymentMode(ReceiptPaymentMode? mode) {
    paymentMode.value = mode;
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  String? validate() {
    final dateText = dateController.text.trim();

    if (dateText.isEmpty) {
      return 'Please select a date.';
    }

    final date = DateTime.tryParse(dateText);

    if (date == null) {
      return 'Please enter a valid date.';
    }

    final amountText = amountController.text.trim();

    if (amountText.isEmpty) {
      return 'Please enter the amount received.';
    }

    final amount = double.tryParse(amountText);

    if (amount == null) {
      return 'Please enter a valid amount.';
    }

    if (amount <= 0) {
      return 'Amount must be greater than zero.';
    }

    if (paymentMode.value == null) {
      return 'Please select where this cash is being kept (Cash / Account).';
    }

    if (receivedFromType.value == null) {
      return 'Please specify whether this is for a Student or Faculty.';
    }

    if (receivedFromType.value == ReceivedFromType.student &&
        selectedStudentId.value == null) {
      return 'Please select a student.';
    }

    if (receivedFromType.value == ReceivedFromType.faculty &&
        receivedFromController.text.trim().isEmpty) {
      return "Please enter the faculty member's name.";
    }

    return null;
  }

  // ===========================================================================
  // BUILD MODEL
  // ===========================================================================

  ReceiptModel? buildReceiptModel() {
    final validationMessage = validate();

    if (validationMessage != null) {
      return null;
    }

    final date = selectedDate;

    final amount = double.tryParse(amountController.text.trim());

    final mode = paymentMode.value;

    if (date == null || amount == null || mode == null) {
      return null;
    }

    final type = receivedFromType.value;
    final notes = notesController.text.trim();

    String? receivedFrom;
    String? studentId;

    if (type == ReceivedFromType.student) {
      studentId = selectedStudentId.value;
      final student = studentController.activeStudents.firstWhereOrNull(
        (s) => s.id == studentId,
      );
      receivedFrom = student?.name;
    } else if (type == ReceivedFromType.faculty) {
      final typed = receivedFromController.text.trim();
      receivedFrom = typed.isEmpty ? null : typed;
    }

    return ReceiptModel(
      id: editingReceipt.value?.id,
      date: date,
      amount: amount,
      paymentMode: mode,
      receivedFrom: receivedFrom,
      receivedFromType: type,
      studentId: studentId,
      notes: notes.isEmpty ? null : notes,
    );
  }

  // ===========================================================================
  // ADD RECEIPT
  // ===========================================================================

  Future<ReceiptModel?> addReceipt() async {
    final receipt = buildReceiptModel();

    if (receipt == null) {
      return null;
    }

    try {
      isSaving.value = true;

      final savedReceipt = receipt.copyWith(id: const Uuid().v4());

      await repository.addReceipt(savedReceipt);

      receipts.add(savedReceipt);

      clearForm();

      return savedReceipt;
    } catch (e, stackTrace) {
      debugPrint('[RECEIPTS] addReceipt failed: $e');
      debugPrint('$stackTrace');
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  // ===========================================================================
  // UPDATE RECEIPT
  // ===========================================================================

  Future<bool> updateReceipt() async {
    final receipt = buildReceiptModel();

    if (receipt == null || receipt.id == null) {
      return false;
    }

    try {
      isSaving.value = true;

      await repository.updateReceipt(receipt);

      final index = receipts.indexWhere((item) => item.id == receipt.id);

      if (index == -1) {
        return false;
      }

      receipts[index] = receipt;

      clearForm();

      return true;
    } catch (e) {
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ===========================================================================
  // DELETE RECEIPT
  // ===========================================================================

  Future<bool> deleteReceipt(String receiptId) async {
    try {
      isLoading.value = true;

      final exists = receipts.any((receipt) => receipt.id == receiptId);

      if (!exists) {
        return false;
      }

      await repository.deleteReceipt(receiptId);

      receipts.removeWhere((receipt) => receipt.id == receiptId);

      return true;
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // EDIT RECEIPT
  // ===========================================================================

  void editReceipt(ReceiptModel receipt) {
    editingReceipt.value = receipt;

    dateController.text = _formatDate(receipt.date);
    amountController.text = receipt.amount.toStringAsFixed(2);
    notesController.text = receipt.notes ?? '';
    paymentMode.value = receipt.paymentMode;

    receivedFromType.value = receipt.receivedFromType;

    if (receipt.receivedFromType == ReceivedFromType.faculty) {
      receivedFromController.text = receipt.receivedFrom ?? '';
      selectedStudentId.value = null;
    } else {
      receivedFromController.clear();
      selectedStudentId.value = receipt.studentId;
    }
  }

  // ===========================================================================
  // CLEAR FORM
  // ===========================================================================

  void clearForm() {
    editingReceipt.value = null;

    dateController.text = _formatDate(DateTime.now());
    amountController.clear();
    receivedFromController.clear();
    notesController.clear();
    paymentMode.value = null;
    receivedFromType.value = null;
    selectedStudentId.value = null;
  }

  // ===========================================================================
  // SUMMARY — all-time. There is no "fee month" concept for this feature
  // (money can come in for any reason, any time), so unlike Expenses this
  // is not scoped to a selected month.
  // ===========================================================================

  double get totalReceipts {
    return receipts.fold<double>(0.0, (total, receipt) => total + receipt.amount);
  }

  double get cashReceipts {
    return receipts
        .where((receipt) => receipt.paymentMode == ReceiptPaymentMode.cash)
        .fold<double>(0.0, (total, receipt) => total + receipt.amount);
  }

  double get accountReceipts {
    return receipts
        .where((receipt) => receipt.paymentMode == ReceiptPaymentMode.account)
        .fold<double>(0.0, (total, receipt) => total + receipt.amount);
  }

  /// Newest first — what the Receipts table actually displays.
  List<ReceiptModel> get receiptsSortedByDateDesc {
    final sorted = List<ReceiptModel>.from(receipts);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  // ===========================================================================
  // DASHBOARD FIGURES — "Student Cash" (Cash / Account boxes)
  //
  // Confirmed rule (client's own words):
  // - A "Cash" entry just adds to the Cash figure. Nothing else moves.
  // - An "Account" entry adds to the Account figure AND subtracts the
  //   same amount from the Cash figure — because the real scenario is
  //   money arriving in the bank while the cashier hands out that same
  //   amount as physical cash to the student. Only the Account portion
  //   also feeds DashboardController.totalAmount (see that getter).
  //
  // These are deliberately separate from the plain totalReceipts/
  // cashReceipts/accountReceipts above, which the Receipts screen's own
  // summary still uses unchanged (a simple raw breakdown by payment
  // mode, not this net accounting view).
  // ===========================================================================

  double get netCashBox => cashReceipts - accountReceipts;

  double get accountBox => accountReceipts;

  // ===========================================================================
  // MONTH FILTER — used by the Reports section's "Student Cash Report"
  // only. The Receipts screen itself stays all-time/unfiltered on
  // purpose (see class comment), so this doesn't affect it.
  // ===========================================================================

  final selectedMonth = ''.obs;

  void setSelectedMonth(String month) {
    selectedMonth.value = month;
  }

  String _monthKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}';
  }

  List<ReceiptModel> receiptsForMonth(String month) {
    final filtered =
        receipts.where((receipt) => _monthKey(receipt.date) == month).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  double totalForMonth(String month) {
    return receiptsForMonth(month)
        .fold<double>(0.0, (total, receipt) => total + receipt.amount);
  }

  double cashForMonth(String month) {
    return receiptsForMonth(month)
        .where((receipt) => receipt.paymentMode == ReceiptPaymentMode.cash)
        .fold<double>(0.0, (total, receipt) => total + receipt.amount);
  }

  double accountForMonth(String month) {
    return receiptsForMonth(month)
        .where((receipt) => receipt.paymentMode == ReceiptPaymentMode.account)
        .fold<double>(0.0, (total, receipt) => total + receipt.amount);
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