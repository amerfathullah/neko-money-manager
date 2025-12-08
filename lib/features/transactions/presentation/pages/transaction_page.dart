import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../home/presentation/providers/ledger_provider.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../../../settings/presentation/providers/currency_provider.dart';
import '../../../../core/widgets/banner_ad_widget.dart';
import '../../../assets/presentation/providers/asset_provider.dart';

class TransactionPage extends ConsumerStatefulWidget {
  final TransactionModel? transaction;

  const TransactionPage({super.key, this.transaction});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _amount = '0';
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  String? _selectedLedgerId;
  String? _selectedDestinationLedgerId;
  String? _selectedAssetId;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);

    if (widget.transaction != null) {
      final t = widget.transaction!;
      _amount = t.amount.toString();
      // Remove trailing .0 if integer
      if (_amount.endsWith('.0')) {
        _amount = _amount.substring(0, _amount.length - 2);
      }
      _selectedDate = t.date;
      _selectedLedgerId = t.ledgerId;

      // Set tab index based on type
      int index = 0;
      switch (t.type) {
        case TransactionType.expense:
          index = 0;
          break;
        case TransactionType.income:
          index = 1;
          break;
        case TransactionType.transfer:
          index = 2;
          _selectedDestinationLedgerId = t.destinationLedgerId;
          break;
      }
      _tabController.index = index;
      _selectedAssetId = t.assetId;
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = null; // Reset category on tab change
        if (_tabController.index != 2) {
          _selectedDestinationLedgerId = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _onKeypadTap(String value) {
    setState(() {
      if (value == 'BACK') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (value == '.') {
        if (!_amount.contains('.')) {
          _amount += value;
        }
      } else {
        if (_amount == '0') {
          _amount = value;
        } else {
          _amount += value;
        }
      }
    });
  }

  Future<void> _submitTransaction() async {
    final amountVal = double.tryParse(_amount);
    if (amountVal == null || amountVal == 0) return;

    final ledgers = ref.read(ledgerProvider).value;
    if (ledgers == null || ledgers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No wallets available. Please create one first.'),
        ),
      );
      return;
    }

    if (_tabController.index != 2 && _selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    if (_tabController.index == 2) {
      if (_selectedDestinationLedgerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a destination wallet')),
        );
        return;
      }

      final sourceId = _selectedLedgerId ?? ledgers.first.id;
      if (_selectedDestinationLedgerId == sourceId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Destination wallet cannot be the same as source'),
          ),
        );
        return;
      }
    }

    final ledgerId = _selectedLedgerId ?? ledgers.first.id;
    final ledger = ledgers.firstWhere(
      (l) => l.id == ledgerId,
      orElse: () => ledgers.first,
    );

    final type = _tabController.index == 0
        ? TransactionType.expense
        : _tabController.index == 1
        ? TransactionType.income
        : TransactionType.transfer;

    String? destName;
    if (_selectedDestinationLedgerId != null) {
      try {
        final dest = ledgers.firstWhere(
          (l) => l.id == _selectedDestinationLedgerId,
        );
        destName = dest.name;
      } catch (_) {}
    }

    String? assetName;
    if (_selectedAssetId != null) {
      final assets = ref.read(assetProvider).value;
      if (assets != null) {
        try {
          assetName = assets.firstWhere((a) => a.id == _selectedAssetId).name;
        } catch (_) {}
      }
    }

    final transaction = TransactionModel(
      id:
          widget.transaction?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      ledgerId: ledger.id,
      categoryId: _selectedCategory?.id ?? '',
      ledgerName: ledger.name,
      categoryName: type == TransactionType.transfer
          ? 'Transfer'
          : _selectedCategory?.name,
      amount: amountVal,
      date: _selectedDate,
      type: type,
      destinationLedgerId: _selectedDestinationLedgerId,
      destinationLedgerName: destName,
      assetId: _selectedAssetId,
      assetName: assetName,
    );

    try {
      if (widget.transaction != null) {
        await ref
            .read(transactionProvider.notifier)
            .updateTransaction(widget.transaction!, transaction);
      } else {
        await ref
            .read(transactionProvider.notifier)
            .addTransaction(transaction);
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction Saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categoriesAsync = ref.watch(categoryProvider);
    final ledgersAsync = ref.watch(ledgerProvider);
    final currencyAsync = ref.watch(currencyProvider);
    final assetsAsync = ref.watch(assetProvider);
    final currencySymbol = currencyAsync.asData?.value ?? '\$';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction != null ? 'Edit Transaction' : 'New Transaction',
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: AppColors.textDark.withValues(alpha: 0.5),
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
            Tab(text: 'Transfer'),
          ],
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (allCategories) {
          if (_isInitialLoad && widget.transaction != null) {
            final t = widget.transaction!;
            try {
              if (t.categoryId.isNotEmpty) {
                _selectedCategory = allCategories.firstWhere(
                  (c) => c.id == t.categoryId,
                );
              }
            } catch (_) {
              // Category might have been deleted
            }
            _isInitialLoad = false;
          }

          List<Category> currentCategories = [];
          if (_tabController.index == 0) {
            currentCategories = allCategories
                .where((c) => c.type == CategoryType.expense)
                .toList();
          } else if (_tabController.index == 1) {
            currentCategories = allCategories
                .where((c) => c.type == CategoryType.income)
                .toList();
          }

          return Column(
            children: [
              // Amount Display
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                color: theme.scaffoldBackgroundColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currencySymbol,
                      style: TextStyle(
                        fontSize: 32,
                        color: AppColors.textDark.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _amount,
                      key: const Key('amountDisplay'),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A35) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Ledger Selector
                        ledgersAsync.when(
                          data: (ledgers) {
                            if (ledgers.isEmpty) return const SizedBox.shrink();

                            // Ensure valid selection
                            final effectiveLedgerId =
                                _selectedLedgerId ??
                                (ledgers.isNotEmpty ? ledgers.first.id : null);

                            // Check if current selection exists in list (robustness against deletions)
                            final ledgerExists = ledgers.any(
                              (l) => l.id == effectiveLedgerId,
                            );
                            final currentLedgerId = ledgerExists
                                ? effectiveLedgerId
                                : ledgers.first.id;

                            // Ensure destination ledger is valid too
                            if (_selectedDestinationLedgerId != null) {
                              if (!ledgers.any(
                                (l) => l.id == _selectedDestinationLedgerId,
                              )) {
                                // Reset if not found
                              }
                            }

                            final validDestId =
                                _selectedDestinationLedgerId != null &&
                                    ledgers.any(
                                      (l) =>
                                          l.id == _selectedDestinationLedgerId,
                                    )
                                ? _selectedDestinationLedgerId
                                : null;

                            return Column(
                              children: [
                                InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'From Wallet',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: currentLedgerId,
                                      isDense: true,
                                      isExpanded: true,
                                      items: ledgers.map((ledger) {
                                        return DropdownMenuItem(
                                          value: ledger.id,
                                          child: Text(ledger.name),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedLedgerId = val;
                                        });
                                      },
                                    ),
                                  ),
                                ),

                                if (_tabController.index == 2) ...[
                                  const SizedBox(height: 16),
                                  InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'To Wallet',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: validDestId,
                                        hint: const Text(
                                          'Select Destination Wallet',
                                        ),
                                        isDense: true,
                                        isExpanded: true,
                                        items: ledgers
                                            .where(
                                              (l) => l.id != currentLedgerId,
                                            )
                                            .map((ledger) {
                                              return DropdownMenuItem(
                                                value: ledger.id,
                                                child: Text(ledger.name),
                                              );
                                            })
                                            .toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedDestinationLedgerId = val;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (err, stack) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 16),

                        // Asset Selector (Category/Tag)
                        assetsAsync.when(
                          data: (assets) {
                            if (assets.isEmpty) return const SizedBox.shrink();

                            return Column(
                              children: [
                                InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Asset Category (Optional)',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedAssetId,
                                      hint: const Text('Select Asset Category'),
                                      isDense: true,
                                      isExpanded: true,
                                      items: [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('None'),
                                        ),
                                        ...assets.map((asset) {
                                          return DropdownMenuItem<String>(
                                            value: asset.id,
                                            child: Text(asset.name),
                                          );
                                        }),
                                      ],
                                      onChanged: (val) {
                                        setState(() => _selectedAssetId = val);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (err, stack) => const SizedBox.shrink(),
                        ),

                        // Category Selector
                        if (_tabController.index != 2)
                          SizedBox(
                            height: 50,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: currentCategories.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final category = currentCategories[index];
                                final isSelected =
                                    _selectedCategory?.id == category.id;

                                return ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        category.icon,
                                        size: 18,
                                        color: isSelected
                                            ? Colors.white
                                            : category.color,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(category.name),
                                    ],
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(
                                      () => _selectedCategory = selected
                                          ? category
                                          : null,
                                    );
                                  },
                                  selectedColor: category.color,
                                  backgroundColor: category.color.withValues(
                                    alpha: 0.1,
                                  ),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textDark,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (_tabController.index != 2)
                          const SizedBox(height: 16),

                        // Date Picker
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: AppColors.textDark,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy',
                                ).format(_selectedDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Keypad
                        _buildKeypad(),

                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _submitTransaction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save Transaction',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const BannerAdWidget(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 12),
        _buildKeypadRow(['.', '0', 'BACK']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        return InkWell(
          onTap: () => _onKeypadTap(key),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withValues(alpha: 0.1),
            ),
            child: key == 'BACK'
                ? const Icon(Icons.backspace_outlined)
                : Text(
                    key,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }
}
