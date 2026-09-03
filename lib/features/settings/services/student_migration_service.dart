import 'package:supabase_flutter/supabase_flutter.dart';

import '../../students/data/datasources/sqlite_student_data_source.dart';

// =============================================================================
// STUDENT MIGRATION SERVICE
//
// One-time (per install) utility: copies every student currently in local
// SQLite into Supabase. This is NOT the ongoing Students data path — that's
// SupabaseStudentDataSource, used for every add/edit/list once Students is
// live on Supabase. This service exists only to seed Supabase with the
// real, already-entered students the first time, instead of starting from
// an empty table.
//
// Ids are preserved exactly as they already exist locally (not
// regenerated) — Fees, Expenses, Receipts and Student Services/Documents
// are all still local-only at this point and reference students by these
// same ids, so changing them here would silently break that linkage the
// moment those features are swapped to Supabase later.
//
// `created_at` has no real historical value to draw from (the old schema
// never recorded when a student was originally added), so each student
// gets a synthetic, strictly increasing timestamp instead — one second
// apart, in the same order the Students screen has always shown them in
// (SqliteStudentDataSource.getStudents() is ordered by rowid, i.e.
// original insertion order). This preserves relative ordering honestly,
// without claiming a false historical date.
// =============================================================================

class StudentMigrationResult {
  final int localCount;
  final int migratedCount;
  final List<String> failures;

  const StudentMigrationResult({
    required this.localCount,
    required this.migratedCount,
    required this.failures,
  });

  bool get isFullSuccess => failures.isEmpty && migratedCount == localCount;
}

class StudentMigrationService {
  SupabaseClient get _client => Supabase.instance.client;

  /// How many students already exist in Supabase right now — used to
  /// warn before a second run, which would otherwise create duplicate
  /// rows (this migration does not check "does this id already exist"
  /// per-row, by design: it's meant for one clean run against an empty
  /// table, not as a repeatable sync).
  Future<int> countExistingSupabaseStudents() async {
    final rows = await _client.from('students').select('id');
    return rows.length;
  }

  Future<StudentMigrationResult> migrateLocalStudentsToSupabase() async {
    final localDataSource = SqliteStudentDataSource();
    final localStudents = await localDataSource.getStudents();

    final failures = <String>[];
    var migrated = 0;

    var syntheticTime = DateTime.now().toUtc().subtract(
      Duration(seconds: localStudents.length),
    );

    for (final student in localStudents) {
      syntheticTime = syntheticTime.add(const Duration(seconds: 1));
      final timestampIso = syntheticTime.toIso8601String();

      try {
        final map = student.toMap()
          ..['created_at'] = timestampIso
          ..['updated_at'] = timestampIso
          ..['deleted_at'] = null;

        await _client.from('students').insert(map);
        migrated++;
      } catch (e) {
        failures.add('${student.name} (id: ${student.id}) — $e');
      }
    }

    return StudentMigrationResult(
      localCount: localStudents.length,
      migratedCount: migrated,
      failures: failures,
    );
  }
}