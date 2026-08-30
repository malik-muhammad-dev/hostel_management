import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


// =============================================================================
// APP DATABASE
//
// Single source of the SQLite connection for the whole app. Every
// SqliteXDataSource should go through `AppDatabase.instance.database`
// rather than opening its own connection.
//
// Schema changes: bump `_dbVersion` and add a migration step inside
// `_onUpgrade`. Never edit `_onCreate` retroactively for an app that's
// already shipped with a lower version — old installs won't re-run it.
//
// Database location: deliberately NOT sqflite's default
// `getDatabasesPath()` — on desktop (via sqflite_common_ffi) that
// resolves relative to the current working directory, which during
// development is the project folder, placing the .db file inside
// `.dart_tool/`. That's a build-cache directory: running `flutter
// clean` — an ordinary, frequent dev command — deletes it, silently
// wiping all student/fee/expense data along with it. It also isn't a
// meaningful location at all once this app is packaged and installed on
// a client's machine (there is no `.dart_tool` in a shipped build).
//
// Instead, this uses `path_provider`'s application-support directory,
// which resolves to a proper, stable, per-user OS data folder
// (e.g. ~/.local/share/<app> on Linux, %APPDATA%/<app> on Windows) that
// persists across rebuilds, `flutter clean`, and app updates.
// =============================================================================

class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  static const _dbName = 'onims_hostel.db';
  static const _dbVersion = 5;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final supportDir = await getApplicationSupportDirectory();

    if (!await supportDir.exists()) {
      await supportDir.create(recursive: true);
    }

    final path = join(supportDir.path, _dbName);

    debugPrint('[DEBUG] AppDatabase opening file at: $path');

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Required for ON DELETE CASCADE to actually take effect — SQLite
    // has foreign keys OFF by default per-connection.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          username        TEXT NOT NULL UNIQUE,
          password_hash   TEXT NOT NULL,
          role            TEXT NOT NULL CHECK (role IN ('admin', 'feeCollector')),
          created_at      TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
          id                          INTEGER PRIMARY KEY AUTOINCREMENT,
          name                        TEXT NOT NULL,
          cnic                        TEXT,
          phone                       TEXT,
          email                       TEXT,
          date_of_birth               TEXT,
          gender                      TEXT,
          address                     TEXT,
          guardian_name               TEXT,
          guardian_relationship       TEXT,
          guardian_cnic               TEXT,
          guardian_primary_contact    TEXT,
          guardian_alternate_contact  TEXT,
          guardian_occupation         TEXT,
          guardian_address            TEXT,
          department                  TEXT,
          program                     TEXT,
          roll_number                 TEXT,
          session                     TEXT,
          semester                    TEXT,
          admission_date              TEXT,
          status                      TEXT,
          hostel_block                TEXT,
          room_number                 TEXT,
          bed_number                  TEXT,
          floor                       TEXT,
          check_in_date               TEXT,
          expected_check_out          TEXT,
          hostel_status               TEXT,
          package_start_date          TEXT,
          monthly_fee                 REAL,
          net_monthly_fee             REAL,
          ledger_id                   INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_students_roll_number ON students(roll_number)',
    );
    await db.execute(
      'CREATE INDEX idx_students_status ON students(status)',
    );

    await db.execute('''
      CREATE TABLE student_services (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          student_id      INTEGER NOT NULL,
          name            TEXT NOT NULL,
          description     TEXT,
          monthly_amount  REAL NOT NULL,
          is_active       INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_student_services_student_id ON student_services(student_id)',
    );

    await db.execute('''
      CREATE TABLE student_documents (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          student_id      INTEGER NOT NULL,
          title           TEXT NOT NULL,
          file_name       TEXT NOT NULL,
          file_path       TEXT,
          is_required     INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_student_documents_student_id ON student_documents(student_id)',
    );

    await db.execute('''
      CREATE TABLE fee_transactions (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          student_id      INTEGER NOT NULL,
          date            TEXT NOT NULL,
          fee_month       TEXT NOT NULL,
          description     TEXT,
          debit           REAL NOT NULL DEFAULT 0,
          credit          REAL NOT NULL DEFAULT 0,
          balance         REAL NOT NULL DEFAULT 0,
          type            TEXT NOT NULL CHECK (type IN ('charge', 'payment')),
          FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_fee_transactions_student_month ON fee_transactions(student_id, fee_month)',
    );

    await db.execute('''
      CREATE TABLE fee_payments (
          id                          INTEGER PRIMARY KEY AUTOINCREMENT,
          student_id                  INTEGER NOT NULL,
          fee_month                   TEXT NOT NULL,
          current_month_fee           REAL NOT NULL,
          previous_balance            REAL NOT NULL,
          fine                        REAL NOT NULL DEFAULT 0,
          discount                    REAL NOT NULL DEFAULT 0,
          amount_received             REAL NOT NULL,
          payment_method              TEXT NOT NULL CHECK (
                                           payment_method IN
                                           ('cash', 'bankTransfer', 'onlinePayment', 'cheque')
                                       ),
          payment_reference           TEXT,
          notes                       TEXT,
          payment_date                TEXT NOT NULL,
          receipt_attachment_path     TEXT,
          FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_fee_payments_student_month ON fee_payments(student_id, fee_month)',
    );

    await db.execute('''
      CREATE TABLE expenses (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          date            TEXT NOT NULL,
          category        TEXT NOT NULL DEFAULT 'Miscellaneous Expense',
          amount          REAL NOT NULL,
          description     TEXT,
          payment_mode    TEXT NOT NULL CHECK (payment_mode IN ('cash', 'account'))
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_expenses_date ON expenses(date)',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_category ON expenses(category)',
    );

    // -------------------------------------------------------------------------
    // A single-row settings table — currently just the one overall
    // "Opening Balance" figure (money already on hand before the hostel
    // started using this app). `CHECK (id = 1)` keeps it a true singleton;
    // the row is always inserted here so app code can always assume it
    // exists and just UPDATE it, never INSERT.
    // -------------------------------------------------------------------------
    await db.execute('''
      CREATE TABLE app_settings (
          id              INTEGER PRIMARY KEY CHECK (id = 1),
          opening_balance REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'INSERT INTO app_settings (id, opening_balance) VALUES (1, 0)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS student_documents (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id      INTEGER NOT NULL,
            title           TEXT NOT NULL,
            file_name       TEXT NOT NULL,
            file_path       TEXT,
            is_required     INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_student_documents_student_id ON student_documents(student_id)',
      );
    }

    if (oldVersion < 3) {
      // The original `expenses` table had `category TEXT NOT NULL`, but
      // ExpenseModel never actually has a category field (the client
      // decided against it) — meaning every insert through
      // SqliteExpenseDataSource would have failed a NOT NULL constraint
      // before this fix. Rebuild the table to match what the app
      // actually writes. SQLite can't just drop a NOT NULL constraint
      // in place, so this recreates the table and carries over any rows
      // that exist (there shouldn't be any successful ones, given the
      // bug this fixes, but this is safe either way).
      await db.execute('ALTER TABLE expenses RENAME TO expenses_old');

      await db.execute('''
        CREATE TABLE expenses (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            date            TEXT NOT NULL,
            amount          REAL NOT NULL,
            description     TEXT,
            payment_mode    TEXT NOT NULL CHECK (payment_mode IN ('cash', 'account'))
        )
      ''');

      await db.execute('''
        INSERT INTO expenses (id, date, amount, description, payment_mode)
        SELECT id, date, amount, description, payment_mode FROM expenses_old
      ''');

      await db.execute('DROP TABLE expenses_old');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date)',
      );
    }

    if (oldVersion < 4) {
      // Category is back — the client confirmed they do want it after
      // all (a fixed list plus a free-typed "Custom" option), just not
      // a sub-category. Existing rows (from before category existed at
      // all, or from the brief period it didn't) get a safe default
      // rather than breaking.
      await db.execute(
        "ALTER TABLE expenses ADD COLUMN category TEXT NOT NULL DEFAULT 'Miscellaneous Expense'",
      );
    }

    if (oldVersion < 5) {
      // New "Opening Balance" setting — the money the hostel already had
      // on hand before switching to this app. Defaults to 0 for existing
      // installs; the client can set the real figure once from the
      // dashboard after updating.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
            id              INTEGER PRIMARY KEY CHECK (id = 1),
            opening_balance REAL NOT NULL DEFAULT 0
        )
      ''');
      await db.execute(
        'INSERT OR IGNORE INTO app_settings (id, opening_balance) VALUES (1, 0)',
      );
    }
  }

  /// Testing/debugging only — never call this from production app code.
  Future<void> resetDatabase() async {
    final db = await database;
    await db.close();
    final supportDir = await getApplicationSupportDirectory();
    final path = join(supportDir.path, _dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}