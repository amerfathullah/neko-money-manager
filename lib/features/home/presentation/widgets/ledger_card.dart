import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

class LedgerCard extends StatelessWidget {
  final String name;
  final double balance;
  final Color color;
  final String currencySymbol;
  final VoidCallback onTap;
  final IconData? icon;

  const LedgerCard({
    super.key,
    required this.name,
    required this.balance,
    required this.color,
    required this.currencySymbol,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In dark mode, reduce opacity of the card to prevent it from being too bright/neon
    // and use white text for better contrast against the darker background.
    final cardColors = isDark
        ? [color.withValues(alpha: 0.2), color.withValues(alpha: 0.3)]
        : [color.withValues(alpha: 0.8), color];

    final textColor = isDark ? themeColors.text : AppColors.textDark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cardColors,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon ?? Icons.account_balance_wallet,
                color: textColor.withValues(alpha: 0.7),
                size: 26,
              ),
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(balance, symbol: currencySymbol),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
