import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/asset.dart';
import '../../data/models/asset_history_model.dart';
import '../../data/repositories/asset_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart'; // For userIdProvider

final assetRepositoryProvider = Provider((ref) => AssetRepository());

final assetProvider = StreamNotifierProvider<AssetNotifier, List<Asset>>(
  AssetNotifier.new,
);

class AssetNotifier extends StreamNotifier<List<Asset>> {
  @override
  Stream<List<Asset>> build() {
    final userId = ref.watch(
      userIdProvider,
    ); // Use same userId provider as ledgers
    if (userId == null) {
      return Stream.value([]);
    }
    final repository = ref.read(assetRepositoryProvider);
    return repository.getAssets(userId);
  }

  Future<void> addAsset(Asset asset) async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    final repository = ref.read(assetRepositoryProvider);
    await repository.addAsset(userId, asset);
  }

  Future<void> updateAsset(Asset asset) async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    final repository = ref.read(assetRepositoryProvider);
    await repository.updateAsset(userId, asset);
  }

  Future<void> deleteAsset(String assetId) async {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;
    final repository = ref.read(assetRepositoryProvider);
    await repository.deleteAsset(userId, assetId);
  }
}

final assetHistoryProvider = StreamProvider<List<AssetHistoryModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(assetRepositoryProvider);
  return repository.getAssetHistoryStream(userId);
});
