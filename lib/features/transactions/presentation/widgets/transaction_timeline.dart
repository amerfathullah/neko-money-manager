import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../assets/data/models/asset.dart';
import '../../../assets/presentation/providers/asset_provider.dart';
import '../../../home/presentation/providers/ledger_provider.dart';
import '../../../home/data/models/ledger.dart';
import '../../data/models/transaction_model.dart';
import 'transaction_details_dialog.dart';
import 'transaction_card.dart';

class TransactionTimeline extends ConsumerWidget {
  final List<TransactionModel> transactions;
  final String currencySymbol;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final bool useComma;
  final Color? backgroundColor;

  const TransactionTimeline({
    super.key,
    required this.transactions,
    required this.currencySymbol,
    this.physics,
    this.shrinkWrap = true,
    this.padding,
    this.useComma = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text('No records', style: TextStyle(color: Colors.grey)),
      );
    }

    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    final categories = ref.watch(categoryProvider).asData?.value ?? [];
    final assets = ref.watch(assetProvider).asData?.value ?? [];
    final ledgers = ref.watch(ledgerProvider).asData?.value ?? [];

    // Group transactions by Date
    final Map<String, List<TransactionModel>> grouped = {};
    for (var t in transactions) {
      final key = DateFormat('yyyyMMdd').format(t.date);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(t);
    }

    // Sort dates descending
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dayTransactions = grouped[dateKey]!;
        final date = dayTransactions.first.date;

        // Sort transactions by date descending to ensure time flow
        dayTransactions.sort((a, b) => b.date.compareTo(a.date));

        // Calculate Day Totals
        double income = 0;
        double expense = 0;
        for (var t in dayTransactions) {
          if (t.type == TransactionType.income) income += t.amount;
          if (t.type == TransactionType.expense) expense += t.amount;
        }

        // Build list with hour grouping
        final List<Widget> transactionWidgets = [];
        int? lastHour;

        for (var t in dayTransactions) {
          bool showTime = false;
          if (lastHour == null || t.date.hour != lastHour) {
            showTime = true;
            lastHour = t.date.hour;
          }

          transactionWidgets.add(
            _buildTimelineItem(
              context,
              t,
              currencySymbol,
              categories,
              assets,
              ledgers,
              useComma,
              showTime,
            ),
          );
        }

        return Column(
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Date Text
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: RichText(
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: DateFormat(
                                      'MMM',
                                    ).format(date).substring(0, 1),
                                    style: const TextStyle(
                                      color:
                                          AppColors.expense, // Highlight color
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '${DateFormat('MMM').format(date).substring(1)} ${DateFormat('dd').format(date)}',
                                    style: TextStyle(
                                      color: themeColors.text,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: themeColors
                                    .container, // Beige/Sand pill background
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                DateFormat('EEE').format(date),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: themeColors.text,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Daily Totals
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (income > 0)
                          Text(
                            '+${CurrencyFormatter.format(income, symbol: '', useGrouping: useComma)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: themeColors.text,
                              fontSize: 18,
                            ),
                          ),
                        if (income > 0 && expense > 0) const SizedBox(width: 8),
                        if (expense > 0)
                          Text(
                            '-${CurrencyFormatter.format(expense, symbol: '', useGrouping: useComma)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.expense,
                              fontSize: 18,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Connecting line from header to first item
            // This is a bit tricky with the current layout. The original logic just listed items.
            // The image check in previous turn implies the line connects items.
            // But usually there is a connection from date header too?
            // The code I analyzed in `ledger_details_page.dart` didn't explicitly show a connector *from* the header,
            // but the items clearly have a vertical line.

            // Checking logic:
            // The item has `Stack` with `Container(width: 2, color: category.color)`.
            // Wait, I need to make sure the connector matches the design.
            // The user request in history 05b... mentioned "connecting line from the date header to the timeline".
            // I should verify if that was implemented in `LedgerDetailsPage`.
            // Looking at `read_file` output of `ledger_details_page.dart`:
            // It just does `Row` with `RichText` etc. No vertical line mentioned in the Date Header part.
            // But let's check `_buildTimelineItem`. It has a vertical line.
            // If I want to be 100% faithful to the *current* state of `LedgerDetailsPage`, I should just copy what's there.
            // I'll stick to the logic I read from `ledger_details_page.dart` line 244 onwards.
            // It seems the "connecting line" might have been missed or I missed it in the read.
            // Let's re-read line 244-332 of `ledger_details_page.dart` from the previous turn context.
            // It prints `Row` for header. Then `...dayTransactions.map`.
            // So there's no visual connection *between* the header row and the first item in the code I read?
            // Ah, wait. `_buildTimelineItem` has the line.
            // If the user *wants* the connection, and claimed it was done in a previous task, maybe I missed it or it's implicitly handled by alignment.
            // *Wait*, looking at the `find_by_name` results, there is no separate "timeline widget" file yet, so I am creating it.
            // I will implement `_buildTimelineItem` logic inside this widget.

            // Transactions Timeline
            ...transactionWidgets,
          ],
        );
      },
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    TransactionModel t,
    String currencySymbol,
    List<Category> categories,
    List<Asset> assets,
    List<Ledger> ledgers,
    bool useComma,
    bool showTime,
  ) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;

    final category = categories.firstWhere(
      (c) => c.id == t.categoryId,
      orElse: () => Category(
        id: 'unknown',
        name: t.categoryName ?? 'Unknown',
        iconCodePoint: Icons.help_outline.codePoint,
        iconFontFamily: 'MaterialIcons',
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

    // Use Asset Icon
    // final assetIcon = asset.icon; // Removed

    // Use Ledger from transaction
    final transactionLedger = ledgers.firstWhere(
      (l) => l.id == t.ledgerId,
      orElse: () => Ledger(
        id: 'unknown',
        name: 'Unknown',
        colorValue: Colors.grey.toARGB32(),
      ),
    );

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => TransactionDetailsDialog(
            transaction: t,
            category: category,
            asset: asset,
            ledger: transactionLedger,
            currencySymbol: currencySymbol,
          ),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time Column (Left)
            // Time Column (Left)
            SizedBox(
              width: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dashed Line (Background)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(width: 2, color: category.color),
                    ),
                  ),
                  // Time (Foreground with Mask)
                  if (showTime)
                    Positioned(
                      top: 0,
                      bottom: 10, // Matches card bottom margin
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          color:
                              backgroundColor ??
                              themeColors
                                  .background, // Mask line with background color
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            DateFormat('HH:00').format(t.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: themeColors.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Arrow Column
            SizedBox(
              width: 20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (showTime)
                    Positioned(
                      top: 0,
                      bottom: 10, // Matches card bottom margin
                      left: 0,
                      right: 0,
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow,
                          size: 12,
                          color: AppColors.timelineArrow,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Card
            Expanded(
              child: TransactionCard(
                transaction: t,
                category: category,
                asset: asset,
                ledger: transactionLedger,
                currencySymbol: currencySymbol,
                useComma: useComma,
                backgroundColor: backgroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
