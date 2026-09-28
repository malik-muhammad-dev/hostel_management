import '../../models/balance_addition_model.dart';

abstract class BalanceAdditionDataSource {
  Future<List<BalanceAdditionModel>> getBalanceAdditions();

  Future<void> addBalanceAddition(BalanceAdditionModel addition);
}
