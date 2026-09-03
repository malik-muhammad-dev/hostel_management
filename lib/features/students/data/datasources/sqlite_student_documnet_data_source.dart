import 'package:hostel_management/features/students/data/models/student_document%20model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../core/database/app_database.dart';
import 'student_document_data_source.dart';

class SqliteStudentDocumentDataSource implements StudentDocumentDataSource {
  Future<Database> get _db async => AppDatabase.instance.database;

  @override
  Future<List<StudentDocumentModel>> getDocumentsForStudent(
    String studentId,
  ) async {
    final db = await _db;
    // Ordered by rowid, not `id` — `id` is now a UUID with no ordering
    // meaning, but every ordinary SQLite table keeps an implicit
    // auto-incrementing `rowid` (this one isn't WITHOUT ROWID), so it
    // still reflects insertion order the way the old integer `id` did.
    final rows = await db.query(
      'student_documents',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'rowid ASC',
    );
    return rows.map(StudentDocumentModel.fromMap).toList();
  }

  @override
  Future<void> addDocument(StudentDocumentModel document) async {
    final db = await _db;
    await db.insert(
      'student_documents',
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateDocument(StudentDocumentModel document) async {
    if (document.id == null) return;

    final db = await _db;
    await db.update(
      'student_documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    final db = await _db;
    await db.delete(
      'student_documents',
      where: 'id = ?',
      whereArgs: [documentId],
    );
  }
}