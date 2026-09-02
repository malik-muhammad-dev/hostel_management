import '../datasources/receipt_data_source.dart';
import '../../models/receipt_model.dart';

class ReceiptRepository {
  final ReceiptDataSource dataSource;

  ReceiptRepository(this.dataSource);

  Future<List<ReceiptModel>> getReceipts() {
    return dataSource.getReceipts();
  }

  Future<void> addReceipt(ReceiptModel receipt) {
    return dataSource.addReceipt(receipt);
  }

  Future<void> updateReceipt(ReceiptModel receipt) {
    return dataSource.updateReceipt(receipt);
  }

  Future<void> deleteReceipt(String receiptId) {
    return dataSource.deleteReceipt(receiptId);
  }
}