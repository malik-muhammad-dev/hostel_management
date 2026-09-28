import '../datasources/balance_addition_data_source.dart';
import '../../models/balance_addition_model.dart';

class BalanceAdditionRepository {
  final BalanceAdditionDataSource dataSource;

  BalanceAdditionRepository(this.dataSource);

  Future<List<BalanceAdditionModel>> getBalanceAdditions() {
    return dataSource.getBalanceAdditions();
  }

  Future<void> addBalanceAddition(BalanceAdditionModel addition) {
    return dataSource.addBalanceAddition(addition);
  }
}
