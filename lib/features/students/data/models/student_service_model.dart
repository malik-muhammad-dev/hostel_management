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
  // Serialization — for SqliteStudentServiceDataSource
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
      monthlyAmount: (map['monthly_amount'] as num).toDouble(),
      isActive: (map['is_active'] as int) == 1,
    );
  }
}