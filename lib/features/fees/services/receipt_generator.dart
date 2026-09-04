import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_constants.dart';
import '../../students/data/models/student_model.dart';
import '../data/models/fee_payment_model.dart';
import '../presentation/controllers/fee_controller.dart';

// =============================================================================
// RECEIPT GENERATOR
//
// Builds a fee-payment receipt PDF from data already stored in SQLite —
// nothing is saved as a pre-rendered file anywhere. A receipt is
// regenerated on demand every time it's viewed/downloaded, whether that's
// right after recording a payment or months later from a student's fee
// history. This avoids managing receipt files on disk entirely (no orphan
// files, no storage-path complexity) — the FeePayment record is the only
// source of truth, exactly like the rest of this app.
// =============================================================================

class ReceiptGenerator {
  ReceiptGenerator._();

  static Future<pw.Document> build({
    required StudentModel student,
    required FeePayment payment,
  }) async {
    final doc = pw.Document();

    // Total Due / Remaining are computed live from EVERY payment recorded
    // for this student/month — not just this one row — so a month paid
    // in two or more installments prints the correct remaining balance
    // on the 2nd+ receipt instead of re-showing the full month fee as
    // still owed. See FeeController.totalDueForPayment/
    // remainingBalanceForPayment for why FeePayment.totalDue/
    // remainingBalance (its own getters) aren't used here anymore.
    final feeController = Get.find<FeeController>();
    final totalDue = feeController.totalDueForPayment(payment);
    final remainingBalance = feeController.remainingBalanceForPayment(
      payment,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(),
              pw.SizedBox(height: 18),
              _receiptMeta(payment),
              pw.SizedBox(height: 14),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 10),
              _studentDetails(student),
              pw.SizedBox(height: 16),
              _paymentTable(payment, totalDue),
              pw.SizedBox(height: 18),
              _amountReceivedBox(payment, remainingBalance),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 6),
              _footer(),
            ],
          );
        },
      ),
    );

    return doc;
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  static pw.Widget _header() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          AppConstants.appName,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#6C2B93'),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Fee Payment Receipt',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _receiptMeta(FeePayment payment) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _metaLine('Receipt No.', _receiptNoLabel(payment.receiptNo)),
        _metaLine('Date', payment.paymentDate),
      ],
    );
  }

  static pw.Widget _metaLine(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _studentDetails(StudentModel student) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Student',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          student.name,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          [
            if (student.rollNumber != null) 'Roll No: ${student.rollNumber}',
            if (student.department != null) student.department!,
          ].join('  •  '),
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _paymentTable(FeePayment payment, double totalDue) {
    final rows = <List<String>>[
      ['Fee Month', _formatMonthLabel(payment.feeMonth)],
      ['Current Month Fee', _amount(payment.currentMonthFee)],
      if (payment.previousBalance > 0)
        ['Previous Balance', _amount(payment.previousBalance)],
      if (payment.fine > 0) ['Fine', _amount(payment.fine)],
      if (payment.discount > 0) ['Discount', '- ${_amount(payment.discount)}'],
      ['Total Due', _amount(totalDue)],
    ];

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
      },
      children: rows.map((row) {
        final isTotal = row[0] == 'Total Due';
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                row[0],
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                row[1],
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _amountReceivedBox(
    FeePayment payment,
    double remainingBalance,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F4EDFA'),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Amount Received',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _amount(payment.amountReceived),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#6C2B93'),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Paid via ${_paymentMethodLabel(payment.paymentMethod)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.Text(
                'Remaining: ${_amount(remainingBalance)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
          if (payment.paymentReference != null &&
              payment.paymentReference!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Reference: ${payment.paymentReference}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
          if (payment.notes != null && payment.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Notes: ${payment.notes}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _footer() {
    return pw.Text(
      'This is a computer-generated receipt and does not require a signature.',
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
    );
  }

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  // Falls back to the old raw-ID label only for a payment somehow read
  // without receipt_no (e.g. the very moment before the SQL migration in
  // receipt_voucher_numbers.sql has been run) — every payment recorded
  // after that migration always has a number.
  static String _receiptNoLabel(int? receiptNo) {
    if (receiptNo == null) return 'RCPT-PENDING';
    return 'RCPT-${receiptNo.toString().padLeft(4, '0')}';
  }

  static String _amount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return 'Rs. $formatted';
  }

  static String _paymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.onlinePayment:
        return 'Online Payment';
      case PaymentMethod.cheque:
        return 'Cheque';
    }
  }

  static String _formatMonthLabel(String value) {
    final parts = value.split('-');
    if (parts.length != 2) return value;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return value;
    }

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return '${months[month - 1]} $year';
  }
}