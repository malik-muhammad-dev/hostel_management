import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hostel_management/core/widgets/app_shell.dart';

import 'package:hostel_management/features/fees/presentation/controllers/fee_controller.dart';
import 'package:hostel_management/features/students/presentation/controllers/student_controller.dart';
import '../widgets/payment_date_section.dart';
import '../widgets/receipt_dialog.dart';

import '../../../../app/theme/app_colors.dart';
import '../widgets/payment_actions.dart';
import '../widgets/payment_amount_section.dart';
import '../widgets/payment_basic_information.dart';
import '../widgets/payment_fee_summary.dart';
import '../widgets/payment_reference_section.dart';

class RecordPaymentScreen extends StatelessWidget {
  const RecordPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feeController = Get.find<FeeController>();
    final studentController = Get.find<StudentController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 24),

          Obx(
            () => PaymentBasicInformation(
              students: studentController.activeStudents,
              selectedStudentId: feeController.selectedStudentId.value,
              selectedPaymentMethod: feeController.selectedPaymentMethod.value,
              selectedFeeMonth: feeController.selectedFeeMonth.value,
              onStudentChanged: feeController.setPaymentStudent,
              onPaymentMethodChanged: feeController.setPaymentMethod,
              onFeeMonthChanged: feeController.setFeeMonth,
            ),
          ),
          const SizedBox(height: 24),

          Obx(
            () => PaymentFeeSummary(
              currentMonthFee: feeController.selectedCurrentMonthFee,
              alreadyPaidThisMonth: feeController.selectedAlreadyPaidThisMonth,
              previousBalance: feeController.selectedPreviousBalance,
              fine: feeController.selectedFine,
              discount: feeController.selectedDiscount,
              totalDue: feeController.selectedTotalDue,
            ),
          ),

          const SizedBox(height: 24),

          const PaymentAmountSection(),

          const SizedBox(height: 24),

          const PaymentReferenceSection(),

          const SizedBox(height: 28),
          const PaymentDateSection(),
          const SizedBox(height: 28),

          PaymentActions(
           onCancel: () {
  feeController.resetPaymentForm();
  Get.find<AppShellController>().popPage();
},
            onSubmit: () async {
              final validationMessage = feeController.validatePayment();

              if (validationMessage != null) {
                Get.snackbar(
                  'Payment Validation',
                  validationMessage,
                  snackPosition: SnackPosition.BOTTOM,
                );

                return;
              }

              // Captured before submitPayment() clears the form.
              final studentId = feeController.selectedStudentId.value;

              // submitPayment() now hands back the exact payment record
              // it just created (already carrying its real, persisted
              // UUID id) instead of just a bool — so there's no more
              // need to go searching for "the just-created payment"
              // afterward. The old approach found it by picking the
              // highest id among that student/month's payments, which
              // only worked because ids used to be sequential integers
              // assigned by SQLite; that assumption no longer holds now
              // that ids are UUIDs.
              final justCreatedPayment = await feeController.submitPayment();

              if (justCreatedPayment == null) {
                return;
              }

              final student = studentController.activeStudents
                  .firstWhereOrNull((student) => student.id == studentId);

              feeController.resetPaymentForm();

              if (justCreatedPayment != null &&
                  student != null &&
                  context.mounted) {
                await showReceiptDialog(
                  context,
                  student: student,
                  payment: justCreatedPayment,
                );
              }

              if (context.mounted) {
                Get.find<AppShellController>().popPage();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Record Payment',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Record a payment received from a student',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}