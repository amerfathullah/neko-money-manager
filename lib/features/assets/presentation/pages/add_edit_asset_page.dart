import 'package:flutter/material.dart';
import 'package:neko_money_manager/core/widgets/dynamic_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../data/models/asset.dart';
import '../providers/asset_provider.dart';
import '../../../../features/settings/presentation/providers/currency_provider.dart';

class AddEditAssetPage extends ConsumerStatefulWidget {
  final Asset? asset;

  const AddEditAssetPage({super.key, this.asset});

  @override
  ConsumerState<AddEditAssetPage> createState() => _AddEditAssetPageState();
}

class _AddEditAssetPageState extends ConsumerState<AddEditAssetPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _remarkController;
  late Color _selectedColor;
  late int _selectedIconCodePoint;
  String? _selectedIconFontFamily;
  String? _selectedIconFontPackage;

  // Grouped Icons (Same as Ledger for consistency)
  final Map<String, List<IconData>> _iconGroups = {
    'General': [
      Icons.account_balance_wallet,
      Icons.account_balance,
      Icons.payments,
      Icons.credit_card,
      Icons.savings,
      Icons.attach_money,
      Icons.monetization_on,
      Icons.currency_exchange,
      Icons.price_check,
      Icons.receipt_long,
      Icons.wallet,
      Icons.percent,
    ],
    'Personal': [
      Icons.person,
      Icons.home,
      Icons.shopping_bag,
      Icons.shopping_cart,
      Icons.directions_car,
      Icons.flight,
      Icons.restaurant,
      Icons.medical_services,
      Icons.fitness_center,
      Icons.school,
      Icons.family_restroom,
      Icons.local_grocery_store,
    ],
    'Work': [
      Icons.work,
      Icons.business,
      Icons.computer,
      Icons.store,
      Icons.calculate,
      Icons.business_center,
      Icons.meeting_room,
      Icons.badge,
      Icons.groups,
      Icons.fax,
      Icons.assignment,
      Icons.bar_chart,
    ],
    'Others': [
      Icons.star,
      Icons.favorite,
      Icons.card_giftcard,
      Icons.pets,
      Icons.local_cafe,
      Icons.gamepad,
      Icons.music_note,
      Icons.movie,
      Icons.palette,
      Icons.emoji_events,
      Icons.extension,
      Icons.lightbulb,
    ],
  };

  // Predefined colors
  final List<Color> _colors = [
    AppColors.pastelPink,
    AppColors.pastelPurple,
    AppColors.pastelBlue,
    AppColors.pastelYellow,
    AppColors.pastelGreen,
    AppColors.expense,
    AppColors.income,
    Colors.orangeAccent,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asset?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.asset != null ? widget.asset!.balance.toString() : '',
    );
    _remarkController = TextEditingController(text: widget.asset?.remark ?? '');
    _selectedColor = widget.asset?.color ?? AppColors.pastelPurple;
    if (widget.asset != null) {
      _selectedIconCodePoint =
          widget.asset!.iconCodePoint ?? Icons.account_balance_wallet.codePoint;
      _selectedIconFontFamily = widget.asset!.iconFontFamily;
      _selectedIconFontPackage = widget.asset!.iconFontPackage;
    } else {
      _selectedIconCodePoint = Icons.account_balance_wallet.codePoint;
      _selectedIconFontFamily = Icons.account_balance_wallet.fontFamily;
      _selectedIconFontPackage = Icons.account_balance_wallet.fontPackage;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _saveAsset() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final remark = _remarkController.text.trim();
      final balance = double.tryParse(_balanceController.text) ?? 0.0;

      if (widget.asset == null) {
        // Create new
        final newAsset = Asset(
          id: const Uuid().v4(),
          name: name,
          colorValue: _selectedColor.toARGB32(),
          balance: balance,
          initialBalance: balance, // Set initial balance for history baseline
          remark: remark,
          iconCodePoint: _selectedIconCodePoint,
          iconFontFamily: _selectedIconFontFamily,
          iconFontPackage: _selectedIconFontPackage,
        );
        await ref.read(assetProvider.notifier).addAsset(newAsset);
      } else {
        // Update existing
        // For updates, we generally update current balance?
        // Or should we only update non-balance fields and let transactions handle balance?
        // The dialog allowed editing balance, so we keep that behavior.
        final updatedAsset = widget.asset!.copyWith(
          name: name,
          colorValue: _selectedColor.toARGB32(),
          balance: balance,
          remark: remark,
          iconCodePoint: _selectedIconCodePoint,
          iconFontFamily: _selectedIconFontFamily,
          iconFontPackage: _selectedIconFontPackage,
        );
        await ref.read(assetProvider.notifier).updateAsset(updatedAsset);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyAsync = ref.watch(currencyProvider);
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    final currencySymbol = currencyAsync.asData?.value ?? '\$';

    return Scaffold(
      backgroundColor: themeColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: themeColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.asset == null ? 'Add Asset' : 'Edit Asset',
          style: TextStyle(
            color: themeColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Theme Color Row
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Theme Color',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _colors.map((color) {
                        final isSelected =
                            _selectedColor.toARGB32() == color.toARGB32();
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.textDark,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Icon Selection
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Select Icon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._iconGroups.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: themeColors.textSubtle,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: entry.value.map((icon) {
                            final isSelected =
                                _selectedIconCodePoint == icon.codePoint &&
                                _selectedIconFontFamily == icon.fontFamily &&
                                _selectedIconFontPackage == icon.fontPackage;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIconCodePoint = icon.codePoint;
                                  _selectedIconFontFamily = icon.fontFamily;
                                  _selectedIconFontPackage = icon.fontPackage;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _selectedColor.withValues(alpha: 0.1)
                                      : Theme.of(context).cardColor,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: _selectedColor,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Icon(
                                  icon,
                                  color: isSelected
                                      ? _selectedColor
                                      : Colors.grey[600],
                                  size: 24,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Sticky Bottom Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name Row
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _selectedColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _selectedColor, width: 2),
                        ),
                        child: DynamicIcon(
                          codePoint: _selectedIconCodePoint,
                          fontFamily: _selectedIconFontFamily,
                          fontPackage: _selectedIconFontPackage,
                          color: _selectedColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: themeColors.inputBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Asset Name',
                              hintStyle: TextStyle(
                                color: themeColors.text.withValues(alpha: 0.4),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: themeColors.text,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Balance Row
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: themeColors.inputBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          currencySymbol,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: themeColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: themeColors.inputBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextFormField(
                            controller: _balanceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Current Balance',
                              hintStyle: TextStyle(
                                color: themeColors.text.withValues(alpha: 0.4),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: themeColors.text,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Remark Row
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: themeColors.inputBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          color: themeColors.textSubtle,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: themeColors.inputBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextFormField(
                            controller: _remarkController,
                            decoration: InputDecoration(
                              hintText: 'Remark (Optional)',
                              hintStyle: TextStyle(
                                color: themeColors.text.withValues(alpha: 0.4),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: themeColors.text,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      if (widget.asset != null) ...[
                        // If editing, can delete?
                        // User didn't verify deletion in this page, but good to have
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              ref
                                  .read(assetProvider.notifier)
                                  .deleteAsset(widget.asset!.id);
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saveAsset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBF4C58),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
