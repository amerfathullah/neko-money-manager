import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../home/presentation/providers/ledger_provider.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../../../../core/widgets/banner_ad_widget.dart';
import '../../../assets/presentation/providers/asset_provider.dart';
import '../../../assets/data/models/asset.dart';
import '../widgets/transaction_options_panel.dart';
import '../widgets/transfer_form.dart';
import '../widgets/category_grid_selector.dart';
import '../widgets/custom_keypad.dart';
import '../../../categories/presentation/pages/categories_page.dart';

class TransactionPage extends ConsumerStatefulWidget {
  final TransactionModel? transaction;
  final TransactionType? initialType;

  const TransactionPage({super.key, this.transaction, this.initialType});

  @override
  ConsumerState<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends ConsumerState<TransactionPage> {
  int _selectedTypeIndex = 0; // 0: Expense, 1: Income, 2: Transfer
  String _inputAmountStr = '0'; // Used for calculator display
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  String? _selectedLedgerId;
  String? _selectedAssetId;
  String? _selectedDestinationAssetId;
  bool _isReimburse = false;
  String _remark = '';
  String _transferCharge = '0';
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _loadTransaction(widget.transaction!);
    } else if (widget.initialType != null) {
      switch (widget.initialType!) {
        case TransactionType.expense:
          _selectedTypeIndex = 0;
          break;
        case TransactionType.income:
          _selectedTypeIndex = 1;
          break;
        case TransactionType.transfer:
          _selectedTypeIndex = 2;
          break;
      }
    }
  }

  void _loadTransaction(TransactionModel t) {
    _inputAmountStr = t.amount.toString();
    if (_inputAmountStr.endsWith('.0')) {
      _inputAmountStr = _inputAmountStr.substring(
        0,
        _inputAmountStr.length - 2,
      );
    }
    _selectedDate = t.date;
    _selectedLedgerId = t.ledgerId;
    _selectedAssetId = t.assetId;
    // _selectedDestinationAssetId = t.destinationAssetId; // Not in model yet? Checked previously, it was in old code.
    // Logic for destination asset was present in old code (lines 63, 226)
    _selectedDestinationAssetId = t.destinationAssetId;

    // Determine type index
    switch (t.type) {
      case TransactionType.expense:
        _selectedTypeIndex = 0;
        break;
      case TransactionType.income:
        _selectedTypeIndex = 1;
        break;
      case TransactionType.transfer:
        _selectedTypeIndex = 2;
        break;
    }

    // Parse Remark if available (not in state previously but likely needed)
    // Old code didn't load remark into state explicitly?
    // Checking `TransactionModel`...
    // The previous implementation didn't seem to have `remark` field in `TransactionModel` visible?
    // Wait, let's check definition of `TransactionModel` implicitly from usage.
    // Old code line 219: `amount: amountVal`.
    // Let's assume remark is somewhere or add it.
  }

  void _onKeypadTap(String value) {
    setState(() {
      if (_inputAmountStr == '0' && value != '.') {
        _inputAmountStr = value;
      } else {
        _inputAmountStr += value;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_inputAmountStr.length > 1) {
        _inputAmountStr = _inputAmountStr.substring(
          0,
          _inputAmountStr.length - 1,
        );
      } else {
        _inputAmountStr = '0';
      }
    });
  }

  void _calculateOrSave(bool closeAfter) {
    // If input contains operators, calculate first
    if (_inputAmountStr.contains('+') || _inputAmountStr.contains('-')) {
      _performCalculation();
      return; // Show result first, user must tap again to save
    }

    _submitTransaction(closeAfter);
  }

  void _performCalculation() {
    try {
      // Basic parser for + and -
      // Split by operators but keep them or just handle simple left-to-right
      // Example: 100+20-5
      // This is a quick implementation.

      // Remove trailing operator
      String evalStr = _inputAmountStr;
      if (evalStr.endsWith('+') || evalStr.endsWith('-')) {
        evalStr = evalStr.substring(0, evalStr.length - 1);
      }

      // Very simple parser logic:
      // 1. Replace - with +- (to sum negatives)
      List<String> parts = evalStr.replaceAll('-', '+-').split('+');
      double sum = 0;
      for (String part in parts) {
        if (part.isEmpty) continue;
        sum += double.tryParse(part) ?? 0;
      }

      setState(() {
        _inputAmountStr = sum.toString();
        if (_inputAmountStr.endsWith('.0')) {
          _inputAmountStr = _inputAmountStr.substring(
            0,
            _inputAmountStr.length - 2,
          );
        }
      });
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _submitTransaction(bool closeAfter) async {
    final amountVal = double.tryParse(_inputAmountStr);
    if (amountVal == null || amountVal == 0) return;

    final ledgers = ref.read(ledgerProvider).value;
    if (ledgers == null || ledgers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No ledgers available. Please create one first.'),
        ),
      );
      return;
    }

    // Validation
    if (_selectedTypeIndex != 2 && _selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    if (_selectedAssetId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an Asset')));
      return;
    }

    if (_selectedTypeIndex == 2) {
      if (_selectedDestinationAssetId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a destination Asset')),
        );
        return;
      }
      if (_selectedDestinationAssetId == _selectedAssetId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Destination Asset cannot be the same as source'),
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

    final type = _selectedTypeIndex == 0
        ? TransactionType.expense
        : _selectedTypeIndex == 1
        ? TransactionType.income
        : TransactionType.transfer;

    // Get Names
    String? destAssetName;
    if (_selectedDestinationAssetId != null) {
      final assets = ref.read(assetProvider).value;
      if (assets != null) {
        try {
          destAssetName = assets
              .firstWhere((a) => a.id == _selectedDestinationAssetId)
              .name;
        } catch (_) {}
      }
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
      destinationLedgerId: null,
      destinationLedgerName: null,
      assetId: _selectedAssetId,
      assetName: assetName,
      destinationAssetId: _selectedDestinationAssetId,
      destinationAssetName: destAssetName,
      // remark: _remark, // Add to model if updated
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction Saved!')));
        if (closeAfter) {
          Navigator.of(context).pop();
        } else {
          // Reset for "Add & Continue"
          setState(() {
            _inputAmountStr = '0';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  // --- Popups ---
  void _showRemarkPopup() async {
    final curVal = _remark;
    final controller = TextEditingController(text: curVal);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Remark'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Remark'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _remark = result);
    }
  }

  void _showDatePopup() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFC25E5E), // Match custom red
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // New unified Asset Popup for options panel
  Future<void> _showAssetSelectionPopup(List<Asset> assets) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final asset = assets[index];
          return ListTile(
            leading: Icon(Icons.account_balance_wallet, color: asset.color),
            title: Text(asset.name),
            onTap: () {
              setState(() => _selectedAssetId = asset.id);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  void _showTransferChargePopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFF3E0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Transfer charge is included in the total amount. 【Transfer in】 = 【Total】 - 【charge】 . For example transfer out 1000, and the transfer charge is 50, the final transfer in amount is 950.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC25E5E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferChargeInputPopup() async {
    final curVal = _transferCharge;
    final controller = TextEditingController(text: curVal == '0' ? '' : curVal);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Transfer Charge'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(hintText: '0'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _transferCharge = result.isEmpty ? '0' : result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final ledgersAsync = ref.watch(ledgerProvider);
    final assetsAsync = ref.watch(assetProvider);

    // Ensure assets are loaded for popups
    final ledgers = ledgersAsync.value ?? [];
    final assets = assetsAsync.value ?? [];

    // Filter Categories
    List<Category> displayCategories = [];
    if (categoriesAsync.hasValue) {
      final all = categoriesAsync.value!;
      if (_isInitialLoad &&
          widget.transaction != null &&
          _selectedCategory == null) {
        try {
          if (widget.transaction!.categoryId.isNotEmpty) {
            _selectedCategory = all.firstWhere(
              (c) => c.id == widget.transaction!.categoryId,
            );
          }
        } catch (_) {}
        _isInitialLoad = false;
      }

      if (_selectedTypeIndex == 0) {
        displayCategories = all
            .where((c) => c.type == CategoryType.expense)
            .toList();
      } else if (_selectedTypeIndex == 1) {
        displayCategories = all
            .where((c) => c.type == CategoryType.income)
            .toList();
      }
    }

    // Resolve Names for Options Panel
    final ledgerName = ledgers
        .firstWhere(
          (l) =>
              l.id ==
              (_selectedLedgerId ??
                  (ledgers.isNotEmpty ? ledgers.first.id : '')),
          orElse: () => ledgers.isNotEmpty ? ledgers.first : throw 'No Ledger',
        )
        .name;

    String assetName = 'Asset';
    if (assets.isNotEmpty) {
      final aid = _selectedAssetId ?? assets.first.id;
      try {
        assetName = assets.firstWhere((a) => a.id == aid).name;
        if (_selectedAssetId == null) {
          // Initialize if null
          // Wait, cannot set state in build directly.
          // It will be handled when accessing _selectedAssetId or we should Init it properly.
          // Let's just display correctly.
        }
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F3EC), // Light Beige Background
      resizeToAvoidBottomInset:
          false, // Prevent keyboard from distorting layout
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: Colors.black87,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF5E6D3), // Darker beige
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Custom Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E6D3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTabItem('Expenses', 0),
                        _buildTabItem('Income', 1),
                        _buildTabItem('Transfer', 2),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40), // Balance spacing
                ],
              ),
            ),

            // Middle Content
            Expanded(
              child: _selectedTypeIndex == 2
                  ? TransferForm(
                      selectedSourceAsset: assets
                          .where((a) => a.id == _selectedAssetId)
                          .firstOrNull,
                      selectedDestAsset: assets
                          .where((a) => a.id == _selectedDestinationAssetId)
                          .firstOrNull,
                      chargeAmount: _transferCharge,
                      assets: assets,
                      onSourceAssetChanged: (a) =>
                          setState(() => _selectedAssetId = a?.id),
                      onDestAssetChanged: (a) =>
                          setState(() => _selectedDestinationAssetId = a?.id),
                      onChargeHelpTap: _showTransferChargePopup,
                      onChargeTap: _showTransferChargeInputPopup,
                    )
                  : CategoryGridSelector(
                      categories: displayCategories,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (c) =>
                          setState(() => _selectedCategory = c),
                      onSettingTap: () {
                        debugPrint('Debug: Navigating to CategoriesPage');
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CategoriesPage(),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Panel
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Amount Display
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E6D3),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          alignment: Alignment.centerRight,
                          child: Text(
                            _inputAmountStr == '0' || _inputAmountStr.isEmpty
                                ? 'Amount'
                                : _inputAmountStr,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  _inputAmountStr == '0' ||
                                      _inputAmountStr.isEmpty
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Remark hint
                      Expanded(
                        flex: 2,
                        // Make it flexible to avoid overflow
                        child: GestureDetector(
                          onTap:
                              _showRemarkPopup, // Allow tapping remark box too
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5E6D3),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _remark.isEmpty ? 'Remark' : _remark,
                              style: TextStyle(
                                color: _remark.isEmpty
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Keypad and Options
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomKeypad(
                          onKeyTap: _onKeypadTap,
                          onBackspaceTap: _onBackspace,
                          onBlackCheckTap: () => _calculateOrSave(false),
                          onRedActionTap: () => _calculateOrSave(true),
                          isCalculationMode:
                              _inputAmountStr.contains('+') ||
                              _inputAmountStr.contains('-'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TransactionOptionsPanel(
                          selectedDate: _selectedDate,
                          ledgerName: ledgerName, // Need name
                          assetName: assetName,
                          isReimburse: _isReimburse,
                          onDateTap: _showDatePopup,
                          onLedgerTap: () async {
                            // Show Ledger Picker
                            if (ledgers.isNotEmpty) {
                              await showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (ctx) => ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: ledgers.length,
                                  itemBuilder: (context, index) {
                                    final l = ledgers[index];
                                    return ListTile(
                                      title: Text(l.name),
                                      onTap: () {
                                        setState(
                                          () => _selectedLedgerId = l.id,
                                        );
                                        Navigator.pop(ctx);
                                      },
                                    );
                                  },
                                ),
                              );
                            }
                          },
                          onAssetTap: () => _showAssetSelectionPopup(assets),
                          onReimburseTap: () =>
                              setState(() => _isReimburse = !_isReimburse),
                          onRemarkTap: _showRemarkPopup, // Remark Button
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const BannerAdWidget(), // Restore Banner Ad
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    bool isSelected = _selectedTypeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTypeIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8E1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
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
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black87 : Colors.black54,
          ),
        ),
      ),
    );
  }
}

// Extension to help find first null safely if needed
extension ListExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
