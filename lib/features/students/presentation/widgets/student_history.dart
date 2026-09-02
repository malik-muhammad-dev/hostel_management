import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../fees/data/models/fee_payment_model.dart';
import '../../../fees/presentation/controllers/fee_controller.dart';
import '../controllers/student_controller.dart';

class StudentHistory extends StatelessWidget {
  final String studentId;

  const StudentHistory({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final studentController = Get.find<StudentController>();
    final feeController = Get.find<FeeController>();

    return Obx(() {
      final student = studentController.students.firstWhereOrNull(
        (student) => student.id == studentId,
      );

      if (student == null) {
        return const SizedBox.shrink();
      }

      final events = _buildHistory(
        student: student,
        payments: feeController.payments
            .where(
              (payment) => payment.studentId == studentId,
            )
            .toList(),
      );

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            const SizedBox(height: 28),

            if (events.isEmpty)
              _buildEmptyState()
            else
              ...events.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final event = entry.value;

                  return _HistoryItem(
                    date: event.date,
                    title: event.title,
                    description: event.description,
                    icon: event.icon,
                    isLast: index == events.length - 1,
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.history_rounded,
            size: 19,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student History',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Important activities and changes related to this student',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // BUILD REAL HISTORY
  // ===========================================================================

  List<_HistoryEvent> _buildHistory({
    required dynamic student,
    required List<FeePayment> payments,
  }) {
    final events = <_HistoryEvent>[];

    // -------------------------------------------------------------------------
    // Admission
    // -------------------------------------------------------------------------

    if (student.admissionDate != null &&
        student.admissionDate!.trim().isNotEmpty) {
      events.add(
        _HistoryEvent(
          date: _formatDate(student.admissionDate!),
          title: 'Student Admitted',
          description:
              'Student profile was created and admission was recorded.',
          icon: Icons.person_add_alt_1_outlined,
          sortDate: _parseDate(student.admissionDate!),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // Hostel information
    //
    // We only show this when actual hostel information exists.
    // -------------------------------------------------------------------------

    final hasHostelInformation =
        (student.hostelBlock?.trim().isNotEmpty ?? false) ||
        (student.roomNumber?.trim().isNotEmpty ?? false) ||
        (student.bedNumber?.trim().isNotEmpty ?? false);

    if (hasHostelInformation) {
      final hostelParts = <String>[];

      if (student.hostelBlock?.trim().isNotEmpty ?? false) {
        hostelParts.add(
          'Block ${student.hostelBlock!.trim()}',
        );
      }

      if (student.roomNumber?.trim().isNotEmpty ?? false) {
        hostelParts.add(
          'Room ${student.roomNumber!.trim()}',
        );
      }

      if (student.bedNumber?.trim().isNotEmpty ?? false) {
        hostelParts.add(
          'Bed ${student.bedNumber!.trim()}',
        );
      }

      final hostelDate =
          student.checkInDate?.trim().isNotEmpty ?? false
              ? student.checkInDate!
              : student.admissionDate;

      events.add(
        _HistoryEvent(
          date: hostelDate != null
              ? _formatDate(hostelDate)
              : '-',
          title: 'Room Information',
          description:
              '${hostelParts.join(' • ')} is assigned to this student.',
          icon: Icons.bed_outlined,
          sortDate: hostelDate != null
              ? _parseDate(hostelDate)
              : DateTime(1900),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // Real payments
    // -------------------------------------------------------------------------

    for (final payment in payments) {
      final amount = _formatAmount(
        payment.amountReceived,
      );

      final method =
          _formatPaymentMethod(payment.paymentMethod);

      final date = payment.paymentDate.trim().isEmpty
          ? '-'
          : _formatDate(payment.paymentDate);

      events.add(
        _HistoryEvent(
          date: date,
          title: 'Payment Recorded',
          description:
              '$amount payment was recorded via $method.',
          icon: Icons.payments_outlined,
          sortDate: _parseDate(payment.paymentDate),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // Sort newest first
    // -------------------------------------------------------------------------

    events.sort(
      (a, b) => b.sortDate.compareTo(a.sortDate),
    );

    return events;
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 30,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 30,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 10),
            Text(
              'No history available',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Student activities will appear here when recorded.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DATE
  // ===========================================================================

  String _formatDate(String value) {
    final date = _parseDate(value);

    if (date.year == 1900) {
      return value;
    }

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  DateTime _parseDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed != null) {
      return parsed;
    }

    return DateTime(1900);
  }

  // ===========================================================================
  // AMOUNT
  // ===========================================================================

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );

    return 'Rs. $formatted';
  }

  // ===========================================================================
  // PAYMENT METHOD
  // ===========================================================================

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';

      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';

      default:
        return method.name;
    }
  }
}

// =============================================================================
// History event
// =============================================================================

class _HistoryEvent {
  final String date;
  final String title;
  final String description;
  final IconData icon;
  final DateTime sortDate;

  const _HistoryEvent({
    required this.date,
    required this.title,
    required this.description,
    required this.icon,
    required this.sortDate,
  });
}

// =============================================================================
// History item
// =============================================================================

class _HistoryItem extends StatelessWidget {
  final String date;
  final String title;
  final String description;
  final IconData icon;
  final bool isLast;

  const _HistoryItem({
    required this.date,
    required this.title,
    required this.description,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: AppColors.primary,
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 58,
                  margin: const EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  color: AppColors.border,
                ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}