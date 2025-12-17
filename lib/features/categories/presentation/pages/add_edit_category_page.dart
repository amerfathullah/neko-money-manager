import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../data/models/category.dart';
import '../providers/category_provider.dart';

class AddEditCategoryPage extends ConsumerStatefulWidget {
  final Category? category;
  final CategoryType initialType;

  const AddEditCategoryPage({
    super.key,
    this.category,
    required this.initialType,
  });

  @override
  ConsumerState<AddEditCategoryPage> createState() =>
      _AddEditCategoryPageState();
}

class _AddEditCategoryPageState extends ConsumerState<AddEditCategoryPage> {
  late TextEditingController _nameController;
  late int _selectedColorValue;
  late int _selectedIconCodePoint;
  String? _selectedIconFontFamily;
  String? _selectedIconFontPackage;

  // Expanding color palette - vibrant pastels
  final List<Color> _colors = [
    const Color(0xFFFF8A80), // Red Accent
    const Color(0xFFFF5252), // Red Accent 200
    const Color(0xFFFFD180), // Orange Accent
    const Color(0xFFFFAB40), // Orange Accent 200
    const Color(0xFFFFE57F), // Amber Accent
    const Color(0xFFFFD740), // Amber Accent 200
    const Color(0xFFFFFF8D), // Yellow Accent
    const Color(0xFFCCFF90), // Light Green
    const Color(0xFFB9F6CA), // Green Accent
    const Color(0xFF69F0AE), // Green Accent 200
    const Color(0xFF64FFDA), // Teal Accent
    const Color(0xFF18FFFF), // Cyan Accent
    const Color(0xFF40C4FF), // Light Blue
    const Color(0xFF448AFF), // Blue Accent
    const Color(0xFF82B1FF), // Blue Accent 100
    const Color(0xFFB388FF), // Deep Purple Accent
    const Color(0xFFE040FB), // Purple Accent
    const Color(0xFFFF80AB), // Pink Accent
    const Color(0xFFFF4081), // Pink Accent 200
    const Color(0xFFBCAAA4), // Brown Light
  ];

  // Grouped Icons
  final Map<String, List<IconData>> _iconGroups = {
    'Food': [
      Icons.fastfood,
      Icons.restaurant,
      Icons.local_cafe,
      Icons.local_bar,
      Icons.local_pizza,
      Icons.bakery_dining,
      Icons.icecream,
      Icons.lunch_dining,
    ],
    'Transport': [
      Icons.directions_bus,
      Icons.directions_car,
      Icons.train,
      Icons.flight,
      Icons.local_taxi,
      Icons.directions_bike,
      Icons.directions_boat,
      Icons.local_gas_station,
    ],
    'Shopping': [
      Icons.shopping_bag,
      Icons.shopping_cart,
      Icons.shopping_basket,
      Icons.credit_card,
      Icons.receipt,
      Icons.store,
      Icons.local_mall,
      Icons.card_giftcard,
    ],
    'Health': [
      Icons.local_hospital,
      Icons.medication,
      Icons.healing,
      Icons.monitor_heart,
      Icons.spa,
      Icons.fitness_center,
      Icons.medical_services,
      Icons.local_pharmacy,
    ],
    'Entertainment': [
      Icons.movie,
      Icons.music_note,
      Icons.sports_esports,
      Icons.casino,
      Icons.theaters,
      Icons.library_music,
      Icons.sports_soccer,
      Icons.pool,
    ],
    'Others': [
      Icons.pets,
      Icons.home,
      Icons.work,
      Icons.school,
      Icons.build,
      Icons.child_friendly,
      Icons.cleaning_services,
      Icons.wifi,
    ],
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColorValue = widget.category?.colorValue ?? _colors[0].toARGB32();
    if (widget.category != null) {
      _selectedIconCodePoint = widget.category!.iconCodePoint;
      _selectedIconFontFamily = widget.category!.iconFontFamily;
      _selectedIconFontPackage = widget.category!.iconFontPackage;
    } else {
      final defaultIcon = _iconGroups['Food']![0];
      _selectedIconCodePoint = defaultIcon.codePoint;
      _selectedIconFontFamily = defaultIcon.fontFamily;
      _selectedIconFontPackage = defaultIcon.fontPackage;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final newCategory = Category(
      id:
          widget.category?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      iconCodePoint: _selectedIconCodePoint,
      iconFontFamily: _selectedIconFontFamily,
      iconFontPackage: _selectedIconFontPackage,
      colorValue: _selectedColorValue,
      type: widget.initialType,
      index: widget.category?.index ?? 0,
    );

    if (widget.category == null) {
      await ref.read(categoryProvider.notifier).addCategory(newCategory);
    } else {
      await ref
          .read(categoryProvider.notifier)
          .addCategory(
            newCategory,
          ); // update uses addCategory in local provider impl? Checking existing code assumption.
    }

    // Actually the existing code used `addCategory` for both update and add (via copyWith in provider maybe? or overwriting by ID?)
    // In `CategoriesPage`:
    // if (category == null) ... addCategory(newCategory)
    // else ... addCategory(newCategory)
    // So `addCategory` likely handles upsert or list replacement.

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
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
          widget.category == null ? 'New Category' : 'Edit Category',
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Name Input
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: themeColors.inputBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: themeColors.text,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Category Name',
                        hintStyle: TextStyle(
                          color: themeColors.text.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Color Section
                  Text(
                    'Color',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _colors.map((c) {
                      final isSelected = _selectedColorValue == c.toARGB32();
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColorValue = c.toARGB32()),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: themeColors.text, width: 2)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Icon Section
                  Text(
                    'Icon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeColors.text,
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
                              color: themeColors.textSubtle,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
                              onTap: () => setState(() {
                                _selectedIconCodePoint = icon.codePoint;
                                _selectedIconFontFamily = icon.fontFamily;
                                _selectedIconFontPackage = icon.fontPackage;
                              }),
                              child: Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Color(
                                          _selectedColorValue,
                                        ).withValues(alpha: 0.2)
                                      : themeColors.inputBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected
                                      ? Border.all(
                                          color: Color(_selectedColorValue),
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Icon(
                                  icon,
                                  color: isSelected
                                      ? Color(_selectedColorValue)
                                      : themeColors.textSubtle,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(24),
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indianRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
