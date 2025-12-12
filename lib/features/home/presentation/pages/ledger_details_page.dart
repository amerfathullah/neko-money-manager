import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/ledger.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../settings/presentation/providers/currency_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/pages/add_edit_ledger_page.dart';
import '../../../home/presentation/providers/ledger_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/data/models/category.dart';
// Import for TransactionTimeRange if accessible, otherwise define local or move enum to core
import '../../../transactions/presentation/widgets/transactions_list_widgets.dart';
import '../../../transactions/presentation/widgets/transaction_timeline.dart';
import '../../../transactions/presentation/widgets/time_filter_popup.dart';

class LedgerDetailsPage extends ConsumerStatefulWidget {
  final Ledger ledger;

  const LedgerDetailsPage({super.key, required this.ledger});

  @override
  ConsumerState<LedgerDetailsPage> createState() => _LedgerDetailsPageState();
}

class _LedgerDetailsPageState extends ConsumerState<LedgerDetailsPage> {
  TransactionTimeRange _timeRange = TransactionTimeRange.monthly;
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _customDateRange;
  int _selectedTabIndex = 0; // 0: Record, 1: Statistic

  @override
  Widget build(BuildContext context) {
    final currencyAsync = ref.watch(currencyProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currencySymbol = currencyAsync.asData?.value ?? '\$';
    final useComma = settingsAsync.asData?.value.useCommaSeparator ?? false;

    final transactionsAsync = ref.watch(
      ledgerTransactionsProvider(widget.ledger.id),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Cream background
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context),
            Expanded(
              child: transactionsAsync.when(
                data: (allTransactions) {
                  final filteredTransactions = _filterTransactions(
                    allTransactions,
                  );
                  final summary = _calculateSummary(filteredTransactions);

                  return Column(
                    children: [
                      // Date Filter (Optional, keep for navigating months)
                      _buildDateFilter(),

                      Expanded(
                        child: _selectedTabIndex == 0
                            ? _buildRecordLayout(
                                filteredTransactions,
                                currencySymbol,
                                useComma,
                              )
                            : _buildStatisticTab(
                                filteredTransactions,
                                currencySymbol,
                                ref.watch(categoryProvider).asData?.value ?? [],
                                useComma,
                              ),
                      ),

                      // Bottom Summary (Only for Record Tab usually, but image implies it's persistent or attached)
                      // Image shows it on "Record" tab.
                      _buildBottomSummary(summary, currencySymbol, useComma),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textDark.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: AppColors.textDark,
              ),
            ),
          ),
          // Segmented Control
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFE6D5), // Darker cream/beige
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                _buildTabButton('Record', 0),
                _buildTabButton('Statistic', 1),
              ],
            ),
          ),
          // Settings / More
          IconButton(
            onPressed: () {
              // Show default menu or settings
              _showSettingsMenu(context);
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textDark.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.settings,
                size: 20,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8E1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
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
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.textDark : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: InkWell(
          onTap: _showTimeRangeMenu,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  _getDateLabel(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordLayout(
    List<TransactionModel> transactions,
    String currencySymbol,
    bool useComma,
  ) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text('No records', style: TextStyle(color: Colors.grey)),
      );
    }

    // Check settings for useComma if accessible, or default to false/true based on context.
    // In LedgerDetailsPage, we didn't explicitly watch settingsProvider before.
    // But TransactionTimeline takes `useComma`.
    // I should probably add `final settings = ref.watch(settingsProvider).asData?.value;` at build level
    // or just default to false here if not critical, or pass it in.
    // The original code passed `categories`, `assets`, etc. which are now internal to the widget.

    return TransactionTimeline(
      transactions: transactions,
      currencySymbol: currencySymbol,
      useComma: useComma,
    );
  }

  Widget _buildStatisticTab(
    List<TransactionModel> transactions,
    String currencySymbol,
    List<Category> categories,
    bool useComma,
  ) {
    // Reuse existing logic
    if (transactions.isEmpty) return const Center(child: Text('No data'));
    return SingleChildScrollView(
      child: Column(
        children: [
          TransactionChartSection(
            title: 'Expenses',
            isExpense: true,
            transactions: transactions
                .where((t) => t.type == TransactionType.expense)
                .toList(),
            currencySymbol: currencySymbol,
            useComma: true,
            categories: categories,
          ),
          const Divider(),
          TransactionChartSection(
            title: 'Income',
            isExpense: false,
            transactions: transactions
                .where((t) => t.type == TransactionType.income)
                .toList(),
            currencySymbol: currencySymbol,
            useComma: true,
            categories: categories,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(
    Map<String, double> summary,
    String currencySymbol,
    bool useComma,
  ) {
    final expense = summary['expense'] ?? 0.0;
    final income = summary['income'] ?? 0.0;
    final net = income - expense;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8E1), // Match background or slightly different?
        border: Border(top: BorderSide(color: Color(0xFFEEE0CD), width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.ledger.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.ledger.icon ?? Icons.account_balance_wallet,
                  color: widget.ledger.color,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.ledger.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Expenses',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.expense,
                        size: 16,
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(
                      expense,
                      symbol: currencySymbol,
                      useGrouping: useComma,
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.expense,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(
                      net,
                      symbol: currencySymbol,
                      useGrouping: useComma,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Income',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_up,
                        color: AppColors.textDark,
                        size: 16,
                      ), // Dark arrow for income per image?
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(
                      income,
                      symbol: currencySymbol,
                      useGrouping: useComma,
                    ),
                    style: const TextStyle(
                      fontSize: 24,
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

  // --- Helper Methods (Copied/Adapted) ---
  Map<String, double> _calculateSummary(List<TransactionModel> transactions) {
    double income = 0;
    double expense = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.income) income += t.amount;
      if (t.type == TransactionType.expense) expense += t.amount;
    }
    return {'income': income, 'expense': expense};
  }

  List<TransactionModel> _filterTransactions(
    List<TransactionModel> transactions,
  ) {
    return transactions.where((t) {
      switch (_timeRange) {
        case TransactionTimeRange.daily:
          return isSameDay(t.date, _selectedDate);
        case TransactionTimeRange.weekly:
          // Simplified weekly logic
          final startOfWeek = _selectedDate.subtract(
            Duration(days: _selectedDate.weekday - 1),
          );
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          return t.date.isAfter(
                startOfWeek.subtract(const Duration(seconds: 1)),
              ) &&
              t.date.isBefore(endOfWeek.add(const Duration(days: 1)));
        case TransactionTimeRange.monthly:
          return t.date.year == _selectedDate.year &&
              t.date.month == _selectedDate.month;
        case TransactionTimeRange.annual:
          return t.date.year == _selectedDate.year;
        case TransactionTimeRange.all:
          return true;
        case TransactionTimeRange.custom:
          if (_customDateRange == null) return true;
          return t.date.isAfter(_customDateRange!.start) &&
              t.date.isBefore(_customDateRange!.end);
      }
    }).toList();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDateLabel() {
    switch (_timeRange) {
      case TransactionTimeRange.daily:
        return DateFormat('dd MMM yyyy').format(_selectedDate);
      case TransactionTimeRange.weekly:
        final startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('dd MMM').format(startOfWeek)} - ${DateFormat('dd MMM').format(endOfWeek)}';
      case TransactionTimeRange.monthly:
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case TransactionTimeRange.annual:
        return DateFormat('yyyy').format(_selectedDate);
      case TransactionTimeRange.custom:
        if (_customDateRange != null) {
          return '${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM').format(_customDateRange!.end)}';
        }
        return 'Custom Range';
      case TransactionTimeRange.all:
        return 'All Time';
    }
  }

  void _showTimeRangeMenu() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => TimeFilterPopup(
        initialRange: _timeRange,
        initialSelectedDate: _selectedDate,
        initialCustomDateRange: _customDateRange,
      ),
    );

    if (result != null) {
      setState(() {
        _timeRange = result['range'] as TransactionTimeRange;
        _selectedDate = result['date'] as DateTime;
        _customDateRange = result['customRange'] as DateTimeRange?;
      });
    }
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Ledger'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditLedgerPage(ledger: widget.ledger),
                ),
              );
            },
          ),
          if (!widget.ledger.isDefault)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Ledger',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    // Deletion Logic
    await ref.read(ledgerProvider.notifier).deleteLedger(widget.ledger.id);
    if (mounted) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }
}
