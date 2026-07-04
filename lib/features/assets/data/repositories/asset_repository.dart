import '../../../../core/services/database_service.dart';
import '../models/asset.dart';
import '../models/asset_history_model.dart';

class AssetRepository {
  Future<List<Asset>> getAssets() async {
    final db = await DatabaseService.database;
    final maps = await db.query('assets');
    return maps.map((m) => Asset.fromJson(m)).toList();
  }

  Future<void> addAsset(Asset asset) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    batch.insert('assets', asset.toJson());

    final historyId = DateTime.now().millisecondsSinceEpoch.toString();
    final history = AssetHistoryModel(
      id: historyId,
      assetId: asset.id,
      balance: asset.balance,
      date: DateTime.now(),
      reason: 'initial_creation',
    );
    batch.insert('asset_history', history.toJson());

    await batch.commit(noResult: true);
  }

  Future<void> updateAsset(Asset asset) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    batch.update('assets', asset.toJson(), where: 'id = ?', whereArgs: [asset.id]);

    final historyId = DateTime.now().millisecondsSinceEpoch.toString();
    final history = AssetHistoryModel(
      id: historyId,
      assetId: asset.id,
      balance: asset.balance,
      date: DateTime.now(),
      reason: 'manual_edit',
    );
    batch.insert('asset_history', history.toJson());

    await batch.commit(noResult: true);
  }

  Future<List<AssetHistoryModel>> getAssetHistory() async {
    final db = await DatabaseService.database;
    final maps = await db.query('asset_history', orderBy: 'date DESC');
    return maps.map((m) => AssetHistoryModel.fromJson(m)).toList();
  }

  Future<void> deleteAsset(String assetId) async {
    final db = await DatabaseService.database;
    await db.delete('assets', where: 'id = ?', whereArgs: [assetId]);
  }
}
