import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/asset.dart';
import '../providers/asset_provider.dart';
import '../../../../core/widgets/banner_ad_widget.dart';
import '../widgets/asset_graph_section.dart';
import '../widgets/asset_pie_chart_section.dart';
import '../../../transactions/presentation/pages/transaction_history_page.dart';
import '../../../home/presentation/providers/ledger_provider.dart';
import '../../../transactions/presentation/pages/transaction_page.dart';
import '../../../transactions/data/models/transaction_model.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Cream background
      body: assetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (assets) {
          double totalAssets = 0;
          double totalLiabilities = 0;

          for (var asset in assets) {
            if (asset.balance >= 0) {
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
                  top: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.8,
                    child: Image.asset(
                      'assets/images/cat_top_right.png',
                      width: 120,
                      errorBuilder: (c, e, s) => const SizedBox.shrink(),
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
                                  symbol: '',
                                ),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.pastelRed,
                                ),
                              ),
                              Text(
                                '${CurrencyFormatter.format(net, symbol: '')} ≣',
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
                                  symbol: '',
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
                                      AssetGraphSection(assets: assets),
                                      const SizedBox(height: 32),

                                      // Assets List (Positive)
                                      const Text(
                                        'Assets',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildAssetList(
                                        context,
                                        ref,
                                        _getAssets(
                                          assets,
                                          isLiabilities: false,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Assets Pie Chart
                                      AssetPieChartSection(
                                        assets: assets,
                                        isLiabilities: false,
                                      ),

                                      const SizedBox(height: 32),

                                      // Liabilities List (Negative)
                                      const Text(
                                        'Liabilities',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.pastelRed,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildAssetList(
                                        context,
                                        ref,
                                        _getAssets(assets, isLiabilities: true),
                                      ),
                                      const SizedBox(height: 16),
                                      // Liabilities Pie Chart
                                      AssetPieChartSection(
                                        assets: assets,
                                        isLiabilities: true,
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
                        // Peeking Cat
                        Positioned(
                          top: 0,
                          child: Image.asset(
                            'assets/images/cat_peek.png',
                            width: 60,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 50,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: const Icon(Icons.pets, size: 20),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'assets_fab',
        onPressed: () => _showAddEditAssetDialog(context, ref, null),
        backgroundColor: AppColors.pastelOrange,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Asset> _getAssets(List<Asset> assets, {required bool isLiabilities}) {
    return assets.where((a) {
      if (isLiabilities) return a.balance < 0;
      return a.balance >= 0;
    }).toList();
  }

  Widget _buildAssetList(
    BuildContext context,
    WidgetRef ref,
    List<Asset> assets,
  ) {
    if (assets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No items',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }
    return Column(
      children: assets.map((asset) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          color: Colors.white,
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: asset.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                asset.name.isNotEmpty
                    ? asset.name.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  color: asset.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              asset.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            subtitle: asset.remark.isNotEmpty ? Text(asset.remark) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyFormatter.format(asset.balance, symbol: '\$'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: asset.balance < 0
                        ? AppColors.pastelRed
                        : AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                  onPressed: () => _showAddEditAssetDialog(context, ref, asset),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TransactionHistoryPage(asset: asset),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  void _showAddEditAssetDialog(
    BuildContext context,
    WidgetRef ref,
    Asset? existingAsset,
  ) {
    final nameController = TextEditingController(
      text: existingAsset?.name ?? '',
    );
    final balanceController = TextEditingController(
      text: existingAsset?.initialBalance.toString() ?? '',
    );
    final remarkController = TextEditingController(
      text: existingAsset?.remark ?? '',
    );

    // You could add a color picker here later
    Color selectedColor = existingAsset?.color ?? AppColors.pastelPurple;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                existingAsset == null
                    ? 'Add Asset Category'
                    : 'Edit Asset Category',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Asset Name (e.g. Business, Personal)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: balanceController,
                      decoration: const InputDecoration(
                        labelText: 'Initial Balance',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      enabled: existingAsset == null,
                    ),
                    if (existingAsset != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Note: Changing Initial Balance will not affect current calculated balance unless you implement recalculation logic. For now, it is just for reference.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: remarkController,
                      decoration: const InputDecoration(
                        labelText: 'Remark (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (existingAsset != null)
                  TextButton(
                    onPressed: () {
                      ref
                          .read(assetProvider.notifier)
                          .deleteAsset(existingAsset.id);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final initialBalance =
                        double.tryParse(balanceController.text) ?? 0.0;
                    final remark = remarkController.text.trim();

                    if (existingAsset == null) {
                      final asset = Asset(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        colorValue: selectedColor.toARGB32(),
                        balance: initialBalance,
                        initialBalance: initialBalance,
                        remark: remark,
                      );
                      ref.read(assetProvider.notifier).addAsset(asset);
                    } else {
                      final asset = existingAsset.copyWith(
                        name: name,
                        initialBalance: initialBalance,
                        remark: remark,
                      );
                      ref.read(assetProvider.notifier).updateAsset(asset);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
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
