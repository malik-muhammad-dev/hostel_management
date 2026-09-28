import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_error_logger.dart';
import '../../../../core/realtime/realtime_table_sync.dart';
import '../../data/repositories/balance_addition_repository.dart';
import '../../models/balance_addition_model.dart';

// =============================================================================
// BALANCE ADDITION CONTROLLER — "Add to Total Balance" on the Dashboard
//
// Deliberately tiny: load the list, add a new entry. There is no
// edit/delete here — the client was explicit that this only ever adds,
// never replaces or touches an existing entry (see balance_addition_model
// .dart for the full reasoning).
// =============================================================================

class BalanceAdditionController extends GetxController {
  final BalanceAdditionRepository repository;

  BalanceAdditionController(this.repository);

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  final balanceAdditions = <BalanceAdditionModel>[].obs;

  final isLoading = false.obs;
  final isSaving = false.obs;

  // ---------------------------------------------------------------------------
  // Realtime — reloads from Supabase whenever `balance_additions` changes,
  // from this PC or any other one. See RealtimeTableSync for why this
  // exists.
  // ---------------------------------------------------------------------------

  late final RealtimeTableSync _realtimeSync;

  @override
  void onInit() {
    super.onInit();

    loadBalanceAdditions();

    _realtimeSync = RealtimeTableSync(
      tables: const ['balance_additions'],
      onChange: loadBalanceAdditions,
    );
  }

  @override
  void onClose() {
    _realtimeSync.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<void> loadBalanceAdditions() async {
    try {
      isLoading.value = true;

      final result = await repository.getBalanceAdditions();

      balanceAdditions.assignAll(result);
    } catch (e, stackTrace) {
      debugPrint('[BALANCE] loadBalanceAdditions failed: $e');
      debugPrint('$stackTrace');
      AppErrorLogger.log(
        'BalanceAdditionController.loadBalanceAdditions',
        e,
        stackTrace,
      );
      AppErrorLogger.notifyLoadFailure('Balance additions');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Add — the only write this feature has. Always a brand-new entry on
  // top of whatever already exists; never edits or removes a past one.
  // ---------------------------------------------------------------------------

  Future<bool> addBalance({
    required double amount,
    required BalanceAdditionBox box,
  }) async {
    if (amount <= 0) return false;

    try {
      isSaving.value = true;

      final addition = BalanceAdditionModel(
        id: const Uuid().v4(),
        date: DateTime.now(),
        amount: amount,
        box: box,
      );

      await repository.addBalanceAddition(addition);

      balanceAdditions.add(addition);

      return true;
    } catch (e, stackTrace) {
      debugPrint('[BALANCE] addBalance failed: $e');
      debugPrint('$stackTrace');
      AppErrorLogger.log('BalanceAdditionController.addBalance', e, stackTrace);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Totals — read by DashboardController to fold into Cash Box, Account
  // Box, and Total Amount. See dashboard_controller.dart for exactly how.
  // ---------------------------------------------------------------------------

  double get totalCashAdded => balanceAdditions
      .where((addition) => addition.box == BalanceAdditionBox.cash)
      .fold<double>(0.0, (sum, addition) => sum + addition.amount);

  double get totalAccountAdded => balanceAdditions
      .where((addition) => addition.box == BalanceAdditionBox.account)
      .fold<double>(0.0, (sum, addition) => sum + addition.amount);

  double get totalAdded => totalCashAdded + totalAccountAdded;
}
