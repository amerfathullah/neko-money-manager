import 'package:flutter/material.dart';
import '../../../categories/data/models/category.dart';

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

    // Include "Setting" as a special item at the end or handle it externally?
    // Based on image: "Setting" is last item.
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
          return _buildSettingButton();
        }

        final category = categories[index];
        final isSelected = selectedCategory?.id == category.id;

        return _buildCategoryItem(category, isSelected);
      },
    );
  }

  Widget _buildCategoryItem(Category category, bool isSelected) {
    // Determine background color.
    // Image shows colorful backgrounds for all items.
    // If selected, maybe highlight border or darken?
    // The image shows "Cash" selected with Red background.
    // Unselected items have light pastel backgrounds.

    // Assuming category.color is the main color.
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
            // border: isSelected ? Border.all(color: Colors.black12, width: 1) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  // shape: BoxShape.circle,
                  // color: Colors.white24,
                ),
                child: Icon(
                  category.icon,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.black87,
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
                    color: isSelected ? Colors.white : Colors.black87,
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

  Widget _buildSettingButton() {
    return Material(
      color: Colors.grey[300], // Grey for settings
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
            const Icon(Icons.settings, size: 16, color: Colors.black54),
            const SizedBox(width: 4),
            const Text(
              'Setting',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
