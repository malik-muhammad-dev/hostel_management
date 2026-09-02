import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../students/data/models/student_model.dart';
import '../../../fees/data/models/student_fee_summary_model.dart';

class FeeCollectionTable extends StatelessWidget {
  final List<StudentModel> students;
  final List<StudentFeeSummary> summaries;

  const FeeCollectionTable({
    super.key,
    required this.students,
    required this.summaries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(
            height: 1,
            color: AppColors.border,
          ),
          _buildTableHeader(),
          _buildRows(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Student Fee Collection',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Monthly fee collection by student',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Student',
              style: _headerStyle,
            ),
          ),
          Expanded(
            child: Text(
              'Charged',
              style: _headerStyle,
            ),
          ),
          Expanded(
            child: Text(
              'Paid',
              style: _headerStyle,
            ),
          ),
          Expanded(
            child: Text(
              'Pending',
              style: _headerStyle,
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              'Status',
              style: _headerStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRows() {
    final rows = students.where(
      (student) => student.id != null,
    );

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No students found.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: rows.map(
        (student) {
          final summary = _summaryFor(
            student.id!,
          );

          if (summary == null) {
            return const SizedBox.shrink();
          }

          return _buildRow(
            student,
            summary,
          );
        },
      ).toList(),
    );
  }

  Widget _buildRow(
    StudentModel student,
    StudentFeeSummary summary,
  ) {
    final pending =
        summary.feePending < 0
            ? 0.0
            : summary.feePending;

    final status = _status(
      summary.feeSubmitted,
      pending,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              student.name,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatAmount(
                summary.feeCharged,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatAmount(
                summary.feeSubmitted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatAmount(pending),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  StudentFeeSummary? _summaryFor(
    String studentId,
  ) {
    for (final summary in summaries) {
      if (summary.studentId == studentId) {
        return summary;
      }
    }

    return null;
  }

  String _status(
    double paid,
    double pending,
  ) {
    if (pending <= 0) {
      return 'Paid';
    }

    if (paid > 0) {
      return 'Partial';
    }

    return 'Pending';
  }

  String _formatAmount(double amount) {
    return 'Rs. ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        )}';
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
}