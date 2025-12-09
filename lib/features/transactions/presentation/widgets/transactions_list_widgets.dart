import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../pages/category_transactions_page.dart';
import '../pages/transaction_page.dart';

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
  final Function(TransactionTimeRange) onTimeRangeChanged;
  final VoidCallback onCustomDateRangePressed;
  final double totalIncome;
  final double totalExpense;
  final String currencySymbol;

  const TransactionsTopSection({
    super.key,
    required this.selectedLedgerId,
    required this.ledgers,
    required this.timeRange,
    required this.selectedDate,
    required this.onLedgerChanged,
    required this.onTimeRangeChanged,
    required this.onCustomDateRangePressed,
    required this.totalIncome,
    required this.totalExpense,
    required this.currencySymbol,
    this.customDateRange,
  });

  String get _timeRangeLabel {
    switch (timeRange) {
      case TransactionTimeRange.daily:
        return 'Daily';
      case TransactionTimeRange.weekly:
        return 'Weekly';
      case TransactionTimeRange.monthly:
        return 'Monthly';
      case TransactionTimeRange.annual:
        return 'Annual';
      case TransactionTimeRange.custom:
        return 'Custom';
      case TransactionTimeRange.all:
        return 'All';
    }
  }

  String get _dateDisplay {
    switch (timeRange) {
      case TransactionTimeRange.daily:
        return DateFormat('MMM dd yyyy').format(selectedDate);
      case TransactionTimeRange.weekly:
        // Show start and end of week? simplified for now
        return 'Week ${DateFormat('w').format(selectedDate)}';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        children: [
          // Top Row: Ledger & Time Range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ledger Dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pastelOrange.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: selectedLedgerId,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textDark,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    dropdownColor: const Color(0xFFFFFDF5),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.book,
                              size: 20,
                              color: AppColors.textDark,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'All ledgers',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Map ledgers from props
                      ...ledgers.map(
                        (l) => DropdownMenuItem(
                          value: l.id,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                size: 20,
                                color: AppColors.textDark,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l.name,
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
                    onChanged: onLedgerChanged,
                  ),
                ),
              ),

              // Time Range Button
              InkWell(
                onTap: () {
                  _showTimeRangeMenu(context);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pastelBlue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 18,
                        color: AppColors.textDark,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _timeRangeLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _dateDisplay,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Totals Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Expense
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
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
                    ),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),

              // Income
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
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
                    CurrencyFormatter.format(totalIncome, symbol: ''),
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
        ],
      ),
    );
  }

  void _showTimeRangeMenu(BuildContext context) async {
    final result = await showModalBottomSheet<TransactionTimeRange>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeOption(ctx, 'Daily', TransactionTimeRange.daily),
          _buildTimeOption(ctx, 'Weekly', TransactionTimeRange.weekly),
          _buildTimeOption(ctx, 'Monthly', TransactionTimeRange.monthly),
          _buildTimeOption(ctx, 'Annual', TransactionTimeRange.annual),
          _buildTimeOption(ctx, 'Custom', TransactionTimeRange.custom),
          _buildTimeOption(ctx, 'All', TransactionTimeRange.all),
        ],
      ),
    );

    if (result != null) {
      if (result == TransactionTimeRange.custom) {
        onCustomDateRangePressed();
      } else {
        onTimeRangeChanged(result);
      }
    }
  }

  ListTile _buildTimeOption(
    BuildContext context,
    String title,
    TransactionTimeRange value,
  ) {
    return ListTile(
      title: Text(title),
      onTap: () => Navigator.pop(context, value),
      trailing: timeRange == value
          ? const Icon(Icons.check, color: AppColors.textDark)
          : null,
    );
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
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey,
            ), // Should be empty/invisible prefix if we want right icon?
            // Image shows text on left, icon on right.
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

  const TransactionChartSection({
    super.key,
    required this.title,
    required this.isExpense,
    required this.transactions,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Group by category
    final Map<String, double> categoryTotals = {};
    final Map<String, int> categoryCounts =
        {}; // For colors? Or just random/hashed?
    double total = 0;

    for (var t in transactions) {
      final key = t.categoryName ?? 'Uncategorized';
      categoryTotals[key] = (categoryTotals[key] ?? 0) + t.amount;
      categoryCounts[key] = (categoryCounts[key] ?? 0) + 1;
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
                    final percent = (value / total) * 100;
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
            final percent = (value / total);

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
                        // Icon (placeholder)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isExpense ? Icons.lunch_dining : Icons.wallet,
                            size: 20,
                            color: color,
                          ), // Dynamic icon needed ideally
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
                              CurrencyFormatter.format(value, symbol: ''),
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

  const TransactionCalendarSection({
    super.key,
    required this.transactions,
    required this.isExpenseView,
    required this.onViewChanged,
  });

  @override
  State<TransactionCalendarSection> createState() =>
      _TransactionCalendarSectionState();
}

class _TransactionCalendarSectionState
    extends State<TransactionCalendarSection> {
  @override
  Widget build(BuildContext context) {
    // Generate dates for current month view (or selected range). Defaulting to "this month" for calendar visual as per image
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDay = DateTime(now.year, now.month, 1);
    final startingWeekday = firstDay.weekday % 7; // Sunday = 0

    // Map data to days
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
              ), // Red header per image
              Row(
                children: [
                  // Toggle Buttons? Image shows Filter icon and Arrow up.
                  // Implementing simple toggle for now
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
              const TableRow(
                children: [
                  Center(child: Text('Sun', style: TextStyle(fontSize: 10))),
                  Center(child: Text('Mon', style: TextStyle(fontSize: 10))),
                  Center(child: Text('Tue', style: TextStyle(fontSize: 10))),
                  Center(child: Text('Wed', style: TextStyle(fontSize: 10))),
                  Center(child: Text('Thu', style: TextStyle(fontSize: 10))),
                  Center(child: Text('Fri', style: TextStyle(fontSize: 10))),
                  Center(child: Text('Sat', style: TextStyle(fontSize: 10))),
                ],
              ),
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
              ), // Spacer
              ..._buildCalendarRows(daysInMonth, startingWeekday, dailyTotals),
            ],
          ),
        ],
      ),
    );
  }

  List<TableRow> _buildCalendarRows(
    int daysInMonth,
    int startingWeekday,
    Map<int, double> totals,
  ) {
    List<TableRow> rows = [];
    int currentDay = 1;

    // Row 1 (Partial)
    List<Widget> rowWidgets = [];
    for (int i = 0; i < 7; i++) {
      if (i < startingWeekday) {
        rowWidgets.add(const SizedBox());
      } else {
        if (currentDay <= daysInMonth) {
          rowWidgets.add(_buildDayCell(currentDay, totals[currentDay]));
          currentDay++;
        }
      }
    }
    rows.add(TableRow(children: rowWidgets));

    // Rest of rows
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
              NumberFormat.compact().format(amount),
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

  const TransactionListSection({super.key, required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group by Date for sticky headers or just sections
    // Reusing logic from Home Page would be good, but rewriting for cleaner structure here

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
    // Sort logic already assumed in input? better sort here
    sortedDates.sort((a, b) => b.compareTo(a));

    return Column(
      children: sortedDates.map((dateKey) {
        final dayTransactions = grouped[dateKey]!;
        final date = dayTransactions.first.date;

        // Calculate daily header totals
        double dayIncome = 0;
        double dayExpense = 0;
        for (var t in dayTransactions) {
          if (t.type == TransactionType.income) dayIncome += t.amount;
          if (t.type == TransactionType.expense) dayExpense += t.amount;
          if (t.type == TransactionType.transfer) {
            // simplified transfer logic for list view (net 0 usually unless specific logic)
          }
        }

        return Column(
          children: [
            // Header
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
                          '+${CurrencyFormatter.format(dayIncome, symbol: '')}',
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
                          '-${CurrencyFormatter.format(dayExpense, symbol: '')}',
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

            // Items
            ...dayTransactions.map((t) => _buildTransactionItem(context, t)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel t) {
    final isExpense = t.type == TransactionType.expense;
    final isIncome = t.type == TransactionType.income;
    // simple transfer logic

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
              '${isExpense ? '-' : (isIncome ? '+' : '')}${CurrencyFormatter.format(t.amount, symbol: '')}',
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
