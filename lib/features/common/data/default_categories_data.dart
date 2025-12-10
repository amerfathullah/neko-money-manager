import '../../categories/data/models/category.dart';

class DefaultCategoriesData {
  static const List<Category> defaults = [
    // EXPENSES
    Category(
      id: 'food_drink',
      name: 'Food & Drink',
      iconCodePoint: 0xe56c, // Icons.restaurant
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFFFF5252, // Red Accent
      type: CategoryType.expense,
      index: 0,
    ),
    Category(
      id: 'transportation',
      name: 'Transportation',
      iconCodePoint: 0xe530, // Icons.directions_bus
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFF448AFF, // Blue Accent
      type: CategoryType.expense,
      index: 1,
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      iconCodePoint: 0xe8cc, // Icons.shopping_cart
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFFFFAB40, // Orange Accent
      type: CategoryType.expense,
      index: 2,
    ),
    Category(
      id: 'health_personal_care',
      name: 'Health & Personal Care',
      iconCodePoint: 0xe548, // Icons.local_hospital
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFFF06292, // Pink Light
      type: CategoryType.expense,
      index: 3,
    ),
    Category(
      id: 'entertainment_leisure',
      name: 'Entertainment & Leisure',
      iconCodePoint: 0xe404, // Icons.movie
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFFE040FB, // Purple Accent
      type: CategoryType.expense,
      index: 4,
    ),
    Category(
      id: 'pets',
      name: 'Pets',
      iconCodePoint: 0xe91d, // Icons.pets
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFF795548, // Brown
      type: CategoryType.expense,
      index: 5,
    ),
    Category(
      id: 'services_miscellaneous',
      name: 'Services & Miscellaneous',
      iconCodePoint: 0xe87b, // Icons.extension
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFF607D8B, // Blue Grey
      type: CategoryType.expense,
      index: 6,
    ),

    // INCOME
    Category(
      id: 'salary_bonus',
      name: 'Salary & Bonus',
      iconCodePoint: 0xe232, // Icons.attach_money
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFF69F0AE, // Green Accent
      type: CategoryType.income,
      index: 0,
    ),
    Category(
      id: 'investments_savings',
      name: 'Investments & Savings',
      iconCodePoint: 0xe84f, // Icons.account_balance
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFF536DFE, // Indigo Accent
      type: CategoryType.income,
      index: 1,
    ),
    Category(
      id: 'sales_cash',
      name: 'Sales & Cash',
      iconCodePoint: 0xf05b, // Icons.sell
      iconFontFamily: 'MaterialIcons',
      colorValue: 0xFF00B8D4, // Cyan Accent
      type: CategoryType.income,
      index: 2,
    ),
  ];
}
