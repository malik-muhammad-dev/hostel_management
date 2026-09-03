import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_model.dart';
import 'student_data_source.dart';

// =============================================================================
// SUPABASE STUDENT DATA SOURCE
//
// First feature swapped over per the migration design spec's delivery
// order (Students → Fees → Expenses → Receipts → Settings → Auth). Same
// contract as SqliteStudentDataSource — StudentController, StudentRepository
// and every screen above them are completely unaware which one is wired
// up in AppBinding.
//
// Notes:
// - `id` is always a client-generated UUID, assigned by StudentController
//   before addStudent() is ever called — same as the SQLite version, this
//   datasource never relies on the backend to generate one.
// - Soft delete: deleteStudent() sets `deleted_at` instead of removing the
//   row (see design spec §3.2). getStudents()/getStudentById() filter
//   deleted_at out, so a soft-deleted student behaves exactly like a hard
//   delete from the app's point of view.
// - Ordering: uses `created_at`, a plain insert-time timestamp — NOT the
//   `id` column, which is a UUID with no ordering meaning at all. (This
//   mirrors the `rowid` fix applied on the SQLite side for the same
//   reason.) `created_at` must exist on the `students` table in Supabase
//   — see the ALTER TABLE note delivered alongside this file.
// - `updated_at` is set explicitly on every write rather than relied on
//   as a database default, because Postgres only applies a column
//   default on INSERT, never on UPDATE.
// =============================================================================

class SupabaseStudentDataSource implements StudentDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<StudentModel>> getStudents() async {
    final rows = await _client
        .from('students')
        .select()
        .isFilter('deleted_at', null)
        .order('created_at', ascending: true);

    return rows
        .map((row) => StudentModel.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  @override
  Future<StudentModel?> getStudentById(String id) async {
    final rows = await _client
        .from('students')
        .select()
        .eq('id', id)
        .isFilter('deleted_at', null)
        .limit(1);

    if (rows.isEmpty) return null;
    return StudentModel.fromMap(Map<String, Object?>.from(rows.first));
  }

  @override
  Future<void> addStudent(StudentModel student) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final map = student.toMap()
      ..['created_at'] = nowIso
      ..['updated_at'] = nowIso
      ..['deleted_at'] = null;

    await _client.from('students').insert(map);
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    if (student.id == null) return;

    // The primary key never belongs in an UPDATE payload — it's the
    // filter target (.eq below), not a field being changed.
    final map = student.toMap()
      ..remove('id')
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await _client.from('students').update(map).eq('id', student.id!);
  }

  @override
  Future<void> deleteStudent(String id) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('students')
        .update({'deleted_at': nowIso, 'updated_at': nowIso})
        .eq('id', id);
  }
}