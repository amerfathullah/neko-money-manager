import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/asset.dart';
import '../models/asset_history_model.dart';

class AssetRepository {
  final FirebaseFirestore _firestore;

  AssetRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Asset> _assetsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('assets')
        .withConverter<Asset>(
          fromFirestore: (snapshot, _) => Asset.fromJson(snapshot.data()!),
          toFirestore: (asset, _) => asset.toJson(),
        );
  }

  Stream<List<Asset>> getAssets(String userId) {
    return _assetsRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> addAsset(String userId, Asset asset) async {
    final batch = _firestore.batch();

    // 1. Add Asset
    batch.set(_assetsRef(userId).doc(asset.id), asset);

    // 2. Add History (Initial)
    final historyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('asset_history')
        .doc();

    final history = AssetHistoryModel(
      id: historyRef.id,
      assetId: asset.id,
      balance: asset.balance,
      date: DateTime.now(),
      reason: 'initial_creation',
    );

    batch.set(historyRef, history.toJson());

    await batch.commit();
  }

  Future<void> updateAsset(String userId, Asset asset) async {
    final batch = _firestore.batch();

    // 1. Update Asset
    batch.set(_assetsRef(userId).doc(asset.id), asset);

    // 2. Add History (Manual Update)
    final historyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('asset_history')
        .doc();

    final history = AssetHistoryModel(
      id: historyRef.id,
      assetId: asset.id,
      balance: asset.balance,
      date: DateTime.now(),
      reason: 'manual_edit',
    );

    batch.set(historyRef, history.toJson());

    await batch.commit();
  }

  Stream<List<AssetHistoryModel>> getAssetHistoryStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('asset_history')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AssetHistoryModel.fromJson(doc.data()))
              .toList();
        });
  }

  Future<void> deleteAsset(String userId, String assetId) async {
    await _assetsRef(userId).doc(assetId).delete();
  }
}
