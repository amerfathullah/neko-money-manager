import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../../../../features/home/presentation/providers/ledger_provider.dart';
import '../../../settings/presentation/providers/currency_provider.dart';
import '../widgets/transactions_list_widgets.dart';

class TransactionsListPage extends ConsumerStatefulWidget {
  const TransactionsListPage({super.key});

  @override
  ConsumerState<TransactionsListPage> createState() =>
      _TransactionsListPageState();
}

class _TransactionsListPageState extends ConsumerState<TransactionsListPage> {
  String? _selectedLedgerId;
  TransactionTimeRange _timeRange = TransactionTimeRange.monthly;
  final DateTime _selectedDate =
      DateTime.now(); // Anchor date for daily/monthly/annual
  DateTimeRange? _customDateRange;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _calendarIsExpenseView = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateTimeRange(TransactionTimeRange range) {
    setState(() {
      _timeRange = range;
    });
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange:
          _customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _timeRange = TransactionTimeRange.custom;
      });
    }
  }

  bool _isTransactionInTimeRange(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    switch (_timeRange) {
      case TransactionTimeRange.daily:
        return date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
      case TransactionTimeRange.weekly:
        // Simple "current week" for demo
        // Ideally calculate start/end of week based on selectedDate
        // week of year logic or simple +/- 3 days?
        // Let's implement actual week logic from selectedDate
        // final diff = date.difference(_selectedDate).inDays;
        // This is complex without proper util, sticking to "Same Week" check?
        // Using intl week?
        // Simplified: Match same ISO week number (very rough)
        // Better:
        final startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return startOfDay.isAfter(
              startOfWeek.subtract(const Duration(seconds: 1)),
            ) &&
            startOfDay.isBefore(endOfWeek.add(const Duration(days: 1)));

      case TransactionTimeRange.monthly:
        return date.year == _selectedDate.year &&
            date.month == _selectedDate.month;
      case TransactionTimeRange.annual:
        return date.year == _selectedDate.year;
      case TransactionTimeRange.custom:
        if (_customDateRange == null) return true;
        return startOfDay.isAfter(
              _customDateRange!.start.subtract(const Duration(seconds: 1)),
            ) &&
            startOfDay.isBefore(
              _customDateRange!.end.add(const Duration(days: 1)),
            );
      case TransactionTimeRange.all:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledgersAsync = ref.watch(ledgerProvider);
    final transactionsAsync = ref.watch(transactionProvider);
    final currencyAsync = ref.watch(
      currencyProvider,
    ); // Keep for symbol if needed, though passed down
    // final theme = Theme.of(context);
    final currencySymbol = currencyAsync.asData?.value ?? '\$';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Cream background

      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (allTransactions) {
          // 1. Filter by Ledger
          List<TransactionModel> filtered = allTransactions;
          if (_selectedLedgerId != null) {
            filtered = filtered.where((t) {
              if (t.type == TransactionType.transfer) {
                return t.ledgerId == _selectedLedgerId ||
                    t.destinationLedgerId == _selectedLedgerId;
              }
              return t.ledgerId == _selectedLedgerId;
            }).toList();
          }

          // 2. Filter by Time Range
          filtered = filtered
              .where((t) => _isTransactionInTimeRange(t.date))
              .toList();

          // 3. Filter by Search (Amount or Remarks)
          if (_searchQuery.isNotEmpty) {
            filtered = filtered.where((t) {
              final query = _searchQuery.toLowerCase();
              final amountStr = t.amount.toString();
              final remarks = t.remarks?.toLowerCase() ?? '';
              final note = t.note?.toLowerCase() ?? ''; // Also search notes?
              final cat = t.categoryName?.toLowerCase() ?? '';

              return amountStr.contains(query) ||
                  remarks.contains(query) ||
                  note.contains(query) ||
                  cat.contains(query);
            }).toList();
          }

          // Calculate Totals for Top Section
          double totalIncome = 0;
          double totalExpense = 0;
          for (var t in filtered) {
            if (t.type == TransactionType.income) totalIncome += t.amount;
            if (t.type == TransactionType.expense) totalExpense += t.amount;
            if (t.type == TransactionType.transfer) {
              // Per wallet total logic?
              if (_selectedLedgerId != null) {
                if (t.ledgerId == _selectedLedgerId) totalExpense += t.amount;
                if (t.destinationLedgerId == _selectedLedgerId) {
                  totalIncome += t.amount;
                }
              }
            }
          }

          final ledgers = ledgersAsync.asData?.value ?? [];

          return SafeArea(
            child: Stack(
              children: [
                // Background Elements
                Positioned(
                  top: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.6,
                    child: Image.asset(
                      'assets/images/cat_top_right.png',
                      width: 100,
                      errorBuilder: (c, e, s) => const SizedBox(),
                    ),
                  ),
                ),

                // Top Section
                Column(
                  children: [
                    TransactionsTopSection(
                      selectedLedgerId: _selectedLedgerId,
                      ledgers: ledgers,
                      timeRange: _timeRange,
                      selectedDate: _selectedDate,
                      customDateRange: _customDateRange,
                      onLedgerChanged: (val) =>
                          setState(() => _selectedLedgerId = val),
                      onTimeRangeChanged: _updateTimeRange,
                      onCustomDateRangePressed: _pickCustomDateRange,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      currencySymbol: currencySymbol,
                    ),
                  ],
                ),

                // Draggable Sheet
                DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.7,
                  maxChildSize: 1.0,
                  builder: (context, scrollController) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        // White Sheet
                        Container(
                          margin: const EdgeInsets.only(top: 25),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFDF5),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.only(top: 40, bottom: 80),
                            children: [
                              // Section 1: Search
                              TransactionSearchBar(
                                controller: _searchController,
                                onChanged: (v) {},
                              ),
                              const SizedBox(height: 24),

                              // Section 2: Expenses
                              TransactionChartSection(
                                title: 'Expenses',
                                isExpense: true,
                                transactions: filtered
                                    .where(
                                      (t) =>
                                          t.type == TransactionType.expense ||
                                          (t.type == TransactionType.transfer &&
                                              t.ledgerId == _selectedLedgerId),
                                    )
                                    .toList(),
                                currencySymbol: currencySymbol,
                              ),

                              // Section 3: Income
                              TransactionChartSection(
                                title: 'Income',
                                isExpense: false,
                                transactions: filtered
                                    .where(
                                      (t) =>
                                          t.type == TransactionType.income ||
                                          (t.type == TransactionType.transfer &&
                                              t.destinationLedgerId ==
                                                  _selectedLedgerId),
                                    )
                                    .toList(),
                                currencySymbol: currencySymbol,
                              ),

                              // Section 4: Calendar
                              TransactionCalendarSection(
                                transactions: filtered,
                                isExpenseView: _calendarIsExpenseView,
                                onViewChanged: (val) => setState(
                                  () => _calendarIsExpenseView = val,
                                ),
                              ),

                              // Section 5: List
                              TransactionListSection(
                                transactions: filtered,
                                currencySymbol: currencySymbol,
                              ),
                            ],
                          ),
                        ),

                        // Cat Peek
                        Positioned(
                          top: 0,
                          child: Image.asset(
                            'assets/images/cat_peek.png',
                            width: 60,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 50,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: const Icon(Icons.pets, size: 20),
                                ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
