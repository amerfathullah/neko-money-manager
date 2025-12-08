import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../categories/presentation/providers/category_provider.dart';

class TransactionChart extends ConsumerStatefulWidget {
  final List<TransactionModel> transactions;
  final Function(String categoryName)? onCategoryTap;

  const TransactionChart({
    super.key,
    required this.transactions,
    this.onCategoryTap,
  });

  @override
  ConsumerState<TransactionChart> createState() => _TransactionChartState();
}

class _TransactionChartState extends ConsumerState<TransactionChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // 1. Filter Expenses
    final expenses = widget.transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (expenses.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No expenses to show')),
      );
    }

    // 2. Access Categories for Colors
    final categories = ref.watch(categoryProvider).asData?.value ?? [];
    final categoryColorMap = {for (var c in categories) c.name: c.color};

    // 3. Aggregate by Category
    final Map<String, double> categoryTotals = {};
    for (final t in expenses) {
      final category = t.categoryName ?? 'Uncategorized';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + t.amount;
    }

    // 4. Create Sections
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by amount desc

    final totalExpense = expenses.fold(0.0, (sum, t) => sum + t.amount);

    final sections = sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final categoryName = entry.value.key;
      final amount = entry.value.value;
      final percentage = (amount / totalExpense) * 100;
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final fontSize = isTouched ? 14.0 : 12.0;

      // Determine color: Try map, else generated palette
      Color sectionColor =
          categoryColorMap[categoryName] ?? AppColors.pastelRed; // Fallback
      if (!categoryColorMap.containsKey(categoryName)) {
        // Cycle through palette if not found (or 'Uncategorized')
        final palette = [
          AppColors.pastelRed,
          AppColors.pastelBlue,
          AppColors.pastelGreen,
          AppColors.pastelYellow,
          AppColors.pastelPurple,
          AppColors.pastelOrange,
        ];
        sectionColor = palette[index % palette.length];
      }

      return PieChartSectionData(
        color: sectionColor,
        value: amount,
        title: '$categoryName\n${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
        ),
      );
    }).toList();

    return AspectRatio(
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
                final touchedIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;

                // Handle click action
                if (_touchedIndex != touchedIndex && event is FlTapUpEvent) {
                  if (touchedIndex >= 0 &&
                      touchedIndex < sortedEntries.length) {
                    final categoryName = sortedEntries[touchedIndex].key;
                    widget.onCategoryTap?.call(categoryName);
                  }
                }

                _touchedIndex = touchedIndex;
              });
            },
          ),
        ),
      ),
    );
  }
}
