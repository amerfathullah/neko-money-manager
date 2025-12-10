import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';

  Stream<List<Category>> getCategories(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Category.fromJson(doc.data()))
              .toList();
        });
  }

  Future<void> addCategory(String userId, Category category) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection(_collection)
        .doc(category.id)
        .set(category.toJson());
  }

  Future<void> updateCategoriesOrder(
    String userId,
    List<Category> categories,
  ) async {
    final batch = _firestore.batch();
    for (var category in categories) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(_collection)
          .doc(category.id);
      batch.update(docRef, {'index': category.index});
    }
    await batch.commit();
  }

  Future<void> deleteCategory(String userId, String categoryId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection(_collection)
        .doc(categoryId)
        .delete();
  }
}
