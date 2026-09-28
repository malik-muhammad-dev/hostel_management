import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hostel_management/app/theme/app_colors.dart';
import 'package:hostel_management/features/expenses/models/expense_model.dart';
import 'package:hostel_management/features/expenses/services/expense_voucher_generator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

// =============================================================================
// EXPENSE VOUCHER DIALOG
//
// Same pattern as the Fees ReceiptDialog — a live PDF preview with Print
// built in via the `printing` package. The package's own "Share" icon
// was removed (allowSharing: false) — on Windows it did nothing useful,
// just opening the PDF in a browser tab. A "Send via WhatsApp" icon
// takes its place in the same toolbar instead: saves the voucher PDF to
// a well-known folder, opens that folder in Explorer so the file is one
// drag away, and opens WhatsApp Web (already logged in on the staff
// laptop) so they just pick the chat and drag the file in themselves.
//
// Used both right after adding an expense, and later from the expenses
// table to re-view/re-download any past expense's voucher.
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

  // Category + the expense's own date (not today's date) — e.g.
  // "Voucher_Electricity_Bill_10-Sep-2026" — rather than the voucher
  // number, so the file name itself tells staff what it is without
  // opening it. Category is sanitized because a few categories contain
  // "/" (e.g. "PTCL / Internet Bill"), which isn't a legal character in
  // a Windows file name.
  String _fileNameLabel(ExpenseModel expense) {
    final category = _sanitizeForFileName(expense.category);
    final date = _formatFileDate(expense.date);
    return 'Voucher_${category}_$date';
  }

  String _sanitizeForFileName(String value) {
    return value
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
  }

  String _formatFileDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '$day-${months[date.month - 1]}-${date.year}';
  }

  Future<void> _sendViaWhatsApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final doc = await ExpenseVoucherGenerator.build(expense: expense);
      final bytes = await doc.save();

      // Same folder used for fee receipts, so staff only have to
      // remember one place — Documents/ONIMS Receipts.
      final documentsDir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(documentsDir.path, 'ONIMS Receipts'));
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final file = File(
        p.join(folder.path, '${_fileNameLabel(expense)}.pdf'),
      );
      await file.writeAsBytes(bytes);

      // Open the folder first so the file is visible and ready to drag...
      await launchUrl(Uri.file(folder.path));
      // ...then open WhatsApp Web so staff can pick the chat.
      await launchUrl(
        Uri.parse('https://web.whatsapp.com'),
        mode: LaunchMode.externalApplication,
      );

      messenger?.showSnackBar(
        const SnackBar(
          content: Text(
            'Voucher saved to "ONIMS Receipts" — drag it into the chat on WhatsApp.',
          ),
        ),
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Could not open WhatsApp: $e')),
      );
    }
  }

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
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                pdfFileName: '${_fileNameLabel(expense)}.pdf',
                actions: [
                  IconButton(
                    tooltip: 'Send via WhatsApp',
                    onPressed: () => _sendViaWhatsApp(context),
                    icon: const Icon(
                      Icons.chat_rounded,
                      color: Color(0xFF25D366),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}