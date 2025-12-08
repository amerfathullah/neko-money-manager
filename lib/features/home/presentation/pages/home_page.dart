import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../settings/presentation/providers/currency_provider.dart';
import '../providers/ledger_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _selectedLedgerId; // null means "All Ledgers"

  @override
  Widget build(BuildContext context) {
    final ledgersAsync = ref.watch(ledgerProvider);
    final transactionsAsync = ref.watch(transactionProvider);
    final currencyAsync = ref.watch(currencyProvider);
    final currencySymbol = currencyAsync.asData?.value ?? '\$';

    // Calculate totals & Filter Transactions
    double currentMonthExpense = 0;
    double currentMonthIncome = 0;

    // Grouped transactions for display (Date -> List<Transaction>)
    Map<String, List<TransactionModel>> groupedTransactions = {};
    List<String> sortedDates = [];

    if (transactionsAsync.hasValue) {
      final now = DateTime.now();
      // Calculate start date for 3 months history (e.g. 90 days ago or start of 2 months ago)
      final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);

      var allTransactions = transactionsAsync.asData!.value;

      // 1. Filter by Ledger
      List<TransactionModel> ledgerFilteredTransactions = [];
      if (_selectedLedgerId != null) {
        ledgerFilteredTransactions = allTransactions.where((t) {
          if (t.type.toString().contains('transfer')) {
            return t.ledgerId == _selectedLedgerId ||
                t.destinationLedgerId == _selectedLedgerId;
          }
          return t.ledgerId == _selectedLedgerId;
        }).toList();
      } else {
        ledgerFilteredTransactions = allTransactions;
      }

      // 2. Process Transactions
      for (var t in ledgerFilteredTransactions) {
        final isExpense = t.type.toString().contains('expense');
        final isIncome = t.type.toString().contains('income');
        final isTransfer = t.type.toString().contains('transfer');

        // A. Current Month Totals Calculation
        if (t.date.year == now.year && t.date.month == now.month) {
          if (_selectedLedgerId == null) {
            // Global View
            if (isExpense) {
              currentMonthExpense += t.amount;
            } else if (isIncome) {
              currentMonthIncome += t.amount;
            }
            // Transfers ignored globally
          } else {
            // Specific Ledger View
            if (isExpense) {
              if (t.ledgerId == _selectedLedgerId) {
                currentMonthExpense += t.amount;
              }
            } else if (isIncome) {
              if (t.ledgerId == _selectedLedgerId) {
                currentMonthIncome += t.amount;
              }
            } else if (isTransfer) {
              if (t.ledgerId == _selectedLedgerId) {
                currentMonthExpense += t.amount; // Outgoing
              } else if (t.destinationLedgerId == _selectedLedgerId) {
                currentMonthIncome += t.amount; // Incoming
              }
            }
          }
        }

        // B. 3-Month History Grouping
        // Check if transaction is within last ~3 months
        if (t.date.isAfter(threeMonthsAgo.subtract(const Duration(days: 1)))) {
          final dateKey = DateFormat('yyyyMMdd').format(t.date);
          if (!groupedTransactions.containsKey(dateKey)) {
            groupedTransactions[dateKey] = [];
            sortedDates.add(dateKey);
          }
          groupedTransactions[dateKey]!.add(t);
        }
      }

      // Sort dates descending (newest first)
      sortedDates.sort((a, b) => b.compareTo(a));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Cream background
      body: SafeArea(
        child: Stack(
          children: [
            // Background Elements (e.g. Cat Top Right)
            Positioned(
              top: 0,
              right: 0,
              child: Opacity(
                opacity: 0.8,
                child: Image.asset(
                  'assets/images/cat_top_right.png',
                  width: 120,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.pets,
                    size: 80,
                    color: AppColors.pastelOrange,
                  ),
                ),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 16),

                // Top Bar: Ledger Dropdown | Budget
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      ledgersAsync.when(
                        data: (ledgers) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pastelOrange.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _selectedLedgerId,
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
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.book,
                                        size: 20,
                                        color: AppColors.textDark,
                                      ),
                                      SizedBox(width: 8),
                                      Text('All ledgers'),
                                    ],
                                  ),
                                ),
                                ...ledgers.map(
                                  (l) => DropdownMenuItem<String?>(
                                    value: l.id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet,
                                          size: 20,
                                          color: AppColors.textDark,
                                        ),
                                        SizedBox(width: 8),
                                        Text(l.name),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedLedgerId = val;
                                });
                              },
                            ),
                          ),
                        ),
                        loading: () => const SizedBox(width: 120, height: 40),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),

                      const Spacer(),

                      _TopPill(
                        icon: Icons.attach_money,
                        label: 'Budget',
                        color: AppColors.pastelGreen,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Income / Expense Indicators (Current Month Only)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SummaryItem(
                        label: 'Dec · Expenses',
                        amount: currentMonthExpense,
                        currency: currencySymbol,
                        isExpense: true,
                      ),
                      _SummaryItem(
                        label: 'Dec · Income',
                        amount: currentMonthIncome,
                        currency: currencySymbol,
                        isExpense: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Peek Cat & Container
                Expanded(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // The main white/cream container
                      Container(
                        margin: const EdgeInsets.only(top: 25),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFFDF5),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  const SizedBox(
                                    height: 40,
                                  ), // Space for cat overlap
                                  // Quick Actions Grid
                                  SizedBox(
                                    height: 90,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      children: const [
                                        _QuickAction(
                                          icon: Icons.book,
                                          label: 'Ledger',
                                          color: AppColors.pastelOrange,
                                        ),
                                        _QuickAction(
                                          icon: Icons.calendar_today,
                                          label: 'Recurring',
                                          color: AppColors.pastelBlue,
                                        ),
                                        _QuickAction(
                                          icon: Icons.lunch_dining,
                                          label: 'Category',
                                          color: AppColors.pastelRed,
                                        ),
                                        _QuickAction(
                                          icon: Icons.work,
                                          label: 'Reimburse',
                                          color: AppColors.pastelPurple,
                                        ),
                                        _QuickAction(
                                          icon: Icons.bookmark,
                                          label: 'Bookmarks',
                                          color: AppColors.pastelBlue,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),

                            if (sortedDates.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/cat_balloons.png',
                                      height: 200,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.image,
                                                size: 100,
                                                color: AppColors.pastelBlue,
                                              ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Welcome',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'There is no record at the moment\nstart your first record now.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.textDark.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    if (index >= sortedDates.length) {
                                      return const SizedBox(
                                        height: 80,
                                      ); // Bottom padding
                                    }

                                    final dateKey = sortedDates[index];
                                    final transactions =
                                        groupedTransactions[dateKey]!;
                                    final date = transactions
                                        .first
                                        .date; // All represent the same day

                                    // Calculate Daily Totals
                                    double dailyIncome = 0;
                                    double dailyExpense = 0;
                                    for (var t in transactions) {
                                      // Simplified logic for daily summary
                                      if (t.type == TransactionType.income) {
                                        dailyIncome += t.amount;
                                      } else if (t.type ==
                                          TransactionType.expense) {
                                        dailyExpense += t.amount;
                                      }
                                      // Transfers - logic depends on view, but for list display usually just show activity.
                                      // If we want exact daily balance change for 'Selected Wallet', we'd sum signed amounts.
                                      // The reference image shows: "+500 -0".
                                      else if (t.type ==
                                          TransactionType.transfer) {
                                        if (_selectedLedgerId != null) {
                                          if (t.ledgerId == _selectedLedgerId) {
                                            dailyExpense += t.amount;
                                          } else if (t.destinationLedgerId ==
                                              _selectedLedgerId) {
                                            dailyIncome += t.amount;
                                          }
                                        }
                                      }
                                    }

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Date Header
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            24,
                                            16,
                                            24,
                                            8,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    DateFormat(
                                                      'MMM dd',
                                                    ).format(date),
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.textDark,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      DateFormat(
                                                        'EEE',
                                                      ).format(date),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  if (dailyIncome > 0)
                                                    Text(
                                                      '+${CurrencyFormatter.format(dailyIncome, symbol: '')}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors.income,
                                                      ),
                                                    ),
                                                  if (dailyIncome > 0 &&
                                                      dailyExpense > 0)
                                                    const SizedBox(width: 8),
                                                  if (dailyExpense > 0)
                                                    Text(
                                                      '-${CurrencyFormatter.format(dailyExpense, symbol: '')}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            AppColors.expense,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Transactions
                                        ...transactions.map((t) {
                                          final isExpense =
                                              t.type == TransactionType.expense;
                                          final isIncome =
                                              t.type == TransactionType.income;
                                          final isTransfer =
                                              t.type ==
                                              TransactionType.transfer;

                                          Color color = AppColors.textDark;
                                          String prefix = '';

                                          if (isExpense) {
                                            prefix = '-';
                                            color = AppColors.expense;
                                          } else if (isIncome) {
                                            prefix = '+';
                                            color = AppColors.income;
                                          } else if (isTransfer) {
                                            if (_selectedLedgerId != null &&
                                                t.ledgerId ==
                                                    _selectedLedgerId) {
                                              prefix = '-';
                                              color = AppColors.expense;
                                            } else if (_selectedLedgerId !=
                                                    null &&
                                                t.destinationLedgerId ==
                                                    _selectedLedgerId) {
                                              prefix = '+';
                                              color = AppColors.income;
                                            }
                                          }

                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 6,
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFFFF8E1,
                                              ), // Light cream card
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                // Icon
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors
                                                        .amber[100], // Placeholder color
                                                    // color: Color(categoryColor).withValues(alpha: 0.2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    // t.categoryIcon ??
                                                    isExpense
                                                        ? Icons.lunch_dining
                                                        : Icons.attach_money,
                                                    color: Colors
                                                        .brown, // Placeholder
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        t.categoryName ??
                                                            (isTransfer
                                                                ? 'Transfer'
                                                                : 'Uncategorized'),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: AppColors
                                                              .textDark,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            DateFormat(
                                                              'HH:mm',
                                                            ).format(t.date),
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          if (t.note != null &&
                                                              t
                                                                  .note!
                                                                  .isNotEmpty) ...[
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Icon(
                                                              Icons
                                                                  .sticky_note_2,
                                                              size: 14,
                                                              color: Colors
                                                                  .blue[300],
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  '$prefix${CurrencyFormatter.format(t.amount, symbol: '')}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: color,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  },
                                  childCount:
                                      sortedDates.length +
                                      1, // +1 for bottom padding
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Peeking Cat at Top
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Re-using _TopPill, _SummaryItem, _QuickAction (Redefined to avoid missing referenced classes if I replaced whole file)
class _TopPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TopPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textDark),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final bool isExpense;
  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.currency,
    required this.isExpense,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isExpense ? Icons.arrow_drop_down : Icons.arrow_drop_up,
              color: isExpense ? AppColors.pastelRed : AppColors.textDark,
            ),
          ],
        ),
        Text(
          CurrencyFormatter.format(amount, symbol: ''),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isExpense ? AppColors.pastelRed : AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
