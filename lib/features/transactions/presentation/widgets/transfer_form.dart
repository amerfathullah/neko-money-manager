import 'package:flutter/material.dart';
import 'package:neko_money_manager/core/widgets/dynamic_icon.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../assets/data/models/asset.dart';

class TransferForm extends StatelessWidget {
  final Asset? selectedSourceAsset;
  final Asset? selectedDestAsset;
  final String chargeAmount;
  final List<Asset> assets;
  final ValueChanged<Asset?> onSourceAssetChanged;
  final ValueChanged<Asset?> onDestAssetChanged;
  final VoidCallback onChargeHelpTap;
  final VoidCallback onChargeTap;

  const TransferForm({
    super.key,
    required this.selectedSourceAsset,
    required this.selectedDestAsset,
    required this.chargeAmount,
    required this.assets,
    required this.onSourceAssetChanged,
    required this.onDestAssetChanged,
    required this.onChargeHelpTap,
    required this.onChargeTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildAssetSelector(
            label: 'Asset from',
            selectedAsset: selectedSourceAsset,
            onChanged: onSourceAssetChanged,
            assets: assets,
            themeColors: themeColors,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Icon(
              Icons.swap_vert,
              size: 32,
              color: themeColors.textSubtle,
            ),
          ),
          _buildAssetSelector(
            label: 'Asset to',
            selectedAsset: selectedDestAsset,
            onChanged: onDestAssetChanged,
            assets: assets
                .where((a) => a.id != selectedSourceAsset?.id)
                .toList(),
            themeColors: themeColors,
          ),
          const SizedBox(height: 24),
          _buildChargeField(themeColors),
        ],
      ),
    );
  }

  Widget _buildAssetSelector({
    required String label,
    required Asset? selectedAsset,
    required ValueChanged<Asset?> onChanged,
    required List<Asset> assets,
    required AppThemeColors themeColors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: themeColors.inputBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColors.text,
            ),
            child: Icon(Icons.add, color: themeColors.background, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Asset>(
                value: selectedAsset,
                dropdownColor: themeColors.surface,
                hint: Text(
                  label,
                  style: TextStyle(
                    color: themeColors.textSubtle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                isExpanded: true,
                icon: const SizedBox.shrink(),
                items: assets.map((asset) {
                  return DropdownMenuItem(
                    value: asset,
                    child: Row(
                      children: [
                        DynamicIcon(
                          codePoint: asset.iconCodePoint,
                          fontFamily: asset.iconFontFamily,
                          fontPackage: asset.iconFontPackage,
                          color: asset.color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          asset.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: themeColors.text,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargeField(AppThemeColors themeColors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeColors.inputBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onChargeTap,
              child: Text(
                chargeAmount.isEmpty || chargeAmount == '0'
                    ? 'Transfer charge'
                    : 'Charge: $chargeAmount',
                style: TextStyle(
                  color: chargeAmount.isEmpty || chargeAmount == '0'
                      ? themeColors.text.withValues(alpha: 0.3)
                      : themeColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onChargeHelpTap,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeColors.surface,
              ),
              child: Icon(
                Icons.question_mark,
                size: 16,
                color: themeColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
