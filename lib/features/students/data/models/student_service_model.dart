// Postgres `numeric` columns come back from Supabase's REST API
// (PostgREST) as JSON strings, not JSON numbers — deliberate, to avoid
// precision loss. SQLite's REAL columns already come back as actual num
// values, so this just needs to tolerate both sources. `monthly_amount`
// is a NOT NULL column, so an unparseable value fails loudly rather than
// silently reading as 0.
double _parseDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException('Expected a number for monthly_amount, got: $value');
}

// Postgres `boolean` columns come back from Supabase as real JSON
// booleans (true/false). SQLite has no boolean type, so the local table
// stores this as an INTEGER (1/0) instead — this tolerates both sources
// rather than assuming one.
bool _parseBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  throw FormatException('Expected a boolean for is_active, got: $value');
}

class StudentServiceModel {
  final String? id;
  final String studentId;

  final String name;
  final String? description;

  final double monthlyAmount;

  final bool isActive;

  const StudentServiceModel({
    this.id,
    required this.studentId,
    required this.name,
    this.description,
    required this.monthlyAmount,
    this.isActive = true,
  });

  StudentServiceModel copyWith({
    String? id,
    String? studentId,
    String? name,
    String? description,
    double? monthlyAmount,
    bool? isActive,
  }) {
    return StudentServiceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      description: description ?? this.description,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      isActive: isActive ?? this.isActive,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialization — for SqliteStudentServiceDataSource. `is_active` is
  // encoded as 1/0 here for SQLite's benefit; SupabaseStudentServiceDataSource
  // overrides it back to a real bool before sending, since Postgres'
  // `boolean` column doesn't accept 1/0.
  // ---------------------------------------------------------------------------

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'name': name,
      'description': description,
      'monthly_amount': monthlyAmount,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory StudentServiceModel.fromMap(Map<String, Object?> map) {
    return StudentServiceModel(
      id: map['id'] as String?,
      studentId: map['student_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      monthlyAmount: _parseDouble(map['monthly_amount']),
      isActive: _parseBool(map['is_active']),
    );
  }
}