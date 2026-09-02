// =============================================================================
// STUDENT DOCUMENT MODEL
//
// Mirrors the shape of StudentDocumentsSection's local `_SelectedDocument`
// (title/fileName/path) plus a `studentId` link and `isRequired` flag so
// the 4 named documents (CNIC, Admission Form, College/Student Card,
// Medical Certificate) and any custom "Add Other Document" entries are
// both represented the same way in the database.
// =============================================================================

class StudentDocumentModel {
  final String? id;
  final String studentId;

  final String title;
  final String fileName;
  final String? filePath;
  final bool isRequired;

  const StudentDocumentModel({
    this.id,
    required this.studentId,
    required this.title,
    required this.fileName,
    this.filePath,
    this.isRequired = false,
  });

  StudentDocumentModel copyWith({
    String? id,
    String? studentId,
    String? title,
    String? fileName,
    String? filePath,
    bool? isRequired,
  }) {
    return StudentDocumentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      isRequired: isRequired ?? this.isRequired,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialization — for SqliteStudentDocumentDataSource
  // ---------------------------------------------------------------------------

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'title': title,
      'file_name': fileName,
      'file_path': filePath,
      'is_required': isRequired ? 1 : 0,
    };
  }

  factory StudentDocumentModel.fromMap(Map<String, Object?> map) {
    return StudentDocumentModel(
      id: map['id'] as String?,
      studentId: map['student_id'] as String,
      title: map['title'] as String,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String?,
      isRequired: (map['is_required'] as int) == 1,
    );
  }
}