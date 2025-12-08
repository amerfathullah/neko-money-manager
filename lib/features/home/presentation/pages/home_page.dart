import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../providers/ledger_provider.dart';
import '../widgets/ledger_card.dart';
import '../widgets/transaction_chart.dart';
import 'ledger_details_page.dart';
import '../../../../core/widgets/banner_ad_widget.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../settings/presentation/providers/currency_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ledgersAsync = ref.watch(ledgerProvider);
    final transactionsAsync = ref.watch(transactionProvider);
    final currencyAsync = ref.watch(currencyProvider);
    final currencySymbol = currencyAsync.asData?.value ?? '\$';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: theme.brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Wallets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: ledgersAsync.when(
                    data: (ledgers) => ledgers.isEmpty
                        ? const Center(
                            child: Text('No wallets found. Add one!'),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: ledgers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final ledger = ledgers[index];
                              return LedgerCard(
                                name: ledger.name,
                                balance: ledger.balance,
                                color: ledger.color,
                                currencySymbol: currencySymbol,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          LedgerDetailsPage(ledger: ledger),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Expense Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                transactionsAsync.when(
                  data: (transactions) => TransactionChart(
                    transactions: transactions,
                    onCategoryTap: (categoryName) {
                      _showCategoryTransactions(
                        context,
                        transactions,
                        categoryName,
                        currencySymbol,
                      );
                    },
                  ),
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No transactions yet'),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        final isExpense =
                            transaction.type == TransactionType.expense;
                        final isIncome =
                            transaction.type == TransactionType.income;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          color: Theme.of(context).cardColor,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isExpense
                                  ? AppColors.pastelRed.withValues(alpha: 0.2)
                                  : isIncome
                                  ? AppColors.pastelGreen.withValues(alpha: 0.2)
                                  : AppColors.pastelBlue.withValues(alpha: 0.2),
                              child: Icon(
                                isExpense
                                    ? Icons.arrow_downward
                                    : isIncome
                                    ? Icons.arrow_upward
                                    : Icons.swap_horiz,
                                color: isExpense
                                    ? AppColors.expense
                                    : isIncome
                                    ? AppColors.income
                                    : AppColors.transfer,
                              ),
                            ),
                            title: Text(
                              transaction.categoryName ?? 'Uncategorized',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(transaction.date),
                              style: TextStyle(
                                color: AppColors.textDark.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            trailing: Text(
                              '${isExpense ? '-' : '+'}${CurrencyFormatter.format(transaction.amount, symbol: currencySymbol)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isExpense
                                    ? AppColors.expense
                                    : isIncome
                                    ? AppColors.income
                                    : AppColors
                                          .textDark, // Transfer neutral? or specific color
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      Center(child: Text('Error loading transactions: $err')),
                ),

                const SizedBox(height: 24),
                const BannerAdWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryTransactions(
    BuildContext context,
    List<TransactionModel> allTransactions,
    String categoryName,
    String currencySymbol,
  ) {
    final filtered = allTransactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              (t.categoryName == categoryName ||
                  (t.categoryName == null && categoryName == 'Uncategorized')),
        )
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$categoryName Transactions',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final t = filtered[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      DateFormat('MMM dd, yyyy').format(t.date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(t.note ?? 'No note'),
                    trailing: Text(
                      '-${CurrencyFormatter.format(t.amount, symbol: currencySymbol)}',
                      style: const TextStyle(
                        color: AppColors.expense,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
