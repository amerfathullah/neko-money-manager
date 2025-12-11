import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../settings/presentation/providers/currency_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/ledger_provider.dart';

import '../../../transactions/presentation/widgets/transaction_timeline.dart';

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
    final settingsAsync = ref.watch(settingsProvider);
    final currencySymbol = currencyAsync.asData?.value ?? '\$';

    // Settings defaults
    final settings = settingsAsync.asData?.value ?? const SettingsState();
    final startDay = settings.monthlyStartDate;
    final useComma = settings.useCommaSeparator;

    // Calculate totals & Filter Transactions
    double currentMonthExpense = 0;
    double currentMonthIncome = 0;

    // Grouped transactions for display (Date -> List<Transaction>)
    // Map<String, List<TransactionModel>> groupedTransactions = {}; // Removed
    // List<String> sortedDates = []; // Removed

    // Calculate Current Month Range based on startDay
    final now = DateTime.now();
    DateTime rangeStart;
    DateTime rangeEnd;

    if (now.day >= startDay) {
      rangeStart = DateTime(now.year, now.month, startDay);
      rangeEnd = DateTime(
        now.year,
        now.month + 1,
        startDay,
      ).subtract(const Duration(days: 1));
    } else {
      rangeStart = DateTime(now.year, now.month - 1, startDay);
      rangeEnd = DateTime(
        now.year,
        now.month,
        startDay,
      ).subtract(const Duration(days: 1));
    }
    // To handle End of Day for comparison or just date parts
    // Best to compare just Date parts if time doesn't matter, but transactions have time.
    // Ideally: t.date >= rangeStart (at 00:00) && t.date <= rangeEnd (at 23:59:59)
    final rangeEndEod = DateTime(
      rangeEnd.year,
      rangeEnd.month,
      rangeEnd.day,
      23,
      59,
      59,
    );

    // Format current month for display (e.g. "Dec" or "Nov-Dec" if needed, but "Dec" is standard)
    // Actually if custom date, maybe display "Period"? keeping it simple: Month Name of the majority?
    // Or just "Current Period". User requested "Monthly Start Date".
    // Usually standard month name of the *End* date is used.
    final currentMonthName = DateFormat('MMM').format(rangeEnd);

    List<TransactionModel> ledgerFilteredTransactions = [];

    if (transactionsAsync.hasValue) {
      var allTransactions = transactionsAsync.value!;

      // 1. Filter by Ledger
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

        // A. Current Month Totals Calculation (Custom Period)
        bool isInCurrentPeriod =
            t.date.isAfter(rangeStart.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(rangeEndEod.add(const Duration(seconds: 1)));

        if (isInCurrentPeriod) {
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

        // B. 3-Month History Grouping (Logic removed as TransactionTimeline handles grouping)
        /*
        // Check if transaction is within last ~3 months
        if (t.date.isAfter(threeMonthsAgo.subtract(const Duration(days: 1)))) {
          final dateKey = DateFormat('yyyyMMdd').format(t.date);
          if (!groupedTransactions.containsKey(dateKey)) {
            groupedTransactions[dateKey] = [];
            sortedDates.add(dateKey);
          }
          groupedTransactions[dateKey]!.add(t);
        }
        */
      }

      // Sort dates descending (newest first)
      // sortedDates.sort((a, b) => b.compareTo(a));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Cream background
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Background Elements (e.g., Cat Top Right)
            Positioned(
              top: -20,
              right: -20,
              child: Opacity(
                opacity: 0.2,
                child: Icon(
                  Icons.pets,
                  size: 180,
                  color: AppColors.pastelOrange,
                ),
              ),
            ),

            // Top Content (Fixed)
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
                                          Icons.book,
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
                        label: '$currentMonthName · Expenses',
                        amount: currentMonthExpense,
                        currency: currencySymbol,
                        isExpense: true,
                        useComma: useComma,
                      ),
                      _SummaryItem(
                        label: '$currentMonthName · Income',
                        amount: currentMonthIncome,
                        currency: currencySymbol,
                        isExpense: false,
                        useComma: useComma,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Draggable Sheet (Peek Cat & Container)
            DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.7,
              maxChildSize: 1.0,
              builder: (context, scrollController) {
                return Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // The main white/cream container
                    Container(
                      margin: const EdgeInsets.only(top: 25),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFFCF0),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 40,
                                ), // Space for cat overlap
                                // Quick Actions Grid
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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

                          if (ledgerFilteredTransactions
                              .isEmpty) // Using ledgerFilteredTransactions instead of sortedDates (logic slightly diff but close enough for main list)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.savings_outlined,
                                    size: 120,
                                    color: AppColors.pastelBlue,
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
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 120),
                                child: TransactionTimeline(
                                  transactions: ledgerFilteredTransactions,
                                  currencySymbol: currencySymbol,
                                  useComma: useComma,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  backgroundColor: const Color(0xFFFFFCF0),
                                ),
                              ),
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
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final bool isExpense;
  final bool useComma;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.currency,
    required this.isExpense,
    required this.useComma,
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
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isExpense ? Icons.arrow_drop_down : Icons.arrow_drop_up,
              color: isExpense ? AppColors.expense : AppColors.textDark,
            ),
          ],
        ),
        Text(
          CurrencyFormatter.format(
            amount,
            symbol: isExpense ? currency : '',
            useGrouping: useComma,
          ),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textDark.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
