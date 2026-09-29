import 'package:get/get.dart';

import '../../../fees/presentation/controllers/fee_controller.dart';
import '../../../students/data/models/student_model.dart';
import '../../../students/presentation/controllers/student_controller.dart';
import '../../../fees/data/models/student_fee_summary_model.dart';

class FeeCollectionReportController extends GetxController {
  final FeeController feeController =
      Get.find<FeeController>();

  final StudentController studentController =
      Get.find<StudentController>();

  // ===========================================================================
  // STATE
  // ===========================================================================

  final selectedMonth = ''.obs;

  final isLoading = false.obs;

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
  // STUDENT SUMMARIES
  // ===========================================================================

  // An Inactive student is excluded here — client's explicit
  // instruction: her fee should be "completely off" everywhere (Fees
  // screen, this report, the visible table below), not just hidden on
  // the Dashboard. Archived students were already excluded via
  // `activeStudents`; this narrows it further, matching
  // FeeController.totalExpected/outstanding/overdue's own filtering.
  List<StudentModel> get _currentStudents {
    return studentController.activeStudents
        .where((student) => student.status != 'Inactive')
        .toList();
  }

  List<StudentFeeSummary> get studentSummaries {
    final month = selectedMonth.value;

    if (month.isEmpty) {
      return [];
    }

    return _currentStudents
        .where((student) => student.id != null)
        .map(
          (student) =>
              feeController.computeFeeSummaryForMonth(
            student.id!,
            month,
          ),
        )
        .toList();
  }

  // ===========================================================================
  // TOTALS
  // ===========================================================================

  double get totalExpected {
    return studentSummaries.fold<double>(
      0.0,
      (total, summary) =>
          total + summary.feeCharged,
    );
  }

  // Deliberately NOT scoped to `studentSummaries`/`_currentStudents` —
  // money a student genuinely already paid must never retroactively
  // vanish from this report just because she went Inactive afterward
  // (same principle as DashboardController.allTimeCollected/
  // _collectedForMonth). Total Expected/Outstanding above answer "what
  // does the hostel currently expect to collect," which rightly drops
  // an Inactive student; Total Collected answers "what has actually
  // been received," which never should.
  double get totalCollected {
    final month = selectedMonth.value;
    if (month.isEmpty) return 0.0;

    return studentController.activeStudents
        .where((student) => student.id != null)
        .fold<double>(0.0, (total, student) {
      final summary = feeController.computeFeeSummaryForMonth(
        student.id!,
        month,
      );
      return total + summary.feeSubmitted;
    });
  }

  // NOT a straight sum of `feePending` — that lets one student's
  // overpayment (a late fine folded into their payment amount, or a
  // generous discount) go negative and silently cancel out another
  // student's genuinely unpaid balance in the total, the exact same
  // issue fixed on FeeController.outstanding (see its comment for the
  // full explanation). Each student's contribution is clamped at a
  // floor of 0 here too, so this report's Outstanding always reflects
  // real money still owed, never a netted-down figure.
  double get totalOutstanding {
    return studentSummaries.fold<double>(
      0.0,
      (total, summary) =>
          total + (summary.feePending < 0 ? 0.0 : summary.feePending),
    );
  }

  double get collectionRate {
    if (totalExpected <= 0) {
      return 0.0;
    }

    return (totalCollected / totalExpected) * 100;
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  List<StudentModel> get students {
    return _currentStudents;
  }

  StudentFeeSummary? summaryForStudent(
    String studentId,
  ) {
    for (final summary in studentSummaries) {
      if (summary.studentId == studentId) {
        return summary;
      }
    }

    return null;
  }
}