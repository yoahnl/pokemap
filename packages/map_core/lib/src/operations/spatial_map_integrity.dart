import 'dart:math' as math;

import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/map_spatial_scene.dart';
import '../models/project_manifest.dart';
import '../models/project_model3d.dart';
import 'spatial_border_resolution.dart';
import 'spatial_smart_tile_models.dart';

enum SpatialGroundGapState { exposed, unproven }

final class SpatialGroundGap {
  const SpatialGroundGap({
    required this.cell,
    required this.state,
    this.coveringInstanceIds = const [],
    this.partialBorderCover = false,
  });

  final GridPos cell;
  final SpatialGroundGapState state;
  final List<String> coveringInstanceIds;
  final bool partialBorderCover;

  Map<String, Object?> toJson() => {
    'cell': {'x': cell.x, 'y': cell.y},
    'state': state.name,
    if (coveringInstanceIds.isNotEmpty) 'coveringInstanceIds': coveringInstanceIds,
    if (partialBorderCover) 'partialBorderCover': true,
  };
}

final class SpatialBorderObjectOverlap {
  const SpatialBorderObjectOverlap({
    required this.layerId,
    required this.featureId,
    required this.instanceId,
    required this.modelId,
    required this.moduleCount,
    required this.firstCell,
    required this.lastCell,
  });

  final String layerId, featureId, instanceId, modelId;
  final int moduleCount;
  final GridPos firstCell, lastCell;

  String get key => '$layerId/$featureId|$instanceId';

  Map<String, Object?> toJson() => {
    'layerId': layerId,
    'featureId': featureId,
    'instanceId': instanceId,
    'modelId': modelId,
    'moduleCount': moduleCount,
    'firstCell': {'x': firstCell.x, 'y': firstCell.y},
    'lastCell': {'x': lastCell.x, 'y': lastCell.y},
  };
}

final class SpatialGroundGapCluster {
  const SpatialGroundGapCluster({
    required this.cells,
    required this.centerX,
    required this.centerZ,
    required this.exposedCellCount,
    required this.coveringInstanceIds,
  });

  final List<GridPos> cells;
  final double centerX, centerZ;
  final int exposedCellCount;
  final List<String> coveringInstanceIds;

  Map<String, Object?> toJson() => {
    'center': {'x': centerX, 'z': centerZ},
    'cellCount': cells.length,
    'exposedCellCount': exposedCellCount,
    'firstCell': {'x': cells.first.x, 'y': cells.first.y},
    if (coveringInstanceIds.isNotEmpty) 'coveringInstanceIds': coveringInstanceIds,
  };
}

final class SpatialMapIntegrityReport {
  const SpatialMapIntegrityReport({
    required this.groundGaps,
    required this.borderObjectOverlaps,
  });

  static const empty = SpatialMapIntegrityReport(groundGaps: [], borderObjectOverlaps: []);

  final List<SpatialGroundGap> groundGaps;
  final List<SpatialBorderObjectOverlap> borderObjectOverlaps;

  int get exposedCellCount =>
      groundGaps.where((gap) => gap.state == SpatialGroundGapState.exposed).length;
  int get unprovenCellCount => groundGaps.length - exposedCellCount;

  /// Gaps grouped by 8-connectivity, largest first, to frame one view each.
  List<SpatialGroundGapCluster> get gapClusters {
    final byCell = {for (final gap in groundGaps) (gap.cell.x, gap.cell.y): gap};
    final seen = <(int, int)>{};
    final clusters = <SpatialGroundGapCluster>[];
    for (final gap in groundGaps) {
      final start = (gap.cell.x, gap.cell.y);
      if (!seen.add(start)) continue;
      final members = <SpatialGroundGap>[];
      final pending = [start];
      while (pending.isNotEmpty) {
        final (x, z) = pending.removeLast();
        members.add(byCell[(x, z)]!);
        for (var dz = -1; dz <= 1; dz++) {
          for (var dx = -1; dx <= 1; dx++) {
            final next = (x + dx, z + dz);
            if (byCell.containsKey(next) && seen.add(next)) pending.add(next);
          }
        }
      }
      members.sort((a, b) => a.cell.y != b.cell.y ? a.cell.y - b.cell.y : a.cell.x - b.cell.x);
      clusters.add(SpatialGroundGapCluster(
        cells: [for (final member in members) member.cell],
        centerX: members.fold<double>(0, (sum, m) => sum + m.cell.x + .5) / members.length,
        centerZ: members.fold<double>(0, (sum, m) => sum + m.cell.y + .5) / members.length,
        exposedCellCount: members.where((m) => m.state == SpatialGroundGapState.exposed).length,
        coveringInstanceIds: ({for (final m in members) ...m.coveringInstanceIds}.toList()..sort()),
      ));
    }
    clusters.sort((a, b) => b.cells.length - a.cells.length);
    return clusters;
  }

  /// Gaps and overlaps of [this] that [before] did not already report.
  SpatialMapIntegrityReport introducedSince(SpatialMapIntegrityReport before) {
    final previous = {
      for (final gap in before.groundGaps) (gap.cell.x, gap.cell.y): gap.state,
    };
    final overlaps = {for (final overlap in before.borderObjectOverlaps) overlap.key};
    return SpatialMapIntegrityReport(
      groundGaps: [
        for (final gap in groundGaps)
          if (switch (previous[(gap.cell.x, gap.cell.y)]) {
            null => true,
            SpatialGroundGapState.unproven => gap.state == SpatialGroundGapState.exposed,
            SpatialGroundGapState.exposed => false,
          })
            gap,
      ],
      borderObjectOverlaps: [
        for (final overlap in borderObjectOverlaps)
          if (!overlaps.contains(overlap.key)) overlap,
      ],
    );
  }
}

const _samples = [.2, .5, .8];

/// Finds enclosed cells where nothing proves a ground is drawn, and placed
/// objects whose bounds cross Border modules.
///
/// A cell has proven ground when a visible Smart Tile layer paints it without
/// a Border mask, when a Smart Tile model replaces its ground, or when Border
/// ground replacements or surfaces cover all its samples. Object bounds and
/// partial Border coverage can hide a hole without proving ground: such cells
/// are `unproven` and need a visual check. Cells connected to the map edge
/// through cells without ground are the map's outer void and are ignored.
SpatialMapIntegrityReport inspectSpatialMapIntegrity({
  required ProjectManifest manifest,
  required MapData map,
}) {
  final scene = map.spatialScene;
  if (scene == null) return SpatialMapIntegrityReport.empty;
  final width = scene.width, depth = scene.depth;
  final masks = resolveSpatialBorderGroundMaskCellsByLayer(manifest: manifest, map: map);
  final replacements = indexSpatialBorderGroundReplacements(
    scene: scene,
    replacements: resolveSpatialBorderGroundReplacements(manifest: manifest, map: map),
  );
  final surfaces = <(int, int), List<SpatialBorderGroundSurface>>{};
  for (final surface in resolveSpatialBorderGroundSurfaces(manifest: manifest, map: map)) {
    for (final footprint in surface.footprints) {
      final xs = footprint.points.map((point) => point.x);
      final zs = footprint.points.map((point) => point.z);
      for (var z = math.max(0, zs.reduce(math.min).floor());
          z < math.min(depth, zs.reduce(math.max).ceil()); z++) {
        for (var x = math.max(0, xs.reduce(math.min).floor());
            x < math.min(width, xs.reduce(math.max).ceil()); x++) {
          surfaces.putIfAbsent((x, z), () => []).add(surface);
        }
      }
    }
  }
  final modelGround = {
    for (final cells in resolveSpatialSmartTileModelProjection(
      map: map,
      catalog: manifest.smartTileCatalog,
      sourceCellWidth: manifest.settings.tileWidth,
      sourceCellHeight: manifest.settings.tileHeight,
    ).groundReplacements.values)
      ...cells,
  };
  final painted = [
    for (final layer in map.layers.whereType<SmartTileLayer>())
      if (layer.isVisible && layer.opacity > 0)
        (cells: layer.field.semanticCells, masked: masks[layer.id] ?? const <(int, int)>{}),
  ];
  final owners = <String, ({String layerId, String featureId})>{
    for (final layer in map.layers.whereType<BorderLayer>())
      for (final feature in layer.content.features)
        for (final placement in feature.materialization?.spatialPlacements ?? const [])
          placement.instanceId: (layerId: layer.id, featureId: feature.id),
  };
  final models = {for (final model in manifest.models3d) model.id: model};
  final environmentModels = {
    for (final preset in manifest.environmentPresets)
      for (final item in preset.palette) ?item.modelId,
  };
  final moduleBoxes = <(_Box, ({String layerId, String featureId}))>[];
  final objectBoxes = <_Box>[];
  for (final instance in scene.instances) {
    final model = models[instance.modelId];
    if (model == null) continue;
    final owner = owners[instance.id];
    if (owner != null) {
      moduleBoxes.add((_Box.of(instance, model), owner));
    } else if (!environmentModels.contains(instance.modelId)) {
      objectBoxes.add(_Box.of(instance, model));
    }
  }
  final coverIndex = <(int, int), List<_Box>>{};
  for (final box in [
    ...objectBoxes,
    for (final instance in scene.instances)
      if (environmentModels.contains(instance.modelId) && models[instance.modelId] != null)
        _Box.of(instance, models[instance.modelId]!),
  ]) {
    for (var z = math.max(0, box.minZ.floor()); z < math.min(depth, box.maxZ.ceil()); z++) {
      for (var x = math.max(0, box.minX.floor()); x < math.min(width, box.maxX.ceil()); x++) {
        coverIndex.putIfAbsent((x, z), () => []).add(box);
      }
    }
  }

  bool paintedAt(int x, int z) {
    final index = z * width + x;
    for (final layer in painted) {
      if (index < layer.cells.length && layer.cells[index] != 0 && !layer.masked.contains((x, z))) {
        return true;
      }
    }
    return modelGround.contains((x, z));
  }

  final gaps = <(int, int), SpatialGroundGap>{};
  for (var z = 0; z < depth; z++) {
    for (var x = 0; x < width; x++) {
      if (paintedAt(x, z)) continue;
      final cellReplacements = replacements[(x, z)] ?? const [];
      final cellSurfaces = surfaces[(x, z)] ?? const [];
      final covers = coverIndex[(x, z)] ?? const <_Box>[];
      var proven = 0;
      final hiding = <String>{};
      var borderPartial = false;
      for (final dz in _samples) {
        for (final dx in _samples) {
          final px = x + dx, pz = z + dz;
          if (cellReplacements.any((replacement) => replacement.contains(px, pz)) ||
              cellSurfaces.any((surface) => surface.footprints.any((f) => f.contains(px, pz)))) {
            proven++;
            borderPartial = true;
            continue;
          }
          for (final box in covers) {
            if (box.containsXZ(px, pz)) hiding.add(box.instanceId);
          }
        }
      }
      if (proven == _samples.length * _samples.length) continue;
      gaps[(x, z)] = SpatialGroundGap(
        cell: GridPos(x: x, y: z),
        state: hiding.isEmpty && !borderPartial
            ? SpatialGroundGapState.exposed
            : SpatialGroundGapState.unproven,
        coveringInstanceIds: (hiding.toList()..sort()),
        partialBorderCover: borderPartial,
      );
    }
  }
  final outside = <(int, int)>{};
  final pending = <(int, int)>[];
  void visit((int, int) cell) {
    if (gaps.containsKey(cell) && outside.add(cell)) pending.add(cell);
  }
  for (var x = 0; x < width; x++) {
    visit((x, 0));
    visit((x, depth - 1));
  }
  for (var z = 0; z < depth; z++) {
    visit((0, z));
    visit((width - 1, z));
  }
  while (pending.isNotEmpty) {
    final (x, z) = pending.removeLast();
    if (x > 0) visit((x - 1, z));
    if (x < width - 1) visit((x + 1, z));
    if (z > 0) visit((x, z - 1));
    if (z < depth - 1) visit((x, z + 1));
  }

  final overlaps = <String, ({SpatialBorderObjectOverlap first, int count, int minX, int minZ, int maxX, int maxZ})>{};
  for (final object in objectBoxes) {
    for (final (module, owner) in moduleBoxes) {
      final ix = math.min(object.maxX, module.maxX) - math.max(object.minX, module.minX);
      final iz = math.min(object.maxZ, module.maxZ) - math.max(object.minZ, module.minZ);
      final iy = math.min(object.maxY, module.maxY) - math.max(object.minY, module.minY);
      if (ix <= .25 || iz <= .25 || iy <= .1) continue;
      final cx = ((math.max(object.minX, module.minX) + math.min(object.maxX, module.maxX)) / 2).floor();
      final cz = ((math.max(object.minZ, module.minZ) + math.min(object.maxZ, module.maxZ)) / 2).floor();
      final key = '${owner.layerId}/${owner.featureId}|${object.instanceId}';
      final current = overlaps[key];
      overlaps[key] = current == null
          ? (
              first: SpatialBorderObjectOverlap(
                layerId: owner.layerId,
                featureId: owner.featureId,
                instanceId: object.instanceId,
                modelId: object.modelId,
                moduleCount: 0,
                firstCell: GridPos(x: cx, y: cz),
                lastCell: GridPos(x: cx, y: cz),
              ),
              count: 1, minX: cx, minZ: cz, maxX: cx, maxZ: cz,
            )
          : (
              first: current.first,
              count: current.count + 1,
              minX: math.min(current.minX, cx),
              minZ: math.min(current.minZ, cz),
              maxX: math.max(current.maxX, cx),
              maxZ: math.max(current.maxZ, cz),
            );
    }
  }
  return SpatialMapIntegrityReport(
    groundGaps: [
      for (var z = 0; z < depth; z++)
        for (var x = 0; x < width; x++)
          if (gaps[(x, z)] case final gap? when !outside.contains((x, z))) gap,
    ],
    borderObjectOverlaps: [
      for (final entry in (overlaps.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
        SpatialBorderObjectOverlap(
          layerId: entry.value.first.layerId,
          featureId: entry.value.first.featureId,
          instanceId: entry.value.first.instanceId,
          modelId: entry.value.first.modelId,
          moduleCount: entry.value.count,
          firstCell: GridPos(x: entry.value.minX, y: entry.value.minZ),
          lastCell: GridPos(x: entry.value.maxX, y: entry.value.maxZ),
        ),
    ],
  );
}

final class _Box {
  const _Box(this.instanceId, this.modelId, this.minX, this.maxX, this.minY, this.maxY, this.minZ, this.maxZ);

  factory _Box.of(SpatialModelInstance instance, ProjectModel3dEntry model) {
    final bounds = model.inspection.bounds;
    final scale = model.scale * instance.scale;
    final angle = instance.rotationDegrees * math.pi / 180;
    final cos = math.cos(angle), sin = math.sin(angle);
    var minX = double.infinity, maxX = -double.infinity;
    var minZ = double.infinity, maxZ = -double.infinity;
    for (final px in [bounds.min.x, bounds.max.x]) {
      for (final pz in [bounds.min.z, bounds.max.z]) {
        final lx = (px - model.pivot.x) * scale, lz = (pz - model.pivot.z) * scale;
        final wx = instance.position.x + cos * lx + sin * lz;
        final wz = instance.position.z - sin * lx + cos * lz;
        minX = math.min(minX, wx);
        maxX = math.max(maxX, wx);
        minZ = math.min(minZ, wz);
        maxZ = math.max(maxZ, wz);
      }
    }
    return _Box(
      instance.id,
      instance.modelId,
      minX,
      maxX,
      instance.position.y + (bounds.min.y - model.pivot.y) * scale,
      instance.position.y + (bounds.max.y - model.pivot.y) * scale,
      minZ,
      maxZ,
    );
  }

  final String instanceId, modelId;
  final double minX, maxX, minY, maxY, minZ, maxZ;

  bool containsXZ(double x, double z) => x >= minX && x <= maxX && z >= minZ && z <= maxZ;
}
