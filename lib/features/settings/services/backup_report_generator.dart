import 'package:get/get.dart';

import '../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../expenses/presentation/controllers/expense_controller.dart';
import '../../fees/presentation/controllers/fee_controller.dart';
import '../../students/presentation/controllers/student_controller.dart';

// =============================================================================
// BACKUP REPORT GENERATOR
//
// Builds one self-contained, static HTML file — a read-only snapshot of
// "what does the dashboard look like right now". This is what the owner
// actually opens (via a desktop shortcut pointed at this file, synced to
// his machine through the same cloud folder as the .db backups) — he
// never touches the .db file or the Flutter app itself.
//
// IMPORTANT — this is READ-ONLY by construction, not just by convention:
// every method here only ever READS from the already-loaded controllers
// (the same ones the live screens read from) — nothing in this file
// writes to the database, a repository, or any controller's state. It
// cannot corrupt or change the admin's real data, no matter when it
// runs or how often.
// =============================================================================

class BackupReportGenerator {
  String _monthKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}';
  }

  String _formatAmount(double amount) {
    final rounded = amount.round();
    final formatted = rounded
        .abs()
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '${rounded < 0 ? '-' : ''}Rs. $formatted';
  }

  String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  /// Builds the full HTML report from whatever the app's controllers
  /// currently hold in memory. Call this from the UI isolate, right
  /// after the controllers have finished their normal load — the same
  /// data the admin is already looking at on screen.
  String generate() {
    final dashboard = Get.find<DashboardController>();
    final feeController = Get.find<FeeController>();
    final studentController = Get.find<StudentController>();
    final expenseController = Get.find<ExpenseController>();

    final now = DateTime.now();
    final currentMonth = _monthKey(now);

    final activeStudents = studentController.activeStudents
        .where((s) => s.id != null)
        .toList();

    // ---------------------------------------------------------------------
    // Per-student fee status for the current month, richest-first (most
    // overdue / most owed at the top) — a "bossy, wants to see the
    // problem immediately" ordering, not alphabetical.
    // ---------------------------------------------------------------------
    final rows = activeStudents.map((student) {
      final summary = feeController.computeFeeSummaryForMonth(
        student.id!,
        currentMonth,
      );
      final fine = feeController.totalFineOwed(student.id!, currentMonth);
      final pending = summary.feePending < 0 ? 0.0 : summary.feePending;

      return _StudentRow(
        name: student.name,
        rollNumber: student.rollNumber ?? '-',
        monthlyFee: summary.feeCharged,
        paid: summary.feeSubmitted,
        pending: pending,
        fine: fine,
      );
    }).toList()
      ..sort((a, b) => (b.pending + b.fine).compareTo(a.pending + a.fine));

    final totalFineOwed = rows.fold<double>(0.0, (sum, r) => sum + r.fine);
    final totalPending = rows.fold<double>(0.0, (sum, r) => sum + r.pending);

    final recent = dashboard.recentActivity;

    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln(
      '<meta name="viewport" content="width=device-width, initial-scale=1">',
    );
    // Auto-refresh so a tab left open re-reads whatever the cloud sync
    // has most recently delivered to this same file path, without the
    // owner needing to do anything.
    buffer.writeln('<meta http-equiv="refresh" content="300">');
    buffer.writeln('<title>ONIMS Hostel — Daily Report</title>');
    buffer.writeln('<style>${_css()}</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    buffer.writeln('<div class="wrap">');

    // Header
    buffer.writeln('<div class="header">');
    buffer.writeln('<div>');
    buffer.writeln('<h1>ONIMS Hostel — Daily Report</h1>');
    buffer.writeln(
      '<p class="subtitle">Obaid Noor Institute of Medical &amp; Science</p>',
    );
    buffer.writeln('</div>');
    buffer.writeln(
      '<div class="asof">As of<br><strong>${_formatDateTime(now)}</strong></div>',
    );
    buffer.writeln('</div>');

    // Stat cards
    buffer.writeln('<div class="cards">');
    buffer.writeln(_card('Active Students', '${activeStudents.length}', ''));
    buffer.writeln(
      _card(
        'Collected This Month',
        _formatAmount(dashboard.collectedThisMonth),
        '',
      ),
    );
    buffer.writeln(
      _card(
        'Expenses This Month',
        _formatAmount(dashboard.expensesThisMonth),
        '',
      ),
    );
    buffer.writeln(
      _card(
        'Net Profit This Month',
        _formatAmount(dashboard.netProfitThisMonth),
        '',
      ),
    );
    buffer.writeln(
      _card('Total Amount (All-Time)', _formatAmount(dashboard.totalAmount), ''),
    );
    buffer.writeln(
      _card(
        'Overdue Fine',
        _formatAmount(totalFineOwed),
        totalFineOwed > 0 ? 'warn' : '',
      ),
    );
    buffer.writeln('</div>');

    // Fee status table
    buffer.writeln('<h2>Fee Status — ${_monthLabel(now)}</h2>');
    if (rows.isEmpty) {
      buffer.writeln('<p class="empty">No active students on record.</p>');
    } else {
      buffer.writeln('<div class="table-scroll"><table>');
      buffer.writeln(
        '<tr><th>Student</th><th>Roll No.</th><th>Monthly Fee</th>'
        '<th>Paid</th><th>Pending</th><th>Fine</th><th>Status</th></tr>',
      );
      for (final row in rows) {
        final isPaid = row.pending <= 0 && row.fine <= 0;
        final statusLabel = isPaid
            ? 'Paid'
            : (row.paid > 0 ? 'Partial' : 'Unpaid');
        final statusClass = isPaid ? 'ok' : (row.fine > 0 ? 'danger' : 'due');

        buffer.writeln('<tr>');
        buffer.writeln('<td>${_escape(row.name)}</td>');
        buffer.writeln('<td>${_escape(row.rollNumber)}</td>');
        buffer.writeln('<td>${_formatAmount(row.monthlyFee)}</td>');
        buffer.writeln('<td>${_formatAmount(row.paid)}</td>');
        buffer.writeln('<td>${_formatAmount(row.pending)}</td>');
        buffer.writeln(
          '<td>${row.fine > 0 ? _formatAmount(row.fine) : '-'}</td>',
        );
        buffer.writeln('<td><span class="badge $statusClass">$statusLabel</span></td>');
        buffer.writeln('</tr>');
      }
      buffer.writeln('</table></div>');
      buffer.writeln(
        '<p class="totals">Total pending this month: '
        '<strong>${_formatAmount(totalPending)}</strong> &nbsp;·&nbsp; '
        'Total fine owed: <strong>${_formatAmount(totalFineOwed)}</strong></p>',
      );
    }

    // Recent activity
    buffer.writeln('<h2>Recent Activity</h2>');
    if (recent.isEmpty) {
      buffer.writeln('<p class="empty">Nothing recorded yet.</p>');
    } else {
      buffer.writeln('<div class="table-scroll"><table>');
      buffer.writeln('<tr><th>Date</th><th>Description</th><th>Amount</th></tr>');
      for (final item in recent) {
        final sign = item.isIncome ? '+' : '-';
        final cls = item.isIncome ? 'income' : 'expense';
        buffer.writeln('<tr>');
        buffer.writeln('<td>${_formatDate(item.date)}</td>');
        buffer.writeln(
          '<td>${_escape(item.title)} <span class="muted">— ${_escape(item.subtitle)}</span></td>',
        );
        buffer.writeln(
          '<td class="$cls">$sign ${_formatAmount(item.amount)}</td>',
        );
        buffer.writeln('</tr>');
      }
      buffer.writeln('</table></div>');
    }

    buffer.writeln(
      '<p class="footer">Generated automatically by Onims Hostel Management. '
      'This page is a read-only snapshot — nothing here can be edited.</p>',
    );

    buffer.writeln('</div>'); // wrap
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  String _card(String label, String value, String tone) {
    final cls = tone.isEmpty ? '' : ' $tone';
    return '<div class="card$cls"><div class="card-label">$label</div>'
        '<div class="card-value">$value</div></div>';
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _monthLabel(DateTime date) => '${_monthNames[date.month - 1]} ${date.year}';

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthNames[date.month - 1].substring(0, 3)} ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(date)}, $hour:$minute $ampm';
  }

  String _css() {
    return '''
      :root { color-scheme: light; }
      * { box-sizing: border-box; }
      body {
        margin: 0; padding: 0; background: #f5f4fa;
        font-family: -apple-system, Segoe UI, Roboto, Arial, sans-serif;
        color: #201a2e;
      }
      .wrap { max-width: 980px; margin: 0 auto; padding: 28px 20px 60px; }
      .header {
        display: flex; justify-content: space-between; align-items: flex-start;
        margin-bottom: 22px;
      }
      h1 { font-size: 22px; margin: 0 0 4px; font-weight: 800; color: #3d2a72; }
      .subtitle { margin: 0; font-size: 13px; color: #6b6478; }
      .asof { text-align: right; font-size: 12px; color: #6b6478; }
      .asof strong { color: #201a2e; font-size: 13px; }
      .cards {
        display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px;
        margin-bottom: 28px;
      }
      .card {
        background: #fff; border: 1px solid #e6e2f2; border-radius: 12px;
        padding: 16px;
      }
      .card.warn { border-color: #f3c9c9; background: #fff6f6; }
      .card-label { font-size: 12px; color: #6b6478; margin-bottom: 6px; }
      .card-value { font-size: 19px; font-weight: 700; color: #201a2e; }
      .card.warn .card-value { color: #b3261e; }
      h2 { font-size: 15px; margin: 26px 0 10px; color: #3d2a72; }
      .table-scroll { overflow-x: auto; background: #fff; border-radius: 12px;
        border: 1px solid #e6e2f2; }
      table { width: 100%; border-collapse: collapse; font-size: 13px; }
      th, td { text-align: left; padding: 10px 12px; white-space: nowrap; }
      th { background: #f8f7fc; color: #6b6478; font-weight: 600; font-size: 12px; }
      tr:not(:last-child) td { border-bottom: 1px solid #f0eef7; }
      .muted { color: #9a93aa; font-size: 12px; }
      .income { color: #1f8a4c; font-weight: 600; }
      .expense { color: #b3261e; font-weight: 600; }
      .badge {
        display: inline-block; padding: 3px 9px; border-radius: 999px;
        font-size: 11px; font-weight: 700;
      }
      .badge.ok { background: #e6f6ec; color: #1f8a4c; }
      .badge.due { background: #fff3e0; color: #a3610a; }
      .badge.danger { background: #fdeaea; color: #b3261e; }
      .totals { font-size: 12.5px; color: #6b6478; margin-top: 10px; }
      .empty { color: #9a93aa; font-size: 13px; }
      .footer { margin-top: 36px; font-size: 11.5px; color: #9a93aa; text-align: center; }
      @media (max-width: 640px) {
        .cards { grid-template-columns: repeat(2, 1fr); }
        .header { flex-direction: column; gap: 10px; }
        .asof { text-align: left; }
      }
    ''';
  }
}

class _StudentRow {
  final String name;
  final String rollNumber;
  final double monthlyFee;
  final double paid;
  final double pending;
  final double fine;

  const _StudentRow({
    required this.name,
    required this.rollNumber,
    required this.monthlyFee,
    required this.paid,
    required this.pending,
    required this.fine,
  });
}