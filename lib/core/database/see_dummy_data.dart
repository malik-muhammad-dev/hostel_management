

// =============================================================================
// SEED DATA — for testing the SQLite integration (Phase A)
//
// This is entirely fictional/dummy data — not the real Excel records.
// Run this once against a fresh database to have something realistic to
// click through while verifying each feature's SqliteDataSource works
// end-to-end (add/edit/delete/search on real persisted data).
//
// The real Excel data migration is a SEPARATE step (Phase B), done only
// after this dummy-data pass confirms the schema + datasources are solid.
//
// Usage: call `await seedDummyData(await AppDatabase.instance.database);`
// once, e.g. from a temporary debug button — do not call this on every
// app start, or you'll keep re-inserting duplicate rows.
// =============================================================================

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> seedDummyData(Database db) async {
  final now = DateTime.now();
  final currentMonth =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Users (Phase 5 — Roles/Auth. Password hashes below are placeholders;
  // replace with real bcrypt hashes once the auth screen is wired up —
  // never store plain-text passwords, even in test/dummy data.)
  // ---------------------------------------------------------------------------

  await db.insert('users', {
    'username': 'admin',
    'password_hash': 'REPLACE_WITH_REAL_HASH',
    'role': 'admin',
  });

  await db.insert('users', {
    'username': 'feecollector',
    'password_hash': 'REPLACE_WITH_REAL_HASH',
    'role': 'feeCollector',
  });

  // ---------------------------------------------------------------------------
  // Students
  // ---------------------------------------------------------------------------

  final studentIds = <int>[];

  final students = [
    {
      'name': 'Ayesha Khan',
      'cnic': '3520112223334',
      'phone': '03001234567',
      'gender': 'Female',
      'guardian_name': 'Muhammad Khan',
      'guardian_relationship': 'Father',
      'guardian_primary_contact': '03011234567',
      'department': 'Nursing',
      'roll_number': 'NUR-101',
      'status': 'Active',
      'hostel_block': 'A',
      'room_number': '12',
      'hostel_status': 'Active',
      'monthly_fee': 15000.0,
      'net_monthly_fee': 15000.0,
    },
    {
      'name': 'Rabia Iqbal',
      'cnic': '3520112223335',
      'phone': '03001234568',
      'gender': 'Female',
      'guardian_name': 'Iqbal Ahmed',
      'guardian_relationship': 'Father',
      'guardian_primary_contact': '03011234568',
      'department': 'Nursing',
      'roll_number': 'NUR-102',
      'status': 'Active',
      'hostel_block': 'A',
      'room_number': '14',
      'hostel_status': 'Active',
      'monthly_fee': 15000.0,
      'net_monthly_fee': 14000.0,
    },
    {
      'name': 'Sana Malik',
      'cnic': '3520112223336',
      'phone': '03001234569',
      'gender': 'Female',
      'guardian_name': 'Malik Nasir',
      'guardian_relationship': 'Father',
      'guardian_primary_contact': '03011234569',
      'department': 'BSN',
      'roll_number': 'BSN-201',
      'status': 'Active',
      'hostel_block': 'B',
      'room_number': '6',
      'hostel_status': 'Active',
      'monthly_fee': 18000.0,
      'net_monthly_fee': 18000.0,
    },
    {
      'name': 'Hina Bibi',
      'cnic': '3520112223337',
      'phone': '03001234570',
      'gender': 'Female',
      'guardian_name': 'Ghulam Bibi',
      'guardian_relationship': 'Mother',
      'guardian_primary_contact': '03011234570',
      'department': 'BSN',
      'roll_number': 'BSN-202',
      'status': 'Inactive',
      'hostel_block': 'B',
      'room_number': '6',
      'hostel_status': 'Inactive',
      'monthly_fee': 18000.0,
      'net_monthly_fee': 18000.0,
    },
  ];

  for (final student in students) {
    final id = await db.insert('students', student);
    studentIds.add(id);
  }

  // ---------------------------------------------------------------------------
  // Student services (Ayesha has transport, Sana has laundry)
  // ---------------------------------------------------------------------------

  await db.insert('student_services', {
    'student_id': studentIds[0],
    'name': 'Transport',
    'monthly_amount': 2000.0,
    'is_active': 1,
  });

  await db.insert('student_services', {
    'student_id': studentIds[2],
    'name': 'Laundry',
    'monthly_amount': 1000.0,
    'is_active': 1,
  });

  // ---------------------------------------------------------------------------
  // Fee transactions + payments — give the first two students a paid
  // current month, and leave the others unpaid so the Fees/Reports
  // screens have something to show in every state (Paid / Partial /
  // Pending).
  // ---------------------------------------------------------------------------

  // Ayesha — fully paid this month (base fee + transport service)
  await db.insert('fee_transactions', {
    'student_id': studentIds[0],
    'date': now.toIso8601String().split('T').first,
    'fee_month': currentMonth,
    'description': 'Monthly Hostel Fee',
    'debit': 17000.0,
    'credit': 0.0,
    'balance': 17000.0,
    'type': 'charge',
  });
  await db.insert('fee_transactions', {
    'student_id': studentIds[0],
    'date': now.toIso8601String().split('T').first,
    'fee_month': currentMonth,
    'description': 'Fee Payment - cash',
    'debit': 0.0,
    'credit': 17000.0,
    'balance': 0.0,
    'type': 'payment',
  });
  await db.insert('fee_payments', {
    'student_id': studentIds[0],
    'fee_month': currentMonth,
    'current_month_fee': 17000.0,
    'previous_balance': 0.0,
    'fine': 0.0,
    'discount': 0.0,
    'amount_received': 17000.0,
    'payment_method': 'cash',
    'payment_date': now.toIso8601String().split('T').first,
  });

  // Rabia — partially paid this month
  await db.insert('fee_transactions', {
    'student_id': studentIds[1],
    'date': now.toIso8601String().split('T').first,
    'fee_month': currentMonth,
    'description': 'Monthly Hostel Fee',
    'debit': 14000.0,
    'credit': 0.0,
    'balance': 14000.0,
    'type': 'charge',
  });
  await db.insert('fee_transactions', {
    'student_id': studentIds[1],
    'date': now.toIso8601String().split('T').first,
    'fee_month': currentMonth,
    'description': 'Fee Payment - bankTransfer',
    'debit': 0.0,
    'credit': 8000.0,
    'balance': 6000.0,
    'type': 'payment',
  });
  await db.insert('fee_payments', {
    'student_id': studentIds[1],
    'fee_month': currentMonth,
    'current_month_fee': 14000.0,
    'previous_balance': 0.0,
    'fine': 0.0,
    'discount': 0.0,
    'amount_received': 8000.0,
    'payment_method': 'bankTransfer',
    'payment_date': now.toIso8601String().split('T').first,
  });

  // Sana and Hina — no payment yet this month (nothing to insert; their
  // "Pending" state is simply the absence of a payment/charge row, which
  // the app already handles by falling back to the student's monthly_fee).

  // ---------------------------------------------------------------------------
  // Expenses — categories taken from the real historical bookkeeping
  // categories (see kExpenseCategories in expense_model.dart), amounts are
  // fictional.
  // ---------------------------------------------------------------------------

  final expenseDate = now.toIso8601String();

  final expenses = [
    {'category': 'Staff Salary', 'amount': 120000.0, 'payment_mode': 'account', 'description': 'Monthly staff salaries'},
    {'category': 'Food Bill', 'amount': 85000.0, 'payment_mode': 'cash', 'description': 'Grocery and mess supplies'},
    {'category': 'FESCO Bill', 'amount': 22000.0, 'payment_mode': 'account', 'description': 'Electricity bill'},
    {'category': 'PTCL Bill', 'amount': 3500.0, 'payment_mode': 'cash', 'description': 'Internet and phone'},
    {'category': 'Generator Fuel', 'amount': 9000.0, 'payment_mode': 'cash', 'description': null},
  ];

  for (final expense in expenses) {
    await db.insert('expenses', {
      'date': expenseDate,
      'category': expense['category'],
      'amount': expense['amount'],
      'description': expense['description'],
      'payment_mode': expense['payment_mode'],
    });
  }
}