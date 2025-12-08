import '../../categories/data/models/category.dart';

class DefaultCategoriesData {
  static const List<Category> defaults = [
    // EXPENSES
    Category(
      id: 'food',
      name: 'Food',
      iconCodePoint: 0xe532, // Icons.fastfood
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFFFF5252, // Red Accent
      type: CategoryType.expense,
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      iconCodePoint: 0xe530, // Icons.directions_bus
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFF448AFF, // Blue Accent
      type: CategoryType.expense,
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      iconCodePoint: 0xe8cc, // Icons.shopping_cart
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFFFFAB40, // Orange Accent
      type: CategoryType.expense,
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      iconCodePoint: 0xe404, // Icons.movie
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFFE040FB, // Purple Accent
      type: CategoryType.expense,
    ),

    // INCOME
    Category(
      id: 'salary',
      name: 'Salary',
      iconCodePoint: 0xe232, // Icons.attach_money
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFF69F0AE, // Green Accent
      type: CategoryType.income,
    ),
    Category(
      id: 'allowance',
      name: 'Allowance',
      iconCodePoint: 0xe25d, // Icons.card_giftcard
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFF40C4FF, // Light Blue Accent
      type: CategoryType.income,
    ),
  ];
}
