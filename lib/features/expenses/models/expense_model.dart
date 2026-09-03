import 'package:flutter/foundation.dart';

// Postgres numeric columns come back from Supabase's REST API (PostgREST)
// as JSON strings, not JSON numbers — deliberate, to avoid precision loss.
// SQLite's REAL columns already come back as actual num values, so this
// just needs to tolerate both sources. `amount` is a NOT NULL column, so
// an unparseable value fails loudly rather than silently reading as 0.
double _parseDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException('Expected a number for an expense amount, got: $value');
}

// =============================================================================
// EXPENSE PAYMENT MODE
// =============================================================================

enum ExpensePaymentMode {
  cash,
  account,
}

extension ExpensePaymentModeLabel on ExpensePaymentMode {
  String get label {
    switch (this) {
      case ExpensePaymentMode.cash:
        return 'Cash';

      case ExpensePaymentMode.account:
        return 'Account';
    }
  }
}

// =============================================================================
// EXPENSE CATEGORIES
//
// Pulled from the hostel's real historical bookkeeping (the original
// Excel ledger sheets) — genuine hostel-paid expenses only. "Custom" is
// always the last option; picking it reveals a free-text field so a
// category not on this list can still be entered without needing a code
// change every time a new one comes up.
// =============================================================================

const List<String> kExpenseCategories = [
  'Staff Salary',
  'Food Bill',
  'Electricity Bill',
  'Gas Bill',
  'Water Bill',
  'PTCL / Internet Bill',
  'Generator Fuel',
  'Generator Repair',
  'Repair & Maintenance',
  'Furniture & Fixture',
  'Electric Appliance Repairing',
  'General Stationery',
  'Medical Bill',
  'College / Van Transport',
  'TA/DA',
  'Entertainment Expense',
  'Cleaning & Sanitation',
  'Security Services',
  'Miscellaneous Expense',
  'Custom',
];

// =============================================================================
// EXPENSE MODEL
//
// Current client requirement:
//
// - Expense date
// - Category (from a fixed list, or a custom typed-in value)
// - Total amount
// - Description
// - Payment method (Cash / Account)
//
// Sub-category is intentionally NOT included.
// =============================================================================

@immutable
class ExpenseModel {
  final String? id;

  final DateTime date;

  final String category;

  final double amount;

  final String? description;

  final ExpensePaymentMode paymentMode;

  const ExpenseModel({
    this.id,
    required this.date,
    required this.category,
    required this.amount,
    this.description,
    required this.paymentMode,
  });

  // ---------------------------------------------------------------------------
  // Copy with
  // ---------------------------------------------------------------------------

  ExpenseModel copyWith({
    String? id,
    DateTime? date,
    String? category,
    double? amount,
    String? description,
    ExpensePaymentMode? paymentMode,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paymentMode: paymentMode ?? this.paymentMode,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialization
  //
  // Date is stored as ISO-8601.
  // Amount remains numeric.
  // Payment mode is stored as the enum name.
  // ---------------------------------------------------------------------------

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'category': category,
      'amount': amount,
      'description': description,
      'payment_mode': paymentMode.name,
    };
  }

  // ---------------------------------------------------------------------------
  // Deserialization
  // ---------------------------------------------------------------------------

  factory ExpenseModel.fromMap(
    Map<String, Object?> map,
  ) {
    return ExpenseModel(
      id: map['id'] as String?,
      date: DateTime.parse(
        map['date'] as String,
      ),
      category: map['category'] as String? ?? 'Miscellaneous Expense',
      amount: _parseDouble(map['amount']),
      description: map['description'] as String?,
      paymentMode: ExpensePaymentMode.values.byName(
        map['payment_mode'] as String,
      ),
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

    return other is ExpenseModel &&
        other.id == id &&
        other.date == date &&
        other.category == category &&
        other.amount == amount &&
        other.description == description &&
        other.paymentMode == paymentMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      date,
      category,
      amount,
      description,
      paymentMode,
    );
  }
}