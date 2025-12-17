import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/dynamic_icon.dart';
import '../../../assets/data/models/asset.dart';
import '../../../categories/data/models/category.dart';
import '../../../home/data/models/ledger.dart';
import '../../data/models/transaction_model.dart';
import 'transaction_details_dialog.dart';
import 'transaction_timeline_asset_icon.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final Category category;
  final Asset asset;
  final Ledger ledger;
  final String currencySymbol;
  final bool useComma;
  final Color? backgroundColor;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.category,
    required this.asset,
    required this.ledger,
    required this.currencySymbol,
    required this.useComma,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    final isExpense = transaction.type == TransactionType.expense;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => TransactionDetailsDialog(
            transaction: transaction,
            category: category,
            asset: asset,
            ledger: ledger,
            currencySymbol: currencySymbol,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
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
                color: backgroundColor ?? themeColors.background,
                shape: BoxShape.circle,
              ),
              child: DynamicIcon(
                codePoint: category.iconCodePoint,
                fontFamily: category.iconFontFamily,
                fontPackage: category.iconFontPackage,
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: themeColors.text,
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
                          DateFormat('HH:mm').format(transaction.date),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: themeColors.text,
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
                        child: TransactionAssetIcon(asset: asset),
                      ),
                      // Ledger Icon
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: ledger.color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: DynamicIcon(
                          codePoint: ledger.iconPoint,
                          fontFamily: ledger.iconFamily,
                          fontPackage: ledger.iconPackage,
                          fallback: Icons.account_balance_wallet,
                          size: 16,
                          color: ledger.color,
                        ),
                      ),
                      // Reimbursement Icon
                      if (transaction.isReimbursement) ...[
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
                      if (transaction.isBookmarked) ...[
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '${isExpense ? '-' : '+'}${CurrencyFormatter.format(transaction.amount, symbol: '', useGrouping: useComma)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isExpense ? AppColors.expense : themeColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
