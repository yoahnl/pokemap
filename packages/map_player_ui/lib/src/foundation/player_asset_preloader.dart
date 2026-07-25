import 'dart:collection';

typedef PlayerAssetLoad = Future<void> Function(String assetPath);

/// Cache de préchargement borné pour les assets de présentation immédiats.
class PlayerAssetPreloader {
  PlayerAssetPreloader({
    required this.load,
    this.maxCachedAssets = 32,
  }) : assert(maxCachedAssets > 0);

  final PlayerAssetLoad load;
  final int maxCachedAssets;
  final LinkedHashSet<String> _cached = LinkedHashSet<String>();

  Future<void> preload(Iterable<String> assetPaths) async {
    for (final rawPath in assetPaths) {
      final path = rawPath.trim();
      if (path.isEmpty || _cached.contains(path)) {
        continue;
      }
      await load(path);
      if (_cached.length >= maxCachedAssets) {
        _cached.remove(_cached.first);
      }
      _cached.add(path);
    }
  }
}
