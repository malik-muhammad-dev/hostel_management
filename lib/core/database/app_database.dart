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
  static const _dbVersion = 10;

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

  // ---------------------------------------------------------------------------
  // Student profile photos — stored as real files on disk (not in SQLite
  // as a BLOB), same application-support directory as the database itself
  // so they survive `flutter clean` and rebuilds. Only the resulting path
  // is stored in the `students.photo_path` column.
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Backup — writes a self-contained, point-in-time SNAPSHOT of the live
  // database to [destinationPath] using SQLite's own `VACUUM INTO`.
  //
  // Why this is safe for the live data:
  // - `VACUUM INTO` only ever READS the source database and WRITES a new
  //   file at the destination. It cannot modify, delete, or lock the
  //   source database in any lasting way — the live `students`,
  //   `fee_payments`, `fee_transactions`, `expenses` tables are never
  //   touched by this call.
  // - It runs on the SAME connection every other read/write already goes
  //   through (`AppDatabase.instance.database`), and sqflite serializes
  //   operations on a connection — so if a backup happens to run at the
  //   exact moment the admin is saving a payment, the save simply waits
  //   its turn in the queue rather than being corrupted or lost. Nothing
  //   is ever in a "half saved" state.
  // - `destinationPath` must not already exist — SQLite refuses to
  //   overwrite via VACUUM INTO. Callers are expected to pass a fresh
  //   (e.g. timestamped) path each time for exactly this reason.
  // ---------------------------------------------------------------------------

  Future<void> backupTo(String destinationPath) async {
    final db = await database;
    await db.execute('VACUUM INTO ?', [destinationPath]);
  }

  Future<Directory> get photosDirectory async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(join(supportDir.path, 'student_photos'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir;
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
          photo_path                  TEXT,
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
    // A single-row settings table. `CHECK (id = 1)` keeps it a true
    // singleton; the row is always inserted here so app code can always
    // assume it exists and just UPDATE it, never INSERT.
    //
    // - opening_balance: money already on hand before the hostel started
    //   using this app.
    // - fine_amount / fine_due_day: the Late Fine rule — once a month's
    //   fine_due_day (day-of-month, 1-28) has passed and that month is
    //   still unpaid, fine_amount is added automatically. See
    //   FeeController's "LATE FINE" section for how this is applied.
    // - fine_effective_from: the fee-month ("YYYY-MM") the fine rule
    //   starts counting from. Set to the current month the moment this
    //   row is created/migrated, so turning the feature on never
    //   retroactively fines a student for months that came and went
    //   before the rule existed.
    // - backup_folder_path: a local folder (typically one a cloud-sync
    //   app like Google Drive/OneDrive is watching) where automatic
    //   backups + the read-only HTML report get written. NULL = the
    //   feature is simply off; nothing runs.
    // - last_backup_at: when the most recent backup completed, shown on
    //   the Settings screen so the admin can see at a glance it's alive.
    // -------------------------------------------------------------------------
    await db.execute('''
      CREATE TABLE app_settings (
          id                  INTEGER PRIMARY KEY CHECK (id = 1),
          opening_balance     REAL NOT NULL DEFAULT 0,
          fine_amount         REAL NOT NULL DEFAULT 100,
          fine_due_day        INTEGER NOT NULL DEFAULT 9,
          fine_effective_from TEXT,
          backup_folder_path  TEXT,
          last_backup_at      TEXT
      )
    ''');
    await db.execute(
      'INSERT INTO app_settings '
      '(id, opening_balance, fine_amount, fine_due_day, fine_effective_from, backup_folder_path, last_backup_at) '
      'VALUES (1, 0, 100, 9, ?, NULL, NULL)',
      [_currentFeeMonthString()],
    );

    // -------------------------------------------------------------------------
    // Cash Receipts ("Student Cash" on screen) — money received that has
    // nothing to do with a student's monthly FEE (e.g. a guardian sending
    // cash for the student to be handed physical money, a faculty
    // reimbursement, a donation). Deliberately a completely separate,
    // standalone table — never read by Collected/Expected/Net Profit, and
    // never touches `students`, `fee_payments`, or `fee_transactions`:
    // - received_from / received_from_type / student_id are purely a
    //   DISPLAY label ("who was this for") — student_id has no FOREIGN
    //   KEY constraint on purpose, so deleting a student later can never
    //   cascade-delete or break a historical cash record.
    // - The one place this table's money DOES reach outside itself is
    //   DashboardController.totalAmount, and only the "account" portion
    //   of it — see the long comment on that getter for the exact rule
    //   and why (client's own accounting logic, confirmed explicitly).
    // -------------------------------------------------------------------------
    await db.execute('''
      CREATE TABLE cash_receipts (
          id                  INTEGER PRIMARY KEY AUTOINCREMENT,
          date                TEXT NOT NULL,
          amount              REAL NOT NULL,
          payment_mode        TEXT NOT NULL CHECK (payment_mode IN ('cash', 'account')),
          received_from       TEXT,
          received_from_type  TEXT CHECK (received_from_type IN ('student', 'faculty')),
          student_id          INTEGER,
          notes               TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_cash_receipts_date ON cash_receipts(date)',
    );
  }

  /// "YYYY-MM" for the current real-world month — used only to stamp a
  /// sensible default for `fine_effective_from` on a brand-new install.
  String _currentFeeMonthString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}';
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

    if (oldVersion < 6) {
      // Student profile photo — stores the path to a copy of the picked
      // image kept under `photosDirectory` (see above), not the image
      // itself. NULL for every existing student until they're re-saved
      // with a photo attached.
      await db.execute(
        'ALTER TABLE students ADD COLUMN photo_path TEXT',
      );
    }

    if (oldVersion < 7) {
      // Late Fine rule — see the app_settings CREATE TABLE comment in
      // _onCreate for what each column means. fine_effective_from is set
      // to the CURRENT month at the moment of this migration (not
      // hardcoded), so an existing install updating to this version
      // starts the fine rule from today forward — it never reaches back
      // and fines a student for older unpaid months that predate this
      // feature existing at all.
      await db.execute(
        "ALTER TABLE app_settings ADD COLUMN fine_amount REAL NOT NULL DEFAULT 100",
      );
      await db.execute(
        "ALTER TABLE app_settings ADD COLUMN fine_due_day INTEGER NOT NULL DEFAULT 9",
      );
      await db.execute(
        "ALTER TABLE app_settings ADD COLUMN fine_effective_from TEXT",
      );
      await db.execute(
        'UPDATE app_settings SET fine_effective_from = ? WHERE id = 1',
        [_currentFeeMonthString()],
      );
    }

    if (oldVersion < 8) {
      // Backup — see the app_settings CREATE TABLE comment in _onCreate.
      // Both columns default to NULL, which is exactly "feature is off"
      // — an existing install upgrading to this version does nothing
      // differently until the admin explicitly picks a backup folder
      // from the Settings screen. Purely additive: no existing column,
      // table, or row is touched by this migration.
      await db.execute(
        'ALTER TABLE app_settings ADD COLUMN backup_folder_path TEXT',
      );
      await db.execute(
        'ALTER TABLE app_settings ADD COLUMN last_backup_at TEXT',
      );
    }

    if (oldVersion < 9) {
      // Cash Receipts — see the CREATE TABLE comment in _onCreate for the
      // full explanation. A brand-new, independent table: this migration
      // does not ALTER, read, or write a single existing table/column/
      // row. An install upgrading to this version simply gains an empty
      // Receipts ledger — every student, fee, expense, and settings row
      // already on the client's machine is completely untouched.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cash_receipts (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            date            TEXT NOT NULL,
            amount          REAL NOT NULL,
            payment_mode    TEXT NOT NULL CHECK (payment_mode IN ('cash', 'account')),
            received_from   TEXT,
            notes           TEXT
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cash_receipts_date ON cash_receipts(date)',
      );
    }

    if (oldVersion < 10) {
      // "Student Cash" — Cash Receipts entries now record WHO the cash
      // was for: a specific enrolled student (student_id, purely a
      // display reference — no FOREIGN KEY, so it can never cascade or
      // block on a later student deletion) or a faculty member (just a
      // typed name in received_from, received_from_type = 'faculty').
      // Both new columns default to NULL, so every receipt entered
      // before this update simply shows as "unspecified" — nothing
      // about an existing row is rewritten.
      // No CHECK constraint here (unlike the CREATE TABLE version above)
      // — SQLite's ALTER TABLE ADD COLUMN support for CHECK constraints
      // depends on the SQLite version bundled with sqflite on the
      // client's machine, and this isn't worth risking on an upgrade
      // path. The app already validates the value before saving
      // (ReceiptController.validate()), so this is enforced at the
      // application layer instead — same safety, no ALTER TABLE risk.
      await db.execute(
        'ALTER TABLE cash_receipts ADD COLUMN received_from_type TEXT',
      );
      await db.execute(
        'ALTER TABLE cash_receipts ADD COLUMN student_id INTEGER',
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