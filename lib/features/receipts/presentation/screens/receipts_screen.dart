import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../models/receipt_model.dart';
import '../controllers/receipt_controller.dart';

// =============================================================================
// RECEIPTS SCREEN
//
// "Cash Receipts" — a running record of money received that has nothing
// to do with student fees (a donation, a refund, cash the owner hands
// over, etc. — client's words: "may it receive from student or anyone").
// Everything on this screen is scoped to its own ReceiptController/table
// and never touches Fees, Expenses, or the Total Amount figure — see the
// CREATE TABLE comment in AppDatabase for the full explanation.
// =============================================================================

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReceiptController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ReceiptsPageHeader(),
          const SizedBox(height: 24),
          Obx(() {
            // Read every Rx value HERE, at the top level of Obx's own
            // builder — never inside a separate widget's own build()
            // (that runs outside Obx's tracking window and silently
            // stops updating; see DashboardScreen's stat cards for the
            // same rule already established in this codebase).
            final total = controller.totalReceipts;
            final cash = controller.cashReceipts;
            final account = controller.accountReceipts;

            return _ReceiptsSummary(total: total, cash: cash, account: account);
          }),
          const SizedBox(height: 24),
          _ReceiptsTable(controller: controller),
        ],
      ),
    );
  }
}

// =============================================================================
// PAGE HEADER
// =============================================================================

class _ReceiptsPageHeader extends StatelessWidget {
  const _ReceiptsPageHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash Receipts',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Money received outside of student fees — kept separately, never counted into Total Amount or fee/expense figures',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SUMMARY CARDS
// =============================================================================

class _ReceiptsSummary extends StatelessWidget {
  final double total;
  final double cash;
  final double account;

  const _ReceiptsSummary({
    required this.total,
    required this.cash,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Received',
            amount: _formatAmount(total),
            subtitle: 'All-time',
            icon: Icons.local_atm_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Cash',
            amount: _formatAmount(cash),
            subtitle: 'All-time',
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Account',
            amount: _formatAmount(account),
            subtitle: 'All-time',
            icon: Icons.account_balance_outlined,
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    return 'Rs. $formatted';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 5),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// RECEIPTS TABLE
// =============================================================================

class _ReceiptsTable extends StatelessWidget {
  final ReceiptController controller;

  const _ReceiptsTable({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: AppColors.border),
          const _TableHeader(),
          Obx(() => _buildRows()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receipt Records',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'View recorded cash receipts',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.find<AppShellController>().openAddReceipt();
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Receipt'),
          ),
        ],
      ),
    );
  }

  Widget _buildRows() {
    final rows = controller.receiptsSortedByDateDesc;

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Center(
          child: Text(
            'No cash receipts recorded yet.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: rows
          .map(
            (receipt) => _ReceiptRow(
              receipt: receipt,
              onDelete: () => _deleteReceipt(receipt.id),
            ),
          )
          .toList(),
    );
  }

  Future<void> _deleteReceipt(String? receiptId) async {
    if (receiptId == null) {
      return;
    }

    await controller.deleteReceipt(receiptId);
  }
}

// =============================================================================
// TABLE HEADER
// =============================================================================

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      color: AppColors.background,
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('Date', style: _receiptHeaderStyle)),
          Expanded(flex: 2, child: Text('Received From', style: _receiptHeaderStyle)),
          Expanded(flex: 3, child: Text('Notes', style: _receiptHeaderStyle)),
          Expanded(flex: 2, child: Text('Amount', style: _receiptHeaderStyle)),
          Expanded(flex: 2, child: Text('Kept As', style: _receiptHeaderStyle)),
          SizedBox(width: 50, child: Text('Action', style: _receiptHeaderStyle)),
        ],
      ),
    );
  }
}

// =============================================================================
// RECEIPT ROW
// =============================================================================

class _ReceiptRow extends StatelessWidget {
  final ReceiptModel receipt;
  final VoidCallback onDelete;

  const _ReceiptRow({required this.receipt, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(receipt.date),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.receivedFrom ?? '-',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (receipt.receivedFromType != null)
                  Text(
                    receipt.receivedFromType!.label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              receipt.notes ?? '-',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatAmount(receipt.amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _PaymentBadge(paymentMode: receipt.paymentMode),
          ),
          SizedBox(
            width: 50,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
              ],
              child: const Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} '
        '${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    return 'Rs. $formatted';
  }
}

// =============================================================================
// PAYMENT BADGE
// =============================================================================

class _PaymentBadge extends StatelessWidget {
  final ReceiptPaymentMode paymentMode;

  const _PaymentBadge({required this.paymentMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        paymentMode.label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

const _receiptHeaderStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);