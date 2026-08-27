enum PaymentMethod { cash, bankTransfer, onlinePayment, cheque }

class FeePayment {
  final int? id;
  final int studentId;
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
      id: map['id'] as int?,
      studentId: map['student_id'] as int,
      feeMonth: map['fee_month'] as String,
      currentMonthFee: (map['current_month_fee'] as num).toDouble(),
      previousBalance: (map['previous_balance'] as num).toDouble(),
      fine: (map['fine'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      amountReceived: (map['amount_received'] as num).toDouble(),
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