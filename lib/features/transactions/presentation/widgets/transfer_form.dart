import 'package:flutter/material.dart';
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
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildAssetSelector(
          label: 'Asset from',
          selectedAsset: selectedSourceAsset,
          onChanged: onSourceAssetChanged,
          assets: assets,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Icon(Icons.swap_vert, size: 32, color: Colors.grey),
        ),
        _buildAssetSelector(
          label: 'Asset to',
          selectedAsset: selectedDestAsset,
          onChanged: onDestAssetChanged,
          assets: assets.where((a) => a.id != selectedSourceAsset?.id).toList(),
        ),
        const SizedBox(height: 24),
        _buildChargeField(),
      ],
    );
  }

  Widget _buildAssetSelector({
    required String label,
    required Asset? selectedAsset,
    required ValueChanged<Asset?> onChanged,
    required List<Asset> assets,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Very light orange/beige
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black87,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Asset>(
                value: selectedAsset,
                hint: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                isExpanded: true,
                icon: const SizedBox.shrink(),
                items: assets.map((asset) {
                  return DropdownMenuItem(
                    value: asset,
                    child: Text(
                      asset.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
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

  Widget _buildChargeField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
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
                      ? Colors.black26
                      : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onChargeHelpTap,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(
                Icons.question_mark,
                size: 16,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
