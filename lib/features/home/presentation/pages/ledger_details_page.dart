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
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/data/models/category.dart';
import '../../../assets/presentation/providers/asset_provider.dart';
import '../../../assets/data/models/asset.dart';

class LedgerDetailsPage extends ConsumerStatefulWidget {
  final Ledger ledger;

  const LedgerDetailsPage({super.key, required this.ledger});

  @override
  ConsumerState<LedgerDetailsPage> createState() => _LedgerDetailsPageState();
}

class _LedgerDetailsPageState extends ConsumerState<LedgerDetailsPage> {
  final TransactionTimeRange _timeRange = TransactionTimeRange.monthly;
  final DateTime _selectedDate = DateTime.now();
  DateTimeRange? _customDateRange;
  int _selectedTabIndex = 0; // 0: Record, 1: Statistic

  @override
  Widget build(BuildContext context) {
    final currencyAsync = ref.watch(currencyProvider);
    final currencySymbol = currencyAsync.asData?.value ?? '\$';

    final transactionsAsync = ref.watch(
      ledgerTransactionsProvider(widget.ledger.id),
    );
    final categories = ref.watch(categoryProvider).asData?.value ?? [];
    final assets = ref.watch(assetProvider).asData?.value ?? [];
    final ledgers = ref.watch(ledgerProvider).asData?.value ?? [];

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
                                categories,
                                assets,
                                ledgers,
                              )
                            : _buildStatisticTab(
                                filteredTransactions,
                                currencySymbol,
                              ),
                      ),

                      // Bottom Summary (Only for Record Tab usually, but image implies it's persistent or attached)
                      // Image shows it on "Record" tab.
                      if (_selectedTabIndex == 0)
                        _buildBottomSummary(summary, currencySymbol),
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
      child: InkWell(
        onTap: _showTimeRangeMenu,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getDateLabel(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordLayout(
    List<TransactionModel> transactions,
    String currencySymbol,
    List<Category> categories,
    List<Asset> assets,
    List<Ledger> ledgers,
  ) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text('No records', style: TextStyle(color: Colors.grey)),
      );
    }

    // Group transactions by Date
    final Map<String, List<TransactionModel>> grouped = {};
    for (var t in transactions) {
      final key = DateFormat('yyyyMMdd').format(t.date);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(t);
    }

    // Sort dates descending
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dayTransactions = grouped[dateKey]!;
        final date = dayTransactions.first.date;

        // Calculate Day Totals
        double income = 0;
        double expense = 0;
        for (var t in dayTransactions) {
          if (t.type == TransactionType.income) income += t.amount;
          if (t.type == TransactionType.expense) expense += t.amount;
        }

        return Column(
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                      children: [
                        TextSpan(text: '${DateFormat('MMM dd').format(date)} '),
                        TextSpan(
                          text: DateFormat('EEE').format(date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (income > 0)
                    Text(
                      '+${CurrencyFormatter.format(income, symbol: '')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  if (income > 0 && expense > 0) const SizedBox(width: 8),
                  if (expense > 0)
                    Text(
                      '-${CurrencyFormatter.format(expense, symbol: '')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.expense,
                      ),
                    ),
                ],
              ),
            ),
            // Transactions Timeline
            ...dayTransactions.map(
              (t) => _buildTimelineItem(
                t,
                currencySymbol,
                categories,
                assets,
                ledgers,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineItem(
    TransactionModel t,
    String currencySymbol,
    List<Category> categories,
    List<Asset> assets,
    List<Ledger> ledgers,
  ) {
    final isExpense = t.type == TransactionType.expense;
    final category = categories.firstWhere(
      (c) => c.id == t.categoryId,
      orElse: () => Category(
        id: 'unknown',
        name: t.categoryName ?? 'Unknown',
        iconCodePoint: Icons.help_outline.codePoint,
        colorValue: Colors.grey.toARGB32(),
        type: CategoryType.expense,
      ),
    );
    final asset = assets.firstWhere(
      (a) => a.id == t.assetId,
      orElse: () => Asset(
        id: 'unknown',
        name: t.assetName ?? 'Unknown',
        colorValue: Colors.blueGrey.toARGB32(),
      ),
    );

    // Determine Asset Icon (Simulated logic as Asset doesn't have icon yet)
    // Use generic savings/bank icon based on name or default
    IconData assetIcon = Icons.account_balance;
    if (asset.name.toLowerCase().contains('cash')) assetIcon = Icons.wallet;
    if (asset.name.toLowerCase().contains('card')) {
      assetIcon = Icons.credit_card;
    }
    if (asset.name.toLowerCase().contains('sav')) assetIcon = Icons.savings;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time Column (Left)
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Text(
                  DateFormat('HH:mm').format(t.date),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 4, // Thicker line
                    color: category.color.withValues(
                      alpha: 0.3,
                    ), // Line matches category? Or just standard pastel
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
                // Arrow
                Icon(Icons.play_arrow, size: 12, color: category.color),
              ],
            ),
          ),

          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: category.color.withValues(
                  alpha: 0.2,
                ), // Background follows category color
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  // Large Category Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors
                          .white, // White bg for icon circle? Or just icon? Image shows stark icon.
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon, size: 32, color: category.color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Name
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Bottom Row: Time Pill, Asset, Ledger, etc.
                        Row(
                          children: [
                            // Time Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: category.color.withValues(
                                  alpha: 0.4,
                                ), // Darker than bg
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DateFormat('HH:mm').format(t.date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Asset Icon
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: asset.color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                assetIcon,
                                size: 16,
                                color: asset.color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Ledger Icon
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: widget.ledger.color.withValues(
                                  alpha: 0.2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.ledger.icon,
                                size: 16,
                                color: widget.ledger.color,
                              ),
                            ),
                            // Reimbursement Icon
                            if (t.isReimbursement) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.work,
                                  size: 16,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                            // Bookmark Icon (Star)
                            if (t.isBookmarked) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.star,
                                size: 18,
                                color: Colors.amber,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Amount (Right side ignored as per user, but kept for function)
                  Text(
                    '${isExpense ? '-' : '+'}${CurrencyFormatter.format(t.amount, symbol: '')}', // Removing symbol per image look?
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18, // Larger
                      color: isExpense
                          ? const Color(0xFFD32F2F)
                          : AppColors
                                .textDark, // Red for expense, Dark for income
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

  Widget _buildStatisticTab(
    List<TransactionModel> transactions,
    String currencySymbol,
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
    final expense = summary['expense'] ?? 0.0;
    final income = summary['income'] ?? 0.0;
    final count = 356; // Placeholder or calculate count

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
                child: Icon(widget.ledger.icon, color: widget.ledger.color),
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
                    CurrencyFormatter.format(expense, symbol: ''),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.expense,
                    ),
                  ),
                  Text(
                    '$count ≡',
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
                    CurrencyFormatter.format(income, symbol: ''),
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
    if (_timeRange == TransactionTimeRange.monthly) {
      return DateFormat('MMMM yyyy').format(_selectedDate);
    }
    return 'Date Filter'; // Simplification for now
  }

  void _showTimeRangeMenu() {
    // Implement Time Range Logic if needed, or stick to monthly default
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
