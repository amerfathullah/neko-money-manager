import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/asset.dart';

class AssetGraphSection extends StatefulWidget {
  final List<Asset> assets;

  const AssetGraphSection({super.key, required this.assets});

  @override
  State<AssetGraphSection> createState() => _AssetGraphSectionState();
}

class _AssetGraphSectionState extends State<AssetGraphSection> {
  @override
  Widget build(BuildContext context) {
    // For now, this is a mock graph as we don't have historical data readily available.
    // We will show a simple "Total Net Worth" trend mock.

    // Calculate current net worth
    double netWorth = 0;
    for (var asset in widget.assets) {
      netWorth += asset.balance;
    }

    // Mock data points (last 7 days)
    // We'll just create a slightly fluctuating line ending at current netWorth
    final now = DateTime.now();
    final spots = List.generate(7, (index) {
      // Days ago: 6, 5, 4, 3, 2, 1, 0
      // Mock fluctuation: +/- 5%
      if (index == 6) return FlSpot(6, netWorth);
      double mockVal =
          netWorth * (0.9 + (index * 0.01) + (index % 2 == 0 ? 0.02 : -0.02));
      return FlSpot(index.toDouble(), mockVal);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Net Worth Trend (Mock)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.70,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (netWorth / 5).abs() + 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xff37434d).withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        // value is 0..6
                        // 0 = 6 days ago
                        // 6 = Today
                        final date = now.subtract(
                          Duration(days: 6 - value.toInt()),
                        );
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                              color: Color(0xff68737d),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY:
                    spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.9,
                maxY:
                    spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppColors.pastelBlue, AppColors.pastelPurple],
                    ),
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.pastelBlue.withValues(alpha: 0.3),
                          AppColors.pastelPurple.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
