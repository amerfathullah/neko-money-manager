import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final categoryRepositoryProvider = Provider((ref) => CategoryRepository());

class CategoryNotifier extends StreamNotifier<List<Category>> {
  @override
  Stream<List<Category>> build() {
    final userId = ref.watch(userIdProvider);
    if (userId == null) {
      return Stream.value([]);
    }
    final repository = ref.read(categoryRepositoryProvider);
    return repository.getCategories(userId);
  }

  Future<void> addCategory(Category category) async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    await ref.read(categoryRepositoryProvider).addCategory(userId, category);
  }

  Future<void> removeCategory(String id) async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    await ref.read(categoryRepositoryProvider).deleteCategory(userId, id);
  }

  Future<void> updateCategoriesOrder(List<Category> categories) async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    await ref
        .read(categoryRepositoryProvider)
        .updateCategoriesOrder(userId, categories);
  }
}

final categoryProvider =
    StreamNotifierProvider<CategoryNotifier, List<Category>>(
      CategoryNotifier.new,
    );
