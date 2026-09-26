import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

final class StudioBorderPreview {
  StudioBorderPreview({required this.projectRoot, required this.changed});

  final String projectRoot;
  final void Function() changed;
  final List<BorderRuntimeAssetCache> _caches = [];
  late BorderRuntimeAssetCache _cache = _newCache();
  List<BorderLayer> _layers = const [];
  ProjectBorderCatalog? _catalog;
  String? _mapId;
  Future<void> _pending = Future.value();
  int _generation = 0;
  bool _disposed = false;

  BorderRuntimeAssetBundle? assets;
  String? issue;
  bool loading = false;
  BorderRuntimeAssetBundle? assetsFor(MapData map) {
    if (_mapId != map.id) return null;
    final layers = map.layers.whereType<BorderLayer>().toList();
    if (layers.length != _layers.length ||
        Iterable<int>.generate(
          layers.length,
        ).any((index) => !identical(layers[index], _layers[index]))) {
      return null;
    }
    return assets;
  }

  BorderRuntimeAssetCache _newCache() {
    final cache = BorderRuntimeAssetCache();
    _caches.add(cache);
    return cache;
  }

  bool get hasVisibleBorders => _layers.any(
    (layer) => layer.isVisible && layer.content.features.isNotEmpty,
  );
  bool get hasBorderFeatures =>
      _layers.any((layer) => layer.content.features.isNotEmpty);

  Future<void> get settled async {
    while (true) {
      final pending = _pending;
      await pending;
      if (identical(pending, _pending)) return;
    }
  }

  void setActiveMap(
    ProjectManifest manifest,
    MapData map, {
    bool force = false,
  }) {
    if (_disposed) return;
    final layers = map.layers.whereType<BorderLayer>().toList();
    if (!force &&
        _mapId == map.id &&
        identical(_catalog, manifest.borderCatalog) &&
        layers.length == _layers.length &&
        Iterable<int>.generate(
          layers.length,
        ).every((index) => identical(layers[index], _layers[index]))) {
      return;
    }
    _mapId = map.id;
    _catalog = manifest.borderCatalog;
    _layers = layers;
    assets = null;
    issue = null;
    loading = layers.any((layer) => layer.content.features.isNotEmpty);
    final generation = ++_generation;
    changed();
    if (!loading) {
      _pending = Future.value();
      return;
    }
    _pending = _load(manifest, map, generation);
  }

  void invalidate(ProjectManifest manifest, MapData map) {
    if (_disposed) return;
    _cache = _newCache();
    setActiveMap(manifest, map, force: true);
  }

  Future<void> _load(
    ProjectManifest manifest,
    MapData map,
    int generation,
  ) async {
    BorderRuntimeAssetBundle? loaded;
    String? failure;
    final cache = _cache;
    try {
      final prepared = await prepareBorderRuntimeBundle(
        RuntimeMapBundle(
          manifest: manifest,
          map: map,
          projectRootDirectory: projectRoot,
          tilesetAbsolutePathsById: const {},
        ),
      );
      loaded = await cache.loadCollection(
        projectRoot: projectRoot,
        collection: prepared.borderRuntimePreparation!.assetCollection,
      );
    } on Object catch (error) {
      failure = error.toString();
    }
    if (_disposed || generation != _generation) return;
    assets = loaded;
    issue = failure;
    loading = false;
    changed();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    await Future.wait([_pending, ..._caches.map((cache) => cache.dispose())]);
  }
}
