import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/asset.dart';

class AssetPieChartSection extends ConsumerStatefulWidget {
  final List<Asset> assets;
  final bool isLiabilities;

  const AssetPieChartSection({
    super.key,
    required this.assets,
    this.isLiabilities = false,
  });

  @override
  ConsumerState<AssetPieChartSection> createState() =>
      _AssetPieChartSectionState();
}

class _AssetPieChartSectionState extends ConsumerState<AssetPieChartSection> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // 1. Filter Assets based on isLiabilities
    final relevantAssets = widget.assets.where((a) {
      if (widget.isLiabilities) return a.balance.isNegative;
      return !a.balance.isNegative;
    }).toList();

    if (relevantAssets.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            widget.isLiabilities
                ? 'No liabilities to show'
                : 'No assets to show',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 2. Prepare Data
    // Sort by absolute balance descending
    relevantAssets.sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));

    final totalBalance = relevantAssets.fold(
      0.0,
      (sum, a) => sum + a.balance.abs(),
    );

    // 3. Create Sections
    final sections = relevantAssets.asMap().entries.map((entry) {
      final index = entry.key;
      final asset = entry.value;
      final amount = asset.balance.abs();
      final percentage = totalBalance == 0 ? 0 : (amount / totalBalance) * 100;
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final fontSize = isTouched ? 14.0 : 12.0;

      return PieChartSectionData(
        color: Color(asset.colorValue),
        value: amount,
        title: '${asset.name}\n${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
        ),
      );
    }).toList();

    return Column(
      children: [
        Text(
          widget.isLiabilities ? 'Liabilities Breakdown' : 'Assets Breakdown',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
