import 'package:flutter/foundation.dart';
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
    debugPrint('[SETTINGS] AppSettingsController created: $hashCode');
    loadOpeningBalance();
  }

  Future<void> loadOpeningBalance() async {
    try {
      isLoading.value = true;
      final loaded = await repository.getOpeningBalance();
      debugPrint('[SETTINGS] loadOpeningBalance() read from DB: $loaded');
      openingBalance.value = loaded;
    } finally {
      isLoading.value = false;
    }
  }

  /// Called from the dashboard's "edit" dialog on the Total Amount card.
  Future<void> setOpeningBalance(double value) async {
    debugPrint(
      '[SETTINGS] setOpeningBalance($value) called on controller $hashCode '
      '— current value before write: ${openingBalance.value}',
    );

    await repository.setOpeningBalance(value);

    final verifyRead = await repository.getOpeningBalance();
    debugPrint('[SETTINGS] after DB write, re-read from DB: $verifyRead');

    openingBalance.value = value;

    debugPrint(
      '[SETTINGS] openingBalance.value is now: ${openingBalance.value}',
    );
  }
}