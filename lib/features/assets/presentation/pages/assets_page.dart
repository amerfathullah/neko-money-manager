import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/asset.dart';
import '../providers/asset_provider.dart';
import '../../../../core/widgets/banner_ad_widget.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../settings/presentation/providers/currency_provider.dart';

class AssetsPage extends ConsumerWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetProvider);
    final currencyAsync = ref.watch(currencyProvider);
    final currencySymbol = currencyAsync.asData?.value ?? '\$';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Net Worth'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: assetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (assets) {
          final totalNetWorth = assets.fold<double>(
            0.0,
            (sum, asset) => sum + asset.currentValue,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Net Worth Card
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Total Net Worth',
                      style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(
                        totalNetWorth,
                        symbol: currencySymbol,
                      ),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: assets.isEmpty
                    ? const Center(
                        child: Text('Add your assets to track net worth!'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: assets.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final asset = assets[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: theme.cardColor,
                            elevation: 0,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: asset.color.withValues(
                                  alpha: 0.2,
                                ),
                                child: Text(
                                  _getInitials(asset.name),
                                  style: TextStyle(color: asset.color),
                                ),
                              ),
                              title: Text(
                                asset.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(asset.type.name.toUpperCase()),
                              trailing: Text(
                                CurrencyFormatter.format(
                                  asset.currentValue,
                                  symbol: currencySymbol,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.income,
                                ),
                              ),
                              onTap: () {
                                _showAddEditAssetDialog(context, ref, asset);
                              },
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              const BannerAdWidget(),
              const SizedBox(height: 80), // Padding for FAB
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'assets_fab',
        onPressed: () => _showAddEditAssetDialog(context, ref, null),
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getInitials(String name) =>
      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

  void _showAddEditAssetDialog(
    BuildContext context,
    WidgetRef ref,
    Asset? existingAsset,
  ) {
    final nameController = TextEditingController(
      text: existingAsset?.name ?? '',
    );
    final valueController = TextEditingController(
      text: existingAsset?.currentValue.toString() ?? '',
    );
    AssetType selectedType = existingAsset?.type ?? AssetType.investment;
    Color selectedColor = existingAsset?.color ?? AppColors.pastelPurple;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existingAsset == null ? 'Add Asset' : 'Edit Asset'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Asset Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: valueController,
                      decoration: const InputDecoration(
                        labelText: 'Current Value',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AssetType>(
                          value: selectedType,
                          isDense: true,
                          isExpanded: true,
                          items: AssetType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => selectedType = val);
                          },
                        ),
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
                    final value =
                        double.tryParse(valueController.text.trim()) ?? 0;
                    if (name.isEmpty) return;

                    final asset = Asset(
                      id:
                          existingAsset?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      currentValue: value,
                      type: selectedType,
                      colorValue: selectedColor.toARGB32(),
                    );

                    if (existingAsset == null) {
                      ref.read(assetProvider.notifier).addAsset(asset);
                    } else {
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
