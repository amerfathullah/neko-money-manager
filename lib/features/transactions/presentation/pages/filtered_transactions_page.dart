import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme_colors.dart';

import '../../../settings/presentation/providers/currency_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_timeline.dart';

class FilteredTransactionsPage extends ConsumerWidget {
  final String title;
  final bool Function(TransactionModel) filter;

  const FilteredTransactionsPage({
    super.key,
    required this.title,
    required this.filter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionProvider);
    final currencyAsync = ref.watch(currencyProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;

    final currencySymbol = currencyAsync.asData?.value ?? '\$';
    final settings = settingsAsync.asData?.value;
    final useComma = settings?.useCommaSeparator ?? true;

    return Scaffold(
      backgroundColor: themeColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: themeColors.text),
        titleTextStyle: TextStyle(
          color: themeColors.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final filteredTransactions = transactions.where(filter).toList();

          // Sort by date descending
          filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

          if (filteredTransactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: themeColors.text.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions found',
                    style: TextStyle(
                      color: themeColors.text.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: TransactionTimeline(
              transactions: filteredTransactions,
              currencySymbol: currencySymbol,
              useComma: useComma,
              backgroundColor: themeColors.background,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
