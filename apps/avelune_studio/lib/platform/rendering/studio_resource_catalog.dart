import 'package:path/path.dart' as p;

import 'package:map_authoring/map_authoring.dart'
    show AssetCatalog, ProjectSnapshotDecodeExecutor, assetCatalogStorageKey;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:map_runtime/map_runtime.dart'
    show
        buildCharacterAnimationSourcePreloadPlan,
        characterAnimationRuntimeImageId;

Future<Map<String, String>> resolveStudioResourcePaths(
  String projectRoot,
  ProjectManifest manifest,
  Set<String> supported, {
  Future<AssetCatalog?>? catalogRead,
}) async {
  final catalog =
      await (catalogRead ?? StudioAssetCatalogCache(projectRoot).read());
  final paths = resolveTilesetAbsolutePaths(
    manifest: manifest,
    projectRoot: projectRoot,
    tilesetIds: supported,
    assetCatalog: catalog,
  );
  final characters = buildCharacterAnimationSourcePreloadPlan(
    manifest: manifest,
    projectRootDirectory: projectRoot,
    assetCatalog: catalog,
  );
  for (final entry in characters.absolutePathsByAssetId.entries) {
    paths[characterAnimationRuntimeImageId(entry.key)] = entry.value;
  }
  return paths;
}

typedef _AssetCatalogSnapshot = ({
  ProjectResourceIdentity? identity,
  AssetCatalog? catalog,
});

final class StudioAssetCatalogCache {
  StudioAssetCatalogCache(this.projectRoot);

  final String projectRoot;
  final _decoder = ProjectSnapshotDecodeExecutor();
  Future<_AssetCatalogSnapshot>? _snapshot;
  int reads = 0;

  Future<AssetCatalog?> read({bool refresh = false}) async {
    if (refresh || _snapshot == null) {
      _snapshot = _load(_snapshot);
    }
    return (await _snapshot!).catalog;
  }

  void invalidate(Set<String> changedPaths) {
    if (changedPaths.contains(assetCatalogStorageKey)) _snapshot = null;
  }

  Future<_AssetCatalogSnapshot> _load(
    Future<_AssetCatalogSnapshot>? previous,
  ) async {
    final last = await previous?.then<_AssetCatalogSnapshot?>(
      (value) => value,
      onError: (Object _, StackTrace _) => null,
    );
    const reader = LocalProjectFileReader();
    final probe = await reader.probeResource(
      projectRoot: projectRoot,
      relativePath: assetCatalogStorageKey,
    );
    if (probe.status == ProjectResourceProbeStatus.missing) {
      return (identity: null, catalog: null);
    }
    if (probe.status != ProjectResourceProbeStatus.exists) {
      throw StateError('Catalogue: ${probe.status.name}');
    }
    final identity = probe.identity!;
    if (last != null && last.identity == identity) return last;
    reads++;
    final bytes = await reader.readBytes(
      projectRoot: projectRoot,
      relativePath: assetCatalogStorageKey,
    );
    return (
      identity: identity,
      catalog: await _decoder.decodeAssetCatalog(bytes),
    );
  }
}

Future<Map<String, String>> resolveStudioPreviewImagePaths({
  required String projectRoot,
  required ProjectManifest manifest,
  required MapData map,
}) {
  final characters = {
    for (final entity in map.entities) ?entity.npc?.characterId,
  };
  final tilesets = {for (final tileset in manifest.tilesets) tileset.id};
  return resolveStudioResourcePaths(projectRoot, manifest, {
    for (final character in manifest.characters)
      if (characters.contains(character.id) &&
          tilesets.contains(character.tilesetId))
        character.tilesetId,
  });
}

Set<String> changedStudioResourceIds({
  required String root,
  required Map<String, String> before,
  required Map<String, String> after,
  required Map<String, TilesetTransparentColor> previousColors,
  required Map<String, TilesetTransparentColor> nextColors,
  required Set<String> changedRelativePaths,
}) {
  final changed = changedRelativePaths
      .map((path) => p.normalize(p.join(root, path)))
      .toSet();
  return {
    for (final id in {...before.keys, ...after.keys})
      if (before[id] != after[id] ||
          previousColors[id] != nextColors[id] ||
          changed.contains(before[id]) ||
          changed.contains(after[id]))
        id,
  };
}
