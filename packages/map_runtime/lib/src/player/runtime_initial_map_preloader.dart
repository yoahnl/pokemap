import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../application/load_runtime_map_bundle.dart';
import '../application/runtime_map_bundle.dart';
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

final class RuntimeInitialMapPreloader implements RuntimeInitialMapPreloadPort {
  RuntimeInitialMapPreloader({
    required RuntimeInitialMapProjectFilePathLoader projectFilePath,
    required RuntimeInitialMapSaveLoader loadSave,
    RuntimeInitialMapManifestLoader manifestLoader =
        loadProjectManifestFromFile,
    RuntimeInitialMapBundleLoader? bundleLoader,
  })  : _projectFilePath = projectFilePath,
        _loadSave = loadSave,
        _manifestLoader = manifestLoader,
        _bundleLoader = bundleLoader;

  final RuntimeInitialMapProjectFilePathLoader _projectFilePath;
  final RuntimeInitialMapSaveLoader _loadSave;
  final RuntimeInitialMapManifestLoader _manifestLoader;
  final RuntimeInitialMapBundleLoader? _bundleLoader;

  _RuntimeInitialMapCacheEntry? _cached;
  int _generation = 0;

  @override
  Future<void> preloadInitialMap(
    RuntimeInitialMapPreloadRequest request, {
    RuntimeInitialMapPreloadProgressSink? onProgress,
  }) async {
    final generation = ++_generation;
    _cached = null;
    void publish(RuntimeInitialMapPreloadStage stage, double value) {
      if (generation != _generation) return;
      onProgress?.call(
        RuntimeInitialMapPreloadProgress(stage: stage, value: value),
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
                publish(RuntimeInitialMapPreloadStage.mapData, 0.7);
              case RuntimeMapBundleLoadStage.assetCatalog:
                publish(RuntimeInitialMapPreloadStage.assetCatalog, 0.8);
              case RuntimeMapBundleLoadStage.tilesets:
                publish(RuntimeInitialMapPreloadStage.tilesets, 0.9);
              case RuntimeMapBundleLoadStage.worldPreparation:
                publish(
                  RuntimeInitialMapPreloadStage.worldPreparation,
                  0.97,
                );
            }
          },
        ));
    if (bundle.map.id != mapId) {
      throw StateError('The preloaded map does not match the requested map.');
    }
    if (generation != _generation) return;
    _cached = _RuntimeInitialMapCacheEntry(
      projectFilePath: projectFilePath,
      request: request,
      mapId: mapId,
      bundle: bundle,
    );
    publish(RuntimeInitialMapPreloadStage.ready, 1);
  }

  Future<RuntimeMapBundle?> resolveForSession({
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
            ? cached.bundle.manifest.newGame.startMapId.trim()
            : null,
      GameSessionLaunchMode.continueGame ||
      GameSessionLaunchMode.load =>
        _resolveContinueMapId(cached.request, descriptor, initialSave),
    };
    if (expectedMapId == null ||
        expectedMapId.isEmpty ||
        expectedMapId != cached.mapId ||
        cached.bundle.map.id != expectedMapId) {
      return null;
    }
    _cached = null;
    return cached.bundle;
  }

  @override
  void clear() {
    _generation++;
    _cached = null;
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
    required this.bundle,
  });

  final String projectFilePath;
  final RuntimeInitialMapPreloadRequest request;
  final String mapId;
  final RuntimeMapBundle bundle;
}
