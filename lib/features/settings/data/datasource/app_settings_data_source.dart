// =============================================================================
// APP SETTINGS DATA SOURCE
//
// Holds app-wide single-row settings: Opening Balance (the money the
// hostel already had on hand before switching to this app), and the Late
// Fine rule (amount, due day of the month, and the fee-month it starts
// counting from). Kept as its own small feature rather than bolted onto
// Dashboard/Fees, since more app-wide settings are likely to land here
// later.
// =============================================================================

abstract class AppSettingsDataSource {
  Future<double> getOpeningBalance();

  Future<void> setOpeningBalance(double value);

  // ---------------------------------------------------------------------------
  // Late Fine rule
  // ---------------------------------------------------------------------------

  Future<double> getFineAmount();

  Future<int> getFineDueDay();

  Future<String?> getFineEffectiveFrom();

  /// Updates the fine amount and due day together — they're always
  /// edited as one rule from a single dialog, so there's no valid
  /// "half updated" state to allow. Does not touch fine_effective_from
  /// (that's only ever set by the migration, on purpose).
  Future<void> setFineRule({
    required double amount,
    required int dueDay,
  });

  // ---------------------------------------------------------------------------
  // Backup — a local folder (usually one a cloud-sync app is watching)
  // where automatic backups + the read-only report get written. NULL
  // path = feature off.
  // ---------------------------------------------------------------------------

  Future<String?> getBackupFolderPath();

  Future<void> setBackupFolderPath(String? path);

  Future<String?> getLastBackupAt();

  Future<void> setLastBackupAt(String value);
}