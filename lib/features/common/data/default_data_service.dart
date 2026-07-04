import '../../../core/services/database_service.dart';
import '../../home/data/models/ledger.dart';
import '../../common/data/default_categories_data.dart';

class DefaultDataService {
  /// Ensures default data exists on first launch.
  static Future<void> ensureDefaults() async {
    final db = await DatabaseService.database;

    // Check if we already have data
    final ledgers = await db.query('ledgers', limit: 1);
    if (ledgers.isNotEmpty) return; // Already initialized

    final batch = db.batch();

    // 1. Create Default Ledger
    final mainWalletId = DateTime.now().millisecondsSinceEpoch.toString();
    final mainWallet = Ledger(
      id: mainWalletId,
      name: 'Default Ledger',
      colorValue: 0xFF42A5F5, // Blue
      isDefault: true,
    );
    batch.insert('ledgers', mainWallet.toJson());

    // 2. Create Default Categories
    final defaultCategories = DefaultCategoriesData.defaults;
    for (final category in defaultCategories) {
      batch.insert('categories', category.toJson());
    }

    await batch.commit(noResult: true);
  }
}
