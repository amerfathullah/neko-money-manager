import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/asset.dart';
import '../../data/models/asset_history_model.dart';
import '../../data/repositories/asset_repository.dart';

final assetRepositoryProvider = Provider((ref) => AssetRepository());

final assetProvider = AsyncNotifierProvider<AssetNotifier, List<Asset>>(
  AssetNotifier.new,
);

class AssetNotifier extends AsyncNotifier<List<Asset>> {
  @override
  Future<List<Asset>> build() async {
    final repository = ref.read(assetRepositoryProvider);
    return repository.getAssets();
  }

  Future<void> addAsset(Asset asset) async {
    final repository = ref.read(assetRepositoryProvider);
    await repository.addAsset(asset);
    ref.invalidateSelf();
  }

  Future<void> updateAsset(Asset asset) async {
    final repository = ref.read(assetRepositoryProvider);
    await repository.updateAsset(asset);
    ref.invalidateSelf();
  }

  Future<void> deleteAsset(String assetId) async {
    final repository = ref.read(assetRepositoryProvider);
    await repository.deleteAsset(assetId);
    ref.invalidateSelf();
  }
}

final assetHistoryProvider = FutureProvider<List<AssetHistoryModel>>((ref) {
  final repository = ref.watch(assetRepositoryProvider);
  return repository.getAssetHistory();
});
