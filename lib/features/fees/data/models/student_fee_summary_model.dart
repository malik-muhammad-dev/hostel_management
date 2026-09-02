class StudentFeeSummary {
  final String studentId;
  final double feeCharged;
  final double feeSubmitted;
  final double feePending;

  const StudentFeeSummary({
    required this.studentId,
    required this.feeCharged,
    required this.feeSubmitted,
    required this.feePending,
  });
}
