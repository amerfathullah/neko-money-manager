import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../assets/data/models/asset.dart';
import '../../../assets/presentation/providers/asset_provider.dart';
import '../../../home/presentation/providers/ledger_provider.dart';
import '../../../home/data/models/ledger.dart';
import '../../data/models/transaction_model.dart';
import '../../presentation/pages/transaction_page.dart';

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
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '${DateFormat('MMM').format(date).substring(1)} ${DateFormat('dd').format(date)}',
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      fontFamily: 'Roboto',
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
                                color: const Color(
                                  0xFFEFE6D5,
                                ), // Beige/Sand pill background
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                DateFormat('EEE').format(date),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textDark,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
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
    final isExpense = t.type == TransactionType.expense;
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

    // Use Asset Icon
    final assetIcon = asset.icon;

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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TransactionPage(transaction: t)),
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
                              const Color(
                                0xFFFFF8E1,
                              ), // Mask line with background color
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            DateFormat('HH:00').format(t.date),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
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
                          color: Color(0xFFBF4C58),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 4,
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  color: category.color.withValues(
                    alpha: 0.2,
                  ), // Background follows category color
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    // Large Category Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: backgroundColor ??
                              const Color(
                                0xFFFFF8E1,
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        category.icon,
                        size: 24,
                        color: category.color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Category Name
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Bottom Row: Time Pill, Asset, Ledger, etc.
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Time Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: category.color.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DateFormat('HH:mm').format(t.date),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              // Asset Icon
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: asset.color.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  assetIcon,
                                  size: 16,
                                  color: asset.color,
                                ),
                              ),
                              // Ledger Icon
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: transactionLedger.color.withValues(
                                    alpha: 0.2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  transactionLedger.icon ??
                                      Icons.account_balance_wallet,
                                  size: 16,
                                  color: transactionLedger.color,
                                ),
                              ),
                              // Reimbursement Icon
                              if (t.isReimbursement) ...[
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.pastelPurple.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.work,
                                    size: 16,
                                    color: AppColors.pastelPurple,
                                  ),
                                ),
                              ],
                              // Bookmark Icon (Star)
                              if (t.isBookmarked) ...[
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Amount
                    Text(
                      '${isExpense ? '-' : '+'}${CurrencyFormatter.format(t.amount, symbol: '', useGrouping: useComma)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isExpense
                            ? AppColors.expense
                            : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
