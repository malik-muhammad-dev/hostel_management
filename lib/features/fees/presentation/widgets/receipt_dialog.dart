import 'package:flutter/material.dart';
import 'package:hostel_management/app/theme/app_colors.dart';
import 'package:hostel_management/features/fees/data/models/fee_payment_model.dart';
import 'package:hostel_management/features/fees/services/receipt_generator.dart';
import 'package:hostel_management/features/students/data/models/student_model.dart';
import 'package:printing/printing.dart';



// =============================================================================
// RECEIPT DIALOG
//
// Shows a live preview of the payment receipt with Save/Print/Share
// built in (via the `printing` package's PdfPreview widget — this is
// what gives the "Save as PDF" option, using each OS's native save/print
// dialog under the hood, so it behaves correctly on Linux/Windows/macOS
// without us needing to build a custom file-save flow).
//
// Used in two places with identical behavior:
//  1. Right after a payment is successfully recorded.
//  2. Later, from a student's Fee Payments history, to re-view/re-download
//     the receipt for any past payment.
// =============================================================================

Future<void> showReceiptDialog(
  BuildContext context, {
  required StudentModel student,
  required FeePayment payment,
}) {
  return showDialog(
    context: context,
    builder: (context) => ReceiptDialog(student: student, payment: payment),
  );
}

class ReceiptDialog extends StatelessWidget {
  final StudentModel student;
  final FeePayment payment;

  const ReceiptDialog({
    super.key,
    required this.student,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 460,
        height: 640,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Payment Receipt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: PdfPreview(
                build: (format) async {
                  final doc = await ReceiptGenerator.build(
                    student: student,
                    payment: payment,
                  );
                  return doc.save();
                },
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                pdfFileName:
                    'Receipt_${student.name.replaceAll(' ', '_')}_${payment.feeMonth}.pdf',
              ),
            ),
          ],
        ),
      ),
    );
  }
}