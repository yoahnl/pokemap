import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../application/load_runtime_map_bundle.dart';
import '../application/runtime_map_bundle.dart';
import '../infrastructure/runtime_tileset_image.dart';
import '../infrastructure/tile_image_loader.dart';
import '../session/game_session_contract.dart';

enum RuntimeInitialMapPreloadMode { continueGame, newGame }

enum RuntimeInitialMapPreloadStage {
  projectResolution,
  manifest,
  saveDiscovery,
  mapSelection,
  mapData,
  assetCatalog,
  tilesets,
  worldPreparation,
  ready,
}

final class RuntimeInitialMapPreloadProgress {
  const RuntimeInitialMapPreloadProgress({
    required this.stage,
    required this.value,
  }) : assert(value >= 0 && value <= 1);

  final RuntimeInitialMapPreloadStage stage;
  final double value;
}

typedef RuntimeInitialMapPreloadProgressSink = void Function(
  RuntimeInitialMapPreloadProgress progress,
);

final class RuntimeInitialMapPreloadRequest {
  const RuntimeInitialMapPreloadRequest.continueGame(
    SaveSlotAddress address,
  )   : mode = RuntimeInitialMapPreloadMode.continueGame,
        saveAddress = address;

  const RuntimeInitialMapPreloadRequest.newGame()
      : mode = RuntimeInitialMapPreloadMode.newGame,
        saveAddress = null;

  final RuntimeInitialMapPreloadMode mode;
  final SaveSlotAddress? saveAddress;
}

abstract interface class RuntimeInitialMapPreloadPort {
  Future<void> preloadInitialMap(
    RuntimeInitialMapPreloadRequest request, {
    RuntimeInitialMapPreloadProgressSink? onProgress,
  });

  void clear();
}

typedef RuntimeInitialMapProjectFilePathLoader = Future<String> Function();
typedef RuntimeInitialMapSaveLoader = Future<SaveEnvelope?> Function(
  SaveSlotAddress address,
);
typedef RuntimeInitialMapManifestLoader = Future<ProjectManifest> Function(
  String projectFilePath,
);
typedef RuntimeInitialMapBundleLoader = Future<RuntimeMapBundle> Function({
  required String projectFilePath,
  required String mapId,
  required ProjectManifest preloadedManifest,
});
typedef RuntimeInitialMapTilesetImageLoader
    = Future<Map<String, RuntimeTilesetImage>> Function(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId,
  RuntimeTilesetImageLoadProgressSink? onProgress,
});

final class RuntimeInitialMapPreloadResult {
  RuntimeInitialMapPreloadResult({required this.bundle});

  RuntimeInitialMapPreloadResult._({
    required this.bundle,
    required RuntimeTilesetImageSingleFlightCache tilesetImageCache,
  }) : _tilesetImageCache = tilesetImageCache;

  final RuntimeMapBundle bundle;
  RuntimeTilesetImageSingleFlightCache? _tilesetImageCache;

  RuntimeTilesetImageSingleFlightCache? takeTilesetImageCache() {
    final cache = _tilesetImageCache;
    _tilesetImageCache = null;
    return cache;
  }

  void dispose() {
    _tilesetImageCache?.dispose();
    _tilesetImageCache = null;
  }
}

final class RuntimeInitialMapPreloader implements RuntimeInitialMapPreloadPort {
  RuntimeInitialMapPreloader({
    required RuntimeInitialMapProjectFilePathLoader projectFilePath,
    required RuntimeInitialMapSaveLoader loadSave,
    RuntimeInitialMapManifestLoader manifestLoader =
        loadProjectManifestFromFile,
    RuntimeInitialMapBundleLoader? bundleLoader,
    RuntimeInitialMapTilesetImageLoader tilesetImageLoader =
        loadTilesetImagesById,
  })  : _projectFilePath = projectFilePath,
        _loadSave = loadSave,
        _manifestLoader = manifestLoader,
        _bundleLoader = bundleLoader,
        _tilesetImageLoader = tilesetImageLoader;

  final RuntimeInitialMapProjectFilePathLoader _projectFilePath;
  final RuntimeInitialMapSaveLoader _loadSave;
  final RuntimeInitialMapManifestLoader _manifestLoader;
  final RuntimeInitialMapBundleLoader? _bundleLoader;
  final RuntimeInitialMapTilesetImageLoader _tilesetImageLoader;

  _RuntimeInitialMapCacheEntry? _cached;
  final Map<int, RuntimeTilesetImageSingleFlightCache>
      _activeTilesetCacheByGeneration =
      <int, RuntimeTilesetImageSingleFlightCache>{};
  int _generation = 0;

  @override
  Future<void> preloadInitialMap(
    RuntimeInitialMapPreloadRequest request, {
    RuntimeInitialMapPreloadProgressSink? onProgress,
  }) async {
    final generation = _beginGeneration();
    var publishedValue = -1.0;
    void publish(RuntimeInitialMapPreloadStage stage, double value) {
      if (generation != _generation) return;
      final boundedValue = value.clamp(0.0, 1.0).toDouble();
      if (boundedValue <= publishedValue) return;
      publishedValue = boundedValue;
      onProgress?.call(
        RuntimeInitialMapPreloadProgress(stage: stage, value: boundedValue),
      );
    }

    final projectFilePath = p.normalize(p.absolute(await _projectFilePath()));
    publish(RuntimeInitialMapPreloadStage.projectResolution, 0.08);
    final manifest = await _manifestLoader(projectFilePath);
    publish(RuntimeInitialMapPreloadStage.manifest, 0.24);
    final mapId = await _resolveMapId(request, manifest);
    if (request.mode == RuntimeInitialMapPreloadMode.continueGame) {
      publish(RuntimeInitialMapPreloadStage.saveDiscovery, 0.32);
    }
    publish(RuntimeInitialMapPreloadStage.mapSelection, 0.38);
    final bundle = await (_bundleLoader?.call(
          projectFilePath: projectFilePath,
          mapId: mapId,
          preloadedManifest: manifest,
        ) ??
        loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: mapId,
          preloadedManifest: manifest,
          progressSink: (stage) {
            switch (stage) {
              case RuntimeMapBundleLoadStage.manifest ||
                    RuntimeMapBundleLoadStage.mapResolution:
                break;
              case RuntimeMapBundleLoadStage.mapData:
                publish(RuntimeInitialMapPreloadStage.mapData, 0.62);
              case RuntimeMapBundleLoadStage.assetCatalog:
                publish(RuntimeInitialMapPreloadStage.assetCatalog, 0.72);
              case RuntimeMapBundleLoadStage.tilesets:
                publish(RuntimeInitialMapPreloadStage.tilesets, 0.78);
              case RuntimeMapBundleLoadStage.worldPreparation:
                break;
            }
          },
        ));
    if (bundle.map.id != mapId) {
      throw StateError('The preloaded map does not match the requested map.');
    }
    if (generation != _generation) return;
    RuntimeTilesetImageLoadProgressSink? tilesetProgress = (completed, total) {
      final fraction = total <= 0 ? 1.0 : completed / total;
      publish(
        RuntimeInitialMapPreloadStage.tilesets,
        0.78 + (0.18 * fraction.clamp(0, 1)),
      );
    };
    final tilesetCache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const <String, TilesetTransparentColor>{},
      }) =>
          _tilesetImageLoader(
        paths,
        transparentColorByTilesetId: transparentColorByTilesetId,
        onProgress: tilesetProgress,
      ),
    );
    _activeTilesetCacheByGeneration[generation] = tilesetCache;
    var retained = false;
    try {
      publish(RuntimeInitialMapPreloadStage.tilesets, 0.78);
      await tilesetCache.loadById(
        bundle.runtimeImageAbsolutePathsById,
        transparentColorByTilesetId: _transparentColorByTilesetId(
          bundle.manifest,
        ),
      );
      if (bundle.runtimeImageAbsolutePathsById.isEmpty) {
        publish(RuntimeInitialMapPreloadStage.tilesets, 0.96);
      }
      tilesetProgress = null;
      if (generation != _generation) return;
      publish(RuntimeInitialMapPreloadStage.worldPreparation, 0.97);
      final result = RuntimeInitialMapPreloadResult._(
        bundle: bundle,
        tilesetImageCache: tilesetCache,
      );
      _cached = _RuntimeInitialMapCacheEntry(
        projectFilePath: projectFilePath,
        request: request,
        mapId: mapId,
        result: result,
      );
      retained = true;
      publish(RuntimeInitialMapPreloadStage.ready, 1);
    } catch (_) {
      if (generation == _generation) rethrow;
    } finally {
      tilesetProgress = null;
      if (identical(
        _activeTilesetCacheByGeneration[generation],
        tilesetCache,
      )) {
        _activeTilesetCacheByGeneration.remove(generation);
      }
      if (!retained) tilesetCache.dispose();
    }
  }

  Future<RuntimeInitialMapPreloadResult?> resolveForSession({
    required String projectFilePath,
    required GameSessionDescriptor descriptor,
    required SaveEnvelope? initialSave,
  }) async {
    final cached = _cached;
    if (cached == null ||
        cached.projectFilePath != p.normalize(p.absolute(projectFilePath))) {
      return null;
    }
    final expectedMapId = switch (descriptor.launchMode) {
      GameSessionLaunchMode.newGame =>
        cached.request.mode == RuntimeInitialMapPreloadMode.newGame &&
                initialSave == null
            ? cached.result.bundle.manifest.newGame.startMapId.trim()
            : null,
      GameSessionLaunchMode.continueGame ||
      GameSessionLaunchMode.load =>
        _resolveContinueMapId(cached.request, descriptor, initialSave),
    };
    if (expectedMapId == null ||
        expectedMapId.isEmpty ||
        expectedMapId != cached.mapId ||
        cached.result.bundle.map.id != expectedMapId) {
      return null;
    }
    _cached = null;
    return cached.result;
  }

  @override
  void clear() {
    _generation++;
    _disposePreloadedResources();
  }

  int _beginGeneration() {
    final generation = ++_generation;
    _disposePreloadedResources();
    return generation;
  }

  void _disposePreloadedResources() {
    _cached?.result.dispose();
    _cached = null;
    for (final cache in _activeTilesetCacheByGeneration.values) {
      cache.dispose();
    }
    _activeTilesetCacheByGeneration.clear();
  }

  Future<String> _resolveMapId(
    RuntimeInitialMapPreloadRequest request,
    ProjectManifest manifest,
  ) async {
    if (request.mode == RuntimeInitialMapPreloadMode.newGame) {
      final mapId = manifest.newGame.startMapId.trim();
      if (!manifest.newGame.enabled || mapId.isEmpty) {
        throw StateError(
          'The project does not define a launchable new game map.',
        );
      }
      return mapId;
    }
    final address = request.saveAddress!;
    final save = await _loadSave(address);
    if (save == null || !_matchesAddress(save, address)) {
      throw StateError('The selected save is no longer launchable.');
    }
    final mapId =
        const GameStateSaveEnvelopeMapper().restore(save).currentMapId.trim();
    if (mapId.isEmpty) {
      throw StateError('The selected save does not reference a map.');
    }
    return mapId;
  }
}

Map<String, TilesetTransparentColor> _transparentColorByTilesetId(
  ProjectManifest manifest,
) {
  return <String, TilesetTransparentColor>{
    for (final tileset in manifest.tilesets)
      if (tileset.transparentColor != null)
        tileset.id: tileset.transparentColor!,
  };
}

String? _resolveContinueMapId(
  RuntimeInitialMapPreloadRequest request,
  GameSessionDescriptor descriptor,
  SaveEnvelope? save,
) {
  final address = SaveSlotAddress(
    gameId: descriptor.identity.gameId,
    profileId: descriptor.profileId,
    slotId: descriptor.slotId,
  );
  if (request.mode != RuntimeInitialMapPreloadMode.continueGame ||
      request.saveAddress != address ||
      save == null ||
      !_matchesAddress(save, address)) {
    return null;
  }
  return const GameStateSaveEnvelopeMapper().restore(save).currentMapId.trim();
}

bool _matchesAddress(SaveEnvelope save, SaveSlotAddress address) =>
    save.gameId == address.gameId &&
    save.profileId == address.profileId &&
    save.slotId == address.slotId;

final class _RuntimeInitialMapCacheEntry {
  const _RuntimeInitialMapCacheEntry({
    required this.projectFilePath,
    required this.request,
    required this.mapId,
    required this.result,
  });

  final String projectFilePath;
  final RuntimeInitialMapPreloadRequest request;
  final String mapId;
  final RuntimeInitialMapPreloadResult result;
}
