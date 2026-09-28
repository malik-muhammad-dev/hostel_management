import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/balance_addition_model.dart';
import 'balance_addition_data_source.dart';

// =============================================================================
// SUPABASE BALANCE ADDITION DATA SOURCE
//
// Table: balance_additions. `id` is a client-generated UUID, assigned by
// BalanceAdditionController before addBalanceAddition() — same pattern
// as every other feature. Soft delete / ordering / explicit
// created_at+updated_at: same reasoning as every other Supabase
// datasource in this app (see supabase_receipt_data_source.dart).
//
// No update/delete here on purpose — the client was explicit that this
// feature only ever adds a new entry, never edits or replaces an old
// one, so there's nothing here for those to do yet.
// =============================================================================

class SupabaseBalanceAdditionDataSource implements BalanceAdditionDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<BalanceAdditionModel>> getBalanceAdditions() async {
    final rows = await _client
        .from('balance_additions')
        .select()
        .isFilter('deleted_at', null)
        .order('created_at', ascending: true);

    return rows
        .map(
          (row) =>
              BalanceAdditionModel.fromMap(Map<String, Object?>.from(row)),
        )
        .toList();
  }

  @override
  Future<void> addBalanceAddition(BalanceAdditionModel addition) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final map = addition.toMap()
      ..['created_at'] = nowIso
      ..['updated_at'] = nowIso
      ..['deleted_at'] = null;

    await _client.from('balance_additions').insert(map);
  }
}
