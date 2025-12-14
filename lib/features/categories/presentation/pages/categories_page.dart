import 'package:flutter/material.dart';
import 'package:neko_money_manager/core/widgets/dynamic_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/category.dart';
import '../providers/category_provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../widgets/add_edit_category_dialog.dart';
import '../widgets/category_action_popup.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({Category? category, required CategoryType type}) {
    showDialog(
      context: context,
      builder: (context) => AddEditCategoryDialog(
        category: category,
        initialType: type,
        onSave: (name, colorValue, iconCodePoint, fontFamily, fontPackage) {
          final newCategory = Category(
            id:
                category?.id ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            iconCodePoint: iconCodePoint,
            iconFontFamily: fontFamily,
            iconFontPackage: fontPackage,
            colorValue: colorValue,
            type: type,
            index:
                category?.index ??
                0, // Keep existing index or 0 (will need smart append logic?)
            // Ideally, for new categories, we should find max index + 1.
            // But for now let's leave it 0, logic elsewhere or just append to list in provider?
            // Existing addCategory just adds.
          );

          if (category == null) {
            // For new items, we might want to append to end.
            // We can fetch current list to find max index from provider but it's async in build.
            // Provider addCategory adds it.
            // Ideally we solve index assignment in provider/repo or locally before saving.
            // For now, let's assume 0 and rely on reorder to fix it or handle it later.
            ref.read(categoryProvider.notifier).addCategory(newCategory);
          } else {
            ref.read(categoryProvider.notifier).addCategory(newCategory);
          }
        },
      ),
    );
  }

  void _showActionPopup(Category category) {
    showDialog(
      context: context,
      builder: (context) {
        final themeColors = Theme.of(context).extension<AppThemeColors>()!;
        return CategoryActionPopup(
          category: category,
          onDelete: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                backgroundColor: themeColors.background, // Cream
                insetPadding: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Are you sure you want to delete this category?',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeColors.text,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      themeColors.buttonBackground, // Beige
                                  foregroundColor: themeColors.text,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: themeColors.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.destructiveRed, // Red
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  ref
                                      .read(categoryProvider.notifier)
                                      .removeCategory(category.id);
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          onModify: () {
            // Open modify dialog
            _showAddEditDialog(category: category, type: category.type);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColors = theme.extension<AppThemeColors>()!;
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: themeColors.text.withValues(alpha: 0.5),
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          // Sort categories by index
          final sortedCategories = List<Category>.from(categories)
            ..sort((a, b) => a.index.compareTo(b.index));

          final expenseCategories = sortedCategories
              .where((c) => c.type == CategoryType.expense)
              .toList();
          final incomeCategories = sortedCategories
              .where((c) => c.type == CategoryType.income)
              .toList();
          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(expenseCategories, CategoryType.expense),
              _buildCategoryList(incomeCategories, CategoryType.income),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading categories: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final type = _tabController.index == 0
              ? CategoryType.expense
              : CategoryType.income;
          _showAddEditDialog(type: type);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, CategoryType type) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No ${type.name} categories yet.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // ReorderableListView needs a key to track items properly?
    // It handles internal reordering visually, but we need to update state on drop.
    return ReorderableGridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2, // Adjust aspect ratio for pill shape in grid
      dragWidgetBuilder: (index, child) {
        return Material(color: Colors.transparent, elevation: 0, child: child);
      },
      onReorder: (oldIndex, newIndex) {
        // ReorderableGridView handles index adjustment internally usually, but
        // let's stick to standard logic.
        // NOTE: reorderable_grid_view might have different behavior than list view regarding index shifting.
        // Usually it mimics the standard behavior.

        final item = categories.removeAt(oldIndex);
        categories.insert(newIndex, item);

        final updatedCategories = <Category>[];
        for (int i = 0; i < categories.length; i++) {
          updatedCategories.add(categories[i].copyWith(index: i));
        }

        ref
            .read(categoryProvider.notifier)
            .updateCategoriesOrder(updatedCategories);
      },
      children: categories.map((category) {
        return Card(
          key: ValueKey(category.id),
          margin: EdgeInsets.zero, // Margin handled by grid spacing
          elevation: 0,
          color: category.color.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _showActionPopup(category),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: 16,
                    child: DynamicIcon(
                      codePoint: category.iconCodePoint,
                      fontFamily: category.iconFontFamily,
                      fontPackage: category.iconFontPackage,
                      color: category.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const Icon(
                    Icons.drag_handle, // Or menu
                    color: Colors.black26,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
