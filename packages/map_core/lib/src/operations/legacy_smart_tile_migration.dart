import 'package:meta/meta.dart' show immutable;

import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import '../models/smart_tile.dart';
import 'map_terrain_autotile.dart';
import 'smart_tile_templates.dart';

const String legacyTerrainSmartTileCategoryId = 'smart_terrain_migrated';
const String legacyPathSmartTileCategoryId = 'smart_path_migrated';
const String legacySmartTileEmptyMaterialId = 'smart_material_empty';

String legacyTerrainSmartTilePresetId(String legacyPresetId) =>
    'smart_terrain_$legacyPresetId';

String legacyPathSmartTilePresetId(String legacyPresetId) =>
    'smart_path_$legacyPresetId';

String legacyTerrainSmartTileMaterialId(String legacyPresetId) =>
    'smart_material_terrain_$legacyPresetId';

String legacyPathSmartTileMaterialId(String legacyPresetId) =>
    'smart_material_path_$legacyPresetId';

@immutable
final class LegacySmartTileMigrationReport {
  const LegacySmartTileMigrationReport({
    required this.migratedTerrainPresets,
    required this.migratedPathPresets,
    required this.migratedTerrainLayers,
    required this.migratedPathLayers,
    required this.removedEmptyTerrainLayers,
    this.warnings = const <String>[],
  });

  final int migratedTerrainPresets;
  final int migratedPathPresets;
  final int migratedTerrainLayers;
  final int migratedPathLayers;
  final int removedEmptyTerrainLayers;
  final List<String> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
}

@immutable
final class LegacySmartTileMigrationResult {
  const LegacySmartTileMigrationResult({
    required this.project,
    required this.maps,
    required this.report,
  });

  final ProjectManifest project;
  final List<MapData> maps;
  final LegacySmartTileMigrationReport report;
}

/// Converts the historical Terrain/Path libraries and their map layers to the
/// native Smart Tile model.
///
/// Existing Smart Tile entries are preserved. Generated ids are namespaced and
/// deterministic, so running the migration more than once is idempotent.
LegacySmartTileMigrationResult migrateLegacyTerrainAndPathsToSmartTiles({
  required ProjectManifest project,
  required Iterable<MapData> maps,
  bool removeLegacyDefinitions = false,
}) {
  final warnings = <String>[];
  final generated = _buildLegacySmartTileCatalog(
    project: project,
    warnings: warnings,
  );
  var migratedTerrainLayers = 0;
  var migratedPathLayers = 0;
  var removedEmptyTerrainLayers = 0;
  final migratedMaps = <MapData>[];
  var retainsLegacyPathLayers = false;
  var retainsLegacyTerrainLayers = false;

  for (final map in maps) {
    final layers = <MapLayer>[];
    for (final layer in map.layers) {
      switch (layer) {
        case TerrainLayer():
          final migration = _migrateTerrainLayer(
            map: map,
            layer: layer,
            project: project,
            warnings: warnings,
          );
          layers.addAll(migration.layers);
          migratedTerrainLayers += migration.migratedLayerCount;
          removedEmptyTerrainLayers += migration.removedEmptyLayerCount;
          retainsLegacyTerrainLayers = retainsLegacyTerrainLayers ||
              migration.layers.any((item) => item is TerrainLayer);
        case PathLayer():
          final migrated = _migratePathLayer(
            map: map,
            layer: layer,
            project: project,
            warnings: warnings,
          );
          layers.add(migrated);
          if (migrated is SmartTileLayer) {
            migratedPathLayers += 1;
          } else {
            retainsLegacyPathLayers = true;
          }
        default:
          layers.add(layer);
      }
    }
    final containsSmartTiles = layers.any((layer) => layer is SmartTileLayer);
    migratedMaps.add(
      map.copyWith(
        version: containsSmartTiles ? ProjectVersion.v4 : map.version,
        layers: List<MapLayer>.unmodifiable(layers),
      ),
    );
  }

  final canRemovePathDefinitions = removeLegacyDefinitions &&
      !retainsLegacyPathLayers &&
      project.pathPatternPresets.isEmpty;
  if (removeLegacyDefinitions && project.pathPatternPresets.isNotEmpty) {
    warnings.add(
      'Legacy path definitions were retained because path pattern presets '
      'still reference them.',
    );
  }
  final canRemoveTerrainDefinitions =
      removeLegacyDefinitions && !retainsLegacyTerrainLayers;
  final migratedProject = project.copyWith(
    version: generated.isNotEmpty ? ProjectVersion.v4 : project.version,
    smartTileCatalog: generated,
    terrainCategories: canRemoveTerrainDefinitions
        ? const <ProjectPresetCategory>[]
        : project.terrainCategories,
    pathCategories: canRemovePathDefinitions
        ? const <ProjectPresetCategory>[]
        : project.pathCategories,
    terrainPresets: canRemoveTerrainDefinitions
        ? const <ProjectTerrainPreset>[]
        : project.terrainPresets,
    pathPresets: canRemovePathDefinitions
        ? const <ProjectPathPreset>[]
        : project.pathPresets,
  );

  return LegacySmartTileMigrationResult(
    project: migratedProject,
    maps: List<MapData>.unmodifiable(migratedMaps),
    report: LegacySmartTileMigrationReport(
      migratedTerrainPresets: project.terrainPresets.length,
      migratedPathPresets: project.pathPresets.length,
      migratedTerrainLayers: migratedTerrainLayers,
      migratedPathLayers: migratedPathLayers,
      removedEmptyTerrainLayers: removedEmptyTerrainLayers,
      warnings: List<String>.unmodifiable(warnings),
    ),
  );
}

ProjectSmartTileCatalog _buildLegacySmartTileCatalog({
  required ProjectManifest project,
  required List<String> warnings,
}) {
  final existing = project.smartTileCatalog;
  final frameExtents = <String, (int, int)>{};

  void collectFrames(
      String defaultTilesetId, Iterable<TilesetVisualFrame> frames) {
    for (final frame in frames) {
      final tilesetId = _effectiveTilesetId(frame, defaultTilesetId);
      if (tilesetId.isEmpty) continue;
      final current = frameExtents[tilesetId] ?? (1, 1);
      final width = frame.source.width <= 0 ? 1 : frame.source.width;
      final height = frame.source.height <= 0 ? 1 : frame.source.height;
      frameExtents[tilesetId] = (
        current.$1 > frame.source.x + width
            ? current.$1
            : frame.source.x + width,
        current.$2 > frame.source.y + height
            ? current.$2
            : frame.source.y + height,
      );
    }
  }

  for (final preset in project.terrainPresets) {
    for (final variant in preset.variants) {
      collectFrames(preset.tilesetId, variant.frames);
    }
  }
  for (final preset in project.pathPresets) {
    for (final variant in preset.variants) {
      collectFrames(preset.tilesetId, variant.frames);
    }
  }

  final categories = <ProjectSmartTileCategory>[
    ...existing.categories,
    if (project.terrainPresets.isNotEmpty &&
        !existing.categories.any(
          (item) => item.id == legacyTerrainSmartTileCategoryId,
        ))
      const ProjectSmartTileCategory(
        id: legacyTerrainSmartTileCategoryId,
        name: 'Terrains migrés',
        sortOrder: 900,
      ),
    if (project.pathPresets.isNotEmpty &&
        !existing.categories.any(
          (item) => item.id == legacyPathSmartTileCategoryId,
        ))
      const ProjectSmartTileCategory(
        id: legacyPathSmartTileCategoryId,
        name: 'Chemins migrés',
        sortOrder: 910,
      ),
  ];
  final atlases = <ProjectSmartTileAtlas>[...existing.atlases];
  for (final entry in frameExtents.entries) {
    final id = _legacyAtlasId(entry.key);
    if (atlases.any((atlas) => atlas.id == id)) continue;
    atlases.add(
      ProjectSmartTileAtlas(
        id: id,
        name: 'Atlas migré — ${entry.key}',
        tilesetId: entry.key,
        cellWidth: project.settings.tileWidth,
        cellHeight: project.settings.tileHeight,
        columns: entry.value.$1,
        rows: entry.value.$2,
      ),
    );
  }

  final materials = <ProjectSmartTileMaterial>[...existing.materials];
  if (project.terrainPresets.isNotEmpty &&
      !materials.any(
        (material) => material.id == legacySmartTileEmptyMaterialId,
      )) {
    materials.add(
      const ProjectSmartTileMaterial(
        id: legacySmartTileEmptyMaterialId,
        name: 'Vide',
        connectionGroupId: legacySmartTileEmptyMaterialId,
        categoryId: legacyTerrainSmartTileCategoryId,
        isEmpty: true,
        sortOrder: -1,
      ),
    );
  }
  final animations = <ProjectSmartTileAnimation>[...existing.animations];
  final presets = <ProjectSmartTilePreset>[...existing.presets];
  for (final preset in project.terrainPresets) {
    final materialId = legacyTerrainSmartTileMaterialId(preset.id);
    if (!materials.any((material) => material.id == materialId)) {
      materials.add(
        ProjectSmartTileMaterial(
          id: materialId,
          name: preset.name,
          connectionGroupId: materialId,
          categoryId: legacyTerrainSmartTileCategoryId,
          terrainType: preset.terrainType,
          sortOrder: preset.sortOrder,
        ),
      );
    }
    final smartPresetId = legacyTerrainSmartTilePresetId(preset.id);
    if (presets.any((item) => item.id == smartPresetId)) continue;
    final candidates = <SmartTileCandidate>[];
    for (var index = 0; index < preset.variants.length; index += 1) {
      final variant = preset.variants[index];
      final candidate = _candidateForFrames(
        candidateId: 'variant_${index.toString().padLeft(3, '0')}',
        animationId: 'smart_animation_terrain_${preset.id}_$index',
        defaultTilesetId: preset.tilesetId,
        frames: variant.frames,
        weight: variant.weight,
        sampling: switch (variant.multiTileLayout) {
          TerrainVariantMultiTileLayout.tessellated =>
            SmartTileFrameSampling.tessellated,
          TerrainVariantMultiTileLayout.stableRandom =>
            SmartTileFrameSampling.stableRandom,
        },
        animations: animations,
        warnings: warnings,
      );
      if (candidate != null) candidates.add(candidate);
    }
    presets.add(
      ProjectSmartTilePreset(
        id: smartPresetId,
        name: preset.name,
        categoryId: legacyTerrainSmartTileCategoryId,
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.cardinal4,
        templateHint: SmartTileTemplateHint.free,
        status: candidates.isEmpty
            ? SmartTilePresetStatus.draft
            : SmartTilePresetStatus.published,
        defaultMaterialId: materialId,
        allowedMaterialIds: <String>[
          materialId,
          legacySmartTileEmptyMaterialId,
        ],
        rules: <SmartTileRule>[
          SmartTileRule(id: 'fallback', candidates: candidates),
        ],
        sortOrder: preset.sortOrder,
        tags: const <String>['migrated', 'legacy-terrain'],
      ),
    );
  }

  for (final preset in project.pathPresets) {
    final materialId = legacyPathSmartTileMaterialId(preset.id);
    if (!materials.any((material) => material.id == materialId)) {
      materials.add(
        ProjectSmartTileMaterial(
          id: materialId,
          name: preset.name,
          connectionGroupId: materialId,
          categoryId: legacyPathSmartTileCategoryId,
          sortOrder: preset.sortOrder,
        ),
      );
    }
    final smartPresetId = legacyPathSmartTilePresetId(preset.id);
    if (presets.any((item) => item.id == smartPresetId)) continue;
    final variants = <TerrainPathVariant, PathPresetVariantMapping>{
      for (final variant in preset.variants) variant.variant: variant,
    };
    final rules = <SmartTileRule>[];
    var hasMissingCandidate = false;
    for (final mask in smartTileCanonicalMasks(SmartTileTemplateHint.blob47)) {
      final legacyVariant = _legacyPathVariantForBlobMask(mask);
      final mapping = variants[legacyVariant];
      SmartTileCandidate? candidate;
      if (mapping != null) {
        candidate = _candidateForFrames(
          candidateId: 'variant_${legacyVariant.name}',
          animationId:
              'smart_animation_path_${preset.id}_${legacyVariant.name}',
          defaultTilesetId: preset.tilesetId,
          frames: mapping.frames,
          weight: 1,
          sampling: SmartTileFrameSampling.fullFrame,
          animations: animations,
          warnings: warnings,
        );
      }
      if (candidate == null) {
        hasMissingCandidate = true;
      }
      rules.add(
        SmartTileRule(
          id: smartTileCanonicalRuleId(mask),
          signature: smartTileSignatureForMask(
            mask,
            topology: SmartTileTopology.blob8,
          ),
          candidates: candidate == null
              ? const <SmartTileCandidate>[]
              : <SmartTileCandidate>[candidate],
        ),
      );
    }
    if (hasMissingCandidate) {
      warnings.add(
        'Path preset "${preset.id}" is incomplete and was migrated as a '
        'draft Smart Tile preset.',
      );
    }
    presets.add(
      ProjectSmartTilePreset(
        id: smartPresetId,
        name: preset.name,
        categoryId: legacyPathSmartTileCategoryId,
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.blob8,
        templateHint: SmartTileTemplateHint.blob47,
        status: hasMissingCandidate
            ? SmartTilePresetStatus.draft
            : SmartTilePresetStatus.published,
        defaultMaterialId: materialId,
        allowedMaterialIds: <String>[materialId],
        rules: rules,
        sortOrder: preset.sortOrder,
        tags: const <String>['migrated', 'legacy-path'],
      ),
    );
  }

  return ProjectSmartTileCatalog(
    formatVersion: existing.formatVersion,
    categories: categories,
    atlases: atlases,
    materials: materials,
    animations: animations,
    presets: presets,
  );
}

SmartTileCandidate? _candidateForFrames({
  required String candidateId,
  required String animationId,
  required String defaultTilesetId,
  required List<TilesetVisualFrame> frames,
  required int weight,
  required SmartTileFrameSampling sampling,
  required List<ProjectSmartTileAnimation> animations,
  required List<String> warnings,
}) {
  final refs = <ProjectSmartTileAnimationFrame>[];
  for (final frame in frames) {
    final tilesetId = _effectiveTilesetId(frame, defaultTilesetId);
    if (tilesetId.isEmpty) {
      warnings.add('A legacy visual frame has no tileset and was skipped.');
      continue;
    }
    refs.add(
      ProjectSmartTileAnimationFrame(
        frame: SmartTileFrameRef(
          atlasId: _legacyAtlasId(tilesetId),
          column: frame.source.x,
          row: frame.source.y,
          columnSpan: frame.source.width <= 0 ? 1 : frame.source.width,
          rowSpan: frame.source.height <= 0 ? 1 : frame.source.height,
        ),
        durationMs: frame.durationMs ?? 150,
      ),
    );
  }
  if (refs.isEmpty) return null;
  final SmartTileVisualSource source;
  if (refs.length == 1) {
    source = SmartTileVisualSource.frame(frame: refs.single.frame);
  } else {
    if (!animations.any((animation) => animation.id == animationId)) {
      animations.add(
        ProjectSmartTileAnimation(
          id: animationId,
          name: animationId,
          frames: refs,
        ),
      );
    }
    source = SmartTileVisualSource.animation(animationId: animationId);
  }
  return SmartTileCandidate(
    id: candidateId,
    weight: weight <= 0 ? 1 : weight,
    parts: <SmartTileVisualPart>[
      SmartTileVisualPart(source: source, frameSampling: sampling),
    ],
  );
}

_TerrainLayerMigration _migrateTerrainLayer({
  required MapData map,
  required TerrainLayer layer,
  required ProjectManifest project,
  required List<String> warnings,
}) {
  final presentTypes = <TerrainType>{
    for (final terrain in layer.terrains)
      if (terrain != TerrainType.none) terrain,
  }.toList()
    ..sort((left, right) => left.index.compareTo(right.index));
  if (presentTypes.isEmpty) {
    return const _TerrainLayerMigration(
      layers: <MapLayer>[],
      migratedLayerCount: 0,
      removedEmptyLayerCount: 1,
    );
  }
  final expectedCellCount = map.size.width * map.size.height;
  if (layer.terrains.length != expectedCellCount || presentTypes.length != 1) {
    warnings.add(
      'Terrain layer "${layer.id}" on map "${map.id}" stays legacy because '
      'native Smart Tile terrain layers require one visual material per '
      'layer.',
    );
    return _TerrainLayerMigration(
      layers: <MapLayer>[layer],
      migratedLayerCount: 0,
      removedEmptyLayerCount: 0,
    );
  }
  final generated = <MapLayer>[];
  final unresolved = <TerrainType>{};
  for (final type in presentTypes) {
    ProjectTerrainPreset? preset;
    for (final candidate in project.terrainPresets) {
      if (candidate.terrainType == type) {
        preset = candidate;
        break;
      }
    }
    if (preset == null) {
      unresolved.add(type);
      warnings.add(
        'Terrain layer "${layer.id}" on map "${map.id}" keeps legacy '
        'cells because terrain type "${type.name}" has no preset.',
      );
      continue;
    }
    final materialId = legacyTerrainSmartTileMaterialId(preset.id);
    final onlyResolvedType = presentTypes.length == 1;
    generated.add(
      MapLayer.smartTile(
        id: onlyResolvedType ? layer.id : '${layer.id}__${type.name}',
        name: onlyResolvedType ? layer.name : '${layer.name} — ${preset.name}',
        isVisible: layer.isVisible,
        opacity: layer.opacity,
        presetId: legacyTerrainSmartTilePresetId(preset.id),
        usage: SmartTileUsage.terrain,
        materialPalette: <String>[
          '',
          materialId,
          legacySmartTileEmptyMaterialId,
        ],
        materialCells: <int>[
          for (final terrain in layer.terrains) terrain == type ? 1 : 2,
        ],
        horizontalEdges: _emptyHorizontalEdges(map),
        verticalEdges: _emptyVerticalEdges(map),
        corners: _emptyCorners(map),
        properties: const <String, String>{
          'pokemap.migration.source': 'legacy_terrain',
        },
      ),
    );
  }
  if (unresolved.isNotEmpty) {
    generated.add(
      layer.copyWith(
        id: generated.isEmpty ? layer.id : '${layer.id}__legacy',
        terrains: <TerrainType>[
          for (final terrain in layer.terrains)
            unresolved.contains(terrain) ? terrain : TerrainType.none,
        ],
      ),
    );
  }
  return _TerrainLayerMigration(
    layers: generated,
    migratedLayerCount: generated.whereType<SmartTileLayer>().length,
    removedEmptyLayerCount: 0,
  );
}

MapLayer _migratePathLayer({
  required MapData map,
  required PathLayer layer,
  required ProjectManifest project,
  required List<String> warnings,
}) {
  ProjectPathPreset? preset;
  for (final candidate in project.pathPresets) {
    if (candidate.id == layer.presetId) {
      preset = candidate;
      break;
    }
  }
  if (preset == null) {
    warnings.add(
      'Path layer "${layer.id}" keeps its legacy type because preset '
      '"${layer.presetId}" does not exist.',
    );
    return layer;
  }
  final materialId = legacyPathSmartTileMaterialId(preset.id);
  return MapLayer.smartTile(
    id: layer.id,
    name: layer.name,
    isVisible: layer.isVisible,
    opacity: layer.opacity,
    presetId: legacyPathSmartTilePresetId(preset.id),
    usage: SmartTileUsage.path,
    materialPalette: <String>['', materialId],
    materialCells: <int>[for (final cell in layer.cells) cell ? 1 : 0],
    horizontalEdges: _emptyHorizontalEdges(map),
    verticalEdges: _emptyVerticalEdges(map),
    corners: _emptyCorners(map),
    properties: <String, String>{
      ...layer.properties,
      'pokemap.migration.source': 'legacy_path',
      'pokemap.migration.animationMode': layer.animationMode.name,
    },
  );
}

TerrainPathVariant _legacyPathVariantForBlobMask(int mask) {
  final cardinal = mask & smartTileCardinalMask;
  if (cardinal != smartTileCardinalMask) {
    return resolvePathVariantFromMask(cardinal);
  }
  final diagonals = <(int, TerrainPathVariant)>[
    (smartTileNorthEastBit, TerrainPathVariant.innerCornerNE),
    (smartTileSouthEastBit, TerrainPathVariant.innerCornerSE),
    (smartTileSouthWestBit, TerrainPathVariant.innerCornerSW),
    (smartTileNorthWestBit, TerrainPathVariant.innerCornerNW),
  ];
  final missing = diagonals.where((entry) => mask & entry.$1 == 0).toList();
  return missing.length == 1 ? missing.single.$2 : TerrainPathVariant.cross;
}

String _effectiveTilesetId(
  TilesetVisualFrame frame,
  String defaultTilesetId,
) {
  final override = frame.tilesetId.trim();
  return override.isEmpty ? defaultTilesetId.trim() : override;
}

String _legacyAtlasId(String tilesetId) => 'smart_atlas_$tilesetId';

List<int> _emptyHorizontalEdges(MapData map) => List<int>.filled(
      map.size.width * (map.size.height + 1),
      0,
      growable: false,
    );

List<int> _emptyVerticalEdges(MapData map) => List<int>.filled(
      (map.size.width + 1) * map.size.height,
      0,
      growable: false,
    );

List<int> _emptyCorners(MapData map) => List<int>.filled(
      (map.size.width + 1) * (map.size.height + 1),
      0,
      growable: false,
    );

@immutable
final class _TerrainLayerMigration {
  const _TerrainLayerMigration({
    required this.layers,
    required this.migratedLayerCount,
    required this.removedEmptyLayerCount,
  });

  final List<MapLayer> layers;
  final int migratedLayerCount;
  final int removedEmptyLayerCount;
}
