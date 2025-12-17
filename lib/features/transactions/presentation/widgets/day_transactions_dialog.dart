import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../assets/data/models/asset.dart';
import '../../../assets/presentation/providers/asset_provider.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../home/data/models/ledger.dart';
import '../../../home/presentation/providers/ledger_provider.dart';
import '../../data/models/transaction_model.dart';
import '../pages/transaction_page.dart';
import 'transaction_card.dart';

class DayTransactionsDialog extends ConsumerWidget {
  final DateTime date;
  final List<TransactionModel> transactions;
  final String currencySymbol;
  final bool useComma;

  const DayTransactionsDialog({
    super.key,
    required this.date,
    required this.transactions,
    required this.currencySymbol,
    required this.useComma,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    final categories = ref.watch(categoryProvider).asData?.value ?? [];
    final assets = ref.watch(assetProvider).asData?.value ?? [];
    final ledgers = ref.watch(ledgerProvider).asData?.value ?? [];

    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.income) totalIncome += t.amount;
      if (t.type == TransactionType.expense) totalExpense += t.amount;
    }
    double total = totalIncome - totalExpense;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: themeColors.surface, // Assuming cream/surface color
          borderRadius: BorderRadius.circular(32),
        ),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: themeColors.background,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM dd yyyy').format(date),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: themeColors.text,
                            ),
                          ),
                          Text(
                            '${total < 0 ? '-' : ''}$currencySymbol${CurrencyFormatter.format(total.abs(), symbol: '', useGrouping: useComma)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: total < 0
                                  ? AppColors.expense
                                  : AppColors.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton.small(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionPage(initialDate: date),
                        ),
                      );
                    },
                    backgroundColor: const Color(0xFFD32F2F), // Muted red
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: transactions.isEmpty
                  ? const Center(child: Text("No transactions"))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final t = transactions[index];
                        final category = categories.firstWhere(
                          (c) => c.id == t.categoryId,
                          orElse: () => Category(
                            id: 'unknown',
                            name: t.categoryName ?? 'Unknown',
                            iconCodePoint: Icons.help_outline.codePoint,
                            colorValue: Colors.grey.toARGB32(),
                            type: CategoryType.expense,
                          ),
                        );
                        final asset = assets.firstWhere(
                          (a) => a.id == t.assetId,
                          orElse: () => Asset(
                            id: 'unknown',
                            name: t.assetName ?? 'Unknown',
                            colorValue: Colors.blueGrey.toARGB32(),
                          ),
                        );
                        final ledger = ledgers.firstWhere(
                          (l) => l.id == t.ledgerId,
                          orElse: () => Ledger(
                            id: 'unknown',
                            name: 'Unknown',
                            colorValue: Colors.grey.toARGB32(),
                          ),
                        );

                        return TransactionCard(
                          transaction: t,
                          category: category,
                          asset: asset,
                          ledger: ledger,
                          currencySymbol: currencySymbol,
                          useComma: useComma,
                          backgroundColor: themeColors.background,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
