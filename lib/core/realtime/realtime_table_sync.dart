import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================================
// REALTIME TABLE SYNC
//
// Generic, reusable helper: subscribes to Postgres changes on one or more
// Supabase tables and calls back (debounced) whenever any of them change
// — from THIS PC or any other one connected to the same project. This is
// what makes every screen reflect changes live instead of needing a full
// app restart to see them.
//
// Why that was needed: GetX controllers here are registered with
// `fenix: true`, so they stay alive in memory across navigation and hot
// reload — nothing ever re-read from Supabase on its own after the
// initial load. A full restart was the only thing that ever refreshed
// them. This closes that gap.
//
// Deliberately dumb on purpose: rather than trying to merge just the
// changed row into the in-memory list (fiddly, easy to get subtly wrong
// once soft-deletes, derived summaries, and filters are involved), every
// event just re-runs the same loadX() each controller already calls on
// its own startup — the exact same "fetch everything fresh" path already
// proven correct by every screen's normal first load. A little more
// network traffic per change, in exchange for one obviously-correct code
// path instead of two.
//
// Debounced because some writes touch more than one table/row at once (a
// fee payment writes to both fee_transactions and fee_payments in a
// single call) — without debouncing, that would trigger two reloads back
// to back for what the user experiences as one action.
//
// Fails safe: if Realtime isn't turned on yet for a table in Supabase
// (a one-time per-table setting), this simply never receives an event
// for it — the screen behaves exactly as it did before this existed. It
// can never crash the app or block the initial load, which already
// happens independently before this is ever wired in.
// =============================================================================

class RealtimeTableSync {
  final List<String> tables;
  final Future<void> Function() onChange;
  final Duration debounce;

  static int _nextId = 0;

  late final RealtimeChannel _channel;
  Timer? _debounceTimer;
  bool _disposed = false;

  RealtimeTableSync({
    required this.tables,
    required this.onChange,
    this.debounce = const Duration(milliseconds: 400),
  }) {
    final id = _nextId++;
    _channel = Supabase.instance.client.channel(
      'sync-$id-${tables.join('-')}',
    );

    for (final table in tables) {
      _channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (payload) {
          debugPrint(
            '[REALTIME] change on "$table": ${payload.eventType.name}',
          );
          _scheduleReload();
        },
      );
    }

    _channel.subscribe((status, error) {
      if (error != null) {
        // Non-fatal by design — see the class comment. Most likely
        // cause: Realtime hasn't been turned on for this table yet in
        // Supabase. The screen keeps working normally; it just won't
        // get live updates until that's fixed.
        debugPrint(
          '[REALTIME] subscribe error for ${tables.join(", ")}: $error',
        );
      } else {
        debugPrint(
          '[REALTIME] ${tables.join(", ")} — status: ${status.name}',
        );
      }
    });
  }

  void _scheduleReload() {
    if (_disposed) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      if (_disposed) return;
      onChange();
    });
  }

  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    Supabase.instance.client.removeChannel(_channel);
  }
}