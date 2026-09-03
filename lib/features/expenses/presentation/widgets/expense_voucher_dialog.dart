import 'package:flutter/material.dart';
import 'package:hostel_management/app/theme/app_colors.dart';
import 'package:hostel_management/features/expenses/models/expense_model.dart';
import 'package:hostel_management/features/expenses/services/expense_voucher_generator.dart';
import 'package:printing/printing.dart';

// =============================================================================
// EXPENSE VOUCHER DIALOG
//
// Same pattern as the Fees ReceiptDialog — a live PDF preview with
// Save/Print/Share built in via the `printing` package. Used both right
// after adding an expense, and later from the expenses table to
// re-view/re-download any past expense's voucher.
// =============================================================================

Future<void> showExpenseVoucherDialog(
  BuildContext context, {
  required ExpenseModel expense,
}) {
  return showDialog(
    context: context,
    builder: (context) => ExpenseVoucherDialog(expense: expense),
  );
}

class ExpenseVoucherDialog extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseVoucherDialog({super.key, required this.expense});

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
                      'Expense Voucher',
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
                  final doc = await ExpenseVoucherGenerator.build(
                    expense: expense,
                  );
                  return doc.save();
                },
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                pdfFileName: '${_fileNameLabel(expense)}.pdf',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Matches the "Voucher No." shown inside the PDF itself
  // (ExpenseVoucherGenerator) rather than the raw UUID, so a saved file's
  // name is something the client can actually read out.
  String _fileNameLabel(ExpenseModel expense) {
    if (expense.voucherNo != null) {
      return 'Voucher_EXP-${expense.voucherNo.toString().padLeft(4, '0')}';
    }
    return expense.id == null ? 'Voucher_draft' : 'Voucher_EXP-PENDING';
  }
}