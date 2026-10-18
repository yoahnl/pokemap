import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../application/load_runtime_map_bundle.dart';
import '../application/runtime_map_bundle.dart';
import '../application/runtime_project_catalog.dart';
import '../player/runtime_initial_map_preloader.dart';
import '../player/runtime_new_game_flow.dart';
import '../session/game_session_contract.dart';

final class SpatialExplorationBootstrap
    implements RuntimeInitialMapPreloadPort, RuntimeNewGameFlowPort {
  SpatialExplorationBootstrap({required this.projectFilePath});
  final Future<String> Function() projectFilePath;
  RuntimeMapBundle? _bundle;
  String? _path, _revision;
  int _generation = 0;

  @override
  Future<void> preloadInitialMap(
    RuntimeInitialMapPreloadRequest request, {
    RuntimeInitialMapPreloadProgressSink? onProgress,
  }) async {
    if (request.mode != RuntimeInitialMapPreloadMode.newGame) {
      throw StateError('Spatial exploration cannot continue a saved game.');
    }
    final generation = ++_generation;
    _bundle?.projectCatalog?.dispose();
    _bundle = null;
    final path = p.normalize(p.absolute(await projectFilePath()));
    final snapshot = await _read(path, retainCatalog: true);
    onProgress?.call(
      const RuntimeInitialMapPreloadProgress(
        stage: RuntimeInitialMapPreloadStage.manifest,
        value: .3,
      ),
    );
    late final RuntimeMapBundle bundle;
    try {
      bundle = await loadRuntimeMapBundle(
        projectFilePath: path,
        mapId: snapshot.map.id,
        preloadedManifest: snapshot.project,
        projectCatalog: snapshot.catalog,
      );
    } catch (_) {
      snapshot.catalog?.dispose();
      rethrow;
    }
    if (generation != _generation) {
      snapshot.catalog?.dispose();
      throw StateError('Exploration preparation cancelled.');
    }
    _path = path;
    _revision = snapshot.revision;
    _bundle = bundle;
    onProgress?.call(
      const RuntimeInitialMapPreloadProgress(
        stage: RuntimeInitialMapPreloadStage.ready,
        value: 1,
      ),
    );
  }

  @override
  Future<RuntimeNewGamePreparation> prepare() async {
    await preloadInitialMap(const RuntimeInitialMapPreloadRequest.newGame());
    final bundle = _bundle!;
    return RuntimeNewGamePreparation(
      projectRevision: _revision!,
      project: bundle.manifest,
      startMap: bundle.map,
    );
  }

  Future<RuntimeInitialMapPreloadResult?> resolveForSession({
    required String projectFilePath,
    required GameSessionDescriptor descriptor,
    required SaveEnvelope? initialSave,
  }) async {
    if (descriptor.launchMode != GameSessionLaunchMode.newGame ||
        initialSave != null ||
        descriptor.initialGameState != null ||
        !descriptor.grantedCapabilities.contains('map3d@1')) {
      throw StateError('Invalid exploration launch authority.');
    }
    if (_bundle == null || _path != p.normalize(p.absolute(projectFilePath))) {
      return null;
    }
    if (await readCurrentProjectRevision() != _revision) {
      throw StateError('The prepared exploration project changed.');
    }
    final bundle = _bundle!;
    _bundle = null;
    return RuntimeInitialMapPreloadResult(bundle: bundle);
  }

  @override
  Future<String> readCurrentProjectRevision() async =>
      (await _read(p.normalize(p.absolute(await projectFilePath())))).revision;

  @override
  void clear() {
    _generation++;
    _bundle?.projectCatalog?.dispose();
    _bundle = null;
    _path = _revision = null;
  }

  Future<
    ({
      ProjectManifest project,
      MapData map,
      String revision,
      RuntimeProjectCatalog? catalog,
    })
  >
  _read(String path, {bool retainCatalog = false}) async {
    final catalog = await RuntimeProjectCatalog.open(path);
    var retained = false;
    try {
      final bytes = await File(path).readAsBytes();
      final metadata = catalog.projectMetadata;
      final project = metadata;
      if (project.settings.dimension != ProjectDimension.threeD ||
          project.maps.isEmpty) {
        throw StateError('A spatial project and initial map are required.');
      }
      final root = p.dirname(path);
      final entry = project.maps.first;
      final mapPath = p.normalize(p.join(root, entry.relativePath));
      if (!p.isWithin(root, mapPath)) {
        throw StateError('The exploration map escapes the project.');
      }
      final mapBytes = await File(mapPath).readAsBytes();
      final loaded = await loadRuntimeCatalogMap(catalog, entry.id);
      final map = loaded.map;
      if (map.id != entry.id || map.spatialScene == null) {
        throw StateError('The initial exploration map is not spatial.');
      }
      retained = retainCatalog;
      return (
        project: loaded.project,
        map: map,
        catalog: retainCatalog ? catalog : null,
        revision: computeNarrativeProjectFingerprint([
          NarrativeProjectFingerprintEntry(
            relativePath: 'project.json',
            bytes: bytes,
          ),
          NarrativeProjectFingerprintEntry(
            relativePath: entry.relativePath,
            bytes: mapBytes,
          ),
        ]),
      );
    } finally {
      if (!retained) catalog.dispose();
    }
  }
}
