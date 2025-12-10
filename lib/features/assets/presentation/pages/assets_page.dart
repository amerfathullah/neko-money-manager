import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/asset.dart';
import '../providers/asset_provider.dart';
import '../../../../core/widgets/banner_ad_widget.dart';
import '../widgets/asset_graph_section.dart';

import '../../../home/presentation/providers/ledger_provider.dart';
import '../../../transactions/presentation/pages/transaction_page.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../widgets/asset_chart_section.dart';
import '../../../settings/presentation/providers/currency_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class AssetsPage extends ConsumerStatefulWidget {
  const AssetsPage({super.key});

  @override
  ConsumerState<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends ConsumerState<AssetsPage> {
  String? _selectedLedgerId; // Visual consistency only for now

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetProvider);
    final ledgersAsync = ref.watch(ledgerProvider);
    final historyAsync = ref.watch(assetHistoryProvider);
    final history = historyAsync.value ?? [];
    final currencyAsync = ref.watch(currencyProvider);
    final settingsAsync = ref.watch(settingsProvider);

    final currencySymbol = currencyAsync.asData?.value ?? '\$';
    final settings = settingsAsync.asData?.value ?? const SettingsState();
    final useComma = settings.useCommaSeparator;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Cream background
      body: assetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (assets) {
          double totalAssets = 0;
          double totalLiabilities = 0;

          for (var asset in assets) {
            if (!asset.balance.isNegative) {
              totalAssets += asset.balance;
            } else {
              totalLiabilities += asset.balance;
            }
          }
          final net = totalAssets + totalLiabilities;

          return SafeArea(
            child: Stack(
              children: [
                // Background Elements (Cat Top Right - reuse from Home)
                Positioned(
                  top: -20,
                  right: -20,
                  child: Opacity(
                    opacity: 0.2,
                    child: Icon(
                      Icons.pets,
                      size: 180,
                      color: AppColors.pastelOrange,
                    ),
                  ),
                ),

                // Top Content
                Column(
                  children: [
                    const SizedBox(height: 16),
                    // Header: Ledger Selector & Transfer Button (Consistency with Home)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          ledgersAsync.when(
                            data: (ledgers) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pastelOrange.withValues(
                                  alpha: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: _selectedLedgerId,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: AppColors.textDark,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  dropdownColor: const Color(0xFFFFFDF5),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.book,
                                            size: 20,
                                            color: AppColors.textDark,
                                          ),
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
                                              Icons.account_balance_wallet,
                                              size: 20,
                                              color: AppColors.textDark,
                                            ),
                                            SizedBox(width: 8),
                                            Text(l.name),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedLedgerId = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                            loading: () =>
                                const SizedBox(width: 120, height: 40),
                            error: (err, stack) => const SizedBox.shrink(),
                          ),

                          const Spacer(),

                          _TopPill(
                            icon: Icons.swap_horiz,
                            label: 'Transfer',
                            color: AppColors.pastelPurple,
                            onTap: () {
                              // Open TransactionPage with Transfer pre-selected
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const TransactionPage(
                                    initialType: TransactionType.transfer,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Summary Section (Liabilities / Assets)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Liabilities',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(
                                  totalLiabilities,
                                  symbol: currencySymbol,
                                  useGrouping: useComma,
                                ),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.pastelRed,
                                ),
                              ),
                              Text(
                                '${CurrencyFormatter.format(net, symbol: currencySymbol, useGrouping: useComma)} ≣',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Assets',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(
                                  totalAssets,
                                  symbol: currencySymbol,
                                  useGrouping: useComma,
                                ),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Draggable Sheet
                DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.7,
                  maxChildSize: 1.0,
                  builder: (context, scrollController) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 25),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFDF5),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: CustomScrollView(
                            controller: scrollController,
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 20),
                                      // Graph Section
                                      AssetGraphSection(
                                        assets: assets,
                                        assetHistory: history,
                                        currencySymbol: currencySymbol,
                                        useComma: useComma,
                                      ),
                                      const SizedBox(height: 32),

                                      // Assets Chart Section
                                      AssetChartSection(
                                        title: 'Assets',
                                        isLiabilities: false,
                                        assets: _getAssets(
                                          assets,
                                          isLiabilities: false,
                                        ),
                                        currencySymbol: currencySymbol,
                                        useComma: useComma,
                                      ),

                                      const SizedBox(height: 32),

                                      // Liabilities Chart Section
                                      AssetChartSection(
                                        title: 'Liabilities',
                                        isLiabilities: true,
                                        assets: _getAssets(
                                          assets,
                                          isLiabilities: true,
                                        ),
                                        currencySymbol: currencySymbol,
                                        useComma: useComma,
                                      ),
                                      const SizedBox(height: 32),
                                      const BannerAdWidget(),
                                      const SizedBox(height: 80), // Fab space
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Drag Handle
                        Positioned(
                          top: 10,
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Asset> _getAssets(List<Asset> assets, {required bool isLiabilities}) {
    return assets.where((a) {
      if (isLiabilities) return a.balance.isNegative;
      return !a.balance.isNegative;
    }).toList();
  }
}

// Copied from HomePage for consistency
class _TopPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TopPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textDark),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
