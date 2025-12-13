import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';

import '../../data/models/category.dart';

class AddEditCategoryDialog extends StatefulWidget {
  final Category? category;
  final CategoryType initialType;
  final Function(String name, int colorValue, IconData icon) onSave;

  const AddEditCategoryDialog({
    super.key,
    this.category,
    required this.initialType,
    required this.onSave,
  });

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  late TextEditingController _nameController;
  late int _selectedColorValue;
  late IconData _selectedIcon;

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
    _selectedIcon = widget.category?.icon ?? _iconGroups['Food']![0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    return Dialog(
      backgroundColor: themeColors.surface, // Light beige match
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ), // Limit height
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.category == null ? 'New' : 'Edit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeColors.text,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.destructiveRed, // Muted red close button
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name Input
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Name',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Content Scroll
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Color Section
                    const Text(
                      'Color',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _colors.map((c) {
                        final isSelected = _selectedColorValue == c.toARGB32();
                        return GestureDetector(
                          onTap: () => setState(
                            () => _selectedColorValue = c.toARGB32(),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.black54, width: 2)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ]
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
                    const Text(
                      'Icon',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ..._iconGroups.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 8.0,
                              top: 8.0,
                            ),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: entry.value.map((icon) {
                              final isSelected = _selectedIcon == icon;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedIcon = icon),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.pastelOrange
                                        : Colors.white.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: isSelected
                                        ? Colors.black87
                                        : Colors.grey[600],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Save Button
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  widget.onSave(
                    _nameController.text,
                    _selectedColorValue,
                    _selectedIcon,
                  );
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indianRed, // Indian Red
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
