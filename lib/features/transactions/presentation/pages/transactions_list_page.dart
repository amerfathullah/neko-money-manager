import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../../../../features/home/presentation/providers/ledger_provider.dart';
import '../../../settings/presentation/providers/currency_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../features/categories/presentation/providers/category_provider.dart';
import '../widgets/transactions_list_widgets.dart';
import '../widgets/transaction_timeline.dart';

class TransactionsListPage extends ConsumerStatefulWidget {
  const TransactionsListPage({super.key});

  @override
  ConsumerState<TransactionsListPage> createState() =>
      _TransactionsListPageState();
}

class _TransactionsListPageState extends ConsumerState<TransactionsListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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

  bool _isTransactionInTimeRange(
    DateTime date,
    int monthlyStartDate,
    int firstDayOfWeek,
  ) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    switch (_timeRange) {
      case TransactionTimeRange.daily:
        return date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
      case TransactionTimeRange.weekly:
        // Use firstDayOfWeek (1=Mon ... 7=Sun)
        // Find start of week for _selectedDate
        // weekday: Mon=1..Sun=7
        // diff = (weekday - first + 7) % 7
        final diff = (_selectedDate.weekday - firstDayOfWeek + 7) % 7;
        final startOfWeek = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ).subtract(Duration(days: diff));

        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        // Check if transaction is in this week
        return startOfDay.isAfter(
              startOfWeek.subtract(const Duration(seconds: 1)),
            ) &&
            startOfDay.isBefore(endOfWeek.add(const Duration(days: 1)));

      case TransactionTimeRange.monthly:
        // Monthly Start Date Logic
        // Cycle starts on Day S of Month M (of _selectedDate)
        // If S=1: Month M, 1 to Month M+1, 0. (Standard month)
        // If S>1: Month M, S to Month M+1, S-1.

        final startDay = monthlyStartDate;
        final startOfPeriod = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          startDay,
        );
        // End is Start + 1 month - 1 day
        // safest way: (month + 1, startDay) subtract 1 day.
        final nextPeriodStart = DateTime(
          _selectedDate.year,
          _selectedDate.month + 1,
          startDay,
        );

        // Need to cover full days so check against startOfDay logic or standard compare
        // t.date usually has time.
        // startOfPeriod is at 00:00. endOfPeriod is at 00:00 of the last day.
        // So we need t.date >= startOfPeriod AND t.date < nextPeriodStart
        return date.isAfter(
              startOfPeriod.subtract(const Duration(seconds: 1)),
            ) &&
            date.isBefore(nextPeriodStart);

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
    super.build(context);
    final ledgersAsync = ref.watch(ledgerProvider);
    final transactionsAsync = ref.watch(transactionProvider);
    final currencyAsync = ref.watch(currencyProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final categories = categoriesAsync.asData?.value ?? [];
    final selectedLedgerId = ref.watch(selectedLedgerProvider);

    final currencySymbol = currencyAsync.asData?.value ?? '\$';

    // Default settings if loading or error
    final settings = settingsAsync.asData?.value ?? const SettingsState();
    final monthlyStartDate = settings.monthlyStartDate;
    final firstDayOfWeek = settings.firstDayOfWeek;
    final useComma = settings.useCommaSeparator;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Cream background

      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (allTransactions) {
          // 1. Filter by Ledger
          List<TransactionModel> filtered = allTransactions;
          if (selectedLedgerId != null) {
            filtered = filtered.where((t) {
              if (t.type == TransactionType.transfer) {
                return t.ledgerId == selectedLedgerId ||
                    t.destinationLedgerId == selectedLedgerId;
              }
              return t.ledgerId == selectedLedgerId;
            }).toList();
          }

          // 2. Filter by Time Range
          filtered = filtered
              .where(
                (t) => _isTransactionInTimeRange(
                  t.date,
                  monthlyStartDate,
                  firstDayOfWeek,
                ),
              )
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
              if (selectedLedgerId != null) {
                if (t.ledgerId == selectedLedgerId) totalExpense += t.amount;
                if (t.destinationLedgerId == selectedLedgerId) {
                  totalIncome += t.amount;
                }
              }
            }
          }

          final ledgers = ledgersAsync.asData?.value ?? [];

          return SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Background Elements - REMOVED

                // Top Section
                Column(
                  children: [
                    TransactionsTopSection(
                      selectedLedgerId: selectedLedgerId,
                      ledgers: ledgers,
                      timeRange: _timeRange,
                      selectedDate: _selectedDate,
                      customDateRange: _customDateRange,
                      onLedgerChanged: (val) =>
                          ref.read(selectedLedgerProvider.notifier).set(val),
                      onTimeRangeChanged: _updateTimeRange,
                      onCustomDateRangePressed: _pickCustomDateRange,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      currencySymbol: currencySymbol,
                      useComma: useComma,
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
                            color: Color(0xFFFFFCF0),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.only(
                              top: 40,
                              bottom: 120,
                            ),
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
                                              t.ledgerId == selectedLedgerId),
                                    )
                                    .toList(),
                                currencySymbol: currencySymbol,
                                useComma: useComma,
                                categories: categories,
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
                                                  selectedLedgerId),
                                    )
                                    .toList(),
                                currencySymbol: currencySymbol,
                                useComma: useComma,
                                categories: categories,
                              ),

                              // Section 4: Calendar
                              TransactionCalendarSection(
                                transactions: filtered,
                                isExpenseView: _calendarIsExpenseView,
                                onViewChanged: (val) => setState(
                                  () => _calendarIsExpenseView = val,
                                ),
                                firstDayOfWeek: firstDayOfWeek,
                              ),

                              // Section 5: List
                              TransactionTimeline(
                                transactions: filtered,
                                currencySymbol: currencySymbol,
                                useComma: useComma,
                                physics:
                                    const NeverScrollableScrollPhysics(), // Since it's inside a ListView
                                shrinkWrap: true,
                                backgroundColor: const Color(0xFFFFFCF0),
                              ),
                            ],
                          ),
                        ),

                        // Drag Handle
                        Positioned(
                          top: 10,
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
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
