import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/ledger.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../settings/presentation/providers/currency_provider.dart';
import '../../../settings/presentation/pages/add_edit_ledger_page.dart';
import '../../../home/presentation/providers/ledger_provider.dart';
// Import for TransactionTimeRange if accessible, otherwise define local or move enum to core
import '../../../transactions/presentation/widgets/transactions_list_widgets.dart';

class LedgerDetailsPage extends ConsumerStatefulWidget {
  final Ledger ledger;

  const LedgerDetailsPage({super.key, required this.ledger});

  @override
  ConsumerState<LedgerDetailsPage> createState() => _LedgerDetailsPageState();
}

class _LedgerDetailsPageState extends ConsumerState<LedgerDetailsPage> {
  TransactionTimeRange _timeRange = TransactionTimeRange.monthly;
  final DateTime _selectedDate = DateTime.now();
  DateTimeRange? _customDateRange;

  @override
  Widget build(BuildContext context) {
    final currencyAsync = ref.watch(currencyProvider);
    final currencySymbol = currencyAsync.asData?.value ?? '\$';

    // We need to fetch transactions and filter them based on _timeRange and _selectedDate
    // Ideally this filtering happens in the provider or repository, but for now we filter locally
    // or assume the provider returns all and we filter.
    // The current ledgerTransactionsProvider(id) returns all transactions for the ledger.
    final transactionsAsync = ref.watch(
      ledgerTransactionsProvider(widget.ledger.id),
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.ledger.name),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: AppColors.textDark),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          AddEditLedgerPage(ledger: widget.ledger),
                    ),
                  );
                } else if (value == 'delete') {
                  if (!widget.ledger.isDefault) {
                    _confirmDelete(context);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                if (!widget.ledger.isDefault)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(
              100,
            ), // Height for Date Filter + TabBar
            child: Column(
              children: [
                // Date Filter Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: _showTimeRangeMenu,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pastelBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _getDateLabel(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
                const TabBar(
                  labelColor: AppColors.pastelPurple,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.pastelPurple,
                  tabs: [
                    Tab(text: 'Record'),
                    Tab(text: 'Statistic'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: transactionsAsync.when(
          data: (allTransactions) {
            // Apply Date Filter
            final filteredTransactions = _filterTransactions(allTransactions);
            final summary = _calculateSummary(filteredTransactions);

            return Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      // Record Tab
                      _buildRecordTab(filteredTransactions, currencySymbol),
                      // Statistic Tab
                      _buildStatisticTab(filteredTransactions, currencySymbol),
                    ],
                  ),
                ),
                // Bottom Summary Sheet
                _buildBottomSummary(summary, currencySymbol),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildRecordTab(
    List<TransactionModel> transactions,
    String currencySymbol,
  ) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          'No records found for this period.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isExpense = transaction.type == TransactionType.expense;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isExpense
                  ? AppColors.pastelRed.withValues(alpha: 0.2)
                  : AppColors.pastelGreen.withValues(alpha: 0.2),
              child: Icon(
                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                color: isExpense ? AppColors.expense : AppColors.income,
              ),
            ),
            title: Text(
              transaction.categoryName ?? 'Uncategorized',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat(
                'MMM dd, yyyy HH:mm',
              ).format(transaction.date), // Added time
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              '${isExpense ? '-' : '+'}${CurrencyFormatter.format(transaction.amount, symbol: currencySymbol)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isExpense ? AppColors.expense : AppColors.income,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticTab(
    List<TransactionModel> transactions,
    String currencySymbol,
  ) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No data for statistics.'));
    }

    // Reuse TransactionChartSection logic roughly
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
            useComma: true, // Assuming default true
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
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(
    Map<String, double> summary,
    String currencySymbol,
  ) {
    final income = summary['income'] ?? 0.0;
    final expense = summary['expense'] ?? 0.0;
    final net = income - expense;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // Background slightly different
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.ledger.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.ledger.icon ?? Icons.account_balance_wallet,
                  color: widget.ledger.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ledger.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.ledger.remark != null &&
                      widget.ledger.remark!.isNotEmpty)
                    Text(
                      widget.ledger.remark!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
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
                  const Text(
                    'Expenses',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    CurrencyFormatter.format(expense, symbol: currencySymbol),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Income',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    CurrencyFormatter.format(income, symbol: currencySymbol),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.income,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Net: ', style: TextStyle(fontSize: 14)),
              Text(
                CurrencyFormatter.format(net, symbol: currencySymbol),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: net >= 0 ? AppColors.income : AppColors.expense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateSummary(List<TransactionModel> transactions) {
    double income = 0;
    double expense = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
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
          // Simple week checking logic
          // Start of week (Monday)
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
          return t.date.isAfter(
                _customDateRange!.start.subtract(const Duration(seconds: 1)),
              ) &&
              t.date.isBefore(
                _customDateRange!.end.add(const Duration(days: 1)),
              );
      }
    }).toList();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDateLabel() {
    switch (_timeRange) {
      case TransactionTimeRange.daily:
        return DateFormat('MMM dd, yyyy').format(_selectedDate);
      case TransactionTimeRange.weekly:
        return 'Week ${DateFormat('w').format(_selectedDate)}'; // Simplified
      case TransactionTimeRange.monthly:
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case TransactionTimeRange.annual:
        return DateFormat('yyyy').format(_selectedDate);
      case TransactionTimeRange.all:
        return 'All Time';
      case TransactionTimeRange.custom:
        if (_customDateRange != null) {
          return '${DateFormat('MMM dd').format(_customDateRange!.start)} - ${DateFormat('MMM dd').format(_customDateRange!.end)}';
        }
        return 'Custom';
    }
  }

  void _showTimeRangeMenu() async {
    // Reuse logic or simpler bottom sheet
    final result = await showModalBottomSheet<TransactionTimeRange>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeOption(ctx, 'Daily', TransactionTimeRange.daily),
          _buildTimeOption(ctx, 'Weekly', TransactionTimeRange.weekly),
          _buildTimeOption(ctx, 'Monthly', TransactionTimeRange.monthly),
          _buildTimeOption(ctx, 'Annual', TransactionTimeRange.annual),
          _buildTimeOption(ctx, 'All', TransactionTimeRange.all),
          // Custom not fully implemented in this quick pass
        ],
      ),
    );
    if (result != null) {
      setState(() => _timeRange = result);
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
      trailing: _timeRange == value
          ? const Icon(Icons.check, color: AppColors.textDark)
          : null,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ledger?'),
        content: Text(
          'Are you sure you want to delete "${widget.ledger.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(ledgerProvider.notifier).deleteLedger(widget.ledger.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // Exit details page
        // Assuming this might pop back to main list which will update automatically
      }
    }
  }
}
