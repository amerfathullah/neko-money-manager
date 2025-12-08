import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/category.dart';
import '../providers/category_provider.dart';

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

  void _showCategoryDialog({Category? category, required CategoryType type}) {
    showDialog(
      context: context,
      builder: (context) =>
          CategoryDialog(category: category, initialType: type),
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
          final expenseCategories = categories
              .where((c) => c.type == CategoryType.expense)
              .toList();
          final incomeCategories = categories
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
          _showCategoryDialog(type: type);
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: category.color.withValues(alpha: 0.2),
              child: Icon(category.icon, color: category.color),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  _showCategoryDialog(category: category, type: type),
            ),
          ),
        );
      },
    );
  }
}

class CategoryDialog extends ConsumerStatefulWidget {
  final Category? category;
  final CategoryType initialType;

  const CategoryDialog({super.key, this.category, required this.initialType});

  @override
  ConsumerState<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<CategoryDialog> {
  late TextEditingController _nameController;
  late int _selectedColorValue;
  late IconData _selectedIcon;

  // Mock Colors and Icons
  final List<Color> _colors = [
    AppColors.pastelRed,
    AppColors.pastelBlue,
    AppColors.pastelGreen,
    AppColors.pastelYellow,
    AppColors.pastelPurple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
  ];

  final List<IconData> _icons = [
    Icons.fastfood,
    Icons.directions_bus,
    Icons.shopping_bag,
    Icons.movie,
    Icons.receipt,
    Icons.health_and_safety,
    Icons.school,
    Icons.fitness_center,
    Icons.pets,
    Icons.home,
    Icons.work,
    Icons.attach_money,
    Icons.card_giftcard,
    Icons.savings,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColorValue = widget.category?.colorValue ?? _colors[0].toARGB32();
    _selectedIcon = widget.category?.icon ?? _icons[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _savecommon() {
    if (_nameController.text.isEmpty) return;

    final newCategory = Category(
      id:
          widget.category?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      iconCodePoint: _selectedIcon.codePoint,
      iconFontFamily: _selectedIcon.fontFamily,
      iconFontPackage: _selectedIcon.fontPackage,
      colorValue: _selectedColorValue,
      type: widget.initialType,
    );

    if (widget.category != null) {
      // Update logic: Remove old and add new (simplistic update)
      // Ideally update method in provider
      ref.read(categoryProvider.notifier).addCategory(newCategory);
      // Wait, simplistic update might need separate update method, but sticking to addCategory as it likely overwrites or handles it.
      // But looking at provider: addCategory calls .add. If ID exists, Firestore .add will create NEW doc with generated ID if we use .add.
      // CategoryRepository.addCategory uses .doc(category.id).set(category.toJson()).
      // So it acts as upsert. Correct.
    } else {
      ref.read(categoryProvider.notifier).addCategory(newCategory);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'New Category' : 'Edit Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors
                  .map(
                    (c) => GestureDetector(
                      onTap: () =>
                          setState(() => _selectedColorValue = c.toARGB32()),
                      child: CircleAvatar(
                        backgroundColor: c,
                        radius: 16,
                        child: _selectedColorValue == c.toARGB32()
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('Icon'),
            const SizedBox(height: 8),
            SizedBox(
              height: 150, // Limit height for icon grid
              width: double.maxFinite,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _icons.length,
                itemBuilder: (context, index) {
                  final icon = _icons[index];
                  final isSelected = _selectedIcon == icon;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = icon),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.2)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Theme.of(context).primaryColor)
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _savecommon, child: const Text('Save')),
      ],
    );
  }
}
