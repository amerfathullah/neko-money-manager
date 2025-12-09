import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/asset.dart';
import '../providers/asset_provider.dart';

void showAddEditAssetDialog(
  BuildContext context,
  WidgetRef ref,
  Asset? existingAsset,
) {
  final nameController = TextEditingController(text: existingAsset?.name ?? '');
  // If editing, show current balance. If new, show empty (or 0)
  final balanceController = TextEditingController(
    text: existingAsset != null
        ? existingAsset.balance.toString()
        : '', // Use balance, not initialBalance
  );
  final remarkController = TextEditingController(
    text: existingAsset?.remark ?? '',
  );

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
                    decoration: InputDecoration(
                      labelText: existingAsset == null
                          ? 'Initial Balance'
                          : 'Current Balance',
                      border: const OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: true, // Always allow editing
                  ),
                  // Warning removed as requested
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

                  final inputBalance =
                      double.tryParse(balanceController.text) ?? 0.0;
                  final remark = remarkController.text.trim();

                  if (existingAsset == null) {
                    final asset = Asset(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      colorValue: selectedColor.toARGB32(),
                      balance: inputBalance,
                      initialBalance: inputBalance,
                      remark: remark,
                    );
                    ref.read(assetProvider.notifier).addAsset(asset);
                  } else {
                    // Update current balance directly
                    final asset = existingAsset.copyWith(
                      name: name,
                      balance: inputBalance, // Update current balance
                      // Initial balance kept history or maybe updated if user wants?
                      // Usually Initial Balance is immutable history.
                      // copyWith keeps existing initialBalance if passed null.
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
