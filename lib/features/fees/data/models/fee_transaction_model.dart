// Postgres numeric columns come back from Supabase's REST API (PostgREST)
// as JSON strings, not JSON numbers — deliberate, to avoid precision loss
// (JSON numbers are IEEE doubles). SQLite's REAL columns already come
// back as actual num values, so this just needs to tolerate both sources.
// Unlike the nullable version used elsewhere, debit/credit/balance are
// NOT NULL columns — if one somehow comes back missing or unparseable,
// that's a real data problem on a money field and should fail loudly
// rather than silently show as 0.
double _parseDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException('Expected a number for a fee amount, got: $value');
}

enum FeeTransactionType { charge, payment }

class FeeTransaction {
  final String? id;
  final String studentId;
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
      id: map['id'] as String?,
      studentId: map['student_id'] as String,
      date: map['date'] as String,
      feeMonth: map['fee_month'] as String,
      description: map['description'] as String?,
      debit: _parseDouble(map['debit']),
      credit: _parseDouble(map['credit']),
      balance: _parseDouble(map['balance']),
      type: FeeTransactionType.values.byName(map['type'] as String),
    );
  }
}