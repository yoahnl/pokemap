import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:map_core/map_core.dart';
import 'package:flutter/foundation.dart' show listEquals;

import 'spatial_ground.dart' show SpatialGroundBorderInputs;
import 'spatial_scene_neighbor.dart' show spatialConnectionOffset;

part 'spatial_scene_decoration_context.dart';
part 'spatial_scene_decoration_borders.dart';

final class SpatialDecorationRenderStats {
  const SpatialDecorationRenderStats({
    this.requestRevision = 0,
    this.committedRevision = 0,
    this.pending = false,
    this.sectorBuilds = 0,
    this.visibleSectors = 0,
  });
  final int requestRevision, committedRevision, sectorBuilds, visibleSectors;
  final bool pending;
  bool get ready => !pending && committedRevision == requestRevision;
}

final class SpatialSceneDecoration {
  const SpatialSceneDecoration({
    required this.ownerMapId,
    required this.decoration,
    required this.offset,
    required this.project,
    required this.loadGroundImage,
    required this.loadModel,
  });

  final String ownerMapId;
  final MapExteriorDecoration decoration;
  final Offset offset;
  final ProjectManifest project;
  final Future<Uint8List> Function(String id) loadGroundImage;
  final Future<Uint8List> Function(String id) loadModel;
}

final class SpatialDecorationProjection {
  SpatialDecorationProjection({
    required this.source,
    required this.sector,
    required this.offset,
    required this.excludedCells,
    required List<Rect> blockedBounds,
    List<Rect>? overhangBlockedBounds,
    MapData? cachedMap,
  }) : _blockedBounds = blockedBounds,
       _overhangBlockedBounds = overhangBlockedBounds,
       map =
           cachedMap ??
           sector.asVisualMap().copyWith(
             id: 'exterior:${source.ownerMapId}:${sector.id}',
           );

  final SpatialSceneDecoration source;
  final ExteriorDecorationSector sector;
  final MapData map;
  final Offset offset;
  final Set<(int, int)> excludedCells;
  final List<Rect> _blockedBounds;
  final List<Rect>? _overhangBlockedBounds;
  late final _environmentSupports = _decorationEnvironmentSupports(map, offset);
  List<Object?> _nativeContextSignature = const [];
  Map<String, SmartTileCellContextResolver> cellContextResolvers = const {};
  SpatialGroundBorderInputs borderGround = const SpatialGroundBorderInputs();
  List<_LogicalBorderSource> _logicalBorders = const [];
  List<SpatialGroundBorderInputs> _logicalBorderInputs = const [];
  List<Rect> _groundOcclusions = const [];
  bool renderTerrainBase = true;
  String get key => map.id;

  bool dependenciesMatch(SpatialDecorationProjection? previous) =>
      previous != null &&
      listEquals(previous._overhangBlockedBounds, _overhangBlockedBounds) &&
      previous._blockedBounds.length == _blockedBounds.length &&
      _blockedBounds.indexed.every(
        (entry) => entry.$2 == previous._blockedBounds[entry.$1],
      );

  bool allowsRasterVisual(SmartTileLayerVisual visual) {
    final bounds = visual.geometry.visualBounds;
    final footprint = Rect.fromLTWH(
      bounds.left + offset.dx,
      bounds.top + offset.dy,
      bounds.width,
      bounds.height,
    );
    return !_blockedBounds.any((blocked) => blocked.overlaps(footprint));
  }

  bool allowsModel(SpatialModelInstance instance, ProjectModel3dEntry model) {
    final visual = spatialDecorationModelFootprint(instance, model, offset);
    final root = Offset(
      instance.supportPosition.x + offset.dx,
      instance.supportPosition.z + offset.dy,
    );
    if (_blockedBounds.any((blocked) => blocked.contains(root))) return false;
    final support = _environmentSupports[instance.id];
    if (support != null &&
        _blockedBounds.any((blocked) => blocked.overlaps(support)))
      return false;
    if (_overhangBlockedBounds?.any((blocked) => blocked.overlaps(visual)) ==
        true)
      return false;
    if (model.collisionBounds case final bounds?) {
      final physical = spatialDecorationModelFootprint(
        instance,
        model,
        offset,
        bounds: bounds,
      );
      if (_blockedBounds.any((blocked) => blocked.overlaps(physical)))
        return false;
    }
    if (!_blockedBounds.any((blocked) => blocked.overlaps(visual))) return true;
    if (support == null ||
        _overhangBlockedBounds == null ||
        instance.clip != null)
      return false;
    if (!support.contains(root)) return false;
    return true;
  }
}

Map<String, Rect> _decorationEnvironmentSupports(MapData map, Offset offset) {
  final instances = {
    for (final instance
        in map.spatialScene?.instances ?? const <SpatialModelInstance>[])
      instance.id: instance,
  };
  final supports = <String, Rect>{};
  for (final layer in map.layers.whereType<EnvironmentLayer>()) {
    if (!layer.isVisible ||
        layer.opacity <= 0 ||
        !layer.content.targetsSpatialTerrain)
      continue;
    for (final area in layer.content.areas) {
      for (final id in area.generatedPlacementIds) {
        final instance = instances[id];
        if (instance == null) continue;
        try {
          final anchor = environmentSpatialPlacementAnchor(
            placementId: id,
            layerId: layer.id,
            areaId: area.id,
            modelId: instance.modelId,
          );
          if (!area.mask.isActiveAt(anchor.x, anchor.y)) continue;
          supports[id] = Rect.fromLTWH(
            offset.dx + anchor.x,
            offset.dy + anchor.y,
            1,
            1,
          );
        } on ValidationException {
          continue;
        }
      }
    }
  }
  return supports;
}

Rect _decorationConnectionApproach(
  Rect owner,
  MapConnection connection,
  List<({MapData map, Offset offset})> nativeMaps,
  Offset sceneOffset,
) {
  final target = nativeMaps
      .where(
        (entry) =>
            entry.map.id == connection.targetMapId &&
            entry.offset + sceneOffset ==
                owner.topLeft +
                    spatialConnectionOffset(
                      GridSize(
                        width: owner.width.toInt(),
                        height: owner.height.toInt(),
                      ),
                      entry.map.size,
                      connection.direction,
                      connection.offset,
                    ),
      )
      .firstOrNull;
  if (target != null) {
    final bounds = Rect.fromLTWH(
      target.offset.dx + sceneOffset.dx,
      target.offset.dy + sceneOffset.dy,
      target.map.size.width.toDouble(),
      target.map.size.height.toDouble(),
    );
    final approach = owner.inflate(1).intersect(bounds.inflate(1));
    if (approach.width > 0 && approach.height > 0) return approach;
  }
  return switch (connection.direction) {
    MapConnectionDirection.north => Rect.fromLTRB(
      owner.left - 1,
      owner.top - 1,
      owner.right + 1,
      owner.top + 1,
    ),
    MapConnectionDirection.east => Rect.fromLTRB(
      owner.right - 1,
      owner.top - 1,
      owner.right + 1,
      owner.bottom + 1,
    ),
    MapConnectionDirection.south => Rect.fromLTRB(
      owner.left - 1,
      owner.bottom - 1,
      owner.right + 1,
      owner.bottom + 1,
    ),
    MapConnectionDirection.west => Rect.fromLTRB(
      owner.left - 1,
      owner.top - 1,
      owner.left + 1,
      owner.bottom + 1,
    ),
  };
}

Rect spatialDecorationModelFootprint(
  SpatialModelInstance instance,
  ProjectModel3dEntry model,
  Offset offset, {
  Model3dBounds? bounds,
}) {
  bounds ??= model.inspection.bounds;
  final scale = model.scale * instance.scale;
  final angle = instance.rotationDegrees * math.pi / 180;
  final xs = <double>[], zs = <double>[];
  final clip = instance.clip;
  final left = clip == null
      ? bounds.min.x
      : math.max(bounds.min.x, model.pivot.x + clip.left / scale);
  final right = clip == null
      ? bounds.max.x
      : math.min(bounds.max.x, model.pivot.x + clip.right / scale);
  final top = clip == null
      ? bounds.min.z
      : math.max(bounds.min.z, model.pivot.z + clip.top / scale);
  final bottom = clip == null
      ? bounds.max.z
      : math.min(bounds.max.z, model.pivot.z + clip.bottom / scale);
  for (final x in [left, right]) {
    for (final z in [top, bottom]) {
      final localX = (x - model.pivot.x) * scale;
      final localZ = (z - model.pivot.z) * scale;
      xs.add(
        instance.position.x +
            offset.dx +
            localX * math.cos(angle) +
            localZ * math.sin(angle),
      );
      zs.add(
        instance.position.z +
            offset.dy -
            localX * math.sin(angle) +
            localZ * math.cos(angle),
      );
    }
  }
  return Rect.fromLTRB(
    xs.reduce(math.min),
    zs.reduce(math.min),
    xs.reduce(math.max),
    zs.reduce(math.max),
  );
}

List<SpatialDecorationProjection> projectSpatialDecorations({
  required List<SpatialSceneDecoration> decorations,
  required List<Rect> playableBounds,
  Offset sceneOffset = Offset.zero,
  Map<String, SpatialDecorationProjection> previous = const {},
  List<({MapData map, Offset offset})> nativeMaps = const [],
}) {
  final ordered = [...decorations]
    ..sort((a, b) => a.ownerMapId.compareTo(b.ownerMapId));
  final results = <SpatialDecorationProjection>[];
  final claimed = <Rect>[];
  final playable = [
    for (final bounds in playableBounds) bounds.shift(sceneOffset),
  ];
  for (final source in ordered) {
    if (source.ownerMapId != source.decoration.mapId) {
      throw StateError('Le propriétaire du décor extérieur est incohérent.');
    }
    final ownerOffset = source.offset + sceneOffset;
    final ownPlayable = Rect.fromLTWH(
      ownerOffset.dx,
      ownerOffset.dy,
      source.decoration.playableWidth.toDouble(),
      source.decoration.playableDepth.toDouble(),
    );
    final blocked = [...playable, ownPlayable, ...claimed];
    final owner = nativeMaps
        .where(
          (entry) =>
              entry.map.id == source.ownerMapId &&
              entry.offset + sceneOffset == ownerOffset,
        )
        .firstOrNull;
    final overhangBlocked = owner == null
        ? null
        : <Rect>[
            for (final bounds in playable)
              if (bounds != ownPlayable) bounds,
            ...claimed,
            for (final connection in owner.map.connections)
              _decorationConnectionApproach(
                ownPlayable,
                connection,
                nativeMaps,
                sceneOffset,
              ),
          ];
    final sectors = [...source.decoration.sectors]
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final sector in sectors) {
      final offset =
          ownerOffset +
          Offset(sector.originX.toDouble(), sector.originZ.toDouble());
      final prior = previous['exterior:${source.ownerMapId}:${sector.id}'];
      final reuseMask =
          prior != null &&
          prior.offset == offset &&
          prior.sector.scene.width == sector.scene.width &&
          prior.sector.scene.depth == sector.scene.depth &&
          prior._blockedBounds.length == blocked.length &&
          blocked.indexed.every(
            (entry) => entry.$2 == prior._blockedBounds[entry.$1],
          );
      final excluded = <(int, int)>{};
      for (var z = 0; !reuseMask && z < sector.scene.depth; z++) {
        for (var x = 0; x < sector.scene.width; x++) {
          final cell = Rect.fromLTWH(offset.dx + x, offset.dy + z, 1, 1);
          if (blocked.any((bounds) => bounds.overlaps(cell)))
            excluded.add((x, z));
        }
      }
      results.add(
        SpatialDecorationProjection(
          source: source,
          sector: sector,
          offset: offset,
          excludedCells: reuseMask
              ? prior.excludedCells
              : Set.unmodifiable(excluded),
          blockedBounds: blocked,
          overhangBlockedBounds: overhangBlocked,
          cachedMap: prior?.sector == sector ? prior?.map : null,
        ),
      );
    }
    _projectLogicalDecorationBorders(
      source,
      ownerOffset,
      blocked,
      results,
      previous,
      nativeMaps,
      claimed,
    );
    for (final sector in sectors) {
      final offset =
          ownerOffset +
          Offset(sector.originX.toDouble(), sector.originZ.toDouble());
      claimed.add(
        Rect.fromLTWH(
          offset.dx,
          offset.dy,
          sector.scene.width.toDouble(),
          sector.scene.depth.toDouble(),
        ),
      );
    }
  }
  _prepareDecorationNativeContexts(results, nativeMaps, previous, sceneOffset);
  return results;
}
