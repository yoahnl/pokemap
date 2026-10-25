import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_manifest_tilesets.dart';
import 'runtime_map_bundle.dart';
import 'runtime_project_catalog.dart';
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
  final relativePath = asset == null
      ? legacyRelativePath
      : assetBlobStorageKey(asset.artifact);
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
    if (await file.length() > 128 * 1024 * 1024) {
      throw const FormatException('Project document exceeds its byte limit.');
    }
    final text = await file.readAsString();
    _runtimeLoaderLog('project manifest read ok bytes=${text.length}');
    // Parse + validation sur un isolate de travail : seul le read était
    // asynchrone, le reste bloquait l'isolate UI à chaque chargement.
    final manifest = await _decodeProjectManifestOffThread(
      text,
      file.parent.path,
    );
    _runtimeLoaderLog(
      'project manifest validated maps=${manifest.maps.length} tilesets=${manifest.tilesets.length} scenarios=${manifest.scenarios.length}',
    );
    return manifest;
  } catch (e) {
    _runtimeLoaderLog(
      'project manifest load failed path=$manifestPath error=$e',
    );
    throw ProjectLoadException('Failed to load project: $e');
  }
}

/// Portée top-level volontaire : un closure créé dans la fonction appelante
/// pourrait capturer des objets non envoyables de son scope.
Future<ProjectManifest> _decodeProjectManifestOffThread(
  String text,
  String projectRoot,
) {
  return Isolate.run(() async {
    final raw = decodeNarrativeEventJsonStrict(text) as Map<String, dynamic>;
    if (!raw.containsKey('format') &&
        !raw.containsKey('kind') &&
        !raw.containsKey('root')) {
      return decodeRuntimeProjectManifest(text);
    }
    if (raw['format'] == 'avelune.working-catalog') {
      final project = await loadWorkingRuntimeProjectManifest(
        p.join(projectRoot, 'project.json'),
        expectedSourceSha256: narrativeEventBytesFingerprint(utf8.encode(text))
            .substring(7),
      );
      final manifest = normalizeRuntimeProjectManifest(project);
      ProjectValidator.validate(manifest);
      return manifest;
    }
    final root = Directory(projectRoot).resolveSymbolicLinksSync();
    var storedBytes = utf8.encode(text).length;
    var values = _catalogJsonValues(raw);
    final consumed = <String>{};
    final project = PortableCatalogPublication.decodeProjectSync(
      raw,
      limits: CatalogStorageLimits(maxStoredBytes: 128 * 1024 * 1024),
      readObject: (reference) {
        final relative = PortableCatalogPublication.objectPath(reference);
        final file = File(p.join(root, relative));
        final resolved = file.resolveSymbolicLinksSync();
        if (!p.isWithin(root, resolved) ||
            !FileSystemEntity.isFileSync(resolved) ||
            file.lengthSync() != reference.byteLength ||
            reference.byteLength > 1024 * 1024) {
          throw const FormatException('Invalid catalog object path or size.');
        }
        final bytes = file.readAsBytesSync();
        if (consumed.add(relative)) {
          storedBytes += bytes.length;
          values += _catalogJsonValues(jsonDecode(utf8.decode(bytes)));
          if (storedBytes > 128 * 1024 * 1024 || values > 8000000) {
            throw const FormatException('Global catalog quota exceeded.');
          }
        }
        return bytes;
      },
    );
    final manifest = normalizeRuntimeProjectManifest(project);
    ProjectValidator.validate(manifest);
    return manifest;
  });
}

int _catalogJsonValues(Object? value) {
  var count = 0;
  final pending = <Object?>[value];
  while (pending.isNotEmpty) {
    final item = pending.removeLast();
    count++;
    if (item is Map) pending.addAll(item.values);
    if (item is List) pending.addAll(item);
  }
  return count;
}

ProjectManifest decodeRuntimeProjectManifest(String text) {
  final raw = jsonDecode(text) as Map<String, dynamic>;
  final manifest = normalizeRuntimeProjectManifest(
    ProjectManifest.fromJson(raw),
  );
  ProjectValidator.validate(manifest);
  return manifest;
}

ProjectManifest normalizeRuntimeProjectManifest(ProjectManifest manifest) {
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
  required ProjectManifest? projectDialogueContext,
  PixelSize? projectTileSize,
}) async {
  final maps = await loadMapDataFiles(
    [absoluteMapPath],
    projectDialogueContext: projectDialogueContext,
    projectTileSize: projectTileSize,
  );
  return maps.single;
}

Future<List<MapData>> loadMapDataFiles(
  List<String> absoluteMapPaths, {
  required ProjectManifest? projectDialogueContext,
  PixelSize? projectTileSize,
}) {
  if (absoluteMapPaths.isEmpty) return Future.value(const <MapData>[]);
  return Isolate.run(
    () => _readMapDataFiles(
      absoluteMapPaths,
      projectDialogueContext,
      projectTileSize,
    ),
  );
}

Future<List<MapData>> _readMapDataFiles(
  List<String> absoluteMapPaths,
  ProjectManifest? projectDialogueContext,
  PixelSize? projectTileSize,
) async {
  final maps = <MapData>[];
  for (final absoluteMapPath in absoluteMapPaths) {
    final file = File(absoluteMapPath);
    _runtimeLoaderLog('map file lookup path=$absoluteMapPath');
    if (!await file.exists()) {
      _runtimeLoaderLog('map file missing path=$absoluteMapPath');
      throw MapLoadException('Map file not found: $absoluteMapPath');
    }
    try {
      final text = await file.readAsString();
      _runtimeLoaderLog('map file read ok bytes=${text.length}');
      final map = _decodeValidateAndComposeMapData(
        text,
        projectDialogueContext,
        projectTileSize,
      );
      _runtimeLoaderLog(
        'map validated id=${map.id} size=${map.size.width}x${map.size.height} layers=${map.layers.length} entities=${map.entities.length} placedElements=${map.placedElements.length} warps=${map.warps.length} triggers=${map.triggers.length}',
      );
      maps.add(map);
    } catch (e) {
      _runtimeLoaderLog('map load failed path=$absoluteMapPath error=$e');
      throw MapLoadException('Failed to load map: $e');
    }
  }
  return List.unmodifiable(maps);
}

MapData _decodeValidateAndComposeMapData(
  String text,
  ProjectManifest? projectDialogueContext,
  PixelSize? projectTileSize,
) {
  final raw = jsonDecode(text) as Map<String, dynamic>;
  final map = MapData.fromJson(raw);
  MapValidator.validate(
    map,
    projectDialogueContext: projectDialogueContext,
    projectTileSize: projectTileSize,
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

Future<({ProjectManifest project, MapData map})> loadRuntimeCatalogMap(
  RuntimeProjectCatalog catalog,
  String mapId, {
  Set<String> additionalCharacterIds = const {},
}) async {
  final map = await catalog.loadMapData(mapId);
  final project = await catalog.manifestForMap(
    map,
    extraCharacterIds: {
      ...additionalCharacterIds,
      if (catalog.projectMetadata.partyCompanion.enabled)
        for (final visual in catalog.projectMetadata.partyCompanion.mappings)
          visual.characterId,
    },
  );
  MapValidator.validate(map, projectDialogueContext: project);
  final composition = buildMapVisualCompositionPlan(map);
  if (!composition.canCompose) {
    throw MapLoadException('Map ${map.id} cannot be composed by this runtime.');
  }
  return (project: project, map: map);
}

Future<SpatialAtmosphereSettings> loadSpatialAtmosphereSettings({
  required String projectRoot,
  required String mapId,
}) async {
  final relativePath = SpatialAtmosphereDocument.relativePathForMap(mapId);
  const reader = LocalProjectFileReader();
  final root = await reader.canonicalizeDirectory(projectRoot);
  final probe = await reader.probeResource(
    projectRoot: root,
    relativePath: relativePath,
  );
  if (probe.status == ProjectResourceProbeStatus.missing) {
    return SpatialAtmosphereSettings();
  }
  try {
    if (probe.status != ProjectResourceProbeStatus.exists ||
        probe.identity!.byteLength > SpatialAtmosphereDocument.maxBytes) {
      throw const FormatException(
        'Atmosphere document is unsafe or exceeds its byte limit.',
      );
    }
    final bytes = await reader.readBytes(
      projectRoot: root,
      relativePath: relativePath,
    );
    if (bytes.length > SpatialAtmosphereDocument.maxBytes) {
      throw const FormatException(
        'Atmosphere document exceeds its byte limit.',
      );
    }
    final document = SpatialAtmosphereDocument.fromJson(
      Map<String, dynamic>.from(
        decodeNarrativeEventJsonStrict(utf8.decode(bytes)) as Map,
      ),
    );
    if (document.mapId != mapId) {
      throw const FormatException('Atmosphere map identity mismatch.');
    }
    return document.settings;
  } on Object catch (error) {
    throw MapLoadException('Failed to load map atmosphere: $error');
  }
}

Future<SpatialVisualPatch> loadSpatialVisualProfile({
  required String projectRoot,
  String? mapId,
}) async {
  final relativePath = mapId == null
      ? SpatialVisualDocument.projectRelativePath
      : SpatialVisualDocument.relativePathForMap(mapId);
  const reader = LocalProjectFileReader();
  final root = await reader.canonicalizeDirectory(projectRoot);
  final probe = await reader.probeResource(
    projectRoot: root,
    relativePath: relativePath,
  );
  if (probe.status == ProjectResourceProbeStatus.missing)
    return SpatialVisualPatch();
  try {
    if (probe.status != ProjectResourceProbeStatus.exists ||
        probe.identity!.byteLength > SpatialVisualDocument.maxBytes) {
      throw const FormatException(
        'Visual document is unsafe or exceeds its byte limit.',
      );
    }
    final bytes = await reader.readBytes(
      projectRoot: root,
      relativePath: relativePath,
    );
    if (bytes.length > SpatialVisualDocument.maxBytes) {
      throw const FormatException('Visual document exceeds its byte limit.');
    }
    final document = SpatialVisualDocument.fromJson(
      Map<String, dynamic>.from(
        decodeNarrativeEventJsonStrict(utf8.decode(bytes)) as Map,
      ),
    );
    if (document.mapId != mapId)
      throw const FormatException('Visual document identity mismatch.');
    return document.profile;
  } on Object catch (error) {
    throw MapLoadException(
      'Failed to load visual settings $relativePath: $error',
    );
  }
}

Future<RuntimeMapBundle> loadRuntimeMapBundle({
  required String projectFilePath,
  required String mapId,
  ProjectManifest? preloadedManifest,
  RuntimeProjectCatalog? projectCatalog,
  RuntimeResourceBudget? resourceBudget,
  Set<String> additionalCharacterIds = const {},
  RuntimeMapBundleLoadProfileSink? profileSink,
  RuntimeMapBundleLoadProgressSink? progressSink,
}) async {
  final totalWatch = Stopwatch()..start();
  _runtimeLoaderLog(
    'bundle load start projectFilePath=$projectFilePath mapId=$mapId',
  );
  var manifestLoadMicroseconds = 0;
  final budget = resourceBudget ?? RuntimeResourceBudget();
  if (projectCatalog != null) {
    final suppliedPath = p.normalize(p.absolute(projectFilePath));
    if (suppliedPath != projectCatalog.projectFilePath &&
        await File(suppliedPath).resolveSymbolicLinks() !=
            projectCatalog.projectFilePath) {
      throw const MapLoadException('Project catalog identity mismatch');
    }
  }
  final catalog =
      projectCatalog ??
      (preloadedManifest == null
          ? await RuntimeProjectCatalog.open(projectFilePath)
          : null);
  late ProjectManifest manifest;
  if (preloadedManifest == null) {
    final watch = Stopwatch()..start();
    manifest = catalog!.projectMetadata;
    watch.stop();
    manifestLoadMicroseconds = watch.elapsedMicroseconds;
  } else {
    final normalized = normalizeRuntimeProjectManifest(preloadedManifest);
    manifest = normalized == preloadedManifest ? preloadedManifest : normalized;
  }
  progressSink?.call(RuntimeMapBundleLoadStage.manifest);
  additionalCharacterIds = {
    ...additionalCharacterIds,
    if (manifest.partyCompanion.enabled)
      for (final visual in manifest.partyCompanion.mappings) visual.characterId,
  };
  final entry = projectMapEntryForId(manifest, mapId);
  if (entry == null) {
    _runtimeLoaderLog(
      'bundle load failed: map id not found mapId=$mapId availableMapIds=${manifest.maps.map((m) => m.id).join(',')}',
    );
    throw MapLoadException('Map id not in project manifest: $mapId');
  }
  final projectRoot = p.dirname(
    catalog?.projectFilePath ?? p.normalize(p.absolute(projectFilePath)),
  );
  final rel = entry.relativePath.trim();
  if (rel.isEmpty) {
    _runtimeLoaderLog('bundle load failed: empty relativePath mapId=$mapId');
    throw const MapLoadException('Map entry has empty relativePath');
  }
  final mapPath = p.normalize(p.join(projectRoot, rel));
  if (!p.isWithin(projectRoot, mapPath)) {
    throw const MapLoadException('Map entry escapes the project directory');
  }
  progressSink?.call(RuntimeMapBundleLoadStage.mapResolution);
  _runtimeLoaderLog(
    'bundle map resolved mapId=$mapId relativePath=$rel mapPath=$mapPath',
  );
  final mapWatch = Stopwatch()..start();
  final MapData map;
  if (catalog == null) {
    map = await loadMapDataFromFile(mapPath, projectDialogueContext: manifest);
  } else {
    final loaded = await loadRuntimeCatalogMap(
      catalog,
      mapId,
      additionalCharacterIds: additionalCharacterIds,
    );
    map = loaded.map;
    manifest = loaded.project;
  }
  final atmosphere = await loadSpatialAtmosphereSettings(
    projectRoot: projectRoot,
    mapId: map.id,
  );
  final projectVisualProfile = await loadSpatialVisualProfile(
    projectRoot: projectRoot,
  );
  final mapVisualProfile = await loadSpatialVisualProfile(
    projectRoot: projectRoot,
    mapId: map.id,
  );
  mapWatch.stop();
  progressSink?.call(RuntimeMapBundleLoadStage.mapData);
  final assetCatalogWatch = Stopwatch()..start();
  final assetCatalog = catalog == null
      ? await _loadRuntimeAssetCatalog(projectRoot)
      : await catalog.loadAssetCatalog();
  assetCatalogWatch.stop();
  progressSink?.call(RuntimeMapBundleLoadStage.assetCatalog);
  final tilesetWatch = Stopwatch()..start();
  final tilesetIds = collectAllRuntimeTilesetIds(
    map,
    manifest,
    additionalCharacterIds: additionalCharacterIds,
  );
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
        map: map,
        additionalCharacterIds: additionalCharacterIds,
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
      'bundle tileset path id=${entry.key} path=${entry.value}',
    );
  }
  _runtimeLoaderLog(
    'bundle load ok mapId=${map.id} projectRoot=$projectRoot tilesets=${paths.length}',
  );
  final borderWatch = Stopwatch()..start();
  final bundle = await prepareBorderRuntimeBundle(
    RuntimeMapBundle(
      manifest: manifest,
      map: map,
      spatialAtmosphereSettings: atmosphere,
      projectVisualProfile: projectVisualProfile,
      mapVisualProfile: mapVisualProfile,
      projectRootDirectory: projectRoot,
      tilesetAbsolutePathsById: paths,
      characterAnimationAbsolutePathsByAssetId:
          characterAnimationPreloadPlan.absolutePathsByAssetId,
      projectCatalog: catalog,
      resourceBudget: budget,
    ),
    resourceBudget: budget,
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
