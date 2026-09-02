import '../../models/receipt_model.dart';

abstract class ReceiptDataSource {
  Future<List<ReceiptModel>> getReceipts();

  Future<void> addReceipt(ReceiptModel receipt);

  Future<void> updateReceipt(ReceiptModel receipt);

  Future<void> deleteReceipt(int receiptId);
}