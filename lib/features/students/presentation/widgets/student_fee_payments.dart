import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hostel_management/features/students/presentation/controllers/student_controller.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../fees/data/models/fee_payment_model.dart';
import '../../../fees/presentation/controllers/fee_controller.dart';
import '../../../fees/presentation/widgets/receipt_dialog.dart';
import '../../data/models/student_model.dart';

class StudentFeePayments extends StatelessWidget {
  final String studentId;

  const StudentFeePayments({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final feeController = Get.find<FeeController>();
    final studentController = Get.find<StudentController>();

    return Obx(() {
      final student = studentController.students.firstWhereOrNull(
        (student) => student.id == studentId,
      );

      if (student == null) {
        return const SizedBox.shrink();
      }

      final summary = feeController.computeFeeSummary(studentId);

      final studentPayments = feeController.payments
          .where((payment) => payment.studentId == studentId)
          .toList()
        ..sort(
          (a, b) => b.paymentDate.compareTo(a.paymentDate),
        );

      final totalDiscount = studentPayments.fold<double>(
        0,
        (sum, payment) => sum + payment.discount,
      );

      // summary.feeCharged is already net of every discount ever given
      // to this student (see FeeController.computeFeeSummary) — it IS
      // Net Payable already. "Total Charges" (the gross, pre-discount
      // figure this card also shows) is reconstructed by adding the
      // discount back, rather than subtracting it a second time here —
      // that double-subtraction used to make a discounted-but-not-fully-
      // paid student appear fully "Paid" with Rs. 0 owed.
      final netPayable = summary.feeCharged;

      final totalCharges = netPayable + totalDiscount;

      final totalPaid = summary.feeSubmitted;

      final remaining = (netPayable - totalPaid) < 0
          ? 0.0
          : netPayable - totalPaid;

      final status = _getStatus(
        paid: totalPaid,
        remaining: remaining,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeeSummaryCard(
            totalCharges: totalCharges,
            discount: totalDiscount,
            netPayable: netPayable,
            totalPaid: totalPaid,
            remaining: remaining,
            status: status,
          ),

          const SizedBox(height: 20),

          _PaymentHistoryCard(
            payments: studentPayments,
            studentId: studentId,
            student: student,
          ),
        ],
      );
    });
  }

  String _getStatus({
    required double paid,
    required double remaining,
  }) {
    if (remaining <= 0 && paid > 0) {
      return 'Paid';
    }

    if (paid > 0) {
      return 'Partially Paid';
    }

    return 'Pending';
  }
}

// =============================================================================
// Fee Summary
// =============================================================================

class _FeeSummaryCard extends StatelessWidget {
  final double totalCharges;
  final double discount;
  final double netPayable;
  final double totalPaid;
  final double remaining;
  final String status;

  const _FeeSummaryCard({
    required this.totalCharges,
    required this.discount,
    required this.netPayable,
    required this.totalPaid,
    required this.remaining,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
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
                      'Fee Summary',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Current financial summary for this student',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              _PaymentStatusBadge(
                label: status,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _FeeAmount(
                  label: 'Total Charges',
                  amount: _formatAmount(totalCharges),
                ),
              ),

              Expanded(
                child: _FeeAmount(
                  label: 'Discount',
                  amount: _formatAmount(discount),
                ),
              ),

              Expanded(
                child: _FeeAmount(
                  label: 'Net Payable',
                  amount: _formatAmount(netPayable),
                ),
              ),

              Expanded(
                child: _FeeAmount(
                  label: 'Total Paid',
                  amount: _formatAmount(totalPaid),
                ),
              ),

              Expanded(
                child: _FeeAmount(
                  label: 'Remaining',
                  amount: _formatAmount(remaining),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );

    return 'Rs. $formatted';
  }
}

// =============================================================================
// Amount
// =============================================================================

class _FeeAmount extends StatelessWidget {
  final String label;
  final String amount;

  const _FeeAmount({
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          amount,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Status Badge
// =============================================================================

class _PaymentStatusBadge extends StatelessWidget {
  final String label;

  const _PaymentStatusBadge({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = label == 'Paid';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isPaid
            ? AppColors.primaryLight
            : AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPaid
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// =============================================================================
// Payment History
// =============================================================================

class _PaymentHistoryCard extends StatelessWidget {
  final List<FeePayment> payments;
  final String studentId;
  final StudentModel student;

  const _PaymentHistoryCard({
    required this.payments,
    required this.studentId,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
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
                      'Payment History',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Payments made by this student',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              OutlinedButton.icon(
                onPressed: () {
                  if (student.status == 'Archived') {
                    Get.snackbar(
                      'Student Archived',
                      'This student is archived — new payments can\'t be recorded for them.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }

                  final feeController = Get.find<FeeController>();

                  feeController.setPaymentStudent(studentId);

                  Get.find<AppShellController>().openRecordPayment();
                },
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),
                label: const Text('Record Payment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 30,
              ),
              child: Center(
                child: Text(
                  'No payments recorded for this student.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...payments.map(
              (payment) => _PaymentItem(
                payment: payment,
                student: student,
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Payment Item
// =============================================================================

class _PaymentItem extends StatelessWidget {
  final FeePayment payment;
  final StudentModel student;

  const _PaymentItem({
    required this.payment,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payments_outlined,
              size: 19,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 2,
            child: _PaymentDetail(
              label: 'Date',
              value: payment.paymentDate.isEmpty
                  ? '-'
                  : payment.paymentDate,
            ),
          ),

          Expanded(
            flex: 2,
            child: _PaymentDetail(
              label: 'Amount',
              value: _formatAmount(
                payment.amountReceived,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: _PaymentDetail(
              label: 'Method',
              value: _formatPaymentMethod(
                payment.paymentMethod,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: _PaymentDetail(
              label: 'Reference',
              value: payment.paymentReference?.isNotEmpty == true
                  ? payment.paymentReference!
                  : '-',
            ),
          ),

          IconButton(
            tooltip: 'View Receipt',
            onPressed: () => showReceiptDialog(
              context,
              student: student,
              payment: payment,
            ),
            icon: const Icon(
              Icons.receipt_long_outlined,
              size: 19,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );

    return 'Rs. $formatted';
  }

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
// Payment Detail
// =============================================================================

class _PaymentDetail extends StatelessWidget {
  final String label;
  final String value;

  const _PaymentDetail({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}