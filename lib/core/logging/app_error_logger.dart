import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// =============================================================================
// APP ERROR LOGGER
//
// Before this, a failure past the initial try/catch just went to
// debugPrint — visible only if someone happens to be watching a terminal
// at that exact moment, which in practice means never. If something
// breaks for the client, there was no way to find out what happened
// after the fact.
//
// This writes one plain-text entry per error to a log file on disk
// (Documents/ONIMS Logs/error_log.txt), so if the client reports "the
// app did something odd," that file can be asked for and read like any
// other text file — no paid monitoring service, no network dependency,
// works the same on the free Supabase tier this client is on.
//
// Deliberately NOT a replacement for a user-facing message on the
// screen — this is the after-the-fact record, not how the person using
// the app finds out something went wrong in the moment.
// =============================================================================

class AppErrorLogger {
  AppErrorLogger._();

  // Keeps the file from growing forever over months/years of daily use
  // — once it passes this size, it's trimmed back to roughly its
  // second half before the next entry is appended.
  static const int _maxBytes = 2 * 1024 * 1024; // 2 MB

  static Future<File> _logFile() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(documentsDir.path, 'ONIMS Logs'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return File(p.join(dir.path, 'error_log.txt'));
  }

  /// Records one error. [context] is a short human label for where it
  /// happened (e.g. "FeeController.loadFeeData") — this file is meant
  /// to be skimmable by a non-developer, so a clear label matters more
  /// than a full stack trace.
  ///
  /// Never throws — a failure while trying to log must never become the
  /// reason something ELSE breaks.
  static Future<void> log(
    String context,
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    // Always at least visible to a dev running from a terminal, exactly
    // as every catch block already did — this is additive, not a
    // replacement.
    debugPrint('[ERROR] $context: $error');

    try {
      final file = await _logFile();
      await _trimIfTooLarge(file);

      final timestamp = DateTime.now().toIso8601String();
      final buffer = StringBuffer()
        ..writeln('[$timestamp] $context')
        ..writeln('  $error');

      if (stackTrace != null) {
        // Only the first few lines — enough to locate the spot without
        // turning one error into fifty lines in a file meant to be
        // skimmed, not debugged line-by-line.
        final lines = stackTrace.toString().split('\n').take(5);
        for (final line in lines) {
          buffer.writeln('  $line');
        }
      }

      buffer.writeln();

      await file.writeAsString(buffer.toString(), mode: FileMode.append);
    } catch (_) {
      // Disk full, permissions issue, whatever — logging failed
      // silently on purpose. debugPrint above already ran.
    }
  }

  static Future<void> _trimIfTooLarge(File file) async {
    if (!await file.exists()) return;

    final length = await file.length();
    if (length <= _maxBytes) return;

    final content = await file.readAsString();
    final keepFrom = (content.length / 2).floor();

    // Cut on a line boundary so the file doesn't start mid-entry.
    final newlineIndex = content.indexOf('\n', keepFrom);
    final trimmed =
        newlineIndex == -1 ? content : content.substring(newlineIndex + 1);

    await file.writeAsString(
      '--- log trimmed ${DateTime.now().toIso8601String()} ---\n$trimmed',
    );
  }

  /// Absolute path to the log file — for telling the client where to
  /// find it. Resolved lazily since path_provider needs platform
  /// channels that aren't ready before main() runs.
  static Future<String> filePath() async {
    final file = await _logFile();
    return file.path;
  }

  /// Shows one short, consistent "couldn't load X" message. Used right
  /// after logging a load failure (a fetch that populates a screen's
  /// list, run at startup or on tab open) so the person using the app
  /// actually finds out something went wrong instead of seeing what
  /// just looks like an empty list — before this, a failed fetch here
  /// left no visible trace anywhere on screen.
  ///
  /// Deliberately NOT used for save/update/delete actions — those
  /// already return null/false to their caller, which shows its own
  /// specific message (e.g. "Unable to save expense.").
  static void notifyLoadFailure(String featureLabel) {
    Get.snackbar(
      "Couldn't load $featureLabel",
      'Check your internet connection, then try again.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
