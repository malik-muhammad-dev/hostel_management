import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user_model.dart';
import 'auth_data_source.dart';

// =============================================================================
// SUPABASE AUTH DATA SOURCE
//
// Last feature swapped over per the migration design spec's delivery
// order (Students → Fees → Expenses → Receipts → Settings → Auth).
//
// This is intentionally the simple, already-agreed-on design from the
// original Milestone 2 schema plan: one shared `users` table, reachable
// with the same anon key as every other table, no Supabase-Auth-service,
// no per-role database policies. That's an honest, deliberate trade-off
// (documented in supabase_schema.sql) — it matches the CURRENT app's
// real security level (a username/password screen only, no
// database-level enforcement), not a downgrade from it. If real
// database-level access control is ever wanted, that means moving login
// to Supabase's own Auth service — a separate, later piece of work.
//
// No migration tool needed for this table (unlike Students/Fees):
// `AuthController.bootstrapDefaultAdmin()` already recreates the exact
// same default admin/feeCollector accounts the very first time it sees
// an empty `users` table — which Supabase's `users` table is, right up
// until this datasource is wired in. Nothing else in the schema
// references `users.id` as a foreign key, so unlike Students there is no
// linkage to preserve by keeping the same row ids.
// =============================================================================

class SupabaseAuthDataSource implements AuthDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<AppUser?> getUserByUsername(String username) async {
    final rows = await _client
        .from('users')
        .select()
        .eq('username', username)
        .isFilter('deleted_at', null)
        .limit(1);

    if (rows.isEmpty) return null;

    return AppUser.fromMap(Map<String, Object?>.from(rows.first));
  }

  @override
  Future<void> addUser(AppUser user) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final map = user.toMap()
      ..['created_at'] = nowIso
      ..['updated_at'] = nowIso
      ..['deleted_at'] = null;

    await _client.from('users').insert(map);
  }

  @override
  Future<int> countUsers() async {
    final rows = await _client
        .from('users')
        .select('id')
        .isFilter('deleted_at', null);

    return rows.length;
  }
}