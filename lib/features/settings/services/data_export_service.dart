import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;

import '../../expenses/data/repositories/expense_repository.dart';
import '../../fees/data/repositories/fee_repository.dart';
import '../../receipts/data/repositories/receipt_repository.dart';
import '../../students/data/repositories/student_repository.dart';

// =============================================================================
// DATA EXPORT SERVICE
//
// One-tap safety net for the free Supabase tier, which has NO automatic
// backups at all (confirmed against Supabase's own pricing page — daily
// backups only start on the paid Pro plan; the free plan has nothing to
// restore from if something ever goes wrong on Supabase's side). This
// pulls every row from every Supabase-backed table right now and writes
// it into one .xlsx file the admin can keep anywhere they like — ideally
// the same cloud-synced folder already used for the local SQLite backup,
// so it rides along automatically once that's set up.
//
// Deliberately read-only: every method here only ever calls a
// repository's getX() — there is no code path here that can write back
// to Supabase or touch local SQLite. A failed or interrupted export can
// only fail to produce a file; it can never damage the live data.
//
// Column layout: each sheet's headers are a fixed list matching that
// model's toMap() keys at the time this was written, but every cell
// value is looked up from toMap() BY KEY (not by position). So a model
// gaining a new field later just means that new field is silently
// skipped by this export — never a column/value mismatch or a crash.
// =============================================================================

class DataExportService {
  final StudentRepository studentRepository;
  final FeeRepository feeRepository;
  final ExpenseRepository expenseRepository;
  final ReceiptRepository receiptRepository;

  DataExportService({
    required this.studentRepository,
    required this.feeRepository,
    required this.expenseRepository,
    required this.receiptRepository,
  });

  static const _studentColumns = [
    'id',
    'name',
    'cnic',
    'phone',
    'email',
    'date_of_birth',
    'gender',
    'address',
    'guardian_name',
    'guardian_relationship',
    'guardian_cnic',
    'guardian_primary_contact',
    'guardian_alternate_contact',
    'guardian_occupation',
    'guardian_address',
    'department',
    'program',
    'roll_number',
    'session',
    'semester',
    'admission_date',
    'status',
    'hostel_block',
    'room_number',
    'bed_number',
    'floor',
    'check_in_date',
    'expected_check_out',
    'hostel_status',
    'package_start_date',
    'monthly_fee',
    'net_monthly_fee',
  ];

  static const _feeTransactionColumns = [
    'id',
    'student_id',
    'date',
    'fee_month',
    'description',
    'debit',
    'credit',
    'balance',
    'type',
  ];

  static const _feePaymentColumns = [
    'id',
    'student_id',
    'fee_month',
    'current_month_fee',
    'previous_balance',
    'fine',
    'discount',
    'amount_received',
    'payment_method',
    'payment_reference',
    'notes',
    'payment_date',
  ];

  static const _expenseColumns = [
    'id',
    'date',
    'category',
    'amount',
    'description',
    'payment_mode',
  ];

  static const _receiptColumns = [
    'id',
    'date',
    'amount',
    'payment_mode',
    'received_from',
    'received_from_type',
    'student_id',
    'notes',
  ];

  /// Fetches everything fresh from Supabase and writes it to a single
  /// .xlsx file inside [destinationFolder] (created if it doesn't exist
  /// yet). Returns the full path of the file that was written.
  Future<String> exportToExcel(String destinationFolder) async {
    final excel = Excel.createExcel();

    final students = await studentRepository.getStudents();
    _writeSheet(
      excel,
      'Students',
      _studentColumns,
      students.map((s) => s.toMap()).toList(),
    );

    final feeTransactions = await feeRepository.getTransactions();
    _writeSheet(
      excel,
      'Fee Transactions',
      _feeTransactionColumns,
      feeTransactions.map((t) => t.toMap()).toList(),
    );

    final feePayments = await feeRepository.getPayments();
    _writeSheet(
      excel,
      'Fee Payments',
      _feePaymentColumns,
      feePayments.map((pay) => pay.toMap()).toList(),
    );

    final expenses = await expenseRepository.getExpenses();
    _writeSheet(
      excel,
      'Expenses',
      _expenseColumns,
      expenses.map((e) => e.toMap()).toList(),
    );

    final receipts = await receiptRepository.getReceipts();
    _writeSheet(
      excel,
      'Student Cash',
      _receiptColumns,
      receipts.map((r) => r.toMap()).toList(),
    );

    // Excel.createExcel() always starts with one default blank sheet
    // named "Sheet1" — drop it now that every real sheet above exists,
    // so the file opens straight to real data instead of an empty tab.
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to generate the Excel file.');
    }

    final directory = Directory(destinationFolder);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(
          RegExp(r'[:.]'),
          '-',
        );
    final fileName = 'onims_data_export_$timestamp.xlsx';
    final filePath = p.join(destinationFolder, fileName);

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return filePath;
  }

  void _writeSheet(
    Excel excel,
    String sheetName,
    List<String> columns,
    List<Map<String, Object?>> rows,
  ) {
    final sheet = excel[sheetName];

    for (var col = 0; col < columns.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = TextCellValue(columns[col]);
    }

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];

      for (var col = 0; col < columns.length; col++) {
        final value = row[columns[col]];
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: rowIndex + 1,
          ),
        );

        if (value == null) {
          continue;
        } else if (value is int) {
          cell.value = IntCellValue(value);
        } else if (value is double) {
          cell.value = DoubleCellValue(value);
        } else if (value is bool) {
          cell.value = BoolCellValue(value);
        } else {
          cell.value = TextCellValue(value.toString());
        }
      }
    }
  }
}