import 'package:flutter/material.dart';
import 'package:neko_money_manager/core/widgets/dynamic_icon.dart';
import '../../../categories/data/models/category.dart';
import '../../../../core/theme/app_theme_colors.dart';

class CategoryGridSelector extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final ValueChanged<Category> onCategorySelected;
  final VoidCallback onSettingTap;

  const CategoryGridSelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onSettingTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No categories found'),
            TextButton(
              onPressed: onSettingTap,
              child: const Text('Add Category'),
            ),
          ],
        ),
      );
    }

    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    final itemCount = categories.length + 1; // +1 for Setting

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columns as per request
        childAspectRatio: 2.2, // Rectangular buttons
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == categories.length) {
          // Setting Button
          return _buildSettingButton(themeColors);
        }

        final category = categories[index];
        final isSelected = selectedCategory?.id == category.id;

        return _buildCategoryItem(category, isSelected, themeColors);
      },
    );
  }

  Widget _buildCategoryItem(
    Category category,
    bool isSelected,
    AppThemeColors themeColors,
  ) {
    // Determine background color.
    final color = category.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onCategorySelected(category),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? color
                : color.withValues(alpha: 0.2), // Light version if not selected
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              SizedBox(
                width: 24,
                height: 24,
                child: DynamicIcon(
                  codePoint: category.iconCodePoint,
                  fontFamily: category.iconFontFamily,
                  fontPackage: category.iconFontPackage,
                  size: 24,
                  color: isSelected ? Colors.white : category.color,
                ),
              ),
              const SizedBox(width: 4),
              // Text
              Flexible(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : themeColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingButton(AppThemeColors themeColors) {
    return Material(
      color: themeColors.inputBackground,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          debugPrint('Debug: Setting button tapped in selector');
          onSettingTap();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 16, color: themeColors.text),
            const SizedBox(width: 4),
            Text(
              'Setting',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: themeColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
