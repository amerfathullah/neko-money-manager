import '../../../../core/services/database_service.dart';
import '../models/category.dart';

class CategoryRepository {
  Future<List<Category>> getCategories() async {
    final db = await DatabaseService.database;
    final maps = await db.query('categories');
    return maps.map((m) => Category.fromJson(m)).toList();
  }

  Future<void> addCategory(Category category) async {
    final db = await DatabaseService.database;
    await db.insert('categories', category.toJson());
  }

  Future<void> updateCategoriesOrder(List<Category> categories) async {
    final db = await DatabaseService.database;
    final batch = db.batch();
    for (var category in categories) {
      batch.update(
        'categories',
        {'index': category.index},
        where: 'id = ?',
        whereArgs: [category.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteCategory(String categoryId) async {
    final db = await DatabaseService.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
  }
}
