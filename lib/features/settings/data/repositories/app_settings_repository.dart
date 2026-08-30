import '../datasource/app_settings_data_source.dart';

class AppSettingsRepository {
  final AppSettingsDataSource dataSource;

  AppSettingsRepository(this.dataSource);

  Future<double> getOpeningBalance() {
    return dataSource.getOpeningBalance();
  }

  Future<void> setOpeningBalance(double value) {
    return dataSource.setOpeningBalance(value);
  }

  // ---------------------------------------------------------------------------
  // Late Fine rule
  // ---------------------------------------------------------------------------

  Future<double> getFineAmount() {
    return dataSource.getFineAmount();
  }

  Future<int> getFineDueDay() {
    return dataSource.getFineDueDay();
  }

  Future<String?> getFineEffectiveFrom() {
    return dataSource.getFineEffectiveFrom();
  }

  Future<void> setFineRule({
    required double amount,
    required int dueDay,
  }) {
    return dataSource.setFineRule(amount: amount, dueDay: dueDay);
  }

  // ---------------------------------------------------------------------------
  // Backup
  // ---------------------------------------------------------------------------

  Future<String?> getBackupFolderPath() {
    return dataSource.getBackupFolderPath();
  }

  Future<void> setBackupFolderPath(String? path) {
    return dataSource.setBackupFolderPath(path);
  }

  Future<String?> getLastBackupAt() {
    return dataSource.getLastBackupAt();
  }

  Future<void> setLastBackupAt(String value) {
    return dataSource.setLastBackupAt(value);
  }
}