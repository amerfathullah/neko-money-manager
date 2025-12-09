import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../assets/data/models/asset.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import 'transaction_page.dart';

class TransactionHistoryPage extends ConsumerWidget {
  final Asset asset;

  const TransactionHistoryPage({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text('${asset.name} History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (allTransactions) {
          // Filter transactions for this asset
          // Include if assetId matches OR (transfer AND destinationAssetId matches)
          final assetTransactions = allTransactions.where((t) {
            final isSource = t.assetId == asset.id;
            final isDest =
                t.type == TransactionType.transfer &&
                t.destinationAssetId == asset.id;
            return isSource || isDest;
          }).toList();

          if (assetTransactions.isEmpty) {
            return const Center(
              child: Text(
                'No transactions found for this asset.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // Sort by date descending
          assetTransactions.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assetTransactions.length,
            itemBuilder: (context, index) {
              final transaction = assetTransactions[index];
              return _buildTransactionItem(context, transaction, asset.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionModel t,
    String currentAssetId,
  ) {
    // Determine signage and color relative to THIS asset
    double amount = t.amount;
    Color color = AppColors.textDark;
    String prefix = '';

    if (t.type == TransactionType.income) {
      color = AppColors.pastelGreen;
      prefix = '+';
    } else if (t.type == TransactionType.expense) {
      color = AppColors.pastelRed;
      prefix = '-';
    } else if (t.type == TransactionType.transfer) {
      if (t.destinationAssetId == currentAssetId) {
        // Incoming transfer
        color = AppColors.pastelGreen;
        prefix = '+';
      } else {
        // Outgoing transfer
        color = AppColors.pastelRed;
        prefix = '-';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getIconForType(t.type), color: color),
        ),
        title: Text(
          t.categoryName ?? 'Uncategorized',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy - hh:mm a').format(t.date),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          '$prefix${CurrencyFormatter.format(amount, symbol: '\$')}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () {
          // Navigate to edit
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TransactionPage(transaction: t),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }
}
