import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../students/data/models/student_model.dart';
import '../../data/models/student_fee_summary_model.dart';
import 'fee_table_header.dart';
import 'fee_table_row.dart';

class FeeRecordsTable extends StatefulWidget {
  final List<StudentModel> students;
  final List<StudentFeeSummary> summaries;

  const FeeRecordsTable({
    super.key,
    required this.students,
    required this.summaries,
  });

  @override
  State<FeeRecordsTable> createState() =>
      _FeeRecordsTableState();
}

class _FeeRecordsTableState
    extends State<FeeRecordsTable> {
  String _statusFilter = 'All';

  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void didUpdateWidget(covariant FeeRecordsTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The underlying data set changes whenever the parent switches
    // months (or "All"), or after a payment is recorded — starting back
    // on page 1 avoids landing on a now out-of-range/confusing page.
    _currentPage = 1;
  }

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

          const FeeTableHeader(),

          _buildRows(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Fee Records',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Monthly fee status and outstanding balances',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          OutlinedButton.icon(
            onPressed: _showFilter,
            icon: const Icon(
              Icons.filter_list_rounded,
              size: 17,
            ),
            label: Text(
              _statusFilter == 'All'
                  ? 'Filter'
                  : _statusFilter,
            ),
          ),

          const SizedBox(width: 10),

          ElevatedButton.icon(
            onPressed: () {
              Get.find<AppShellController>()
                  .openRecordPayment();
            },
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
            ),
            label: const Text(
              'Record Payment',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilter() async {
    final result =
        await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Filter Fee Records',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              _filterOption('All'),
              _filterOption('Paid'),
              _filterOption('Partial'),
              _filterOption('Pending'),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      _statusFilter = result;
      _currentPage = 1;
    });
  }

  Widget _filterOption(String value) {
    return ListTile(
      leading: Icon(
        _statusFilter == value
            ? Icons.radio_button_checked
            : Icons.radio_button_off,
        color: AppColors.primary,
      ),
      title: Text(value),
      onTap: () {
        Navigator.of(context).pop(value);
      },
    );
  }

  Widget _buildRows() {
    if (widget.students.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 40,
        ),
        child: Center(
          child: Text(
            'No students found.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final matchingRows = <_RowData>[];

    for (final student in widget.students) {
      if (student.id == null) {
        continue;
      }

      final summary = _findSummary(student.id!);

      if (summary == null) {
        continue;
      }

      final monthlyFee = summary.feeCharged;
      final paid = summary.feeSubmitted;

      final rawBalance = summary.feePending;

      final balance =
          rawBalance < 0 ? 0.0 : rawBalance;

     final status = _getStatus(
  monthlyFee: monthlyFee,   
  paid: paid,
  balance: balance,
);

      if (_statusFilter != 'All' &&
          status != _statusFilter) {
        continue;
      }

      matchingRows.add(
        _RowData(
          name: student.name,
          studentId: student.rollNumber ?? '-',
          monthlyFee: monthlyFee,
          paid: paid,
          balance: balance,
          status: status,
        ),
      );
    }

    if (matchingRows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 40,
        ),
        child: Center(
          child: Text(
            'No records match the selected filter.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // Pagination — "All" months plus many students can add up to a very
    // long list; this keeps it from just growing forever on screen.
    // -------------------------------------------------------------------------

    final totalPages = (matchingRows.length / _pageSize).ceil().clamp(1, 1 << 30);
    final page = _currentPage.clamp(1, totalPages);

    final start = ((page - 1) * _pageSize).clamp(0, matchingRows.length);
    final end = (start + _pageSize).clamp(0, matchingRows.length);
    final pageRows = matchingRows.sublist(start, end);

    return Column(
      children: [
        ...pageRows.map(
          (row) => FeeTableRow(
            name: row.name,
            studentId: row.studentId,
            monthlyFee: _formatAmount(row.monthlyFee),
            paid: _formatAmount(row.paid),
            balance: _formatAmount(row.balance),
            status: row.status,
          ),
        ),

        if (totalPages > 1)
          _buildPaginationFooter(
            page: page,
            totalPages: totalPages,
            totalRows: matchingRows.length,
            rangeStart: start + 1,
            rangeEnd: end,
          ),
      ],
    );
  }

  Widget _buildPaginationFooter({
    required int page,
    required int totalPages,
    required int totalRows,
    required int rangeStart,
    required int rangeEnd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Text(
            'Showing $rangeStart–$rangeEnd of $totalRows records',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          const Spacer(),

          IconButton(
            tooltip: 'Previous page',
            onPressed: page > 1
                ? () => setState(() => _currentPage = page - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),

          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$page',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Text(
            'of $totalPages',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          IconButton(
            tooltip: 'Next page',
            onPressed: page < totalPages
                ? () => setState(() => _currentPage = page + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  StudentFeeSummary? _findSummary(
    String studentId,
  ) {
    for (final summary in widget.summaries) {
      if (summary.studentId == studentId) {
        return summary;
      }
    }

    return null;
  }

 String _getStatus({
  required double monthlyFee,   // <-- added
  required double paid,
  required double balance,
}) {
  // A student never charged or paid anything (monthlyFee: 0, paid: 0,
  // balance: 0) used to fall into `balance <= 0` below and show "Paid" —
  // misleading, since nothing was ever billed to them yet.
  if (monthlyFee <= 0 && paid <= 0) {
    return 'Not Billed';
  }

  if (balance <= 0) {
    return 'Paid';
  }

  if (paid > 0) {
    return 'Partial';
  }

  return 'Pending';
}

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (match) => ',',
        );

    return 'Rs. $formatted';
  }
}

// =============================================================================
// Row data — intermediate representation so rows can be filtered and
// paginated before being turned into widgets.
// =============================================================================

class _RowData {
  final String name;
  final String studentId;
  final double monthlyFee;
  final double paid;
  final double balance;
  final String status;

  const _RowData({
    required this.name,
    required this.studentId,
    required this.monthlyFee,
    required this.paid,
    required this.balance,
    required this.status,
  });
}