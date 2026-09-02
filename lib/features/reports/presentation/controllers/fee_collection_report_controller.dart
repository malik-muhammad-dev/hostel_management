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

  List<StudentFeeSummary> get studentSummaries {
    final month = selectedMonth.value;

    if (month.isEmpty) {
      return [];
    }

    return studentController.activeStudents
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

  double get totalCollected {
    return studentSummaries.fold<double>(
      0.0,
      (total, summary) =>
          total + summary.feeSubmitted,
    );
  }

  double get totalOutstanding {
    return studentSummaries.fold<double>(
      0.0,
      (total, summary) =>
          total + summary.feePending,
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
    return studentController.activeStudents;
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