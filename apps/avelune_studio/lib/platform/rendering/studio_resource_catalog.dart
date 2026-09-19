import 'dart:convert';
import 'package:path/path.dart' as p;

import 'package:map_authoring/map_authoring.dart'
    show AssetCatalog, assetCatalogStorageKey;
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
  Set<String> supported,
) async {
  const reader = LocalProjectFileReader();
  AssetCatalog? catalog;
  final probe = await reader.probeResource(
    projectRoot: projectRoot,
    relativePath: assetCatalogStorageKey,
  );
  if (probe.status == ProjectResourceProbeStatus.exists) {
    catalog = AssetCatalog.fromJson(
      jsonDecode(
            utf8.decode(
              await reader.readBytes(
                projectRoot: projectRoot,
                relativePath: assetCatalogStorageKey,
              ),
            ),
          )
          as Map<String, dynamic>,
    );
  } else if (probe.status != ProjectResourceProbeStatus.missing) {
    throw StateError('Catalogue: ${probe.status.name}');
  }
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
