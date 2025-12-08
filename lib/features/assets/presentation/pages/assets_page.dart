import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/asset.dart';
import '../providers/asset_provider.dart';
import '../../../../core/widgets/banner_ad_widget.dart';

class AssetsPage extends ConsumerWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Categories'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: assetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (assets) {
          return Column(
            children: [
              Expanded(
                child: assets.isEmpty
                    ? const Center(child: Text('Add your asset categories!'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
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
                              trailing: const Icon(Icons.edit, size: 20),
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

                    final asset = Asset(
                      id:
                          existingAsset?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
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
