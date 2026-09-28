import 'package:flutter/foundation.dart';

// Postgres numeric columns come back from Supabase's REST API (PostgREST)
// as JSON strings, not JSON numbers — same quirk handled everywhere else
// in this app (see fee_payment_model.dart). `amount` is a NOT NULL
// column, so an unparseable value fails loudly rather than silently
// reading as 0.
double _parseDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException(
    'Expected a number for a balance addition amount, got: $value',
  );
}

// =============================================================================
// BALANCE ADDITION BOX
//
// Same two options as Expenses/Receipts (Cash / Account) — kept as its
// own enum rather than reusing either of those, so this feature has zero
// code dependency on them (same reasoning ReceiptPaymentMode already
// documents for itself).
// =============================================================================

enum BalanceAdditionBox {
  cash,
  account,
}

extension BalanceAdditionBoxLabel on BalanceAdditionBox {
  String get label {
    switch (this) {
      case BalanceAdditionBox.cash:
        return 'Cash';

      case BalanceAdditionBox.account:
        return 'Account';
    }
  }
}

// =============================================================================
// BALANCE ADDITION MODEL ("Add to Total Balance" on the Dashboard)
//
// A manual top-up to money the hostel has on hand — NOT a fee payment,
// NOT an expense, NOT Student Cash. Client's own words: money being
// added needs to show up split by Cash/Account same as everything else
// on the Dashboard, and needs a visible record of when/how much was
// added (Recent Activity), instead of a single number anyone can quietly
// overwrite.
//
// Deliberately separate from Settings' `openingBalance` (the original,
// one-time starting figure) — that field is left completely untouched by
// this feature on purpose, so nothing about it or the numbers it already
// feeds changes. Every BalanceAdditionModel row is a NEW, purely
// additive entry on top of whatever already exists; there is no edit or
// replace here — matching the client's explicit instruction not to
// touch old values.
// =============================================================================

@immutable
class BalanceAdditionModel {
  final String? id;

  final DateTime date;

  final double amount;

  final BalanceAdditionBox box;

  const BalanceAdditionModel({
    this.id,
    required this.date,
    required this.amount,
    required this.box,
  });

  // ---------------------------------------------------------------------------
  // Copy with
  // ---------------------------------------------------------------------------

  BalanceAdditionModel copyWith({
    String? id,
    DateTime? date,
    double? amount,
    BalanceAdditionBox? box,
  }) {
    return BalanceAdditionModel(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      box: box ?? this.box,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'box': box.name,
    };
  }

  // ---------------------------------------------------------------------------
  // Deserialization
  // ---------------------------------------------------------------------------

  factory BalanceAdditionModel.fromMap(Map<String, Object?> map) {
    return BalanceAdditionModel(
      id: map['id'] as String?,
      date: DateTime.parse(map['date'] as String),
      amount: _parseDouble(map['amount']),
      box: BalanceAdditionBox.values.byName(map['box'] as String),
    );
  }

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is BalanceAdditionModel &&
        other.id == id &&
        other.date == date &&
        other.amount == amount &&
        other.box == box;
  }

  @override
  int get hashCode {
    return Object.hash(id, date, amount, box);
  }
}
