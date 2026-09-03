import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_constants.dart';
import '../models/expense_model.dart';

// =============================================================================
// EXPENSE VOUCHER GENERATOR
//
// Same idea as the Fees ReceiptGenerator — nothing is saved as a
// pre-rendered file, the voucher is rebuilt on demand from whatever is
// in the expenses table, whether that's right after adding it or
// months later from the records table.
// =============================================================================

class ExpenseVoucherGenerator {
  ExpenseVoucherGenerator._();

  static Future<pw.Document> build({required ExpenseModel expense}) async {
    final doc = pw.Document();

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
              _voucherMeta(expense),
              pw.SizedBox(height: 14),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 14),
              _detailsTable(expense),
              pw.SizedBox(height: 18),
              _amountBox(expense),
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
          'Expense Voucher',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _voucherMeta(ExpenseModel expense) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _metaLine('Voucher No.', _voucherNoLabel(expense.voucherNo)),
        _metaLine('Date', _formatDate(expense.date)),
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

  static pw.Widget _detailsTable(ExpenseModel expense) {
    final rows = <List<String>>[
      ['Category', expense.category],
      ['Payment Mode', expense.paymentMode.label],
      if (expense.description != null && expense.description!.isNotEmpty)
        ['Description', expense.description!],
    ];

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(2),
      },
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                row[0],
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                row[1],
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _amountBox(ExpenseModel expense) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F4EDFA'),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Amount Paid',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            _amount(expense.amount),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#6C2B93'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer() {
    return pw.Text(
      'This is a computer-generated voucher and does not require a signature.',
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
    );
  }

  static String _amount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return 'Rs. $formatted';
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // Falls back to the old raw-ID label only for an expense somehow read
  // without voucher_no (e.g. the very moment before the SQL migration in
  // receipt_voucher_numbers.sql has been run) — every expense recorded
  // after that migration always has a number.
  static String _voucherNoLabel(int? voucherNo) {
    if (voucherNo == null) return 'EXP-PENDING';
    return 'EXP-${voucherNo.toString().padLeft(4, '0')}';
  }
}