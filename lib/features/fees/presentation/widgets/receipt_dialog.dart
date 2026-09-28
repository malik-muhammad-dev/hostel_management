import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hostel_management/app/theme/app_colors.dart';
import 'package:hostel_management/features/fees/data/models/fee_payment_model.dart';
import 'package:hostel_management/features/fees/services/receipt_generator.dart';
import 'package:hostel_management/features/students/data/models/student_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';



// =============================================================================
// RECEIPT DIALOG
//
// Shows a live preview of the payment receipt with Print built in (via
// the `printing` package's PdfPreview widget — this is what gives the
// "Save as PDF" option, using the OS's native print dialog under the
// hood, so it behaves correctly on Linux/Windows/macOS without us
// needing to build a custom file-save flow).
//
// The package's own "Share" icon was removed (allowSharing: false) — on
// Windows it did nothing useful, just opening the PDF in a browser tab.
// A "Send via WhatsApp" icon takes its place in the same toolbar
// instead. There's no way to auto-attach a file to a WhatsApp chat from
// a Windows desktop app — WhatsApp's web/deep links can only open a
// chat, never carry a file — so this does the next best thing: saves
// the receipt PDF to a well-known folder, opens that folder in Explorer
// so the file is one drag away, and opens WhatsApp Web (already logged
// in on the staff laptop) so they just pick the student's chat and drag
// the file in themselves.
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

  String get _fileName =>
      'Receipt_${student.name.replaceAll(' ', '_')}_${payment.feeMonth}.pdf';

  Future<void> _sendViaWhatsApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final doc = await ReceiptGenerator.build(
        student: student,
        payment: payment,
      );
      final bytes = await doc.save();

      // Same folder-resolution convention used for exports in
      // setting_screen.dart — Documents/<AppFolderName>.
      final documentsDir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(documentsDir.path, 'ONIMS Receipts'));
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final file = File(p.join(folder.path, _fileName));
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
            'Receipt saved to "ONIMS Receipts" — drag it into the chat on WhatsApp.',
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
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                pdfFileName: _fileName,
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