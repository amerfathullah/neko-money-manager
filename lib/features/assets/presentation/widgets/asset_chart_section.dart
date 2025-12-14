import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:neko_money_manager/core/widgets/dynamic_icon.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/asset.dart';
import '../../../transactions/presentation/pages/transaction_history_page.dart';

class AssetChartSection extends StatelessWidget {
  final String title;
  final bool isLiabilities;
  final List<Asset> assets;
  final String currencySymbol;
  final bool useComma;

  const AssetChartSection({
    super.key,
    required this.title,
    required this.isLiabilities,
    required this.assets,
    required this.currencySymbol,
    required this.useComma,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
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
                  color: isLiabilities ? AppColors.pastelRed : themeColors.text,
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
                      final value = asset.balance.abs();
                      return PieChartSectionData(
                        color: asset.color,
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
                    final color = asset.color;
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
                            child: Row(
                              // Changed to Row to hold DynamicIcon and Text
                              children: [
                                DynamicIcon(
                                  codePoint: asset.iconCodePoint,
                                  fontFamily: asset.iconFontFamily,
                                  fontPackage: asset.iconFontPackage,
                                  size: 16,
                                  color: asset.color,
                                ),
                                const SizedBox(width: 8), // Added spacing
                                Expanded(
                                  // Wrapped Text in Expanded to handle overflow
                                  child: Text(
                                    asset.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: themeColors.text,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${percent.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: themeColors.text,
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
            final color = asset.color;
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
                          child: DynamicIcon(
                            codePoint: asset.iconCodePoint,
                            fontFamily: asset.iconFontFamily,
                            fontPackage: asset.iconFontPackage,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          asset.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: themeColors.text,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(
                                asset.balance,
                                symbol: currencySymbol,
                                useGrouping: useComma,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isLiabilities
                                    ? AppColors.pastelRed
                                    : themeColors.text,
                              ),
                            ),
                            Text(
                              '${(percent * 100).toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: themeColors.textSubtle,
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
