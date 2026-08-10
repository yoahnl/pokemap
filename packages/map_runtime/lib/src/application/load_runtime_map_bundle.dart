import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_manifest_tilesets.dart';
import 'runtime_map_bundle.dart';
import 'character_animation_source_resolver.dart';
import '../border/border_runtime_readiness.dart';

@immutable
final class RuntimeMapBundleLoadProfile {
  const RuntimeMapBundleLoadProfile({
    required this.usedPreloadedManifest,
    required this.manifestLoadMicroseconds,
    required this.mapLoadMicroseconds,
    required this.assetCatalogLoadMicroseconds,
    required this.tilesetResolutionMicroseconds,
    required this.borderPreparationMicroseconds,
    required this.totalMicroseconds,
    required this.mapCellCount,
    required this.mapLayerCount,
    required this.resolvedTilesetPathCount,
  });

  final bool usedPreloadedManifest;
  final int manifestLoadMicroseconds;
  final int mapLoadMicroseconds;
  final int assetCatalogLoadMicroseconds;
  final int tilesetResolutionMicroseconds;
  final int borderPreparationMicroseconds;
  final int totalMicroseconds;
  final int mapCellCount;
  final int mapLayerCount;
  final int resolvedTilesetPathCount;
}

typedef RuntimeMapBundleLoadProfileSink = void Function(
  RuntimeMapBundleLoadProfile profile,
);

enum RuntimeMapBundleLoadStage {
  manifest,
  mapResolution,
  mapData,
  assetCatalog,
  tilesets,
  worldPreparation,
}

typedef RuntimeMapBundleLoadProgressSink = void Function(
  RuntimeMapBundleLoadStage stage,
);

void _runtimeLoaderLog(String message) {
  if (kDebugMode) {
    debugPrint('[runtime_loader] $message');
  }
}

Map<String, String> resolveTilesetAbsolutePaths({
  required ProjectManifest manifest,
  required String projectRoot,
  required Set<String> tilesetIds,
  AssetCatalog? assetCatalog,
}) {
  final byId = {for (final t in manifest.tilesets) t.id: t};
  final assetsById = <String, AssetRecord>{
    for (final asset in assetCatalog?.records ?? const <AssetRecord>[])
      asset.id: asset,
  };
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
    final source = entry.source;
    if (source is ProjectImageCollectionTilesetSource) {
      for (final page in source.pages) {
        out[page.assetId] = _runtimeAssetPath(
          projectRoot: projectRoot,
          asset: assetsById[page.assetId],
          legacyRelativePath: p.join(rel, '${page.id}.png'),
        );
      }
    } else {
      final assetId = switch (source) {
        ProjectRegularAtlasTilesetSource value => value.assetId,
        _ => id,
      };
      out[id] = _runtimeAssetPath(
        projectRoot: projectRoot,
        asset: assetsById[assetId],
        legacyRelativePath: rel,
      );
    }
  }
  return out;
}

String _runtimeAssetPath({
  required String projectRoot,
  required AssetRecord? asset,
  required String legacyRelativePath,
}) {
  // Canonical authoring imports own bytes through the content-addressed store.
  // The logical path remains presentation metadata and may intentionally have
  // no duplicate file. Projects without a matching catalog record retain the
  // historical physical-path behavior for backwards compatibility.
  final relativePath =
      asset == null ? legacyRelativePath : assetBlobStorageKey(asset.artifact);
  return p.normalize(p.join(projectRoot, relativePath));
}

Future<AssetCatalog?> _loadRuntimeAssetCatalog(String projectRoot) async {
  final file = File(p.join(projectRoot, assetCatalogStorageKey));
  if (!await file.exists()) return null;
  try {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) throw const FormatException('Expected JSON object.');
    return AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
  } on Object catch (error) {
    throw ProjectLoadException('Failed to load asset catalog: $error');
  }
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
    // Parse + validation sur un isolate de travail : seul le read était
    // asynchrone, le reste bloquait l'isolate UI à chaque chargement.
    final manifest = await _decodeProjectManifestOffThread(text);
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

/// Portée top-level volontaire : un closure créé dans la fonction appelante
/// pourrait capturer des objets non envoyables de son scope.
Future<ProjectManifest> _decodeProjectManifestOffThread(String text) {
  return Isolate.run(() => _decodeAndValidateProjectManifest(text));
}

ProjectManifest _decodeAndValidateProjectManifest(String text) {
  final raw = jsonDecode(text) as Map<String, dynamic>;
  final manifest = _normalizeProjectElementCollisionProfiles(
    ProjectManifest.fromJson(raw),
  );
  ProjectValidator.validate(manifest);
  return manifest;
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
    // Parse + validation + plan de composition sur un isolate de travail :
    // c'était un stall de plusieurs centaines de ms par warp sur une grosse
    // carte, entièrement sur l'isolate UI.
    final map = await _decodeMapDataOffThread(text, projectDialogueContext);
    _runtimeLoaderLog(
      'map validated id=${map.id} size=${map.size.width}x${map.size.height} layers=${map.layers.length} entities=${map.entities.length} placedElements=${map.placedElements.length} warps=${map.warps.length} triggers=${map.triggers.length}',
    );
    return map;
  } catch (e) {
    _runtimeLoaderLog('map load failed path=$absoluteMapPath error=$e');
    throw MapLoadException('Failed to load map: $e');
  }
}

/// Portée top-level volontaire : voir [_decodeProjectManifestOffThread].
Future<MapData> _decodeMapDataOffThread(
  String text,
  ProjectManifest projectDialogueContext,
) {
  return Isolate.run(
    () => _decodeValidateAndComposeMapData(text, projectDialogueContext),
  );
}

MapData _decodeValidateAndComposeMapData(
  String text,
  ProjectManifest projectDialogueContext,
) {
  final raw = jsonDecode(text) as Map<String, dynamic>;
  final map = MapData.fromJson(raw);
  MapValidator.validate(
    map,
    projectDialogueContext: projectDialogueContext,
  );
  final visualComposition = buildMapVisualCompositionPlan(map);
  if (!visualComposition.canCompose) {
    final details = visualComposition.diagnostics
        .map((diagnostic) => diagnostic.message)
        .join(' ');
    throw MapLoadException(
      'Map ${map.id} cannot be composed by this runtime. $details',
    );
  }
  return map;
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
  ProjectManifest? preloadedManifest,
  RuntimeMapBundleLoadProfileSink? profileSink,
  RuntimeMapBundleLoadProgressSink? progressSink,
}) async {
  final totalWatch = Stopwatch()..start();
  _runtimeLoaderLog(
    'bundle load start projectFilePath=$projectFilePath mapId=$mapId',
  );
  var manifestLoadMicroseconds = 0;
  late final ProjectManifest manifest;
  if (preloadedManifest == null) {
    final watch = Stopwatch()..start();
    manifest = await loadProjectManifestFromFile(projectFilePath);
    watch.stop();
    manifestLoadMicroseconds = watch.elapsedMicroseconds;
  } else {
    manifest = preloadedManifest;
  }
  progressSink?.call(RuntimeMapBundleLoadStage.manifest);
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
  progressSink?.call(RuntimeMapBundleLoadStage.mapResolution);
  _runtimeLoaderLog(
      'bundle map resolved mapId=$mapId relativePath=$rel mapPath=$mapPath');
  final mapWatch = Stopwatch()..start();
  final map = await loadMapDataFromFile(
    mapPath,
    projectDialogueContext: manifest,
  );
  mapWatch.stop();
  progressSink?.call(RuntimeMapBundleLoadStage.mapData);
  final assetCatalogWatch = Stopwatch()..start();
  final assetCatalog = await _loadRuntimeAssetCatalog(projectRoot);
  assetCatalogWatch.stop();
  progressSink?.call(RuntimeMapBundleLoadStage.assetCatalog);
  final tilesetWatch = Stopwatch()..start();
  final tilesetIds = collectAllRuntimeTilesetIds(map, manifest);
  _runtimeLoaderLog('bundle tilesets collected ids=${tilesetIds.join(',')}');
  final paths = resolveTilesetAbsolutePaths(
    manifest: manifest,
    projectRoot: projectRoot,
    tilesetIds: tilesetIds,
    assetCatalog: assetCatalog,
  );
  final characterAnimationPreloadPlan =
      buildCharacterAnimationSourcePreloadPlan(
    manifest: manifest,
    projectRootDirectory: projectRoot,
    assetCatalog: assetCatalog,
  );
  for (final diagnostic in characterAnimationPreloadPlan.diagnostics) {
    _runtimeLoaderLog(
      'character animation source unavailable character=${diagnostic.characterId} '
      'asset=${diagnostic.sourceAssetId} code=${diagnostic.code.name}',
    );
  }
  tilesetWatch.stop();
  progressSink?.call(RuntimeMapBundleLoadStage.tilesets);
  for (final entry in paths.entries) {
    _runtimeLoaderLog(
        'bundle tileset path id=${entry.key} path=${entry.value}');
  }
  _runtimeLoaderLog(
    'bundle load ok mapId=${map.id} projectRoot=$projectRoot tilesets=${paths.length}',
  );
  final borderWatch = Stopwatch()..start();
  final bundle = await prepareBorderRuntimeBundle(
    RuntimeMapBundle(
      manifest: manifest,
      map: map,
      projectRootDirectory: projectRoot,
      tilesetAbsolutePathsById: paths,
      characterAnimationAbsolutePathsByAssetId:
          characterAnimationPreloadPlan.absolutePathsByAssetId,
    ),
  );
  borderWatch.stop();
  progressSink?.call(RuntimeMapBundleLoadStage.worldPreparation);
  totalWatch.stop();
  profileSink?.call(
    RuntimeMapBundleLoadProfile(
      usedPreloadedManifest: preloadedManifest != null,
      manifestLoadMicroseconds: manifestLoadMicroseconds,
      mapLoadMicroseconds: mapWatch.elapsedMicroseconds,
      assetCatalogLoadMicroseconds: assetCatalogWatch.elapsedMicroseconds,
      tilesetResolutionMicroseconds: tilesetWatch.elapsedMicroseconds,
      borderPreparationMicroseconds: borderWatch.elapsedMicroseconds,
      totalMicroseconds: totalWatch.elapsedMicroseconds,
      mapCellCount: map.size.width * map.size.height,
      mapLayerCount: map.layers.length,
      resolvedTilesetPathCount: paths.length,
    ),
  );
  return bundle;
}
