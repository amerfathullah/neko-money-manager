import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/ledger_provider.dart';

class LedgerSelector extends ConsumerWidget {
  const LedgerSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgersAsync = ref.watch(ledgerProvider);
    final selectedLedgerId = ref.watch(selectedLedgerProvider);

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
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.textDark,
                size: 20,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              borderRadius: BorderRadius.circular(20),
              dropdownColor: AppColors.backgroundLight,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.book, size: 20, color: AppColors.textDark),
                      SizedBox(width: 8),
                      Text('All ledgers'),
                    ],
                  ),
                ),
                ...ledgers.map(
                  (l) => DropdownMenuItem<String?>(
                    value: l.id,
                    child: Row(
                      children: [
                        Icon(
                          l.icon ?? Icons.account_balance_wallet,
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
                        Icon(
                          l.icon ?? Icons.account_balance_wallet,
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
