// See the matching note in fee_transaction_model.dart — PostgREST (the
// Supabase REST API) returns Postgres numeric columns as JSON strings,
// not numbers, to avoid precision loss. These are NOT NULL money fields,
// so an unparseable value fails loudly rather than silently reading 0.
double _parseDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException('Expected a number for a fee amount, got: $value');
}

// Same PostgREST string-vs-number quirk as above, but for the bigint
// `receipt_no` column (see the migration in receipt_voucher_numbers.sql).
// Nullable because a payment created before that migration ran, or read
// through a codepath that doesn't select it, should still display
// something sane rather than crash — see ReceiptGenerator's fallback.
int? _parseNullableInt(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

enum PaymentMethod { cash, bankTransfer, onlinePayment, cheque }

class FeePayment {
  final String? id;

  /// Short, human-friendly sequential number for display on the receipt
  /// PDF (e.g. "RCPT-0001") — NOT the primary key. Assigned automatically
  /// by Postgres on insert (see receipt_voucher_numbers.sql); null only
  /// for a payment whose row hasn't been read back with this column yet.
  final int? receiptNo;

  final String studentId;
  final String feeMonth;
  final double currentMonthFee;
  final double previousBalance;
  final double fine;
  final double discount;
  final double amountReceived;
  final PaymentMethod paymentMethod;
  final String? paymentReference;
  final String? notes;
  final String paymentDate;
  final String? receiptAttachmentPath;

  const FeePayment({
    this.id,
    this.receiptNo,
    required this.studentId,
    required this.feeMonth,
    required this.currentMonthFee,
    required this.previousBalance,
    required this.fine,
    required this.discount,
    required this.amountReceived,
    required this.paymentMethod,
    this.paymentReference,
    this.notes,
    required this.paymentDate,
    this.receiptAttachmentPath,
  });

  // CAUTION: these only know about THIS row. `currentMonthFee` is always
  // the full month fee (not "remaining after earlier installments this
  // month"), and `discount` is only whatever was entered on this one
  // payment — not the month's total discount across every installment.
  // That's correct for a month paid in a single payment, but WRONG the
  // moment a month is paid in 2+ installments (overstates what's still
  // owed by whatever was already collected earlier that month). Do not
  // use these for anything the client will see — use
  // FeeController.totalDueForPayment()/remainingBalanceForPayment()
  // instead, which recompute from every payment recorded for the month.
  // Kept here only because removing them would be a bigger diff than
  // this fix needs; nothing in the app reads them anymore.
  double get totalDue => currentMonthFee + previousBalance + fine - discount;

  double get remainingBalance => totalDue - amountReceived;

  // ---------------------------------------------------------------------------
  // Serialization — for SqliteFeeDataSource
  // ---------------------------------------------------------------------------

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'fee_month': feeMonth,
      'current_month_fee': currentMonthFee,
      'previous_balance': previousBalance,
      'fine': fine,
      'discount': discount,
      'amount_received': amountReceived,
      'payment_method': paymentMethod.name,
      'payment_reference': paymentReference,
      'notes': notes,
      'payment_date': paymentDate,
      'receipt_attachment_path': receiptAttachmentPath,
    };
  }

  factory FeePayment.fromMap(Map<String, Object?> map) {
    return FeePayment(
      id: map['id'] as String?,
      receiptNo: _parseNullableInt(map['receipt_no']),
      studentId: map['student_id'] as String,
      feeMonth: map['fee_month'] as String,
      currentMonthFee: _parseDouble(map['current_month_fee']),
      previousBalance: _parseDouble(map['previous_balance']),
      fine: _parseDouble(map['fine']),
      discount: _parseDouble(map['discount']),
      amountReceived: _parseDouble(map['amount_received']),
      paymentMethod: PaymentMethod.values.byName(
        map['payment_method'] as String,
      ),
      paymentReference: map['payment_reference'] as String?,
      notes: map['notes'] as String?,
      paymentDate: map['payment_date'] as String,
      receiptAttachmentPath: map['receipt_attachment_path'] as String?,
    );
  }
}