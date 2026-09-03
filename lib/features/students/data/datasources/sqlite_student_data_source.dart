import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../core/database/app_database.dart';
import '../models/student_model.dart';
import 'student_data_source.dart';

// =============================================================================
// SQLITE STUDENT DATA SOURCE
//
// Real persistence, swapped in for MockStudentDataSource once verified.
//
// Note on IDs: the `id` column is now a client-generated UUID (TEXT
// PRIMARY KEY, no AUTOINCREMENT) so records created on different PCs
// never collide once this syncs to the shared Supabase backend.
// StudentController assigns the id (a v4 UUID) before calling
// addStudent() — this datasource just inserts whatever id is already on
// the model, it never relies on SQLite to generate or return one.
// =============================================================================

class SqliteStudentDataSource implements StudentDataSource {
  Future<Database> get _db async => AppDatabase.instance.database;

  @override
  Future<List<StudentModel>> getStudents() async {
    final db = await _db;
    // Ordered by rowid, not `id` — `id` is now a UUID with no ordering
    // meaning, but every ordinary SQLite table keeps an implicit
    // auto-incrementing `rowid` (this one isn't WITHOUT ROWID), so it
    // still reflects insertion order the way the old integer `id` did.
    final rows = await db.query('students', orderBy: 'rowid ASC');
    return rows.map(StudentModel.fromMap).toList();
  }

  @override
  Future<StudentModel?> getStudentById(String id) async {
    final db = await _db;
    final rows = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return StudentModel.fromMap(rows.first);
  }

  @override
  Future<void> addStudent(StudentModel student) async {
    final db = await _db;
    await db.insert(
      'students',
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    if (student.id == null) return;

    final db = await _db;
    await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  @override
  Future<void> deleteStudent(String id) async {
    final db = await _db;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }
}