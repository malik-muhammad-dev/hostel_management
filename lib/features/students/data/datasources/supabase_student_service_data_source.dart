import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_service_model.dart';
import 'student_service_datasource.dart';

// =============================================================================
// SUPABASE STUDENT SERVICE DATA SOURCE
//
// Student Services (a student's monthly extra charges — meal plan,
// laundry, etc.) were left on local SQLite when Fees/Expenses were
// migrated, which meant a service added on one PC never showed up — or
// counted toward that student's fee — on any other PC. This closes that
// gap the same way Fees/Expenses/Receipts already were.
//
// - `id` is a client-generated UUID, assigned by StudentServiceController
//   before any write — same pattern as every other feature.
// - Soft delete: deleteService() sets `deleted_at` instead of removing
//   the row — same as Expenses/Fees. The SQLite version still hard-
//   deletes (unchanged, out of scope here).
// - `is_active` is overridden back to a real Dart bool before every
//   write — StudentServiceModel.toMap() encodes it as 1/0 for SQLite's
//   benefit, but Postgres' `boolean` column needs an actual true/false.
// - No `created_at` column on this table (see supabase_schema.sql) —
//   results are ordered by `updated_at` as the closest available stand-in
//   for insertion order. This only affects the display order of a
//   student's (typically short) service list, nothing financial.
// - `updated_at` is set explicitly on every write, never relied on as a
//   database default (Postgres only applies a column default on INSERT,
//   never on UPDATE).
// =============================================================================

class SupabaseStudentServiceDataSource implements StudentServiceDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<StudentServiceModel>> getServicesForStudent(
    String studentId,
  ) async {
    final rows = await _client
        .from('student_services')
        .select()
        .eq('student_id', studentId)
        .isFilter('deleted_at', null)
        .order('updated_at', ascending: true);

    return rows
        .map(
          (row) => StudentServiceModel.fromMap(Map<String, Object?>.from(row)),
        )
        .toList();
  }

  @override
  Future<void> addService(StudentServiceModel service) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final map = service.toMap()
      ..['is_active'] = service.isActive
      ..['updated_at'] = nowIso
      ..['deleted_at'] = null;

    await _client.from('student_services').insert(map);
  }

  @override
  Future<void> updateService(StudentServiceModel service) async {
    if (service.id == null) return;

    final map = service.toMap()
      ..remove('id')
      ..['is_active'] = service.isActive
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await _client.from('student_services').update(map).eq('id', service.id!);
  }

  @override
  Future<void> deleteService(String serviceId) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('student_services')
        .update({'deleted_at': nowIso, 'updated_at': nowIso})
        .eq('id', serviceId);
  }
}
