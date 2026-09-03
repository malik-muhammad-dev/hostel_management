import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/receipt_model.dart';
import 'receipt_data_source.dart';

// =============================================================================
// SUPABASE RECEIPT DATA SOURCE ("Student Cash")
//
// Fourth feature swapped over per the migration design spec's delivery
// order (Students → Fees → Expenses → Receipts → Settings → Auth).
//
// Notes:
// - `id` is a client-generated UUID, assigned by ReceiptController before
//   addReceipt() — same pattern as every other feature.
// - `student_id` is stored as-is with no existence check against the
//   students table — matches the model's own documented design (a plain
//   reference, not a real foreign key, so a student being deleted later
//   can never block or cascade into this table). The `cash_receipts`
//   table in Supabase also has no foreign key constraint on this column
//   (see the schema), so this needs no special handling either way.
// - Soft delete / ordering / explicit created_at+updated_at: same
//   reasoning as every other Supabase datasource so far.
// =============================================================================

class SupabaseReceiptDataSource implements ReceiptDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<ReceiptModel>> getReceipts() async {
    final rows = await _client
        .from('cash_receipts')
        .select()
        .isFilter('deleted_at', null)
        .order('created_at', ascending: true);

    return rows
        .map((row) => ReceiptModel.fromMap(Map<String, Object?>.from(row)))
        .toList();
  }

  @override
  Future<void> addReceipt(ReceiptModel receipt) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final map = receipt.toMap()
      ..['created_at'] = nowIso
      ..['updated_at'] = nowIso
      ..['deleted_at'] = null;

    await _client.from('cash_receipts').insert(map);
  }

  @override
  Future<void> updateReceipt(ReceiptModel receipt) async {
    if (receipt.id == null) return;

    final map = receipt.toMap()
      ..remove('id')
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await _client.from('cash_receipts').update(map).eq('id', receipt.id!);
  }

  @override
  Future<void> deleteReceipt(String receiptId) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await _client
        .from('cash_receipts')
        .update({'deleted_at': nowIso, 'updated_at': nowIso})
        .eq('id', receiptId);
  }
}