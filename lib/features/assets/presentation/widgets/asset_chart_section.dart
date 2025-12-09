import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/asset.dart';
import '../../../transactions/presentation/pages/transaction_history_page.dart';

class AssetChartSection extends StatelessWidget {
  final String title;
  final bool isLiabilities;
  final List<Asset> assets;
  final String currencySymbol;

  const AssetChartSection({
    super.key,
    required this.title,
    required this.isLiabilities,
    required this.assets,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return const SizedBox.shrink();
    }

    double total = 0;
    for (var a in assets) {
      total += a.balance.abs();
    }

    // Sort by amount desc (absolute)
    final sortedAssets = List<Asset>.from(assets)
      ..sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));

    // Define palettes
    final List<Color> assetPalette = [
      const Color(0xFF4DB6AC), // Teal
      const Color(0xFF4DD0E1), // Cyan
      const Color(0xFF81C784), // Green
      const Color(0xFF64B5F6), // Blue
      const Color(0xFF7986CB), // Indigo
      const Color(0xFFAED581), // Light Green
    ];

    final List<Color> liabilityPalette = [
      const Color(0xFFE57373), // Red
      const Color(0xFFFFB74D), // Orange
      const Color(0xFFEF5350), // Red 400
      const Color(0xFFFFA726), // Orange 400
      const Color(0xFFE53935), // Red 600
      const Color(0xFFFB8C00), // Orange 600
    ];

    final palette = isLiabilities ? liabilityPalette : assetPalette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isLiabilities
                      ? AppColors.pastelRed
                      : AppColors.textDark,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Maybe show full list if truncated?
                },
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Pie Chart
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 30,
                    sections: sortedAssets.map((asset) {
                      final index = sortedAssets.indexOf(asset);
                      final color = palette[index % palette.length];
                      final value = asset.balance.abs();
                      return PieChartSectionData(
                        color: color,
                        value: value,
                        radius: 40,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Legend
              Expanded(
                child: Column(
                  children: sortedAssets.take(5).map((asset) {
                    final index = sortedAssets.indexOf(asset);
                    final color = palette[index % palette.length];
                    final value = asset.balance.abs();
                    final percent = total == 0 ? 0.0 : (value / total) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              asset.name,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${percent.toStringAsFixed(2)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Asset List (Bars)
          ...sortedAssets.map((asset) {
            final index = sortedAssets.indexOf(asset);
            final color = palette[index % palette.length];
            final value = asset.balance.abs();
            final percent = total == 0 ? 0.0 : (value / total);

            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TransactionHistoryPage(asset: asset),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            asset.name.isNotEmpty
                                ? asset.name.substring(0, 1).toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          asset.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(
                                asset.balance,
                                symbol: currencySymbol,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isLiabilities
                                    ? AppColors.pastelRed
                                    : AppColors.textDark,
                              ),
                            ),
                            Text(
                              '${(percent * 100).toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
