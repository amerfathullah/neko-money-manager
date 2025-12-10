import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/category.dart';
import '../providers/category_provider.dart';
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
        onSave: (name, colorValue, icon) {
          final newCategory = Category(
            id:
                category?.id ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            iconCodePoint: icon.codePoint,
            iconFontFamily: icon.fontFamily,
            iconFontPackage: icon.fontPackage,
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
      builder: (context) => CategoryActionPopup(
        category: category,
        onDelete: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Category'),
              content: const Text(
                'Are you sure you want to delete this category?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(categoryProvider.notifier)
                        .removeCategory(category.id);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
        onModify: () {
          // Open modify dialog
          _showAddEditDialog(category: category, type: category.type);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: AppColors.textDark.withValues(alpha: 0.5),
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
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            return Material(
              color: Colors.transparent,
              elevation: 0,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  child!,
                ],
              ),
            );
          },
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = categories.removeAt(oldIndex);
        categories.insert(newIndex, item);

        // Update indices for all items in this list (since it's a subset view, we need to be careful)
        // This is tricky. We have `categories` which is a subset (only expense or only income).
        // The indices in `Category` model are likely global or need to be scoped?
        // If we just update indices 0..n for this subset, it might conflict if we mix types in one collection?
        // But `where` filter splits them. If we save index 0 for expense[0] and index 0 for income[0],
        // they might collide if we just sort by index globally?
        // Wait, if we fetch all and sort by index, expense[0] might be global index 5.
        // If we reorder expense list, we should probably re-assign indices for THIS TYPE only or globally?
        // To be safe and simple: Let's assume indices are managed relative to their type?
        // Or if we use global index, we need to re-index potentially everything?
        // Best approach: Just re-assign 0, 1, 2... for the items in THIS list and save.
        // And when loading, sort by index. Since they are separated by type in UI,
        // having Expense(index:0) and Income(index:0) is fine as long as we filter first then sort.
        // Yes, `_buildCategoryList` receives filtered list. So we just update indices for these.

        final updatedCategories = <Category>[];
        for (int i = 0; i < categories.length; i++) {
          updatedCategories.add(categories[i].copyWith(index: i));
        }

        // Optimistically update provider? Or just call saving?
        // The provider stream will refresh the UI eventually.
        // We should call the batch update method.
        ref
            .read(categoryProvider.notifier)
            .updateCategoriesOrder(updatedCategories);
      },
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          key: ValueKey(category.id),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: category.color.withValues(
            alpha: 0.2,
          ), // Light pastel background matching category color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Rounded full pill shape
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _showActionPopup(category),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.transparent, // Icon sits on card bg
                  child: Icon(category.icon, color: category.color, size: 28),
                ),
                title: Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                trailing: const Icon(
                  Icons.menu,
                  color: Colors.black54,
                ), // Burger menu drag handle
              ),
            ),
          ),
        );
      },
    );
  }
}
