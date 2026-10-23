import '../application/scene_runtime/world_presentation_image_loader.dart';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../application/load_runtime_map_bundle.dart';
import '../application/narrative_event_runtime_snapshot.dart';
import '../application/runtime_map_bundle.dart';
import '../application/runtime_project_catalog.dart';
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
  narrativeCatalog,
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
  const RuntimeInitialMapPreloadRequest.continueGame(SaveSlotAddress address)
    : mode = RuntimeInitialMapPreloadMode.continueGame,
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
typedef RuntimeInitialMapTilesetImageLoader =
    Future<Map<String, RuntimeTilesetImage>> Function(
      Map<String, String> absolutePathByTilesetId, {
      Map<String, TilesetTransparentColor> transparentColorByTilesetId,
      RuntimeTilesetImageLoadProgressSink? onProgress,
    });

final class RuntimeInitialMapPreloadResult {
  RuntimeInitialMapPreloadResult({required this.bundle, this.narrativeSnapshot})
    : _projectCatalog = bundle.projectCatalog;

  RuntimeInitialMapPreloadResult._({
    required this.bundle,
    required RuntimeTilesetImageSingleFlightCache tilesetImageCache,
    this.narrativeSnapshot,
  }) : _tilesetImageCache = tilesetImageCache,
       _projectCatalog = bundle.projectCatalog;

  final RuntimeMapBundle bundle;
  final NarrativeEventRuntimeSnapshot? narrativeSnapshot;
  RuntimeTilesetImageSingleFlightCache? _tilesetImageCache;
  RuntimeProjectCatalog? _projectCatalog;

  RuntimeProjectCatalog? takeProjectCatalog() {
    final catalog = _projectCatalog;
    _projectCatalog = null;
    return catalog;
  }

  RuntimeTilesetImageSingleFlightCache? takeTilesetImageCache() {
    final cache = _tilesetImageCache;
    _tilesetImageCache = null;
    return cache;
  }

  void dispose() {
    _tilesetImageCache?.dispose();
    _tilesetImageCache = null;
    _projectCatalog?.dispose();
    _projectCatalog = null;
  }
}

final class RuntimeInitialMapPreloader implements RuntimeInitialMapPreloadPort {
  RuntimeInitialMapPreloader({
    required RuntimeInitialMapProjectFilePathLoader projectFilePath,
    required RuntimeInitialMapSaveLoader loadSave,
    this.expectedIdentity,
    this.preparedNarrativeMapsLoader,
    RuntimeProjectCatalog? preparedProjectCatalog,
    this.resourceProfile = const RuntimeResourceProfile(),
    RuntimeInitialMapManifestLoader? manifestLoader,
    RuntimeInitialMapBundleLoader? bundleLoader,
    RuntimeInitialMapTilesetImageLoader tilesetImageLoader =
        loadTilesetImagesById,
  }) : _projectFilePath = projectFilePath,
       _loadSave = loadSave,
       _preparedProjectCatalog = preparedProjectCatalog,
       _manifestLoader = manifestLoader,
       _bundleLoader = bundleLoader,
       _tilesetImageLoader = tilesetImageLoader;

  final RuntimeInitialMapProjectFilePathLoader _projectFilePath;
  final GameIdentity? expectedIdentity;
  final Future<List<NarrativeMapProjection>?> Function(RuntimeProjectCatalog)?
  preparedNarrativeMapsLoader;
  final RuntimeResourceProfile resourceProfile;
  final RuntimeInitialMapSaveLoader _loadSave;
  final RuntimeInitialMapManifestLoader? _manifestLoader;
  final RuntimeInitialMapBundleLoader? _bundleLoader;
  final RuntimeInitialMapTilesetImageLoader _tilesetImageLoader;

  RuntimeProjectCatalog? _preparedProjectCatalog;
  _RuntimeInitialMapCacheEntry? _cached;
  final Map<int, RuntimeTilesetImageSingleFlightCache>
  _activeTilesetCacheByGeneration =
      <int, RuntimeTilesetImageSingleFlightCache>{};
  int _generation = 0;
  final Map<int, RuntimeProjectCatalog> _activeCatalogByGeneration = {};

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
    final RuntimeProjectCatalog? catalog;
    if (_manifestLoader == null && _bundleLoader == null) {
      final prepared = _preparedProjectCatalog;
      _preparedProjectCatalog = null;
      try {
        if (prepared != null &&
            prepared.projectFilePath ==
                await File(projectFilePath).resolveSymbolicLinks() &&
            await prepared.isCurrentPublication()) {
          catalog = prepared;
        } else {
          prepared?.dispose();
          catalog = await RuntimeProjectCatalog.open(projectFilePath);
        }
      } on Object {
        prepared?.dispose();
        rethrow;
      }
      if (generation != _generation) {
        catalog.dispose();
        return;
      }
      _activeCatalogByGeneration[generation] = catalog;
    } else {
      _preparedProjectCatalog?.dispose();
      _preparedProjectCatalog = null;
      catalog = null;
    }
    try {
      final manifest =
          catalog?.projectMetadata ??
          await (_manifestLoader ?? loadProjectManifestFromFile)(
            projectFilePath,
          );
      publish(RuntimeInitialMapPreloadStage.manifest, 0.24);
      final selection = await _resolveInitialSelection(request, manifest);
      final mapId = selection.mapId;
      if (request.mode == RuntimeInitialMapPreloadMode.continueGame) {
        publish(RuntimeInitialMapPreloadStage.saveDiscovery, 0.32);
      }
      publish(RuntimeInitialMapPreloadStage.mapSelection, 0.38);
      final bundle =
          await (_bundleLoader?.call(
                projectFilePath: projectFilePath,
                mapId: mapId,
                preloadedManifest: manifest,
              ) ??
              loadRuntimeMapBundle(
                projectFilePath: projectFilePath,
                mapId: mapId,
                preloadedManifest: manifest,
                projectCatalog: catalog,
                resourceBudget: RuntimeResourceBudget(profile: resourceProfile),
                additionalCharacterIds: selection.characterIds,
                progressSink: (stage) {
                  switch (stage) {
                    case RuntimeMapBundleLoadStage.manifest ||
                        RuntimeMapBundleLoadStage.mapResolution:
                      break;
                    case RuntimeMapBundleLoadStage.mapData:
                      publish(RuntimeInitialMapPreloadStage.mapData, 0.48);
                    case RuntimeMapBundleLoadStage.assetCatalog:
                      publish(RuntimeInitialMapPreloadStage.assetCatalog, 0.54);
                    case RuntimeMapBundleLoadStage.tilesets:
                      publish(RuntimeInitialMapPreloadStage.tilesets, 0.60);
                    case RuntimeMapBundleLoadStage.worldPreparation:
                      break;
                  }
                },
              ));
      if (bundle.map.id != mapId) {
        throw StateError('The preloaded map does not match the requested map.');
      }
      if (generation != _generation) return;
      RuntimeTilesetImageLoadProgressSink? tilesetProgress =
          (completed, total) {
            final fraction = total <= 0 ? 1.0 : completed / total;
            publish(
              RuntimeInitialMapPreloadStage.tilesets,
              0.60 + (0.15 * fraction.clamp(0, 1)),
            );
          };
      final tilesetCache = RuntimeTilesetImageSingleFlightCache(
        resourceBudget: bundle.resourceBudget,
        identity: catalog?.identity ?? '',
        loader: identical(_tilesetImageLoader, loadTilesetImagesById)
            ? loadTilesetImagesById
            : (
                paths, {
                transparentColorByTilesetId =
                    const <String, TilesetTransparentColor>{},
              }) => _tilesetImageLoader(
                paths,
                transparentColorByTilesetId: transparentColorByTilesetId,
                onProgress: tilesetProgress,
              ),
      );
      _activeTilesetCacheByGeneration[generation] = tilesetCache;
      var retained = false;
      try {
        publish(RuntimeInitialMapPreloadStage.tilesets, 0.60);
        if (bundle.manifest.settings.dimension != ProjectDimension.threeD) {
          await tilesetCache.loadById(
            bundle.runtimeImageAbsolutePathsById,
            isCurrent: () => generation == _generation,
            transparentColorByTilesetId: _transparentColorByTilesetId(
              bundle.manifest,
            ),
          );
        }
        if (bundle.runtimeImageAbsolutePathsById.isEmpty) {
          publish(RuntimeInitialMapPreloadStage.tilesets, 0.75);
        }
        tilesetProgress = null;
        if (generation != _generation) return;
        final registry = manifest.eventRegistry;
        NarrativeEventRuntimeSnapshot? narrativeSnapshot;
        if (registry != null &&
            (registry.mode != EventSystemMode.legacyOnly ||
                registry.hasLocalRuntimeAuthority)) {
          publish(RuntimeInitialMapPreloadStage.narrativeCatalog, 0.75);
          final preparedMaps = catalog == null
              ? null
              : await preparedNarrativeMapsLoader?.call(catalog);
          if (generation != _generation) return;
          final batchMaps = preparedMaps == null && catalog != null
              ? {for (final map in await catalog.loadNarrativeMapData()) map.id: map}
              : null;
          if (generation != _generation) return;
          narrativeSnapshot = await NarrativeEventRuntimeSnapshot.build(
            loadPresentationMediaCatalog: () => WorldPresentationImageLoader(bundle.projectRootDirectory).loadCatalog(),
            preparedMaps: preparedMaps,
            project: manifest,
            loadMap: (id) async {
              final entry = projectMapEntryForId(manifest, id);
              if (entry == null) {
                throw StateError(
                  'The narrative map is missing from the project.',
                );
              }
              final mapPath = p.normalize(
                p.join(bundle.projectRootDirectory, entry.relativePath),
              );
              if (!p.isWithin(bundle.projectRootDirectory, mapPath)) {
                throw StateError('The narrative map path escapes the project.');
              }
              final map = id == bundle.map.id
                  ? bundle.map
                  : batchMaps?[id] ?? await loadMapDataFromFile(
                      mapPath,
                      projectDialogueContext: catalog == null ? manifest : null,
                      projectTileSize: PixelSize(
                        width: manifest.settings.tileWidth,
                        height: manifest.settings.tileHeight,
                      ),
                    );
              return (project: manifest, map: map);
            },
            onMapLoaded: (completed, total) => publish(
              RuntimeInitialMapPreloadStage.narrativeCatalog,
              0.75 + (0.22 * completed / total),
            ),
          );
        }
        if (generation != _generation) return;
        publish(RuntimeInitialMapPreloadStage.worldPreparation, 0.98);
        final result = RuntimeInitialMapPreloadResult._(
          bundle: bundle,
          tilesetImageCache: tilesetCache,
          narrativeSnapshot: narrativeSnapshot,
        );
        publish(RuntimeInitialMapPreloadStage.ready, 1);
        if (generation != _generation) return;
        _cached = _RuntimeInitialMapCacheEntry(
          projectFilePath: projectFilePath,
          request: request,
          mapId: mapId,
          saveFingerprint: selection.saveFingerprint,
          result: result,
        );
        retained = true;
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
    } catch (_) {
      if (generation == _generation) rethrow;
    } finally {
      final owned = _activeCatalogByGeneration.remove(generation);
      if (owned != null &&
          !identical(_cached?.result.bundle.projectCatalog, owned)) {
        owned.dispose();
      }
    }
  }

  Future<RuntimeInitialMapPreloadResult?> resolveForSession({
    required String projectFilePath,
    required GameSessionDescriptor descriptor,
    required SaveEnvelope? initialSave,
  }) async {
    final cached = _cached;
    if ((expectedIdentity != null && descriptor.identity != expectedIdentity) ||
        cached == null ||
        cached.projectFilePath != p.normalize(p.absolute(projectFilePath))) {
      return null;
    }
    final expectedMapId = switch (descriptor.launchMode) {
      GameSessionLaunchMode.newGame =>
        cached.request.mode == RuntimeInitialMapPreloadMode.newGame &&
                initialSave == null
            ? cached.result.bundle.manifest.newGame.startMapId.trim()
            : null,
      GameSessionLaunchMode.continueGame || GameSessionLaunchMode.load =>
        _resolveContinueMapId(cached.request, descriptor, initialSave),
    };
    if (expectedMapId == null ||
        expectedMapId.isEmpty ||
        expectedMapId != cached.mapId ||
        cached.result.bundle.map.id != expectedMapId) {
      return null;
    }
    if (cached.saveFingerprint != null &&
        (initialSave == null ||
            cached.saveFingerprint !=
                narrativeEventCanonicalSha256(
                  const SaveEnvelopeCodec().toJson(initialSave),
                ))) {
      return null;
    }
    final catalog = cached.result.bundle.projectCatalog;
    if (catalog != null && !await catalog.isCurrentPublication()) {
      if (identical(_cached, cached)) {
        _cached = null;
        cached.result.dispose();
      }
      return null;
    }
    if (!identical(_cached, cached)) return null;
    _cached = null;
    return cached.result;
  }

  RuntimeMapBundle? preparedNewGameBundle({required String projectFilePath}) {
    final cached = _cached;
    if (cached == null ||
        cached.request.mode != RuntimeInitialMapPreloadMode.newGame ||
        cached.projectFilePath != p.normalize(p.absolute(projectFilePath)) ||
        cached.result.bundle.map.id != cached.mapId) {
      return null;
    }
    return cached.result.bundle;
  }

  @override
  void clear() {
    _preparedProjectCatalog?.dispose();
    _preparedProjectCatalog = null;
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
    for (final catalog in _activeCatalogByGeneration.values) {
      catalog.dispose();
    }
    _activeCatalogByGeneration.clear();
  }

  Future<({String mapId, Set<String> characterIds, String? saveFingerprint})>
  _resolveInitialSelection(
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
      return (
        mapId: mapId,
        characterIds: const <String>{},
        saveFingerprint: null,
      );
    }
    final address = request.saveAddress!;
    final save = await _loadSave(address);
    if (save == null || !_matchesAddress(save, address)) {
      throw StateError('The selected save is no longer launchable.');
    }
    final state = const GameStateSaveEnvelopeMapper().restore(save);
    final mapId = state.currentMapId.trim();
    if (mapId.isEmpty) {
      throw StateError('The selected save does not reference a map.');
    }
    return (
      mapId: mapId,
      characterIds: {
        if (state.trainerProfile.avatarCharacterId case final id?) id,
      },
      saveFingerprint: narrativeEventCanonicalSha256(
        const SaveEnvelopeCodec().toJson(save),
      ),
    );
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
    this.saveFingerprint,
    required this.result,
  });

  final String projectFilePath;
  final RuntimeInitialMapPreloadRequest request;
  final String mapId;
  final String? saveFingerprint;
  final RuntimeInitialMapPreloadResult result;
}
