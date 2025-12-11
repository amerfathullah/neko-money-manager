import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../../../home/presentation/widgets/ledger_selector.dart';
import '../pages/category_transactions_page.dart';
import '../pages/transaction_page.dart';
import 'time_filter_popup.dart';
import '../../../../features/categories/data/models/category.dart';

// --- ENUMS ---
enum TransactionTimeRange { daily, weekly, monthly, annual, custom, all }

// --- WIDGETS ---

class TransactionsTopSection extends StatelessWidget {
  final String? selectedLedgerId;
  final List<dynamic> ledgers; // Placeholder dynamic, pass actual LedgerModel
  final TransactionTimeRange timeRange;
  final DateTimeRange? customDateRange; // For custom
  final DateTime selectedDate; // For daily/monthly/annual anchors
  final Function(String?) onLedgerChanged;
  final Function(TransactionTimeRange, DateTime, DateTimeRange?)
  onFilterChanged;
  final double totalIncome;
  final double totalExpense;
  final String currencySymbol;
  final bool useComma;

  const TransactionsTopSection({
    super.key,
    required this.selectedLedgerId,
    required this.ledgers,
    required this.timeRange,
    required this.selectedDate,
    required this.onLedgerChanged,
    required this.onFilterChanged,
    required this.totalIncome,
    required this.totalExpense,
    required this.currencySymbol,
    required this.useComma,
    this.customDateRange,
  });

  String get _dateDisplay {
    switch (timeRange) {
      case TransactionTimeRange.daily:
        return DateFormat('dd MMM yyyy').format(selectedDate);
      case TransactionTimeRange.weekly:
        final startOfWeek = selectedDate.subtract(
          Duration(days: selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('dd MMM').format(startOfWeek)} - ${DateFormat('dd MMM').format(endOfWeek)}';
      case TransactionTimeRange.monthly:
        return DateFormat('MMM yyyy').format(selectedDate);
      case TransactionTimeRange.annual:
        return DateFormat('yyyy').format(selectedDate);
      case TransactionTimeRange.custom:
        if (customDateRange != null) {
          return '${DateFormat('MMM dd').format(customDateRange!.start)} - ${DateFormat('MMM dd').format(customDateRange!.end)}';
        }
        return 'Select Dates';
      case TransactionTimeRange.all:
        return 'All Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Top Row: Ledger & Time Range
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const LedgerSelector(),

              // Time Range Button
              InkWell(
                onTap: () {
                  _showTimeRangeMenu(context);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pastelBlue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 20,
                        color: AppColors.textDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dateDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Totals Display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Expense
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Expenses',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: AppColors.expense),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(
                      totalExpense,
                      symbol: currencySymbol,
                      useGrouping: useComma,
                    ),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pastelRed,
                    ),
                  ),
                ],
              ),

              // Income
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Income',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_up, color: AppColors.textDark),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(
                      totalIncome,
                      symbol: currencySymbol,
                      useGrouping: useComma,
                    ),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTimeRangeMenu(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => TimeFilterPopup(
        initialRange: timeRange,
        initialSelectedDate: selectedDate,
        initialCustomDateRange: customDateRange,
      ),
    );

    if (result != null) {
      onFilterChanged(
        result['range'] as TransactionTimeRange,
        result['date'] as DateTime,
        result['customRange'] as DateTimeRange?,
      );
    }
  }
}

class TransactionSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const TransactionSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1), // Background matching main/card
          borderRadius: BorderRadius.circular(24),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: const InputDecoration(
            hintText: 'Search by amount or remarks..',
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            suffixIcon: Icon(Icons.search, color: AppColors.textDark),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
    );
  }
}

class TransactionChartSection extends StatelessWidget {
  final String title;
  final bool isExpense;
  final List<TransactionModel> transactions;
  final String currencySymbol;
  final bool useComma;
  final List<Category> categories;

  const TransactionChartSection({
    super.key,
    required this.title,
    required this.isExpense,
    required this.transactions,
    required this.currencySymbol,
    required this.useComma,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Group by category
    final Map<String, double> categoryTotals = {};
    double total = 0;

    for (var t in transactions) {
      final key = t.categoryName ?? 'Uncategorized';
      categoryTotals[key] = (categoryTotals[key] ?? 0) + t.amount;
      total += t.amount;
    }

    // Sort by amount desc
    final sortedKeys = categoryTotals.keys.toList()
      ..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));

    // Simple color palette loop
    final List<Color> colors = [
      const Color(0xFFFFB74D), // Orange
      const Color(0xFFE57373), // Red
      const Color(0xFFF06292), // Pink
      const Color(0xFF4DB6AC), // Teal
      const Color(0xFF9575CD), // Purple
      const Color(0xFFAED581), // Green
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.substring(0, 1).toUpperCase() +
                    title.substring(1), // Capitalize
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isExpense
                      ? AppColors.expense
                      : AppColors
                            .textDark, // Per image: Expenses is Red/DarkRed text
                ),
              ),
              IconButton(
                onPressed: () {},
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
                    sections: sortedKeys.map((key) {
                      final index = sortedKeys.indexOf(key);
                      final color = colors[index % colors.length];
                      final value = categoryTotals[key]!;

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
                  children: sortedKeys.take(5).map((key) {
                    final index = sortedKeys.indexOf(key);
                    final color = colors[index % colors.length];
                    final value = categoryTotals[key]!;
                    final percent = total > 0 ? (value / total) * 100 : 0.0;
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
                              key,
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
          // Category List (Bars)
          ...sortedKeys.take(3).map((key) {
            final index = sortedKeys.indexOf(key);
            final color = colors[index % colors.length];
            final value = categoryTotals[key]!;
            final percent = total > 0 ? (value / total) : 0.0;

            // Find category for icon
            final category = categories.firstWhere(
              (c) => c.name == key,
              orElse: () => Category(
                id: 'unknown',
                name: 'Unknown',
                iconCodePoint: isExpense
                    ? Icons.lunch_dining.codePoint
                    : Icons.book.codePoint,
                iconFontFamily: 'MaterialIcons',
                colorValue: Colors.grey.toARGB32(),
                type: isExpense ? CategoryType.expense : CategoryType.income,
              ),
            );

            return InkWell(
              onTap: () {
                if (key != 'Uncategorized') {
                  // Navigate
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryTransactionsPage(
                        categoryName: key,
                        transactions: transactions
                            .where((t) => t.categoryName == key)
                            .toList(),
                        currencySymbol: currencySymbol,
                        useComma: useComma,
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(category.icon, size: 20, color: color),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(
                                value,
                                symbol: currencySymbol,
                                useGrouping: useComma,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
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

class TransactionCalendarSection extends StatefulWidget {
  final List<TransactionModel> transactions;
  final bool isExpenseView;
  final ValueChanged<bool> onViewChanged;
  final int firstDayOfWeek; // 1 = Monday, 7 = Sunday, etc.

  const TransactionCalendarSection({
    super.key,
    required this.transactions,
    required this.isExpenseView,
    required this.onViewChanged,
    required this.firstDayOfWeek,
    required this.currencySymbol,
  });

  final String currencySymbol;

  @override
  State<TransactionCalendarSection> createState() =>
      _TransactionCalendarSectionState();
}

class _TransactionCalendarSectionState
    extends State<TransactionCalendarSection> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    // Calculate starting offset based on firstDayOfWeek
    // Weekday: Mon=1,... Sun=7.
    // firstDayOfWeek: Mon=1, Sun=7.
    // if Mon starts (1), and firstDay is Mon (1) -> offset 0.
    // if Sun starts (7), and firstDay is Mon (1) -> offset 1?
    // Weekdays list: [Sun, Mon, Tue...] if Sun starts.
    // Generally: (firstDay.weekday - startOfWeek + 7)  % 7
    final startingOffset =
        (firstDayOfMonth.weekday - widget.firstDayOfWeek + 7) % 7;

    final Map<int, double> dailyTotals = {};
    for (var t in widget.transactions) {
      final isTargetType = widget.isExpenseView
          ? t.type == TransactionType.expense
          : t.type == TransactionType.income;
      if (isTargetType &&
          t.date.year == now.year &&
          t.date.month == now.month) {
        dailyTotals[t.date.day] = (dailyTotals[t.date.day] ?? 0) + t.amount;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Calendar",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.expense,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        widget.onViewChanged(!widget.isExpenseView),
                    icon: Icon(
                      widget.isExpenseView
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: widget.isExpenseView
                          ? AppColors.expense
                          : AppColors.income,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            children: [
              TableRow(children: _buildWeekHeaders()),
              const TableRow(
                children: [
                  SizedBox(height: 8),
                  SizedBox(),
                  SizedBox(),
                  SizedBox(),
                  SizedBox(),
                  SizedBox(),
                  SizedBox(),
                ],
              ),
              ..._buildCalendarRows(daysInMonth, startingOffset, dailyTotals),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeekHeaders() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final shift = widget.firstDayOfWeek - 1;
    final orderedDays = [...days.sublist(shift), ...days.sublist(0, shift)];

    return orderedDays
        .map(
          (d) => Center(child: Text(d, style: const TextStyle(fontSize: 10))),
        )
        .toList();
  }

  List<TableRow> _buildCalendarRows(
    int daysInMonth,
    int startingOffset,
    Map<int, double> totals,
  ) {
    List<TableRow> rows = [];
    int currentDay = 1;

    // Row 1
    List<Widget> rowWidgets = [];
    for (int i = 0; i < 7; i++) {
      if (i < startingOffset) {
        rowWidgets.add(const SizedBox());
      } else {
        if (currentDay <= daysInMonth) {
          rowWidgets.add(_buildDayCell(currentDay, totals[currentDay]));
          currentDay++;
        }
      }
    }
    rows.add(TableRow(children: rowWidgets));

    // Rest
    while (currentDay <= daysInMonth) {
      rowWidgets = [];
      for (int i = 0; i < 7; i++) {
        if (currentDay <= daysInMonth) {
          rowWidgets.add(_buildDayCell(currentDay, totals[currentDay]));
          currentDay++;
        } else {
          rowWidgets.add(const SizedBox());
        }
      }
      rows.add(TableRow(children: rowWidgets));
    }

    return rows;
  }

  Widget _buildDayCell(int day, double? amount) {
    return Container(
      height: 48,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: amount != null
            ? (widget.isExpenseView
                  ? AppColors.pastelRed.withValues(alpha: 0.2)
                  : AppColors.pastelGreen.withValues(alpha: 0.2))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          if ((amount ?? 0) > 0)
            Text(
              '${widget.isExpenseView ? '-' : '+'}${widget.currencySymbol}${NumberFormat.compact().format((amount ?? 0).abs())}',
              style: TextStyle(
                fontSize: 8,
                color: widget.isExpenseView
                    ? AppColors.expense
                    : AppColors.income,
              ),
            ),
        ],
      ),
    );
  }
}

class TransactionListSection extends ConsumerWidget {
  final List<TransactionModel> transactions;
  final String currencySymbol;
  final bool useComma;

  const TransactionListSection({
    super.key,
    required this.transactions,
    this.currencySymbol = '\$',
    required this.useComma,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = <String, List<TransactionModel>>{};
    final sortedDates = <String>[];

    for (var t in transactions) {
      final dateKey = DateFormat('yyyyMMdd').format(t.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
        sortedDates.add(dateKey);
      }
      grouped[dateKey]!.add(t);
    }
    sortedDates.sort((a, b) => b.compareTo(a));

    return Column(
      children: sortedDates.map((dateKey) {
        final dayTransactions = grouped[dateKey]!;
        final date = dayTransactions.first.date;

        double dayIncome = 0;
        double dayExpense = 0;
        for (var t in dayTransactions) {
          if (t.type == TransactionType.income) dayIncome += t.amount;
          if (t.type == TransactionType.expense) dayExpense += t.amount;
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('MMM dd').format(date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEE').format(date),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (dayIncome > 0)
                        Text(
                          '+${CurrencyFormatter.format(dayIncome, symbol: currencySymbol, useGrouping: useComma)}',
                          style: const TextStyle(
                            color: AppColors.income,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (dayIncome > 0 && dayExpense > 0)
                        const SizedBox(width: 8),
                      if (dayExpense > 0)
                        Text(
                          '-${CurrencyFormatter.format(dayExpense, symbol: currencySymbol, useGrouping: useComma)}',
                          style: const TextStyle(
                            color: AppColors.expense,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ...dayTransactions.map((t) => _buildTransactionItem(context, t)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel t) {
    final isExpense = t.type == TransactionType.expense;
    final isIncome = t.type == TransactionType.income;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TransactionPage(transaction: t)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.amber[100],
              radius: 20,
              child: Icon(
                isExpense ? Icons.lunch_dining : Icons.attach_money,
                color: Colors.brown,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.categoryName ?? 'Uncategorized',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (t.remarks != null && t.remarks!.isNotEmpty)
                    Text(
                      t.remarks!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    DateFormat('HH:mm').format(t.date),
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : (isIncome ? '+' : '')}${CurrencyFormatter.format(t.amount, symbol: currencySymbol, useGrouping: useComma)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpense
                    ? AppColors.expense
                    : (isIncome ? AppColors.income : AppColors.textDark),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
