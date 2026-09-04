import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/expense_model.dart';
import 'expense_data_source.dart';

// =============================================================================
// SUPABASE EXPENSE DATA SOURCE
//
// Third feature swapped over per the migration design spec's delivery
// order (Students → Fees → Expenses → Receipts → Settings → Auth).
//
// Notes:
// - `id` is a client-generated UUID, assigned by ExpenseController before
//   addExpense() — same pattern as every other feature.
// - Soft delete: deleteExpense() sets `deleted_at` instead of removing
//   the row (see design spec §3.2) — the SQLite version still does a
//   hard delete (unchanged, out of scope here), so this is a deliberate
//   behavior difference between the two, not an oversight.
// - Ordering: uses `created_at`, not `id` (a UUID has no ordering
//   meaning) — same reasoning as every other Supabase datasource so far.
// - `updated_at`/`created_at` are set explicitly on every write, never
//   relied on as a database default (Postgres only applies a column
//   default on INSERT, never on UPDATE).
// =============================================================================

class SupabaseExpenseDataSource implements ExpenseDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    final rows = await _client
        .from('expenses')
        .select()
        .isFilter('deleted_at', null)
        .order('created_at', ascending: true);

    return rows
        .map((row) => ExpenseModel.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  @override
  Future<ExpenseModel?> getExpenseById(String id) async {
    // A lookup by primary key — Postgres serves this off the table's own
    // index, so it stays fast regardless of how many expenses have piled
    // up, unlike getExpenses() above which fetches everything.
    final rows = await _client
        .from('expenses')
        .select()
        .eq('id', id)
        .isFilter('deleted_at', null)
        .limit(1);

    if (rows.isEmpty) return null;
    return ExpenseModel.fromMap(Map<String, Object?>.from(rows.first));
  }

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final map = expense.toMap()
      ..['created_at'] = nowIso
      ..['updated_at'] = nowIso
      ..['deleted_at'] = null;

    await _client.from('expenses').insert(map);
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    if (expense.id == null) return;

    final map = expense.toMap()
      ..remove('id')
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await _client.from('expenses').update(map).eq('id', expense.id!);
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('expenses')
        .update({'deleted_at': nowIso, 'updated_at': nowIso})
        .eq('id', expenseId);
  }
}
