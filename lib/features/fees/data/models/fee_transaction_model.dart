enum FeeTransactionType { charge, payment }

class FeeTransaction {
  final int? id;
  final int studentId;
  final String date;
  final String feeMonth;
  final String? description;
  final double debit;
  final double credit;
  final double balance;
  final FeeTransactionType type;

  const FeeTransaction({
    this.id,
    required this.studentId,
    required this.date,
    required this.feeMonth,
    this.description,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.type,
  });

  // ---------------------------------------------------------------------------
  // Serialization — for SqliteFeeDataSource
  // ---------------------------------------------------------------------------

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'date': date,
      'fee_month': feeMonth,
      'description': description,
      'debit': debit,
      'credit': credit,
      'balance': balance,
      'type': type.name,
    };
  }

  factory FeeTransaction.fromMap(Map<String, Object?> map) {
    return FeeTransaction(
      id: map['id'] as int?,
      studentId: map['student_id'] as int,
      date: map['date'] as String,
      feeMonth: map['fee_month'] as String,
      description: map['description'] as String?,
      debit: (map['debit'] as num).toDouble(),
      credit: (map['credit'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
      type: FeeTransactionType.values.byName(map['type'] as String),
    );
  }
}