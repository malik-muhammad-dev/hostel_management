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
}