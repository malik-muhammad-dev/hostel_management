// =============================================================================
// APP SETTINGS DATA SOURCE
//
// Right now this only holds one value — Opening Balance (the money the
// hostel already had on hand before switching to this app). Kept as its
// own small feature rather than bolted onto Dashboard/Fees, since more
// app-wide settings are likely to land here later.
// =============================================================================

abstract class AppSettingsDataSource {
  Future<double> getOpeningBalance();

  Future<void> setOpeningBalance(double value);
}