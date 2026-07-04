import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider((ref) => CategoryRepository());

class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final repository = ref.read(categoryRepositoryProvider);
    return repository.getCategories();
  }

  Future<void> addCategory(Category category) async {
    await ref.read(categoryRepositoryProvider).addCategory(category);
    ref.invalidateSelf();
  }

  Future<void> removeCategory(String id) async {
    await ref.read(categoryRepositoryProvider).deleteCategory(id);
    ref.invalidateSelf();
  }

  Future<void> updateCategoriesOrder(List<Category> categories) async {
    await ref.read(categoryRepositoryProvider).updateCategoriesOrder(categories);
    ref.invalidateSelf();
  }
}

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(
      CategoryNotifier.new,
    );
