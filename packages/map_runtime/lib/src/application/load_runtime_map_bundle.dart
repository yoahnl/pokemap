import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_manifest_tilesets.dart';
import 'runtime_map_bundle.dart';

void _runtimeLoaderLog(String message) {
  debugPrint('[runtime_loader] $message');
}

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
  _runtimeLoaderLog('project manifest lookup path=$manifestPath');
  if (!await file.exists()) {
    _runtimeLoaderLog('project manifest missing path=$manifestPath');
    throw const ProjectLoadException('Project file not found');
  }
  try {
    final text = await file.readAsString();
    _runtimeLoaderLog('project manifest read ok bytes=${text.length}');
    final raw = jsonDecode(text) as Map<String, dynamic>;
    final migrated = migrateProjectManifestJson(raw);
    final manifest = _normalizeProjectElementCollisionProfiles(
      ProjectManifest.fromJson(migrated),
    );
    ProjectValidator.validate(manifest);
    _runtimeLoaderLog(
      'project manifest validated maps=${manifest.maps.length} tilesets=${manifest.tilesets.length} scenarios=${manifest.scenarios.length}',
    );
    return manifest;
  } catch (e) {
    _runtimeLoaderLog(
        'project manifest load failed path=$manifestPath error=$e');
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
  _runtimeLoaderLog('map file lookup path=$absoluteMapPath');
  if (!await file.exists()) {
    _runtimeLoaderLog('map file missing path=$absoluteMapPath');
    throw MapLoadException('Map file not found: $absoluteMapPath');
  }
  try {
    final text = await file.readAsString();
    _runtimeLoaderLog('map file read ok bytes=${text.length}');
    final raw = jsonDecode(text) as Map<String, dynamic>;
    final migrated = migrateMapDataJson(raw);
    final map = MapData.fromJson(migrated);
    MapValidator.validate(
      map,
      projectDialogueContext: projectDialogueContext,
    );
    _runtimeLoaderLog(
      'map validated id=${map.id} size=${map.size.width}x${map.size.height} layers=${map.layers.length} entities=${map.entities.length} placedElements=${map.placedElements.length} warps=${map.warps.length} triggers=${map.triggers.length}',
    );
    return map;
  } catch (e) {
    _runtimeLoaderLog('map load failed path=$absoluteMapPath error=$e');
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
  _runtimeLoaderLog(
    'bundle load start projectFilePath=$projectFilePath mapId=$mapId',
  );
  final manifest = await loadProjectManifestFromFile(projectFilePath);
  final entry = projectMapEntryForId(manifest, mapId);
  if (entry == null) {
    _runtimeLoaderLog(
      'bundle load failed: map id not found mapId=$mapId availableMapIds=${manifest.maps.map((m) => m.id).join(',')}',
    );
    throw MapLoadException('Map id not in project manifest: $mapId');
  }
  final projectRoot = p.normalize(p.dirname(projectFilePath));
  final rel = entry.relativePath.trim();
  if (rel.isEmpty) {
    _runtimeLoaderLog('bundle load failed: empty relativePath mapId=$mapId');
    throw const MapLoadException('Map entry has empty relativePath');
  }
  final mapPath = p.normalize(p.join(projectRoot, rel));
  _runtimeLoaderLog(
      'bundle map resolved mapId=$mapId relativePath=$rel mapPath=$mapPath');
  final map = await loadMapDataFromFile(
    mapPath,
    projectDialogueContext: manifest,
  );
  final tilesetIds = collectAllRuntimeTilesetIds(map, manifest);
  _runtimeLoaderLog('bundle tilesets collected ids=${tilesetIds.join(',')}');
  final paths = resolveTilesetAbsolutePaths(
    manifest: manifest,
    projectRoot: projectRoot,
    tilesetIds: tilesetIds,
  );
  for (final entry in paths.entries) {
    _runtimeLoaderLog(
        'bundle tileset path id=${entry.key} path=${entry.value}');
  }
  _runtimeLoaderLog(
    'bundle load ok mapId=${map.id} projectRoot=$projectRoot tilesets=${paths.length}',
  );
  return RuntimeMapBundle(
    manifest: manifest,
    map: map,
    projectRootDirectory: projectRoot,
    tilesetAbsolutePathsById: paths,
  );
}
