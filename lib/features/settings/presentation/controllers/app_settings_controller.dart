import 'package:get/get.dart';

import '../../data/repositories/app_settings_repository.dart';

class AppSettingsController extends GetxController {
  final AppSettingsRepository repository;

  AppSettingsController(this.repository);

  final openingBalance = 0.0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadOpeningBalance();
  }

  Future<void> loadOpeningBalance() async {
    try {
      isLoading.value = true;
      openingBalance.value = await repository.getOpeningBalance();
    } finally {
      isLoading.value = false;
    }
  }

  /// Called from the dashboard's "edit" dialog on the Total Amount card.
  Future<void> setOpeningBalance(double value) async {
    await repository.setOpeningBalance(value);
    openingBalance.value = value;
  }
}