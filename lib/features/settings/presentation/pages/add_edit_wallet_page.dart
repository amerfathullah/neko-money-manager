import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/data/models/ledger.dart';
import '../../../home/presentation/providers/ledger_provider.dart';
import '../providers/currency_provider.dart';

class AddEditWalletPage extends ConsumerStatefulWidget {
  final Ledger? ledger;

  const AddEditWalletPage({super.key, this.ledger});

  @override
  ConsumerState<AddEditWalletPage> createState() => _AddEditWalletPageState();
}

class _AddEditWalletPageState extends ConsumerState<AddEditWalletPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late Color _selectedColor;

  // Predefined colors for wallets
  final List<Color> _colors = [
    AppColors.pastelPink,
    AppColors.pastelPurple,
    AppColors.pastelBlue,
    AppColors.pastelYellow,
    AppColors.pastelGreen,
    AppColors.expense, // Redish
    AppColors.income, // Greenish
    Colors.orangeAccent,
    Colors.teal,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ledger?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.ledger?.balance.toString() ?? '0.0',
    );
    _selectedColor = widget.ledger != null
        ? widget.ledger!.color
        : _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveWallet() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final balance = double.tryParse(_balanceController.text) ?? 0.0;

      if (widget.ledger == null) {
        // Create new
        final newLedger = Ledger(
          id: const Uuid().v4(),
          name: name,
          balance: balance,
          colorValue: _selectedColor.toARGB32(),
        );
        await ref.read(ledgerProvider.notifier).addLedger(newLedger);
      } else {
        // Update existing
        final updatedLedger = widget.ledger!.copyWith(
          name: name,
          balance: balance,
          colorValue: _selectedColor.toARGB32(),
        );
        await ref.read(ledgerProvider.notifier).updateLedger(updatedLedger);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyAsync = ref.watch(currencyProvider);
    final currencySymbol = currencyAsync.asData?.value ?? '\$';
    final isEditing = widget.ledger != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Wallet' : 'Add Wallet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Wallet Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Initial Balance',
                  prefixText: '$currencySymbol ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a balance';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Color',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((color) {
                  final isSelected =
                      _selectedColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 3,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Create Wallet',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
