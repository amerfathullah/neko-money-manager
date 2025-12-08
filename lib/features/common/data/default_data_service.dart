import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/data/models/ledger.dart';
import '../../common/data/default_categories_data.dart'; // We will define this next

class DefaultDataService {
  final FirebaseFirestore _firestore;

  DefaultDataService(this._firestore);

  Future<void> createDefaultData(String userId) async {
    final batch = _firestore.batch();
    final userDoc = _firestore.collection('users').doc(userId);

    // 1. Create Default Ledger (Wallet)
    final mainWalletId = DateTime.now().millisecondsSinceEpoch.toString();
    final mainWallet = Ledger(
      id: mainWalletId,
      name: 'Main Wallet',
      balance: 0.0,
      colorValue: 0xFF42A5F5, // Blue
    );
    final ledgerRef = userDoc.collection('ledgers').doc(mainWalletId);
    batch.set(ledgerRef, mainWallet.toJson());

    // 2. Create Default Categories
    // We will define a list of default categories
    // For now, let's hardcode a few essentials or use the separate file approach
    final defaultCategories = DefaultCategoriesData.defaults;

    for (final category in defaultCategories) {
      final catRef = userDoc.collection('categories').doc(category.id);
      batch.set(catRef, category.toJson());
    }

    await batch.commit();
  }
}
