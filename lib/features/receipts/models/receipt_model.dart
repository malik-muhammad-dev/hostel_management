import 'package:flutter/foundation.dart';

// =============================================================================
// RECEIPT PAYMENT MODE
//
// Same two options as Expenses (Cash / Account) — "Account" meaning the
// hostel's bank account, matching that term's meaning everywhere else in
// the app. Kept as its own enum (rather than reusing ExpensePaymentMode)
// so the Receipts feature has zero code dependency on Expenses.
// =============================================================================

enum ReceiptPaymentMode {
  cash,
  account,
}

extension ReceiptPaymentModeLabel on ReceiptPaymentMode {
  String get label {
    switch (this) {
      case ReceiptPaymentMode.cash:
        return 'Cash';

      case ReceiptPaymentMode.account:
        return 'Account';
    }
  }
}

// =============================================================================
// RECEIVED FROM TYPE
//
// Who the cash was for — client's own distinction: "is it student or
// faculty." When it's a student, the form picks a real enrolled student
// (see ReceiptController.selectedStudentId); when it's faculty, there's
// no list to pick from (the app has no faculty records), so it's just a
// typed name.
// =============================================================================

enum ReceivedFromType {
  student,
  faculty,
}

extension ReceivedFromTypeLabel on ReceivedFromType {
  String get label {
    switch (this) {
      case ReceivedFromType.student:
        return 'Student';

      case ReceivedFromType.faculty:
        return 'Faculty';
    }
  }
}

// =============================================================================
// RECEIPT MODEL ("Student Cash" on screen)
//
// Money received that has NOTHING to do with a student's monthly fee
// (client's own words: "what if they receive other than fee... it may be
// received from a student or anyone"). Deliberately separate from the
// Fees feature — this table is never read by any fee/expense
// calculation, and `studentId` below is a plain reference with no
// FOREIGN KEY constraint, so it can never cascade-delete or block on a
// student being removed later; it exists purely so the record can show
// who the cash was for.
//
// The one place this DOES reach outside itself is
// DashboardController.totalAmount — see the long comment on that getter
// for the exact rule (confirmed explicitly by the client): only the
// "account" portion of Student Cash counts toward Total Amount, and an
// "account" entry also deducts the same amount from the Cash figure,
// because the real-world scenario is money arriving in the bank while
// the cashier hands out the equivalent in physical cash.
// =============================================================================

@immutable
class ReceiptModel {
  final String? id;

  final DateTime date;

  final double amount;

  final ReceiptPaymentMode paymentMode;

  /// Display name — who the cash was for. When [receivedFromType] is
  /// `student`, this is the selected student's name (auto-filled, not
  /// typed); when `faculty`, this is whatever was typed in by hand.
  final String? receivedFrom;

  /// Null for receipts entered before this field existed — shown as
  /// "unspecified" rather than guessed at.
  final ReceivedFromType? receivedFromType;

  /// Only set when [receivedFromType] is `student`. Not a foreign key —
  /// purely a reference for possible future use; nothing in the app
  /// joins against it today, so a student being deleted later can never
  /// break or cascade into this table.
  final String? studentId;

  final String? notes;

  const ReceiptModel({
    this.id,
    required this.date,
    required this.amount,
    required this.paymentMode,
    this.receivedFrom,
    this.receivedFromType,
    this.studentId,
    this.notes,
  });

  // ---------------------------------------------------------------------------
  // Copy with
  // ---------------------------------------------------------------------------

  ReceiptModel copyWith({
    String? id,
    DateTime? date,
    double? amount,
    ReceiptPaymentMode? paymentMode,
    String? receivedFrom,
    ReceivedFromType? receivedFromType,
    String? studentId,
    String? notes,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      receivedFrom: receivedFrom ?? this.receivedFrom,
      receivedFromType: receivedFromType ?? this.receivedFromType,
      studentId: studentId ?? this.studentId,
      notes: notes ?? this.notes,
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
      'payment_mode': paymentMode.name,
      'received_from': receivedFrom,
      'received_from_type': receivedFromType?.name,
      'student_id': studentId,
      'notes': notes,
    };
  }

  // ---------------------------------------------------------------------------
  // Deserialization
  // ---------------------------------------------------------------------------

  factory ReceiptModel.fromMap(Map<String, Object?> map) {
    final typeName = map['received_from_type'] as String?;

    return ReceiptModel(
      id: map['id'] as String?,
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] as num).toDouble(),
      paymentMode: ReceiptPaymentMode.values.byName(
        map['payment_mode'] as String,
      ),
      receivedFrom: map['received_from'] as String?,
      receivedFromType: typeName == null
          ? null
          : ReceivedFromType.values.byName(typeName),
      studentId: map['student_id'] as String?,
      notes: map['notes'] as String?,
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

    return other is ReceiptModel &&
        other.id == id &&
        other.date == date &&
        other.amount == amount &&
        other.paymentMode == paymentMode &&
        other.receivedFrom == receivedFrom &&
        other.receivedFromType == receivedFromType &&
        other.studentId == studentId &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      date,
      amount,
      paymentMode,
      receivedFrom,
      receivedFromType,
      studentId,
      notes,
    );
  }
}