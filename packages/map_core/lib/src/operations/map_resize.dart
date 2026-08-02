import 'dart:math' as math;

import '../exceptions/map_exceptions.dart';
import '../models/border_diagnostics.dart';
import '../models/border_layer.dart';
import '../models/enums.dart';
import '../models/environment.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import '../models/smart_tile_field.dart';
import 'border_resize.dart';
import 'map_placed_element_footprint.dart';

const int _maximumResizeImpactPositionSamples = 8;

/// Authored map collection that would be affected by a resize.
///
/// The enum deliberately stays presentation-neutral. Editor clients can group
/// or localize impacts without parsing engine messages.
enum MapResizeImpactKind {
  tileLayer,
  collisionLayer,
  terrainLayer,
  pathLayer,
  smartTileLayer,
  surfaceLayer,
  environmentArea,
  borderLayer,
  placedElement,
  generatedPlacementReference,
  entity,
  entityWaypoint,
  warp,
  warpTriggerArea,
  localWarpTarget,
  trigger,
  gameplayZone,
  event,
  connection,
}

/// Stable reason why an authored collection appears in a resize preview.
enum MapResizeImpactReason {
  clippedCells,
  positionOutside,
  footprintOutside,
  footprintUnknown,
  areaOutside,
  patrolWaypointOutside,
  localTargetOutside,
  triggerAreaClipped,
  danglingReference,
  borderDiagnostic,
  connectionTopologyChanged,
  missingContext,
}

/// One machine-readable entry in a [MapResizePlan].
///
/// Layer data is aggregated per layer or environment area. Authored objects
/// are emitted individually, which lets the editor list every affected object
/// without recreating Core's spatial rules. [affectedCount] is exact while
/// [positions] is a bounded diagnostic sample, preventing a large clipped map
/// from allocating millions of coordinate objects during live preview.
final class MapResizeImpact {
  factory MapResizeImpact({
    required MapResizeImpactKind kind,
    required MapResizeImpactReason reason,
    required String subjectId,
    required String subjectLabel,
    String? layerId,
    int affectedCount = 1,
    List<GridPos> positions = const <GridPos>[],
    List<String> relatedIds = const <String>[],
    String? diagnosticCode,
  }) {
    if (affectedCount <= 0) {
      throw const ValidationException(
        'MapResizeImpact.affectedCount must be positive',
      );
    }
    return MapResizeImpact._(
      kind: kind,
      reason: reason,
      subjectId: subjectId,
      subjectLabel: subjectLabel,
      layerId: layerId,
      affectedCount: affectedCount,
      positions: List<GridPos>.unmodifiable(positions),
      relatedIds: List<String>.unmodifiable(relatedIds),
      diagnosticCode: diagnosticCode,
    );
  }

  const MapResizeImpact._({
    required this.kind,
    required this.reason,
    required this.subjectId,
    required this.subjectLabel,
    required this.layerId,
    required this.affectedCount,
    required this.positions,
    required this.relatedIds,
    required this.diagnosticCode,
  });

  final MapResizeImpactKind kind;
  final MapResizeImpactReason reason;
  final String subjectId;
  final String subjectLabel;
  final String? layerId;
  final int affectedCount;
  final List<GridPos> positions;
  final List<String> relatedIds;
  final String? diagnosticCode;
}

/// Pure, immutable preview of a complete map resize.
///
/// [canApply] is intentionally conservative. A plan is applicable only when
/// Core can prove that the target size preserves all authored data and known
/// spatial semantics. There is no destructive override in DS-06.
final class MapResizePlan {
  factory MapResizePlan({
    required GridSize sourceSize,
    required GridSize targetSize,
    required List<MapResizeImpact> impacts,
    BorderDiagnosticsReport borderDiagnostics =
        const BorderDiagnosticsReport.empty(),
  }) =>
      MapResizePlan._(
        sourceSize: sourceSize,
        targetSize: targetSize,
        impacts: List<MapResizeImpact>.unmodifiable(impacts),
        borderDiagnostics: borderDiagnostics,
      );

  const MapResizePlan._({
    required this.sourceSize,
    required this.targetSize,
    required this.impacts,
    required this.borderDiagnostics,
  });

  final GridSize sourceSize;
  final GridSize targetSize;
  final List<MapResizeImpact> impacts;
  final BorderDiagnosticsReport borderDiagnostics;

  bool get isNoOp => sourceSize == targetSize;

  bool get isExpansion =>
      !isNoOp &&
      targetSize.width >= sourceSize.width &&
      targetSize.height >= sourceSize.height;

  bool get hasShrink =>
      targetSize.width < sourceSize.width ||
      targetSize.height < sourceSize.height;

  bool get hasDestructiveImpacts => impacts.isNotEmpty;

  bool get canApply => !hasDestructiveImpacts;
}

/// Builds the complete, side-effect-free impact plan for a map resize.
///
/// [project] resolves multi-cell `ProjectElementEntry` footprints. When a
/// shrink contains placed elements but no matching project context, the plan
/// fails closed instead of assuming a one-cell footprint.
///
/// [tileSizePx] is required only when the map contains Border layers. Border
/// diagnostics are folded into the same plan so their clipping and structural
/// errors are visible before any map mutation.
MapResizePlan planMapResize(
  MapData map, {
  required int width,
  required int height,
  ProjectManifest? project,
  GridSize? tileSizePx,
}) {
  if (width <= 0 || height <= 0) {
    throw const ValidationException('Map size must be positive');
  }

  final sourceSize = map.size;
  final targetSize = GridSize(width: width, height: height);
  final impacts = <MapResizeImpact>[];
  final borderDiagnostics = <BorderDiagnostic>[];

  for (final layer in map.layers) {
    if (layer is TileLayer) {
      _addClippedLayerImpact<int>(
        impacts: impacts,
        kind: MapResizeImpactKind.tileLayer,
        layerId: layer.id,
        layerName: layer.name,
        values: layer.tiles,
        sourceSize: sourceSize,
        targetSize: targetSize,
        isMeaningful: (value) => value != 0,
      );
      continue;
    }
    if (layer is CollisionLayer) {
      _addClippedLayerImpact<bool>(
        impacts: impacts,
        kind: MapResizeImpactKind.collisionLayer,
        layerId: layer.id,
        layerName: layer.name,
        values: layer.collisions,
        sourceSize: sourceSize,
        targetSize: targetSize,
        isMeaningful: (value) => value,
      );
      continue;
    }
    if (layer is TerrainLayer) {
      _addClippedLayerImpact<TerrainType>(
        impacts: impacts,
        kind: MapResizeImpactKind.terrainLayer,
        layerId: layer.id,
        layerName: layer.name,
        values: layer.terrains,
        sourceSize: sourceSize,
        targetSize: targetSize,
        isMeaningful: (value) => value != TerrainType.none,
      );
      continue;
    }
    if (layer is PathLayer) {
      _addClippedLayerImpact<bool>(
        impacts: impacts,
        kind: MapResizeImpactKind.pathLayer,
        layerId: layer.id,
        layerName: layer.name,
        values: layer.cells,
        sourceSize: sourceSize,
        targetSize: targetSize,
        isMeaningful: (value) => value,
      );
      continue;
    }
    if (layer is SmartTileLayer) {
      _addClippedSmartTileLayerImpact(
        impacts: impacts,
        layer: layer,
        sourceSize: sourceSize,
        targetSize: targetSize,
      );
      continue;
    }
    if (layer is SurfaceLayer) {
      final clipped = _outsidePositionSummary(
        positions: layer.placements.map(
          (placement) => GridPos(x: placement.x, y: placement.y),
        ),
        targetSize: targetSize,
      );
      if (clipped.isNotEmpty) {
        impacts.add(
          MapResizeImpact(
            kind: MapResizeImpactKind.surfaceLayer,
            reason: MapResizeImpactReason.positionOutside,
            subjectId: layer.id,
            subjectLabel: _labelOrId(layer.name, layer.id),
            layerId: layer.id,
            affectedCount: clipped.count,
            positions: clipped.positions,
          ),
        );
      }
      continue;
    }
    if (layer is EnvironmentLayer) {
      for (final area in layer.content.areas) {
        final clipped = _clippedMeaningfulPositions<bool>(
          values: area.mask.cells,
          sourceSize: sourceSize,
          targetSize: targetSize,
          isMeaningful: (value) => value,
        );
        if (clipped.isEmpty) continue;
        impacts.add(
          MapResizeImpact(
            kind: MapResizeImpactKind.environmentArea,
            reason: MapResizeImpactReason.clippedCells,
            subjectId: area.id,
            subjectLabel: _labelOrId(area.name, area.id),
            layerId: layer.id,
            affectedCount: clipped.count,
            positions: clipped.positions,
          ),
        );
      }
      continue;
    }
    if (layer is BorderLayer) {
      final resolvedTileSize = tileSizePx;
      if (resolvedTileSize == null) {
        impacts.add(
          MapResizeImpact(
            kind: MapResizeImpactKind.borderLayer,
            reason: MapResizeImpactReason.missingContext,
            subjectId: layer.id,
            subjectLabel: _labelOrId(layer.name, layer.id),
            layerId: layer.id,
          ),
        );
        continue;
      }
      final result = resizeBorderLayerContent(
        content: layer.content,
        oldMapSize: sourceSize,
        newMapSize: targetSize,
        tileSizePx: resolvedTileSize,
        layerId: layer.id,
      );
      borderDiagnostics.addAll(result.diagnosticReport.diagnostics);
      for (final diagnostic in result.diagnosticReport.diagnostics) {
        if (diagnostic.severity == BorderDiagnosticSeverity.info) continue;
        final subjectId = diagnostic.featureId ?? layer.id;
        impacts.add(
          MapResizeImpact(
            kind: MapResizeImpactKind.borderLayer,
            reason: MapResizeImpactReason.borderDiagnostic,
            subjectId: subjectId,
            subjectLabel: subjectId == layer.id
                ? _labelOrId(layer.name, layer.id)
                : subjectId,
            layerId: layer.id,
            affectedCount: _borderDiagnosticAffectedCount(diagnostic),
            positions: diagnostic.cell == null
                ? const <GridPos>[]
                : <GridPos>[diagnostic.cell!],
            diagnosticCode: diagnostic.code,
          ),
        );
      }
    }
  }

  final removedPlacedElementIds = <String>{};
  final projectElements = project == null
      ? const <String, ProjectElementEntry>{}
      : <String, ProjectElementEntry>{
          for (final element in project.elements) element.id: element,
        };
  for (final instance in map.placedElements) {
    if (!_isInBounds(instance.pos, targetSize)) {
      removedPlacedElementIds.add(instance.id);
      impacts.add(
        MapResizeImpact(
          kind: MapResizeImpactKind.placedElement,
          reason: MapResizeImpactReason.positionOutside,
          subjectId: instance.id,
          subjectLabel: instance.id,
          layerId: instance.layerId,
          positions: <GridPos>[instance.pos],
          relatedIds: <String>[instance.elementId],
        ),
      );
      continue;
    }
    if (!_hasShrink(sourceSize, targetSize)) continue;

    final element = projectElements[instance.elementId];
    if (element == null || element.frames.isEmpty) {
      impacts.add(
        MapResizeImpact(
          kind: MapResizeImpactKind.placedElement,
          reason: project == null
              ? MapResizeImpactReason.missingContext
              : MapResizeImpactReason.footprintUnknown,
          subjectId: instance.id,
          subjectLabel: instance.id,
          layerId: instance.layerId,
          positions: <GridPos>[instance.pos],
          relatedIds: <String>[instance.elementId],
        ),
      );
      continue;
    }

    final footprint = resolveMapPlacedElementFootprint(
      instance: instance,
      element: element,
    ).destinationSize;
    final clipped = _clippedRectPositions(
      origin: instance.pos,
      size: footprint,
      targetSize: targetSize,
    );
    if (clipped.isNotEmpty) {
      impacts.add(
        MapResizeImpact(
          kind: MapResizeImpactKind.placedElement,
          reason: MapResizeImpactReason.footprintOutside,
          subjectId: instance.id,
          subjectLabel: _labelOrId(element.name, instance.id),
          layerId: instance.layerId,
          affectedCount: clipped.count,
          positions: clipped.positions,
          relatedIds: <String>[instance.elementId],
        ),
      );
    }
  }

  if (removedPlacedElementIds.isNotEmpty) {
    for (final layer in map.layers.whereType<EnvironmentLayer>()) {
      for (final area in layer.content.areas) {
        final danglingIds = area.generatedPlacementIds
            .where(removedPlacedElementIds.contains)
            .toList(growable: false);
        if (danglingIds.isEmpty) continue;
        impacts.add(
          MapResizeImpact(
            kind: MapResizeImpactKind.generatedPlacementReference,
            reason: MapResizeImpactReason.danglingReference,
            subjectId: area.id,
            subjectLabel: _labelOrId(area.name, area.id),
            layerId: layer.id,
            affectedCount: danglingIds.length,
            relatedIds: danglingIds,
          ),
        );
      }
    }
  }

  for (final entity in map.entities) {
    final clipped = _clippedRectPositions(
      origin: entity.pos,
      size: entity.size,
      targetSize: targetSize,
    );
    if (clipped.isNotEmpty) {
      impacts.add(
        MapResizeImpact(
          kind: MapResizeImpactKind.entity,
          reason: _isInBounds(entity.pos, targetSize)
              ? MapResizeImpactReason.footprintOutside
              : MapResizeImpactReason.positionOutside,
          subjectId: entity.id,
          subjectLabel: _labelOrId(entity.name, entity.id),
          affectedCount: clipped.count,
          positions: clipped.positions,
        ),
      );
    }
    final clippedWaypoints = _outsidePositionSummary(
      positions: entity.npc?.movement.waypoints ?? const <GridPos>[],
      targetSize: targetSize,
    );
    if (clippedWaypoints.isNotEmpty) {
      impacts.add(
        MapResizeImpact(
          kind: MapResizeImpactKind.entityWaypoint,
          reason: MapResizeImpactReason.patrolWaypointOutside,
          subjectId: entity.id,
          subjectLabel: _labelOrId(entity.name, entity.id),
          affectedCount: clippedWaypoints.count,
          positions: clippedWaypoints.positions,
        ),
      );
    }
  }

  for (final warp in map.warps) {
    if (!_isInBounds(warp.pos, targetSize)) {
      impacts.add(
        MapResizeImpact(
          kind: MapResizeImpactKind.warp,
          reason: MapResizeImpactReason.positionOutside,
          subjectId: warp.id,
          subjectLabel: warp.id,
          positions: <GridPos>[warp.pos],
          relatedIds: <String>[warp.targetMapId],
        ),
      );
    }
    if (warp.targetMapId == map.id &&
        !_isInBounds(warp.targetPos, targetSize)) {
      impacts.add(
        MapResizeImpact(
          kind: MapResizeImpactKind.localWarpTarget,
          reason: MapResizeImpactReason.localTargetOutside,
          subjectId: warp.id,
          subjectLabel: warp.id,
          positions: <GridPos>[warp.targetPos],
          relatedIds: <String>[warp.targetMapId],
        ),
      );
    }
    final clippedTriggerCells = _clippedWarpTriggerCells(
      warp: warp,
      sourceSize: sourceSize,
      targetSize: targetSize,
    );
    if (clippedTriggerCells.isNotEmpty) {
      impacts.add(
        MapResizeImpact(
          kind: MapResizeImpactKind.warpTriggerArea,
          reason: MapResizeImpactReason.triggerAreaClipped,
          subjectId: warp.id,
          subjectLabel: warp.id,
          affectedCount: clippedTriggerCells.count,
          positions: clippedTriggerCells.positions,
          relatedIds: <String>[warp.targetMapId],
        ),
      );
    }
  }

  for (final trigger in map.triggers) {
    final clipped = _clippedRectPositions(
      origin: trigger.area.pos,
      size: trigger.area.size,
      targetSize: targetSize,
    );
    if (clipped.isEmpty) continue;
    impacts.add(
      MapResizeImpact(
        kind: MapResizeImpactKind.trigger,
        reason: MapResizeImpactReason.areaOutside,
        subjectId: trigger.id,
        subjectLabel: _labelOrId(trigger.name, trigger.id),
        affectedCount: clipped.count,
        positions: clipped.positions,
      ),
    );
  }

  for (final zone in map.gameplayZones) {
    final clipped = _clippedRectPositions(
      origin: zone.area.pos,
      size: zone.area.size,
      targetSize: targetSize,
    );
    if (clipped.isEmpty) continue;
    impacts.add(
      MapResizeImpact(
        kind: MapResizeImpactKind.gameplayZone,
        reason: MapResizeImpactReason.areaOutside,
        subjectId: zone.id,
        subjectLabel: _labelOrId(zone.name, zone.id),
        affectedCount: clipped.count,
        positions: clipped.positions,
      ),
    );
  }

  for (final event in map.events) {
    final position = GridPos(x: event.position.x, y: event.position.y);
    if (_isInBounds(position, targetSize)) continue;
    impacts.add(
      MapResizeImpact(
        kind: MapResizeImpactKind.event,
        reason: MapResizeImpactReason.positionOutside,
        subjectId: event.id,
        subjectLabel: _labelOrId(event.title, event.id),
        layerId: event.position.layerId,
        positions: <GridPos>[position],
      ),
    );
  }

  // Every connection depends on a source border. Shrinking either dimension
  // can move that border or remove aligned crossing cells, so DS-06 blocks the
  // operation until a future connection-aware migration can prove equivalence.
  if (_hasShrink(sourceSize, targetSize)) {
    for (final connection in map.connections) {
      impacts.add(
        MapResizeImpact(
          kind: MapResizeImpactKind.connection,
          reason: MapResizeImpactReason.connectionTopologyChanged,
          subjectId: connection.direction.name,
          subjectLabel: connection.targetMapId,
          relatedIds: <String>[connection.targetMapId],
        ),
      );
    }
  }

  return MapResizePlan(
    sourceSize: sourceSize,
    targetSize: targetSize,
    impacts: impacts,
    borderDiagnostics: BorderDiagnosticsReport(
      diagnostics: borderDiagnostics,
    ),
  );
}

/// Atomic map-level result for the Border-aware resize path.
final class MapResizeWithBorderDiagnosticsResult {
  factory MapResizeWithBorderDiagnosticsResult({
    required MapData? map,
    required BorderDiagnosticsReport diagnosticReport,
    required bool canApply,
  }) {
    final hasErrors = diagnosticReport.hasErrors;
    if ((map == null) != hasErrors) {
      throw const ValidationException(
        'MapResizeWithBorderDiagnosticsResult.map must be null exactly when '
        'errors exist',
      );
    }
    if (canApply != !hasErrors) {
      throw const ValidationException(
        'MapResizeWithBorderDiagnosticsResult.canApply must be true exactly '
        'when no errors exist',
      );
    }
    return MapResizeWithBorderDiagnosticsResult._(
      map: map,
      diagnosticReport: diagnosticReport,
      canApply: canApply,
    );
  }

  const MapResizeWithBorderDiagnosticsResult._({
    required this.map,
    required this.diagnosticReport,
    required this.canApply,
  });

  final MapData? map;
  final BorderDiagnosticsReport diagnosticReport;
  final bool canApply;
}

MapData resizeMapData(
  MapData map, {
  required int width,
  required int height,
}) {
  if (width <= 0 || height <= 0) {
    throw const ValidationException('Map size must be positive');
  }

  final oldSize = map.size;
  if (oldSize.width == width && oldSize.height == height) return map;

  if (map.layers.any((layer) => layer is BorderLayer)) {
    throw const ValidationException(
      'Maps with Border layers must be resized with '
      'resizeMapDataWithBorderDiagnostics',
    );
  }

  return _resizeMapDataLegacyLayers(
    map,
    width: width,
    height: height,
  );
}

/// Resizes a complete map after atomically preflighting every Border layer.
MapResizeWithBorderDiagnosticsResult resizeMapDataWithBorderDiagnostics(
  MapData map, {
  required int width,
  required int height,
  required GridSize tileSizePx,
}) {
  final oldSize = map.size;
  final newSize = GridSize(width: width, height: height);
  final borderLayers = map.layers.whereType<BorderLayer>().toList(
        growable: false,
      );
  if (borderLayers.isEmpty) {
    return MapResizeWithBorderDiagnosticsResult(
      map: resizeMapData(map, width: width, height: height),
      diagnosticReport: const BorderDiagnosticsReport.empty(),
      canApply: true,
    );
  }

  final resizedBorderContents = Map<BorderLayer, BorderLayerContent>.identity();
  final diagnostics = <BorderDiagnostic>[];

  for (final layer in borderLayers) {
    final result = resizeBorderLayerContent(
      content: layer.content,
      oldMapSize: oldSize,
      newMapSize: newSize,
      tileSizePx: tileSizePx,
      layerId: layer.id,
    );
    diagnostics.addAll(result.diagnosticReport.diagnostics);
    final resizedContent = result.content;
    if (resizedContent != null) {
      resizedBorderContents[layer] = resizedContent;
    }
  }

  final report = BorderDiagnosticsReport(diagnostics: diagnostics);
  if (report.hasErrors) {
    return MapResizeWithBorderDiagnosticsResult(
      map: null,
      diagnosticReport: report,
      canApply: false,
    );
  }
  if (oldSize == newSize) {
    return MapResizeWithBorderDiagnosticsResult(
      map: map,
      diagnosticReport: report,
      canApply: true,
    );
  }

  return MapResizeWithBorderDiagnosticsResult(
    map: _resizeMapDataLegacyLayers(
      map,
      width: width,
      height: height,
      resizedBorderContents: resizedBorderContents,
    ),
    diagnosticReport: report,
    canApply: true,
  );
}

MapData _resizeMapDataLegacyLayers(
  MapData map, {
  required int width,
  required int height,
  Map<BorderLayer, BorderLayerContent>? resizedBorderContents,
}) {
  final oldSize = map.size;

  final newLayers = map.layers
      .map(
        (layer) => layer.map(
          tile: (l) => l.copyWith(
            tiles: _resizeFlattened<int>(
              src: l.tiles,
              srcSize: oldSize,
              dstSize: GridSize(width: width, height: height),
              defaultValue: 0,
            ),
          ),
          collision: (l) => l.copyWith(
            collisions: _resizeFlattened<bool>(
              src: l.collisions,
              srcSize: oldSize,
              dstSize: GridSize(width: width, height: height),
              defaultValue: false,
            ),
          ),
          terrain: (l) => l.copyWith(
            terrains: _resizeFlattened<TerrainType>(
              src: l.terrains,
              srcSize: oldSize,
              dstSize: GridSize(width: width, height: height),
              defaultValue: TerrainType.none,
            ),
          ),
          path: (l) => l.copyWith(
            cells: _resizeFlattened<bool>(
              src: l.cells,
              srcSize: oldSize,
              dstSize: GridSize(width: width, height: height),
              defaultValue: false,
            ),
          ),
          smartTile: (l) => l.copyWith(
            field: _resizeSmartTileField(
              l.field,
              oldSize: oldSize,
              newSize: GridSize(width: width, height: height),
            ),
          ),
          surface: (l) => l.copyWith(
            placements: l.placements
                .where((placement) =>
                    placement.x >= 0 &&
                    placement.y >= 0 &&
                    placement.x < width &&
                    placement.y < height)
                .toList(growable: false),
          ),
          object: (l) => l,
          environment: (l) => l.copyWith(
            content: EnvironmentLayerContent(
              targetTileLayerId: l.content.targetTileLayerId,
              areas: l.content.areas
                  .map(
                    (area) => EnvironmentArea(
                      id: area.id,
                      name: area.name,
                      presetId: area.presetId,
                      mask: EnvironmentAreaMask(
                        width: width,
                        height: height,
                        cells: _resizeFlattened<bool>(
                          src: area.mask.cells,
                          srcSize: oldSize,
                          dstSize: GridSize(width: width, height: height),
                          defaultValue: false,
                        ),
                      ),
                      seed: area.seed,
                      paramsOverride: area.paramsOverride,
                      generatedPlacementIds:
                          area.generatedPlacementIds.toList(),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          border: (l) => l.copyWith(
            content: resizedBorderContents?[l] ?? l.content,
          ),
        ),
      )
      .toList(growable: false);

  final newPlacedElements = map.placedElements
      .where(
        (instance) =>
            instance.pos.x >= 0 &&
            instance.pos.y >= 0 &&
            instance.pos.x < width &&
            instance.pos.y < height,
      )
      .toList(growable: false);

  return map.copyWith(
    size: GridSize(width: width, height: height),
    layers: newLayers,
    placedElements: newPlacedElements,
  );
}

void _addClippedLayerImpact<T>({
  required List<MapResizeImpact> impacts,
  required MapResizeImpactKind kind,
  required String layerId,
  required String layerName,
  required List<T> values,
  required GridSize sourceSize,
  required GridSize targetSize,
  required bool Function(T value) isMeaningful,
}) {
  final clipped = _clippedMeaningfulPositions<T>(
    values: values,
    sourceSize: sourceSize,
    targetSize: targetSize,
    isMeaningful: isMeaningful,
  );
  if (clipped.isEmpty) return;
  impacts.add(
    MapResizeImpact(
      kind: kind,
      reason: MapResizeImpactReason.clippedCells,
      subjectId: layerId,
      subjectLabel: _labelOrId(layerName, layerId),
      layerId: layerId,
      affectedCount: clipped.count,
      positions: clipped.positions,
    ),
  );
}

void _addClippedSmartTileLayerImpact({
  required List<MapResizeImpact> impacts,
  required SmartTileLayer layer,
  required GridSize sourceSize,
  required GridSize targetSize,
}) {
  final clippedLattices = <_ResizePositionSummary>[];

  void collect(
    List<int> values,
    GridSize latticeSourceSize,
    GridSize latticeTargetSize,
  ) {
    final clipped = _clippedMeaningfulPositions<int>(
      values: values,
      sourceSize: latticeSourceSize,
      targetSize: latticeTargetSize,
      isMeaningful: (value) => value != 0,
    );
    if (clipped.isNotEmpty) clippedLattices.add(clipped);
  }

  void collectSemantic(List<int> values) {
    collect(values, sourceSize, targetSize);
  }

  void collectHorizontal(List<int> values) {
    collect(
      values,
      GridSize(width: sourceSize.width, height: sourceSize.height + 1),
      GridSize(width: targetSize.width, height: targetSize.height + 1),
    );
  }

  void collectVertical(List<int> values) {
    collect(
      values,
      GridSize(width: sourceSize.width + 1, height: sourceSize.height),
      GridSize(width: targetSize.width + 1, height: targetSize.height),
    );
  }

  void collectCorners(List<int> values) {
    collect(
      values,
      GridSize(
        width: sourceSize.width + 1,
        height: sourceSize.height + 1,
      ),
      GridSize(
        width: targetSize.width + 1,
        height: targetSize.height + 1,
      ),
    );
  }

  switch (layer.field) {
    case SmartTileCellField(:final semanticCells):
      collectSemantic(semanticCells);
    case SmartTileCornerField(
        :final semanticCells,
        corners: final cornerValues,
      ):
      collectSemantic(semanticCells);
      collectCorners(cornerValues);
    case SmartTileEdgeField(
        :final semanticCells,
        :final horizontalEdges,
        :final verticalEdges,
      ):
      collectSemantic(semanticCells);
      collectHorizontal(horizontalEdges);
      collectVertical(verticalEdges);
    case SmartTileMixedField(
        :final semanticCells,
        :final horizontalEdges,
        :final verticalEdges,
        corners: final cornerValues,
      ):
      collectSemantic(semanticCells);
      collectHorizontal(horizontalEdges);
      collectVertical(verticalEdges);
      collectCorners(cornerValues);
  }

  if (clippedLattices.isEmpty) return;
  final positions = <GridPos>[];
  var affectedCount = 0;
  for (final clipped in clippedLattices) {
    affectedCount += clipped.count;
    for (final position in clipped.positions) {
      if (positions.length >= _maximumResizeImpactPositionSamples) break;
      positions.add(position);
    }
  }
  impacts.add(
    MapResizeImpact(
      kind: MapResizeImpactKind.smartTileLayer,
      reason: MapResizeImpactReason.clippedCells,
      subjectId: layer.id,
      subjectLabel: _labelOrId(layer.name, layer.id),
      layerId: layer.id,
      affectedCount: affectedCount,
      positions: positions,
    ),
  );
}

_ResizePositionSummary _clippedMeaningfulPositions<T>({
  required List<T> values,
  required GridSize sourceSize,
  required GridSize targetSize,
  required bool Function(T value) isMeaningful,
}) {
  var count = 0;
  final samples = <GridPos>[];
  for (var y = 0; y < sourceSize.height; y++) {
    for (var x = 0; x < sourceSize.width; x++) {
      if (x < targetSize.width && y < targetSize.height) continue;
      final index = y * sourceSize.width + x;
      if (index < 0 || index >= values.length) continue;
      if (isMeaningful(values[index])) {
        count += 1;
        if (samples.length < _maximumResizeImpactPositionSamples) {
          samples.add(GridPos(x: x, y: y));
        }
      }
    }
  }
  return _ResizePositionSummary(count: count, positions: samples);
}

_ResizePositionSummary _clippedRectPositions({
  required GridPos origin,
  required GridSize size,
  required GridSize targetSize,
}) {
  var count = 0;
  final samples = <GridPos>[];
  for (var y = origin.y; y < origin.y + size.height; y++) {
    for (var x = origin.x; x < origin.x + size.width; x++) {
      final position = GridPos(x: x, y: y);
      if (!_isInBounds(position, targetSize)) {
        count += 1;
        if (samples.length < _maximumResizeImpactPositionSamples) {
          samples.add(position);
        }
      }
    }
  }
  return _ResizePositionSummary(count: count, positions: samples);
}

_ResizePositionSummary _clippedWarpTriggerCells({
  required MapWarp warp,
  required GridSize sourceSize,
  required GridSize targetSize,
}) {
  var count = 0;
  final samples = <GridPos>[];
  final left = warp.pos.x - warp.triggerPadding.left;
  final right = warp.pos.x + warp.triggerPadding.right;
  final top = warp.pos.y - warp.triggerPadding.top;
  final bottom = warp.pos.y + warp.triggerPadding.bottom;
  for (var y = top; y <= bottom; y++) {
    for (var x = left; x <= right; x++) {
      final position = GridPos(x: x, y: y);
      // Padding is allowed outside the source map. Only cells that were
      // reachable before the resize count as newly clipped trigger coverage.
      if (_isInBounds(position, sourceSize) &&
          !_isInBounds(position, targetSize)) {
        count += 1;
        if (samples.length < _maximumResizeImpactPositionSamples) {
          samples.add(position);
        }
      }
    }
  }
  return _ResizePositionSummary(count: count, positions: samples);
}

_ResizePositionSummary _outsidePositionSummary({
  required Iterable<GridPos> positions,
  required GridSize targetSize,
}) {
  var count = 0;
  final samples = <GridPos>[];
  for (final position in positions) {
    if (_isInBounds(position, targetSize)) continue;
    count += 1;
    if (samples.length < _maximumResizeImpactPositionSamples) {
      samples.add(position);
    }
  }
  return _ResizePositionSummary(count: count, positions: samples);
}

final class _ResizePositionSummary {
  _ResizePositionSummary({
    required this.count,
    required List<GridPos> positions,
  }) : positions = List<GridPos>.unmodifiable(positions);

  final int count;
  final List<GridPos> positions;

  bool get isEmpty => count == 0;
  bool get isNotEmpty => count > 0;
}

bool _isInBounds(GridPos position, GridSize size) =>
    position.x >= 0 &&
    position.y >= 0 &&
    position.x < size.width &&
    position.y < size.height;

bool _hasShrink(GridSize sourceSize, GridSize targetSize) =>
    targetSize.width < sourceSize.width ||
    targetSize.height < sourceSize.height;

String _labelOrId(String label, String id) {
  final normalized = label.trim();
  return normalized.isEmpty ? id : normalized;
}

int _borderDiagnosticAffectedCount(BorderDiagnostic diagnostic) {
  const countKeys = <String>[
    'clippedTrueCellCount',
    'clippedPointCount',
    'removedFragmentCount',
    'affectedPlacementCount',
  ];
  for (final key in countKeys) {
    final value = diagnostic.parameters[key];
    if (value is int && value > 0) return value;
  }
  return 1;
}

SmartTileField _resizeSmartTileField(
  SmartTileField field, {
  required GridSize oldSize,
  required GridSize newSize,
}) {
  List<int> cells(List<int> values) => _resizeFlattened<int>(
        src: values,
        srcSize: oldSize,
        dstSize: newSize,
        defaultValue: 0,
      );
  List<int> horizontal(List<int> values) => _resizeFlattened<int>(
        src: values,
        srcSize: GridSize(
          width: oldSize.width,
          height: oldSize.height + 1,
        ),
        dstSize: GridSize(
          width: newSize.width,
          height: newSize.height + 1,
        ),
        defaultValue: 0,
      );
  List<int> vertical(List<int> values) => _resizeFlattened<int>(
        src: values,
        srcSize: GridSize(
          width: oldSize.width + 1,
          height: oldSize.height,
        ),
        dstSize: GridSize(
          width: newSize.width + 1,
          height: newSize.height,
        ),
        defaultValue: 0,
      );
  List<int> corners(List<int> values) => _resizeFlattened<int>(
        src: values,
        srcSize: GridSize(
          width: oldSize.width + 1,
          height: oldSize.height + 1,
        ),
        dstSize: GridSize(
          width: newSize.width + 1,
          height: newSize.height + 1,
        ),
        defaultValue: 0,
      );

  return switch (field) {
    SmartTileCellField(:final semanticCells) => SmartTileField.cell(
        semanticCells: cells(semanticCells),
      ),
    SmartTileCornerField(:final semanticCells, corners: final sourceCorners) =>
      SmartTileField.corner(
        semanticCells: cells(semanticCells),
        corners: corners(sourceCorners),
      ),
    SmartTileEdgeField(
      :final semanticCells,
      :final horizontalEdges,
      :final verticalEdges,
    ) =>
      SmartTileField.edge(
        semanticCells: cells(semanticCells),
        horizontalEdges: horizontal(horizontalEdges),
        verticalEdges: vertical(verticalEdges),
      ),
    SmartTileMixedField(
      :final semanticCells,
      :final horizontalEdges,
      :final verticalEdges,
      corners: final sourceCorners,
    ) =>
      SmartTileField.mixed(
        semanticCells: cells(semanticCells),
        horizontalEdges: horizontal(horizontalEdges),
        verticalEdges: vertical(verticalEdges),
        corners: corners(sourceCorners),
      ),
  };
}

List<T> _resizeFlattened<T>({
  required List<T> src,
  required GridSize srcSize,
  required GridSize dstSize,
  required T defaultValue,
}) {
  final dstLen = dstSize.width * dstSize.height;
  final dst = List<T>.filled(dstLen, defaultValue, growable: false);

  final copyW = math.min(srcSize.width, dstSize.width);
  final copyH = math.min(srcSize.height, dstSize.height);

  for (var y = 0; y < copyH; y++) {
    final srcRowStart = y * srcSize.width;
    final dstRowStart = y * dstSize.width;
    for (var x = 0; x < copyW; x++) {
      final srcIndex = srcRowStart + x;
      if (srcIndex < 0 || srcIndex >= src.length) continue;
      final dstIndex = dstRowStart + x;
      dst[dstIndex] = src[srcIndex];
    }
  }

  return dst;
}
