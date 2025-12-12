import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../assets/data/models/asset.dart';
import '../../../categories/data/models/category.dart';
import '../../../home/data/models/ledger.dart';
import '../../data/models/transaction_model.dart';
import '../pages/transaction_page.dart';
import '../providers/transaction_provider.dart';

class TransactionDetailsDialog extends ConsumerStatefulWidget {
  final TransactionModel transaction;
  final Category category;
  final Asset asset;
  final Ledger ledger;
  final String currencySymbol;

  const TransactionDetailsDialog({
    super.key,
    required this.transaction,
    required this.category,
    required this.asset,
    required this.ledger,
    required this.currencySymbol,
  });

  @override
  ConsumerState<TransactionDetailsDialog> createState() =>
      _TransactionDetailsDialogState();
}

class _TransactionDetailsDialogState
    extends ConsumerState<TransactionDetailsDialog> {
  late TransactionModel _currentTransaction;

  @override
  void initState() {
    super.initState();
    _currentTransaction = widget.transaction;
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _currentTransaction.type == TransactionType.expense;
    final color = widget.category.color;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFFFFF8E5), // Cream color
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Icon, Name, Amount
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.category.icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.category.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Text(
                  '${isExpense ? '-' : ''}${CurrencyFormatter.format(_currentTransaction.amount, symbol: widget.currencySymbol)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isExpense ? AppColors.expense : AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Details
            _buildDetailRow(
              'Date',
              DateFormat('MMM dd yyyy').format(_currentTransaction.date),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Time',
              DateFormat('HH:mm').format(_currentTransaction.date),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Asset', widget.asset.name),
            const SizedBox(height: 12),
            _buildDetailRow('Ledger', widget.ledger.name),

            const SizedBox(height: 24),

            // Remark
            Text(
              (_currentTransaction.remarks != null &&
                      _currentTransaction.remarks!.isNotEmpty)
                  ? _currentTransaction.remarks!
                  : 'No remark',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                // Edit
                _buildOptionBtn(
                  icon: Icons.edit,
                  color: AppColors.textDark,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TransactionPage(transaction: _currentTransaction),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Delete
                _buildOptionBtn(
                  icon: Icons.delete,
                  color: AppColors.textDark,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Transaction?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                          TextButton(
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await ref
                          .read(transactionProvider.notifier)
                          .deleteTransaction(_currentTransaction);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(width: 8),
                // Bookmark
                _buildOptionBtn(
                  icon: _currentTransaction.isBookmarked
                      ? Icons.star
                      : Icons.star_border,
                  color: _currentTransaction.isBookmarked
                      ? Colors.amber
                      : AppColors.textDark,
                  onTap: () {
                    final oldTx = _currentTransaction;
                    setState(() {
                      _currentTransaction = oldTx.copyWith(
                        isBookmarked: !oldTx.isBookmarked,
                      );
                    });
                    ref
                        .read(transactionProvider.notifier)
                        .toggleBookmark(oldTx);
                  },
                ),

                const Spacer(),

                // Reimburse Button
                if (_currentTransaction.isReimbursement)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC25E5E), // Redish
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Reimbursement processed (Placeholder)',
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Reimburse',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textDark,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5E6D3), // Beige background
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
