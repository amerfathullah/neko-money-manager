import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/dynamic_icon.dart';
import '../../../assets/data/models/asset.dart';

class ReimburseDialog extends ConsumerStatefulWidget {
  final double? initialAmount;
  final String? initialAssetId;
  final List<Asset> assets;
  final bool isEditing;
  final VoidCallback? onDelete;

  const ReimburseDialog({
    super.key,
    this.initialAmount,
    this.initialAssetId,
    required this.assets,
    this.isEditing = false,
    this.onDelete,
  });

  @override
  ConsumerState<ReimburseDialog> createState() => _ReimburseDialogState();
}

class _ReimburseDialogState extends ConsumerState<ReimburseDialog> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedAssetId;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _amountController.text = (widget.initialAmount! % 1 == 0)
          ? widget.initialAmount!.toInt().toString()
          : widget.initialAmount.toString();
    }
    _selectedAssetId = widget.initialAssetId;
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    final selectedAsset = widget.assets
        .where((a) => a.id == _selectedAssetId)
        .firstOrNull;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: themeColors.surface,
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Input
            Container(
              decoration: BoxDecoration(
                color: themeColors.inputBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeColors.text,
                ),
                decoration: InputDecoration(
                  hintText: 'Amount of reimbursement',
                  hintStyle: TextStyle(
                    color: themeColors.text.withValues(alpha: 0.3),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Asset Selector
            InkWell(
              onTap: () => _showAssetSelectionPopup(),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                decoration: BoxDecoration(
                  color: themeColors.inputBackground,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedAsset != null) ...[
                      DynamicIcon(
                        codePoint: selectedAsset.iconCodePoint,
                        fontFamily: selectedAsset.iconFontFamily,
                        fontPackage: selectedAsset.iconFontPackage,
                        color: selectedAsset.color,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedAsset.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: themeColors.text,
                              ),
                            ),
                            // Optional: Show balance if desired, mocking "RM1,168" from image
                            Text(
                              'Balance: ${selectedAsset.balance.toStringAsFixed(2)}', // Minimal representation
                              style: TextStyle(
                                fontSize: 12,
                                color: themeColors.text.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Text(
                          'Refund into account',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: themeColors.text,
                          ),
                        ),
                      ),
                    Icon(Icons.chevron_right, color: themeColors.text),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColors.inputBackground, // Beige
                        foregroundColor: themeColors.text,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (widget.isEditing && widget.onDelete != null) {
                          widget.onDelete!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        widget.isEditing ? 'Delete' : 'Cancel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeColors.text, // Usually dark
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.destructiveRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _submit,
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      // Basic validation
      return;
    }
    if (_selectedAssetId == null) {
      // Basic validation
      return;
    }
    Navigator.pop(context, {'amount': amount, 'assetId': _selectedAssetId});
  }

  void _showAssetSelectionPopup() {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    showModalBottomSheet(
      context: context,
      backgroundColor: themeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: widget.assets.length,
        itemBuilder: (context, index) {
          final asset = widget.assets[index];
          return ListTile(
            leading: DynamicIcon(
              codePoint: asset.iconCodePoint,
              fontFamily: asset.iconFontFamily,
              fontPackage: asset.iconFontPackage,
              color: asset.color,
            ),
            title: Text(asset.name, style: TextStyle(color: themeColors.text)),
            onTap: () {
              setState(() => _selectedAssetId = asset.id);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }
}
