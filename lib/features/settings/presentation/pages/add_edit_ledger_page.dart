import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/data/models/ledger.dart';
import '../../../home/presentation/providers/ledger_provider.dart';

class AddEditLedgerPage extends ConsumerStatefulWidget {
  final Ledger? ledger;

  const AddEditLedgerPage({super.key, this.ledger});

  @override
  ConsumerState<AddEditLedgerPage> createState() => _AddEditLedgerPageState();
}

class _AddEditLedgerPageState extends ConsumerState<AddEditLedgerPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _remarkController;
  late Color _selectedColor;
  IconData _selectedIcon = Icons.account_balance_wallet;

  // Templates
  final List<Map<String, dynamic>> _templates = [
    {'name': 'Bank', 'icon': Icons.account_balance},
    {'name': 'Cash', 'icon': Icons.payments},
    {'name': 'Card', 'icon': Icons.credit_card},
    {'name': 'Savings', 'icon': Icons.savings},
    {'name': 'Investment', 'icon': Icons.trending_up},
    {'name': 'Insurance', 'icon': Icons.health_and_safety},
  ];

  // Grouped Icons
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
    _nameController = TextEditingController(text: widget.ledger?.name ?? '');
    _remarkController = TextEditingController(
      text: widget.ledger?.remark ?? '',
    );
    _selectedColor = widget.ledger != null
        ? widget.ledger!.color
        : _colors.first;
    if (widget.ledger?.icon != null) {
      _selectedIcon = widget.ledger!.icon!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _applyTemplate(Map<String, dynamic> template, Color color) {
    _nameController.text = template['name'];
    setState(() {
      _selectedIcon = template['icon'];
      _selectedColor = color;
    });
  }

  Future<void> _saveLedger() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final remark = _remarkController.text.trim();

      if (widget.ledger == null) {
        // Create new
        final newLedger = Ledger(
          id: const Uuid().v4(),
          name: name,
          colorValue: _selectedColor.toARGB32(),
          iconPoint: _selectedIcon.codePoint,
          iconFamily: _selectedIcon.fontFamily,
          iconPackage: _selectedIcon.fontPackage,
          remark: remark.isEmpty ? null : remark,
        );
        await ref.read(ledgerProvider.notifier).addLedger(newLedger);
      } else {
        // Update existing
        final updatedLedger = widget.ledger!.copyWith(
          name: name,
          colorValue: _selectedColor.toARGB32(),
          iconPoint: _selectedIcon.codePoint,
          iconFamily: _selectedIcon.fontFamily,
          iconPackage: _selectedIcon.fontPackage,
          remark: remark.isEmpty ? null : remark,
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
    // Reusing the same grid delegate as designs often use 3 columns for templates
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: const Text(
                      'Recommend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Templates Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final template = _templates[index];
                      final color = _colors[index % _colors.length];

                      return GestureDetector(
                        onTap: () => _applyTemplate(template, color),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            children: [
                              // Top colored section (Vibrant)
                              Expanded(
                                flex: 2,
                                child: Container(
                                  color: color,
                                  child: Stack(
                                    children: [
                                      // Bookmark
                                      Positioned(
                                        top: -4,
                                        left: 8,
                                        child: Icon(
                                          Icons.bookmark,
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          size: 24,
                                        ),
                                      ),
                                      // Main Icon
                                      Center(
                                        child: Icon(
                                          template['icon'],
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          size: 32,
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(0, 2),
                                              blurRadius: 4,
                                              color: Colors.black.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Bottom pastel section
                              Expanded(
                                flex: 1,
                                child: Container(
                                  width: double.infinity,
                                  color: color.withValues(alpha: 0.2),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    template['name'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          14, // Increased to 14 Match Ledgers Page
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Theme Color Row
                  if (widget.ledger == null) ...[
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Theme Color',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
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
                  ],
                  const SizedBox(height: 24),

                  // Icon Selection
                  Align(
                    alignment: Alignment.center,
                    child: const Text(
                      'Select Icon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
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
                              fontSize: 16, // Increased from 12
                              fontWeight: FontWeight.bold, // Added bold
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: entry.value.map((icon) {
                            final isSelected = _selectedIcon == icon;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIcon = icon;
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
              color: const Color(
                0xFFFFF8E5,
              ), // Beige/Cream background per image
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
                      // Selected Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _selectedColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _selectedColor, width: 2),
                        ),
                        child: Icon(
                          _selectedIcon,
                          color: _selectedColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name Input
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF3E9D2,
                            ), // Darker beige for input
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Ledger Name',
                              hintStyle: TextStyle(
                                color: Colors.black.withValues(alpha: 0.4),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textDark,
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

                  // Remark Row
                  Row(
                    children: [
                      // Remark Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E9D2), // Match input bg
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.description_outlined, // Text bubble/tag icon
                          color: AppColors.textDark.withValues(alpha: 0.7),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Remark Input
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E9D2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextFormField(
                            controller: _remarkController,
                            decoration: InputDecoration(
                              hintText: 'Ledger remark',
                              hintStyle: TextStyle(
                                color: Colors.black.withValues(alpha: 0.4),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textDark,
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
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFEEE0CD,
                            ), // Light beige button
                            foregroundColor: AppColors.textDark,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveLedger,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFBF4C58,
                            ), // Rusty Red per image
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
