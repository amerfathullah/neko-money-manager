import 'package:flutter/material.dart';
import '../../../../core/widgets/dynamic_icon.dart';
import '../../../assets/data/models/asset.dart';

class TransactionAssetIcon extends StatelessWidget {
  const TransactionAssetIcon({super.key, required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return DynamicIcon(
      codePoint: asset.iconCodePoint,
      fontFamily: asset.iconFontFamily,
      fontPackage: asset.iconFontPackage,
      size: 16,
      color: asset.color,
    );
  }
}
