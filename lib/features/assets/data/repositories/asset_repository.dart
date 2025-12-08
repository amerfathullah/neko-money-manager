import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/asset.dart';

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
    await _assetsRef(userId).doc(asset.id).set(asset);
  }

  Future<void> updateAsset(String userId, Asset asset) async {
    await _assetsRef(userId).doc(asset.id).set(asset);
  }

  Future<void> deleteAsset(String userId, String assetId) async {
    await _assetsRef(userId).doc(assetId).delete();
  }
}
