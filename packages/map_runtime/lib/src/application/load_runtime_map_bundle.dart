import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_manifest_tilesets.dart';
import 'runtime_map_bundle.dart';

Map<String, String> resolveTilesetAbsolutePaths({
  required ProjectManifest manifest,
  required String projectRoot,
  required Set<String> tilesetIds,
}) {
  final byId = {for (final t in manifest.tilesets) t.id: t};
  final out = <String, String>{};
  for (final id in tilesetIds) {
    final entry = byId[id];
    if (entry == null) {
      throw AssetNotFoundException('Tileset not in manifest: $id');
    }
    final rel = entry.relativePath.trim();
    if (rel.isEmpty) {
      throw AssetNotFoundException('Tileset $id has empty relativePath');
    }
    out[id] = p.normalize(p.join(projectRoot, rel));
  }
  return out;
}

Future<ProjectManifest> loadProjectManifestFromFile(String manifestPath) async {
  final file = File(manifestPath);
  if (!await file.exists()) {
    throw const ProjectLoadException('Project file not found');
  }
  try {
    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final migrated = migrateProjectManifestJson(raw);
    final manifest = _normalizeProjectElementCollisionProfiles(
      ProjectManifest.fromJson(migrated),
    );
    final normalized = applyElementAutoShadowPolicyToProject(manifest).project;
    ProjectValidator.validate(normalized);
    return normalized;
  } catch (e) {
    throw ProjectLoadException('Failed to load project: $e');
  }
}

ProjectManifest _normalizeProjectElementCollisionProfiles(
  ProjectManifest manifest,
) {
  final tileSize = manifest.settings.tileWidth;
  return manifest.copyWith(
    elements: [
      for (final element in manifest.elements)
        element.collisionProfile == null
            ? element
            : element.copyWith(
                collisionProfile: normalizeElementCollisionProfile(
                  element.collisionProfile!,
                  tileSize: tileSize,
                ),
              ),
    ],
  );
}

Future<MapData> loadMapDataFromFile(
  String absoluteMapPath, {
  required ProjectManifest projectDialogueContext,
}) async {
  final file = File(absoluteMapPath);
  if (!await file.exists()) {
    throw MapLoadException('Map file not found: $absoluteMapPath');
  }
  try {
    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final migrated = migrateMapDataJson(raw);
    final map = MapData.fromJson(migrated);
    MapValidator.validate(
      map,
      projectDialogueContext: projectDialogueContext,
    );
    return map;
  } catch (e) {
    throw MapLoadException('Failed to load map: $e');
  }
}

ProjectMapEntry? projectMapEntryForId(ProjectManifest manifest, String mapId) {
  for (final entry in manifest.maps) {
    if (entry.id == mapId) {
      return entry;
    }
  }
  return null;
}

Future<RuntimeMapBundle> loadRuntimeMapBundle({
  required String projectFilePath,
  required String mapId,
}) async {
  final manifest = await loadProjectManifestFromFile(projectFilePath);
  final entry = projectMapEntryForId(manifest, mapId);
  if (entry == null) {
    throw MapLoadException('Map id not in project manifest: $mapId');
  }
  final projectRoot = p.normalize(p.dirname(projectFilePath));
  final rel = entry.relativePath.trim();
  if (rel.isEmpty) {
    throw const MapLoadException('Map entry has empty relativePath');
  }
  final mapPath = p.normalize(p.join(projectRoot, rel));
  final map = await loadMapDataFromFile(
    mapPath,
    projectDialogueContext: manifest,
  );
  final tilesetIds = collectAllRuntimeTilesetIds(map, manifest);
  final paths = resolveTilesetAbsolutePaths(
    manifest: manifest,
    projectRoot: projectRoot,
    tilesetIds: tilesetIds,
  );
  return RuntimeMapBundle(
    manifest: manifest,
    map: map,
    projectRootDirectory: projectRoot,
    tilesetAbsolutePathsById: paths,
  );
}
