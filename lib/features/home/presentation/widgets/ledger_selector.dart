import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';
import 'package:neko_money_manager/core/widgets/dynamic_icon.dart';
import '../providers/ledger_provider.dart';

class LedgerSelector extends ConsumerWidget {
  const LedgerSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgersAsync = ref.watch(ledgerProvider);
    final selectedLedgerId = ref.watch(selectedLedgerProvider);
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;

    return ledgersAsync.when(
      data: (ledgers) {
        // Find selected ledger object to get color/icon if needed for the button itself
        final selectedLedger = ledgers
            .where((l) => l.id == selectedLedgerId)
            .firstOrNull;

        // Determine button background color based on selection or default
        final buttonColor =
            selectedLedger?.color.withValues(alpha: 0.3) ??
            AppColors.pastelOrange.withValues(alpha: 0.3);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedLedgerId,
              isDense: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: themeColors.text,
                size: 20,
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeColors.text,
              ),
              borderRadius: BorderRadius.circular(20),
              dropdownColor: themeColors.surface,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.book, size: 20, color: themeColors.text),
                      const SizedBox(width: 8),
                      Text('All ledgers'),
                    ],
                  ),
                ),
                ...ledgers.map(
                  (l) => DropdownMenuItem<String?>(
                    value: l.id,
                    child: Row(
                      children: [
                        DynamicIcon(
                          codePoint: l.iconPoint,
                          fontFamily: l.iconFamily,
                          fontPackage: l.iconPackage,
                          fallback: Icons.account_balance_wallet,
                          size: 20,
                          color: l.color,
                        ),
                        SizedBox(width: 8),
                        Text(l.name),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                ref.read(selectedLedgerProvider.notifier).set(val);
              },
              selectedItemBuilder: (context) {
                return [
                  // For "null" value (All ledgers)
                  const Row(
                    children: [
                      Icon(Icons.book, size: 20, color: AppColors.textDark),
                      SizedBox(width: 8),
                      Text('All ledgers'),
                    ],
                  ),
                  // For each ledger item
                  ...ledgers.map((l) {
                    return Row(
                      children: [
                        DynamicIcon(
                          codePoint: l.iconPoint,
                          fontFamily: l.iconFamily,
                          fontPackage: l.iconPackage,
                          fallback: Icons.account_balance_wallet,
                          size: 20,
                          color: l.color,
                        ),
                        SizedBox(width: 8),
                        Text(l.name),
                      ],
                    );
                  }),
                ];
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox(width: 120, height: 40),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
