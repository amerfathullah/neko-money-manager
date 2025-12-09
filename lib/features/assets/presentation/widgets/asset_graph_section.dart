import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/asset.dart';
import '../../data/models/asset_history_model.dart';
import 'dart:math';

enum GraphTimeRange { oneWeek, oneMonth, threeMonths, sixMonths, oneYear, all }

enum GraphFilterType { net, income, expenses }

class AssetGraphSection extends StatefulWidget {
  final List<Asset> assets;
  final List<AssetHistoryModel> assetHistory;

  const AssetGraphSection({
    super.key,
    required this.assets,
    required this.assetHistory,
  });

  @override
  State<AssetGraphSection> createState() => _AssetGraphSectionState();
}

class _AssetGraphSectionState extends State<AssetGraphSection> {
  GraphTimeRange _selectedRange = GraphTimeRange.oneWeek;
  GraphFilterType _selectedType = GraphFilterType.net;

  @override
  Widget build(BuildContext context) {
    // 1. Calculate historical points based on history and filter
    final points = _calculateHistoryPoints();

    // 2. Prepare spots for FlChart
    List<FlSpot> spots = [];
    if (points.isNotEmpty) {
      // Normalize X axis to be index 0..N-1
      for (int i = 0; i < points.length; i++) {
        spots.add(FlSpot(i.toDouble(), points[i].value));
      }
    } else {
      // Fallback if no history - calculate current based on filter
      double currentVal = 0;
      for (var a in widget.assets) {
        if (_selectedType == GraphFilterType.net) {
          currentVal += a.balance;
        } else if (_selectedType == GraphFilterType.income) {
          if (a.balance >= 0) currentVal += a.balance;
        } else if (_selectedType == GraphFilterType.expenses) {
          if (a.balance < 0) currentVal += a.balance;
        }
      }
      spots = [FlSpot(0, currentVal), FlSpot(1, currentVal)];
    }

    // Min/Max for Y Axis scaling
    double minY = spots.isEmpty ? 0 : spots.map((e) => e.y).reduce(min);
    double maxY = spots.isEmpty ? 100 : spots.map((e) => e.y).reduce(max);
    if (minY == maxY) {
      if (minY != 0) {
        minY *= 0.9;
        maxY *= 1.1;
      } else {
        minY = 0;
        maxY = 100;
      }
    } else {
      double range = maxY - minY;
      minY -= range * 0.1;
      maxY += range * 0.1;
    }

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
          // Header Row: Title + Time Range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Worth Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              _buildTimeRangeSelector(),
            ],
          ),
          const SizedBox(height: 16),
          // Filter Row: Net | Income | Expenses
          _buildFilterSelector(),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.70,
            child: spots.isEmpty
                ? const Center(child: Text("Not enough data"))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (maxY - minY) / 5 == 0
                            ? 1
                            : (maxY - minY) / 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: const Color(
                              0xff37434d,
                            ).withValues(alpha: 0.1),
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
                            interval: (spots.length / 5).ceilToDouble() == 0
                                ? 1
                                : (spots.length / 5).ceilToDouble(),
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index < 0 || index >= points.length) {
                                return const SizedBox.shrink();
                              }

                              final date = points[index].date;
                              String text;
                              if (_selectedRange == GraphTimeRange.oneWeek) {
                                text = DateFormat('E').format(date); // Mon, Tue
                              } else if (_selectedRange ==
                                  GraphTimeRange.oneMonth) {
                                text = '${date.day}';
                              } else {
                                text = DateFormat('MMM').format(date);
                              }

                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    color: Color(0xff68737d),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
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
                      maxX: (spots.length - 1).toDouble(),
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.pastelBlue,
                              AppColors.pastelPurple,
                            ],
                          ),
                          barWidth: 4,
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
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => AppColors.textDark,
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              final index = barSpot.x.toInt();
                              if (index < 0 || index >= points.length) {
                                return null;
                              }
                              final point = points[index];
                              return LineTooltipItem(
                                '${DateFormat('MMM dd').format(point.date)}\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                    text: '\$${point.value.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppColors.pastelGreen,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRangeButton('1W', GraphTimeRange.oneWeek),
          _buildRangeButton('1M', GraphTimeRange.oneMonth),
          _buildRangeButton('3M', GraphTimeRange.threeMonths),
          _buildRangeButton('6M', GraphTimeRange.sixMonths),
        ],
      ),
    );
  }

  Widget _buildRangeButton(String label, GraphTimeRange range) {
    final isSelected = _selectedRange == range;
    return GestureDetector(
      onTap: () => setState(() => _selectedRange = range),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.textDark : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildFilterButton('Net', GraphFilterType.net)),
          Expanded(child: _buildFilterButton('Income', GraphFilterType.income)),
          Expanded(
            child: _buildFilterButton('Expenses', GraphFilterType.expenses),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, GraphFilterType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.textDark : Colors.grey,
          ),
        ),
      ),
    );
  }

  List<_HistoryPoint> _calculateHistoryPoints() {
    // 0. Sort history ascending
    List<AssetHistoryModel> history = List.from(widget.assetHistory);
    history.sort((a, b) => a.date.compareTo(b.date));

    // Determine Start Date
    DateTime now = DateTime.now();
    DateTime startDate;
    switch (_selectedRange) {
      case GraphTimeRange.oneWeek:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case GraphTimeRange.oneMonth:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case GraphTimeRange.threeMonths:
        startDate = now.subtract(const Duration(days: 90));
        break;
      case GraphTimeRange.sixMonths:
        startDate = now.subtract(const Duration(days: 180));
        break;
      case GraphTimeRange.oneYear:
        startDate = now.subtract(const Duration(days: 365));
        break;
      case GraphTimeRange.all:
        if (history.isEmpty) {
          startDate = now.subtract(const Duration(days: 1));
        } else {
          startDate = history.first.date;
        }
        break;
    }

    // Normalize Start Date to midnight
    startDate = DateTime(startDate.year, startDate.month, startDate.day);
    DateTime today = DateTime(now.year, now.month, now.day);

    List<_HistoryPoint> results = [];
    Map<String, double> currentBalances = {};

    // Initialize balances from before start date (history is ascending)
    int historyIndex = 0;
    while (historyIndex < history.length &&
        history[historyIndex].date.isBefore(startDate)) {
      final h = history[historyIndex];
      currentBalances[h.assetId] = h.balance;
      historyIndex++;
    }

    // Iterate day by day
    DateTime iterator = startDate;
    // Iterate until Today (inclusive)
    while (!iterator.isAfter(today)) {
      DateTime endOfDay = iterator
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      // Apply all history updates for this day
      while (historyIndex < history.length &&
          history[historyIndex].date.isBefore(endOfDay)) {
        final h = history[historyIndex];
        currentBalances[h.assetId] = h.balance;
        historyIndex++;
      }

      // Sum based on Filter
      double total = 0;
      for (var balance in currentBalances.values) {
        if (_selectedType == GraphFilterType.net) {
          total += balance;
        } else if (_selectedType == GraphFilterType.income) {
          if (balance >= 0) total += balance;
        } else if (_selectedType == GraphFilterType.expenses) {
          if (balance < 0) total += balance;
        }
      }
      results.add(_HistoryPoint(iterator, total));

      iterator = iterator.add(const Duration(days: 1));
    }

    return results;
  }
}

class _HistoryPoint {
  final DateTime date;
  final double value;
  _HistoryPoint(this.date, this.value);
}
