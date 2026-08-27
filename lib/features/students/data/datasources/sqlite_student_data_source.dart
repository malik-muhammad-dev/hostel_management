

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../core/database/app_database.dart';
import '../models/student_model.dart';
import 'student_data_source.dart';

// =============================================================================
// SQLITE STUDENT DATA SOURCE
//
// Real persistence, swapped in for MockStudentDataSource once verified.
//
// Note on IDs: StudentController._nextStudentId() already assigns the id
// (max existing id + 1) before calling addStudent() — this datasource does
// NOT rely on SQLite's own AUTOINCREMENT to generate it, it just inserts
// whatever id is already on the model. This keeps the already-tested
// controller logic completely untouched during this migration. If this is
// ever revisited to use true autoincrement instead, the controller's
// _nextStudentId() would need to be removed and addStudent() would need to
// return the assigned id from the insert instead.
// =============================================================================

class SqliteStudentDataSource implements StudentDataSource {
  Future<Database> get _db async => AppDatabase.instance.database;

  @override
  Future<List<StudentModel>> getStudents() async {
    final db = await _db;
    final rows = await db.query('students', orderBy: 'id ASC');
    return rows.map(StudentModel.fromMap).toList();
  }

  @override
  Future<StudentModel?> getStudentById(int id) async {
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
  Future<void> deleteStudent(int id) async {
    final db = await _db;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }
}