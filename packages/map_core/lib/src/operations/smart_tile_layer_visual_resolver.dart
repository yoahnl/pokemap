import 'package:meta/meta.dart' show immutable;

import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/smart_tile.dart';
import 'map_placed_element_animation.dart';
import 'smart_tile_layer_context.dart';
import 'smart_tile_pattern_operations.dart';
import 'smart_tile_resolver.dart';
import 'smart_tile_sprite_geometry.dart';

enum SmartTileVisualPass { background, actorOcclusion, foreground }

@immutable
final class SmartTileLayerVisual {
  const SmartTileLayerVisual({
    required this.cellX,
    required this.cellY,
    required this.ruleId,
    required this.candidateId,
    required this.channel,
    required this.isAnimated,
    required this.tilesetId,
    required this.sourceRect,
    required this.transform,
    required this.geometry,
    required this.offsetUnit,
    required this.offsetX,
    required this.offsetY,
    required this.footprintWidth,
    required this.footprintHeight,
    required this.anchorX,
    required this.anchorY,
    required this.drawOrder,
  });

  final int cellX;
  final int cellY;
  final String ruleId;
  final String candidateId;
  final SmartTileRenderChannel channel;
  final bool isAnimated;
  final String tilesetId;
  final SmartTileSourceRect sourceRect;
  final SmartTileSpriteTransform transform;
  final SmartTileSpriteGeometry geometry;
  final SmartTileOffsetUnit offsetUnit;
  final int offsetX;
  final int offsetY;
  final int footprintWidth;
  final int footprintHeight;
  final int anchorX;
  final int anchorY;
  final int drawOrder;
}

/// Deterministic operation counts emitted by one Smart Tile visual pass.
///
/// These counters deliberately describe algorithmic work instead of wall
/// clock time. They can therefore guard viewport culling in CI across hosts.
@immutable
final class SmartTileLayerVisualWorkCounts {
  const SmartTileLayerVisualWorkCounts({
    required this.requestedCellCount,
    required this.ownerCellVisits,
    required this.patternStrokeCellVisits,
    required this.resolvedVisualCount,
  });

  const SmartTileLayerVisualWorkCounts.empty()
      : requestedCellCount = 0,
        ownerCellVisits = 0,
        patternStrokeCellVisits = 0,
        resolvedVisualCount = 0;

  final int requestedCellCount;
  final int ownerCellVisits;
  final int patternStrokeCellVisits;
  final int resolvedVisualCount;
}

@immutable
final class SmartTileLayerVisualBatch {
  SmartTileLayerVisualBatch({
    required Iterable<SmartTileLayerVisual> visuals,
    required this.work,
  }) : visuals = List<SmartTileLayerVisual>.unmodifiable(visuals);

  const SmartTileLayerVisualBatch.empty()
      : visuals = const <SmartTileLayerVisual>[],
        work = const SmartTileLayerVisualWorkCounts.empty();

  final List<SmartTileLayerVisual> visuals;
  final SmartTileLayerVisualWorkCounts work;
}

typedef _SmartTilePatternOwner = ({
  SmartTilePatternStroke stroke,
  ProjectSmartTilePattern pattern,
});

/// Sparse, reusable ownership projection for pattern strokes in one layer.
///
/// Building it is map-load work. Passing it to every visible-frame resolution
/// prevents navigation from rescanning all persisted stroke cells.
final class SmartTilePatternOwnerIndex {
  SmartTilePatternOwnerIndex._({
    required this.layer,
    required this.catalog,
    required this.mapWidth,
    required this.mapHeight,
    required Map<int, _SmartTilePatternOwner> owners,
    required Iterable<ProjectSmartTilePattern> patterns,
  })  : _owners = Map<int, _SmartTilePatternOwner>.unmodifiable(owners),
        _patterns = List<ProjectSmartTilePattern>.unmodifiable(patterns);

  factory SmartTilePatternOwnerIndex.build({
    required MapData map,
    required SmartTileLayer layer,
    required ProjectSmartTileCatalog catalog,
  }) {
    final patternsById = <String, ProjectSmartTilePattern>{
      for (final pattern in catalog.patterns) pattern.id: pattern,
    };
    final owners = <int, _SmartTilePatternOwner>{};
    final usedPatterns = <String, ProjectSmartTilePattern>{};
    for (final stroke in layer.patternStrokes) {
      final pattern = patternsById[stroke.patternId];
      if (pattern == null || pattern.usage != layer.usage) continue;
      usedPatterns[pattern.id] = pattern;
      for (final cell in stroke.cells) {
        if (cell.x < 0 ||
            cell.y < 0 ||
            cell.x >= map.size.width ||
            cell.y >= map.size.height) {
          continue;
        }
        owners[cell.y * map.size.width + cell.x] = (
          stroke: stroke,
          pattern: pattern,
        );
      }
    }
    return SmartTilePatternOwnerIndex._(
      layer: layer,
      catalog: catalog,
      mapWidth: map.size.width,
      mapHeight: map.size.height,
      owners: owners,
      patterns: usedPatterns.values,
    );
  }

  final SmartTileLayer layer;
  final ProjectSmartTileCatalog catalog;
  final int mapWidth;
  final int mapHeight;
  final Map<int, _SmartTilePatternOwner> _owners;
  final List<ProjectSmartTilePattern> _patterns;

  int get entryCount => _owners.length;

  bool _supports({
    required MapData map,
    required SmartTileLayer layer,
    required ProjectSmartTileCatalog catalog,
  }) =>
      identical(this.layer, layer) &&
      identical(this.catalog, catalog) &&
      mapWidth == map.size.width &&
      mapHeight == map.size.height;
}

/// Resolves a native map layer into renderer-neutral visual instructions.
///
/// Editor and runtime both consume this operation, which guarantees identical
/// neighborhood matching, deterministic candidate choice, Wang lattice
/// interpretation, source rectangles, and render-pass splitting.
List<SmartTileLayerVisual> resolveSmartTileLayerVisuals({
  required MapData map,
  required SmartTileLayer layer,
  required ProjectSmartTileCatalog catalog,
  required SmartTileVisualPass pass,
  int projectSeed = 0,
  int elapsedMs = 0,
  int startX = 0,
  int startY = 0,
  int? endX,
  int? endY,
  double destinationCellWidth = 1,
  double destinationCellHeight = 1,
  double sourceCellWidth = 32,
  double sourceCellHeight = 32,
  SmartTileGeometryRect? viewportBounds,
  SmartTilePatternOwnerIndex? patternOwnerIndex,
}) =>
    resolveSmartTileLayerVisualBatch(
      map: map,
      layer: layer,
      catalog: catalog,
      pass: pass,
      projectSeed: projectSeed,
      elapsedMs: elapsedMs,
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
      destinationCellWidth: destinationCellWidth,
      destinationCellHeight: destinationCellHeight,
      sourceCellWidth: sourceCellWidth,
      sourceCellHeight: sourceCellHeight,
      viewportBounds: viewportBounds,
      patternOwnerIndex: patternOwnerIndex,
    ).visuals;

/// Profiled form of [resolveSmartTileLayerVisuals].
///
/// Rendering semantics and ordering are identical; only stable work counts
/// are added for editor/runtime performance evidence.
SmartTileLayerVisualBatch resolveSmartTileLayerVisualBatch({
  required MapData map,
  required SmartTileLayer layer,
  required ProjectSmartTileCatalog catalog,
  required SmartTileVisualPass pass,
  int projectSeed = 0,
  int elapsedMs = 0,
  int startX = 0,
  int startY = 0,
  int? endX,
  int? endY,
  double destinationCellWidth = 1,
  double destinationCellHeight = 1,
  double sourceCellWidth = 32,
  double sourceCellHeight = 32,
  SmartTileGeometryRect? viewportBounds,
  SmartTilePatternOwnerIndex? patternOwnerIndex,
}) {
  ProjectSmartTilePreset? preset;
  for (final candidate in catalog.presets) {
    if (candidate.id == layer.presetId) {
      preset = candidate;
      break;
    }
  }
  if (preset == null || preset.usage != layer.usage) {
    return const SmartTileLayerVisualBatch.empty();
  }
  if (destinationCellWidth <= 0 ||
      destinationCellHeight <= 0 ||
      sourceCellWidth <= 0 ||
      sourceCellHeight <= 0) {
    return const SmartTileLayerVisualBatch.empty();
  }

  final atlases = <String, ProjectSmartTileAtlas>{
    for (final atlas in catalog.atlases) atlas.id: atlas,
  };
  final animations = <String, ProjectSmartTileAnimation>{
    for (final animation in catalog.animations) animation.id: animation,
  };
  final patterns = <String, ProjectSmartTilePattern>{
    for (final pattern in catalog.patterns) pattern.id: pattern,
  };
  final reusablePatternIndex = patternOwnerIndex != null &&
      patternOwnerIndex._supports(map: map, layer: layer, catalog: catalog);
  final patternOwners = reusablePatternIndex
      ? patternOwnerIndex._owners
      : <int, _SmartTilePatternOwner>{};
  var patternStrokeCellVisits = 0;
  if (!reusablePatternIndex) {
    for (final stroke in layer.patternStrokes) {
      final pattern = patterns[stroke.patternId];
      if (pattern == null || pattern.usage != layer.usage) continue;
      for (final cell in stroke.cells) {
        patternStrokeCellVisits += 1;
        if (cell.x < 0 ||
            cell.y < 0 ||
            cell.x >= map.size.width ||
            cell.y >= map.size.height) {
          continue;
        }
        patternOwners[cell.y * map.size.width + cell.x] = (
          stroke: stroke,
          pattern: pattern,
        );
      }
    }
  }
  final visuals = <SmartTileLayerVisual>[];
  final requestedStartX = startX.clamp(0, map.size.width);
  final requestedStartY = startY.clamp(0, map.size.height);
  final requestedEndX = (endX ?? map.size.width).clamp(
    requestedStartX,
    map.size.width,
  );
  final requestedEndY = (endY ?? map.size.height).clamp(
    requestedStartY,
    map.size.height,
  );
  final hasRequestedViewport = viewportBounds != null ||
      startX != 0 ||
      startY != 0 ||
      endX != null ||
      endY != null;
  final requestedViewport = viewportBounds ??
      (hasRequestedViewport
          ? SmartTileGeometryRect(
              left: requestedStartX * destinationCellWidth,
              top: requestedStartY * destinationCellHeight,
              width: (requestedEndX - requestedStartX) * destinationCellWidth,
              height: (requestedEndY - requestedStartY) * destinationCellHeight,
            )
          : null);
  final scan = _resolveOwnerScanRange(
    mapWidth: map.size.width,
    mapHeight: map.size.height,
    preset: preset,
    patterns: reusablePatternIndex
        ? patternOwnerIndex._patterns
        : patternOwners.values.map((owner) => owner.pattern),
    pass: pass,
    atlases: atlases,
    animations: animations,
    destinationCellWidth: destinationCellWidth,
    destinationCellHeight: destinationCellHeight,
    sourceCellWidth: sourceCellWidth,
    sourceCellHeight: sourceCellHeight,
    viewport: requestedViewport,
  );
  final resolver = PreparedSmartTileResolver(
    preset: preset,
    materials: catalog.materials,
    mapId: map.id,
    layerId: layer.id,
    projectSeed: projectSeed,
    layerSeed: layer.layerSeed,
    candidateWeights: layer.candidateWeights,
  );
  var ownerCellVisits = 0;
  for (var y = scan.startY; y < scan.endY; y++) {
    for (var x = scan.startX; x < scan.endX; x++) {
      ownerCellVisits += 1;
      final context = smartTileCellContextForLayerCell(
        layer: layer,
        map: map,
        preset: preset,
        x: x,
        y: y,
      );
      final resolution = resolver.resolve(
        context: context,
        x: x,
        y: y,
      );
      final candidate = resolution.candidate;
      if (candidate != null && resolution.ruleId != null) {
        for (final part in candidate.parts) {
          if (!_channelBelongsToPass(part.channel, pass)) continue;
          final frame = _resolveVisualFrame(
            source: part.source,
            animations: animations,
            elapsedMs: elapsedMs,
            deterministicHash: resolution.deterministicHash ?? 0,
          );
          if (frame == null) continue;
          final visual = _buildPartVisual(
            frame: frame,
            part: part,
            atlases: atlases,
            cellX: x,
            cellY: y,
            deterministicHash: resolution.deterministicHash ?? 0,
            transform: composeSmartTileSpriteTransforms(
              first: part.transform,
              second: resolution.transform,
            ),
            ruleId: resolution.ruleId!,
            candidateId: candidate.id,
            drawOrder: part.drawOrder,
            destinationCellWidth: destinationCellWidth,
            destinationCellHeight: destinationCellHeight,
            sourceCellWidth: sourceCellWidth,
            sourceCellHeight: sourceCellHeight,
          );
          if (visual == null) continue;
          if (requestedViewport != null &&
              !visual.geometry.visualBounds.intersects(requestedViewport)) {
            continue;
          }
          visuals.add(visual);
        }
      }
      final patternOwner = patternOwners[y * map.size.width + x];
      if (patternOwner == null) continue;
      final patternCell = smartTilePatternCellAt(
        pattern: patternOwner.pattern,
        stroke: patternOwner.stroke,
        cell: GridPos(x: x, y: y),
      );
      if (patternCell == null) continue;
      final deterministicHash = stableHash32(
        '${map.id}|${layer.id}|${patternOwner.pattern.id}|$x|$y|'
        '$projectSeed|${layer.layerSeed}',
      );
      for (final part in patternCell.parts) {
        if (!_channelBelongsToPass(part.channel, pass)) continue;
        final frame = _resolveVisualFrame(
          source: part.source,
          animations: animations,
          elapsedMs: elapsedMs,
          deterministicHash: deterministicHash,
        );
        if (frame == null) continue;
        final visual = _buildPartVisual(
          frame: frame,
          part: part,
          atlases: atlases,
          cellX: x,
          cellY: y,
          deterministicHash: deterministicHash,
          transform: part.transform,
          ruleId: 'pattern:${patternOwner.pattern.id}',
          candidateId: 'pattern-cell-${patternCell.x}-${patternCell.y}',
          drawOrder: patternOwner.pattern.drawOrder + part.drawOrder,
          destinationCellWidth: destinationCellWidth,
          destinationCellHeight: destinationCellHeight,
          sourceCellWidth: sourceCellWidth,
          sourceCellHeight: sourceCellHeight,
        );
        if (visual == null) continue;
        if (requestedViewport != null &&
            !visual.geometry.visualBounds.intersects(requestedViewport)) {
          continue;
        }
        visuals.add(visual);
      }
    }
  }
  visuals.sort(_compareSmartTileVisualPaintOrder);
  return SmartTileLayerVisualBatch(
    visuals: visuals,
    work: SmartTileLayerVisualWorkCounts(
      requestedCellCount:
          (requestedEndX - requestedStartX) * (requestedEndY - requestedStartY),
      ownerCellVisits: ownerCellVisits,
      patternStrokeCellVisits: patternStrokeCellVisits,
      resolvedVisualCount: visuals.length,
    ),
  );
}

/// Expands a viewport to every owner cell whose visual could intersect it.
///
/// This derives a conservative envelope from the preset itself, so an
/// overhang is never lost merely because its semantic owner is offscreen.
({int startX, int startY, int endX, int endY}) _resolveOwnerScanRange({
  required int mapWidth,
  required int mapHeight,
  required ProjectSmartTilePreset preset,
  required Iterable<ProjectSmartTilePattern> patterns,
  required SmartTileVisualPass pass,
  required Map<String, ProjectSmartTileAtlas> atlases,
  required Map<String, ProjectSmartTileAnimation> animations,
  required double destinationCellWidth,
  required double destinationCellHeight,
  required double sourceCellWidth,
  required double sourceCellHeight,
  required SmartTileGeometryRect? viewport,
}) {
  if (viewport == null) {
    return (startX: 0, startY: 0, endX: mapWidth, endY: mapHeight);
  }
  final envelope = _layerVisualEnvelope(
    preset: preset,
    patterns: patterns,
    pass: pass,
    atlases: atlases,
    animations: animations,
    destinationCellWidth: destinationCellWidth,
    destinationCellHeight: destinationCellHeight,
    sourceCellWidth: sourceCellWidth,
    sourceCellHeight: sourceCellHeight,
  );
  return _scanRangeForViewport(
    mapWidth: mapWidth,
    mapHeight: mapHeight,
    envelope: envelope,
    viewport: viewport,
    destinationCellWidth: destinationCellWidth,
    destinationCellHeight: destinationCellHeight,
  );
}

/// Conservative visual envelope of a layer's preset plus its used patterns.
SmartTileGeometryRect _layerVisualEnvelope({
  required ProjectSmartTilePreset preset,
  required Iterable<ProjectSmartTilePattern> patterns,
  required SmartTileVisualPass pass,
  required Map<String, ProjectSmartTileAtlas> atlases,
  required Map<String, ProjectSmartTileAnimation> animations,
  required double destinationCellWidth,
  required double destinationCellHeight,
  required double sourceCellWidth,
  required double sourceCellHeight,
}) {
  var envelope = _presetVisualEnvelope(
    preset: preset,
    pass: pass,
    atlases: atlases,
    animations: animations,
    destinationCellWidth: destinationCellWidth,
    destinationCellHeight: destinationCellHeight,
    sourceCellWidth: sourceCellWidth,
    sourceCellHeight: sourceCellHeight,
  );
  for (final pattern in patterns) {
    final patternEnvelope = _patternVisualEnvelope(
      pattern: pattern,
      pass: pass,
      atlases: atlases,
      animations: animations,
      destinationCellWidth: destinationCellWidth,
      destinationCellHeight: destinationCellHeight,
      sourceCellWidth: sourceCellWidth,
      sourceCellHeight: sourceCellHeight,
    );
    envelope = _unionGeometryRects(envelope, patternEnvelope);
  }
  return envelope;
}

({int startX, int startY, int endX, int endY}) _scanRangeForViewport({
  required int mapWidth,
  required int mapHeight,
  required SmartTileGeometryRect envelope,
  required SmartTileGeometryRect viewport,
  required double destinationCellWidth,
  required double destinationCellHeight,
}) {
  return (
    startX: ((viewport.left - envelope.right) / destinationCellWidth)
        .floor()
        .clamp(0, mapWidth),
    startY: ((viewport.top - envelope.bottom) / destinationCellHeight)
        .floor()
        .clamp(0, mapHeight),
    endX: ((viewport.right - envelope.left) / destinationCellWidth)
        .ceil()
        .clamp(0, mapWidth),
    endY: ((viewport.bottom - envelope.top) / destinationCellHeight)
        .ceil()
        .clamp(0, mapHeight),
  );
}

int _compareSmartTileVisualPaintOrder(
  SmartTileLayerVisual a,
  SmartTileLayerVisual b,
) {
  final order = a.drawOrder.compareTo(b.drawOrder);
  if (order != 0) return order;
  final y = a.cellY.compareTo(b.cellY);
  if (y != 0) return y;
  return a.cellX.compareTo(b.cellX);
}

/// Builds one renderer-neutral visual for an already-resolved frame.
///
/// Shared by the per-call batch resolver and [SmartTileLayerVisualPlan] so
/// both paths keep identical sampling, source rectangles, and geometry.
SmartTileLayerVisual? _buildPartVisual({
  required SmartTileFrameRef frame,
  required SmartTileVisualPart part,
  required Map<String, ProjectSmartTileAtlas> atlases,
  required int cellX,
  required int cellY,
  required int deterministicHash,
  required SmartTileSpriteTransform transform,
  required String ruleId,
  required String candidateId,
  required int drawOrder,
  required double destinationCellWidth,
  required double destinationCellHeight,
  required double sourceCellWidth,
  required double sourceCellHeight,
}) {
  final atlas = atlases[frame.atlasId];
  if (atlas == null) return null;
  final sampledFrame = _sampleVisualFrame(
    frame: frame,
    sampling: part.frameSampling,
    cellX: cellX,
    cellY: cellY,
    deterministicHash: deterministicHash,
  );
  SmartTileSourceRect sourceRect;
  try {
    sourceRect = atlas.sourceRectFor(
      column: sampledFrame.column,
      row: sampledFrame.row,
      columnSpan: sampledFrame.columnSpan,
      rowSpan: sampledFrame.rowSpan,
    );
  } on RangeError {
    return null;
  }
  final geometry = resolveSmartTileSpriteGeometry(
    cellX: cellX,
    cellY: cellY,
    destinationCellWidth: destinationCellWidth,
    destinationCellHeight: destinationCellHeight,
    sourceCellWidth: sourceCellWidth,
    sourceCellHeight: sourceCellHeight,
    offsetUnit: part.offsetUnit,
    offsetX: part.offsetX,
    offsetY: part.offsetY,
    atlasPixelOffsetX: atlas.pixelOffsetX,
    atlasPixelOffsetY: atlas.pixelOffsetY,
    footprintWidth: part.footprintWidth,
    footprintHeight: part.footprintHeight,
    anchorX: part.anchorX,
    anchorY: part.anchorY,
    transform: transform,
  );
  return SmartTileLayerVisual(
    cellX: cellX,
    cellY: cellY,
    ruleId: ruleId,
    candidateId: candidateId,
    channel: part.channel,
    isAnimated: part.source.map(
      frame: (_) => false,
      animation: (_) => true,
    ),
    tilesetId: atlas.tilesetId,
    sourceRect: sourceRect,
    transform: transform,
    geometry: geometry,
    offsetUnit: part.offsetUnit,
    offsetX: part.offsetX,
    offsetY: part.offsetY,
    footprintWidth: part.footprintWidth,
    footprintHeight: part.footprintHeight,
    anchorX: part.anchorX,
    anchorY: part.anchorY,
    drawOrder: drawOrder,
  );
}

SmartTileGeometryRect _patternVisualEnvelope({
  required ProjectSmartTilePattern pattern,
  required SmartTileVisualPass pass,
  required Map<String, ProjectSmartTileAtlas> atlases,
  required Map<String, ProjectSmartTileAnimation> animations,
  required double destinationCellWidth,
  required double destinationCellHeight,
  required double sourceCellWidth,
  required double sourceCellHeight,
}) {
  SmartTileGeometryRect? envelope;
  for (final cell in pattern.cells) {
    for (final part in cell.parts) {
      if (!_channelBelongsToPass(part.channel, pass)) continue;
      final atlasIds = part.source.when(
        frame: (frame) => <String>{frame.atlasId},
        animation: (animationId) => <String>{
          for (final frame in animations[animationId]?.frames ??
              const <ProjectSmartTileAnimationFrame>[])
            frame.frame.atlasId,
        },
      );
      for (final atlasId in atlasIds) {
        final atlas = atlases[atlasId];
        if (atlas == null) continue;
        final bounds = resolveSmartTileSpriteGeometry(
          cellX: 0,
          cellY: 0,
          destinationCellWidth: destinationCellWidth,
          destinationCellHeight: destinationCellHeight,
          sourceCellWidth: sourceCellWidth,
          sourceCellHeight: sourceCellHeight,
          offsetUnit: part.offsetUnit,
          offsetX: part.offsetX,
          offsetY: part.offsetY,
          atlasPixelOffsetX: atlas.pixelOffsetX,
          atlasPixelOffsetY: atlas.pixelOffsetY,
          footprintWidth: part.footprintWidth,
          footprintHeight: part.footprintHeight,
          anchorX: part.anchorX,
          anchorY: part.anchorY,
          transform: part.transform,
        ).visualBounds;
        envelope =
            envelope == null ? bounds : _unionGeometryRects(envelope, bounds);
      }
    }
  }
  return envelope ??
      SmartTileGeometryRect(
        left: 0,
        top: 0,
        width: destinationCellWidth,
        height: destinationCellHeight,
      );
}

SmartTileGeometryRect _unionGeometryRects(
  SmartTileGeometryRect first,
  SmartTileGeometryRect second,
) {
  final left = first.left < second.left ? first.left : second.left;
  final top = first.top < second.top ? first.top : second.top;
  final right = first.right > second.right ? first.right : second.right;
  final bottom = first.bottom > second.bottom ? first.bottom : second.bottom;
  return SmartTileGeometryRect(
    left: left,
    top: top,
    width: right - left,
    height: bottom - top,
  );
}

SmartTileGeometryRect _presetVisualEnvelope({
  required ProjectSmartTilePreset preset,
  required SmartTileVisualPass pass,
  required Map<String, ProjectSmartTileAtlas> atlases,
  required Map<String, ProjectSmartTileAnimation> animations,
  required double destinationCellWidth,
  required double destinationCellHeight,
  required double sourceCellWidth,
  required double sourceCellHeight,
}) {
  SmartTileGeometryRect? envelope;
  final generatedTransforms = smartTileAllowedTransforms(
    preset.transformPolicy,
  );
  for (final rule in preset.rules) {
    for (final candidate in rule.candidates) {
      for (final part in candidate.parts) {
        if (!_channelBelongsToPass(part.channel, pass)) continue;
        final atlasIds = part.source.when(
          frame: (frame) => <String>{frame.atlasId},
          animation: (animationId) => <String>{
            for (final frame in animations[animationId]?.frames ??
                const <ProjectSmartTileAnimationFrame>[])
              frame.frame.atlasId,
          },
        );
        for (final atlasId in atlasIds) {
          final atlas = atlases[atlasId];
          if (atlas == null) continue;
          for (final generatedTransform in generatedTransforms) {
            final transform = composeSmartTileSpriteTransforms(
              first: part.transform,
              second: generatedTransform,
            );
            final bounds = resolveSmartTileSpriteGeometry(
              cellX: 0,
              cellY: 0,
              destinationCellWidth: destinationCellWidth,
              destinationCellHeight: destinationCellHeight,
              sourceCellWidth: sourceCellWidth,
              sourceCellHeight: sourceCellHeight,
              offsetUnit: part.offsetUnit,
              offsetX: part.offsetX,
              offsetY: part.offsetY,
              atlasPixelOffsetX: atlas.pixelOffsetX,
              atlasPixelOffsetY: atlas.pixelOffsetY,
              footprintWidth: part.footprintWidth,
              footprintHeight: part.footprintHeight,
              anchorX: part.anchorX,
              anchorY: part.anchorY,
              transform: transform,
            ).visualBounds;
            envelope = envelope == null
                ? bounds
                : SmartTileGeometryRect(
                    left: envelope.left < bounds.left
                        ? envelope.left
                        : bounds.left,
                    top: envelope.top < bounds.top ? envelope.top : bounds.top,
                    width: (envelope.right > bounds.right
                            ? envelope.right
                            : bounds.right) -
                        (envelope.left < bounds.left
                            ? envelope.left
                            : bounds.left),
                    height: (envelope.bottom > bounds.bottom
                            ? envelope.bottom
                            : bounds.bottom) -
                        (envelope.top < bounds.top ? envelope.top : bounds.top),
                  );
          }
        }
      }
    }
  }
  return envelope ??
      SmartTileGeometryRect(
        left: 0,
        top: 0,
        width: destinationCellWidth,
        height: destinationCellHeight,
      );
}

SmartTileFrameRef _sampleVisualFrame({
  required SmartTileFrameRef frame,
  required SmartTileFrameSampling sampling,
  required int cellX,
  required int cellY,
  required int deterministicHash,
}) {
  if (sampling == SmartTileFrameSampling.fullFrame ||
      frame.columnSpan == 1 && frame.rowSpan == 1) {
    return frame;
  }
  final (columnOffset, rowOffset) = switch (sampling) {
    SmartTileFrameSampling.fullFrame => (0, 0),
    SmartTileFrameSampling.tessellated => (
        _positiveModulo(cellX, frame.columnSpan),
        _positiveModulo(cellY, frame.rowSpan),
      ),
    SmartTileFrameSampling.stableRandom => () {
        final index = _positiveModulo(
          deterministicHash,
          frame.columnSpan * frame.rowSpan,
        );
        return (index % frame.columnSpan, index ~/ frame.columnSpan);
      }(),
  };
  return frame.copyWith(
    column: frame.column + columnOffset,
    row: frame.row + rowOffset,
    columnSpan: 1,
    rowSpan: 1,
  );
}

int _positiveModulo(int value, int modulus) {
  final result = value % modulus;
  return result < 0 ? result + modulus : result;
}

bool _channelBelongsToPass(
  SmartTileRenderChannel channel,
  SmartTileVisualPass pass,
) {
  return switch (pass) {
    SmartTileVisualPass.background =>
      channel == SmartTileRenderChannel.ground ||
          channel == SmartTileRenderChannel.understory ||
          channel == SmartTileRenderChannel.shadow,
    SmartTileVisualPass.foreground =>
      channel == SmartTileRenderChannel.canopy ||
          channel == SmartTileRenderChannel.foreground,
    SmartTileVisualPass.actorOcclusion =>
      channel == SmartTileRenderChannel.actorOcclusion,
  };
}

SmartTileFrameRef? _resolveVisualFrame({
  required SmartTileVisualSource source,
  required Map<String, ProjectSmartTileAnimation> animations,
  required int elapsedMs,
  required int deterministicHash,
}) {
  return source.map(
    frame: (source) => source.frame,
    animation: (source) {
      final animation = animations[source.animationId];
      if (animation == null || animation.frames.isEmpty) return null;
      final timeline = _animationTimeline(animation);
      final totalDuration = timeline.fold<int>(
        0,
        (sum, frame) => sum + frame.durationMs,
      );
      if (totalDuration <= 0) return timeline.first.frame;
      var time = elapsedMs < 0 ? 0 : elapsedMs;
      if (animation.sync == SmartTileAnimationSync.perCell) {
        time += deterministicHash % totalDuration;
      }
      if (animation.loop == SmartTileAnimationLoop.once) {
        if (time >= totalDuration) return timeline.last.frame;
      } else {
        time %= totalDuration;
      }
      var cursor = 0;
      for (final frame in timeline) {
        cursor += frame.durationMs;
        if (time < cursor) return frame.frame;
      }
      return timeline.last.frame;
    },
  );
}

List<ProjectSmartTileAnimationFrame> _animationTimeline(
  ProjectSmartTileAnimation animation,
) {
  if (animation.loop != SmartTileAnimationLoop.pingPong ||
      animation.frames.length < 3) {
    return animation.frames;
  }
  return <ProjectSmartTileAnimationFrame>[
    ...animation.frames,
    ...animation.frames.sublist(1, animation.frames.length - 1).reversed,
  ];
}

/// Builds a [SmartTileLayerVisualPlan] for one layer, pass, and cell metrics.
///
/// The plan captures every time-invariant part of
/// [resolveSmartTileLayerVisualBatch] — preset lookup, catalog index maps,
/// pattern ownership, the prepared rule resolver, and the culling envelope —
/// so per-frame emission stops re-deriving them. Cell resolutions themselves
/// are planned lazily on first visit, which keeps plan construction cheap on
/// very large maps.
SmartTileLayerVisualPlan buildSmartTileLayerVisualPlan({
  required MapData map,
  required SmartTileLayer layer,
  required ProjectSmartTileCatalog catalog,
  required SmartTileVisualPass pass,
  int projectSeed = 0,
  double destinationCellWidth = 1,
  double destinationCellHeight = 1,
  double sourceCellWidth = 32,
  double sourceCellHeight = 32,
  SmartTilePatternOwnerIndex? patternOwnerIndex,
}) {
  ProjectSmartTilePreset? preset;
  for (final candidate in catalog.presets) {
    if (candidate.id == layer.presetId) {
      preset = candidate;
      break;
    }
  }
  if (preset == null ||
      preset.usage != layer.usage ||
      destinationCellWidth <= 0 ||
      destinationCellHeight <= 0 ||
      sourceCellWidth <= 0 ||
      sourceCellHeight <= 0) {
    return SmartTileLayerVisualPlan._inert(map: map);
  }

  final atlases = <String, ProjectSmartTileAtlas>{
    for (final atlas in catalog.atlases) atlas.id: atlas,
  };
  final animations = <String, ProjectSmartTileAnimation>{
    for (final animation in catalog.animations) animation.id: animation,
  };
  final reusablePatternIndex = patternOwnerIndex != null &&
      patternOwnerIndex._supports(map: map, layer: layer, catalog: catalog);
  Map<int, _SmartTilePatternOwner> patternOwners;
  Iterable<ProjectSmartTilePattern> usedPatterns;
  if (reusablePatternIndex) {
    patternOwners = patternOwnerIndex._owners;
    usedPatterns = patternOwnerIndex._patterns;
  } else {
    final patterns = <String, ProjectSmartTilePattern>{
      for (final pattern in catalog.patterns) pattern.id: pattern,
    };
    patternOwners = <int, _SmartTilePatternOwner>{};
    for (final stroke in layer.patternStrokes) {
      final pattern = patterns[stroke.patternId];
      if (pattern == null || pattern.usage != layer.usage) continue;
      for (final cell in stroke.cells) {
        if (cell.x < 0 ||
            cell.y < 0 ||
            cell.x >= map.size.width ||
            cell.y >= map.size.height) {
          continue;
        }
        patternOwners[cell.y * map.size.width + cell.x] = (
          stroke: stroke,
          pattern: pattern,
        );
      }
    }
    usedPatterns = patternOwners.values.map((owner) => owner.pattern);
  }
  final envelope = _layerVisualEnvelope(
    preset: preset,
    patterns: usedPatterns,
    pass: pass,
    atlases: atlases,
    animations: animations,
    destinationCellWidth: destinationCellWidth,
    destinationCellHeight: destinationCellHeight,
    sourceCellWidth: sourceCellWidth,
    sourceCellHeight: sourceCellHeight,
  );
  final resolver = PreparedSmartTileResolver(
    preset: preset,
    materials: catalog.materials,
    mapId: map.id,
    layerId: layer.id,
    projectSeed: projectSeed,
    layerSeed: layer.layerSeed,
    candidateWeights: layer.candidateWeights,
  );
  return SmartTileLayerVisualPlan._(
    map: map,
    layer: layer,
    preset: preset,
    pass: pass,
    projectSeed: projectSeed,
    atlases: atlases,
    animations: animations,
    patternOwners: patternOwners,
    resolver: resolver,
    envelope: envelope,
    destinationCellWidth: destinationCellWidth,
    destinationCellHeight: destinationCellHeight,
    sourceCellWidth: sourceCellWidth,
    sourceCellHeight: sourceCellHeight,
  );
}

/// Time-invariant smart-tile resolution for one layer, pass and cell metrics.
///
/// [resolveBatch] emits the same visuals as [resolveSmartTileLayerVisualBatch]
/// (both paths share [_buildPartVisual]) but only selects the active animation
/// variant per planned cell instead of re-running rule matching, atlas
/// lookups, geometry, and per-cell string hashing on every frame.
final class SmartTileLayerVisualPlan {
  SmartTileLayerVisualPlan._({
    required MapData map,
    required SmartTileLayer layer,
    required ProjectSmartTilePreset preset,
    required this.pass,
    required int projectSeed,
    required Map<String, ProjectSmartTileAtlas> atlases,
    required Map<String, ProjectSmartTileAnimation> animations,
    required Map<int, _SmartTilePatternOwner> patternOwners,
    required PreparedSmartTileResolver resolver,
    required SmartTileGeometryRect envelope,
    required double destinationCellWidth,
    required double destinationCellHeight,
    required double sourceCellWidth,
    required double sourceCellHeight,
  })  : _map = map,
        _layer = layer,
        _preset = preset,
        _projectSeed = projectSeed,
        _atlases = atlases,
        _animations = animations,
        _patternOwners = patternOwners,
        _resolver = resolver,
        _envelope = envelope,
        _destinationCellWidth = destinationCellWidth,
        _destinationCellHeight = destinationCellHeight,
        _sourceCellWidth = sourceCellWidth,
        _sourceCellHeight = sourceCellHeight;

  SmartTileLayerVisualPlan._inert({required MapData map})
      : _map = map,
        _layer = null,
        _preset = null,
        pass = SmartTileVisualPass.background,
        _projectSeed = 0,
        _atlases = const <String, ProjectSmartTileAtlas>{},
        _animations = const <String, ProjectSmartTileAnimation>{},
        _patternOwners = const <int, _SmartTilePatternOwner>{},
        _resolver = null,
        _envelope = null,
        _destinationCellWidth = 1,
        _destinationCellHeight = 1,
        _sourceCellWidth = 1,
        _sourceCellHeight = 1;

  static const List<_PlannedSmartTileVisual> _emptyCellPlan =
      <_PlannedSmartTileVisual>[];

  final SmartTileVisualPass pass;
  final MapData _map;
  final SmartTileLayer? _layer;
  final ProjectSmartTilePreset? _preset;
  final int _projectSeed;
  final Map<String, ProjectSmartTileAtlas> _atlases;
  final Map<String, ProjectSmartTileAnimation> _animations;
  final Map<int, _SmartTilePatternOwner> _patternOwners;
  final PreparedSmartTileResolver? _resolver;
  final SmartTileGeometryRect? _envelope;
  final double _destinationCellWidth;
  final double _destinationCellHeight;
  final double _sourceCellWidth;
  final double _sourceCellHeight;

  /// Lazily planned cells; sparse so huge maps only retain visited cells.
  final Map<int, List<_PlannedSmartTileVisual>> _plannedByCellIndex =
      <int, List<_PlannedSmartTileVisual>>{};

  /// Emits the visuals intersecting [viewportBounds] at [elapsedMs].
  ///
  /// Work counters mirror [resolveSmartTileLayerVisualBatch]: owner cell
  /// visits count the scanned envelope range. Pattern stroke visits are
  /// always zero because ownership is resolved at plan build time.
  SmartTileLayerVisualBatch resolveBatch({
    int elapsedMs = 0,
    SmartTileGeometryRect? viewportBounds,
    SmartTileAnimationElapsedMsForCell? animationElapsedMsForCell,
  }) {
    final envelope = _envelope;
    if (envelope == null) {
      return const SmartTileLayerVisualBatch.empty();
    }
    final mapWidth = _map.size.width;
    final mapHeight = _map.size.height;
    final (:startX, :startY, :endX, :endY) = viewportBounds == null
        ? (startX: 0, startY: 0, endX: mapWidth, endY: mapHeight)
        : _scanRangeForViewport(
            mapWidth: mapWidth,
            mapHeight: mapHeight,
            envelope: envelope,
            viewport: viewportBounds,
            destinationCellWidth: _destinationCellWidth,
            destinationCellHeight: _destinationCellHeight,
          );
    final visuals = <SmartTileLayerVisual>[];
    var ownerCellVisits = 0;
    for (var y = startY; y < endY; y++) {
      final rowBase = y * mapWidth;
      for (var x = startX; x < endX; x++) {
        ownerCellVisits += 1;
        final items = _plannedByCellIndex[rowBase + x] ??= _planCell(x, y);
        final cellElapsedMs = animationElapsedMsForCell?.call(
              cellX: x,
              cellY: y,
              elapsedMs: elapsedMs,
            ) ??
            elapsedMs;
        for (final item in items) {
          final visual = item.visualAt(cellElapsedMs);
          if (visual == null) continue;
          if (viewportBounds != null &&
              !visual.geometry.visualBounds.intersects(viewportBounds)) {
            continue;
          }
          visuals.add(visual);
        }
      }
    }
    visuals.sort(_compareSmartTileVisualPaintOrder);
    return SmartTileLayerVisualBatch(
      visuals: visuals,
      work: SmartTileLayerVisualWorkCounts(
        requestedCellCount: (endX - startX) * (endY - startY),
        ownerCellVisits: ownerCellVisits,
        patternStrokeCellVisits: 0,
        resolvedVisualCount: visuals.length,
      ),
    );
  }

  List<_PlannedSmartTileVisual> _planCell(int x, int y) {
    final layer = _layer!;
    final preset = _preset!;
    final context = smartTileCellContextForLayerCell(
      layer: layer,
      map: _map,
      preset: preset,
      x: x,
      y: y,
    );
    final resolution = _resolver!.resolve(context: context, x: x, y: y);
    List<_PlannedSmartTileVisual>? items;
    final candidate = resolution.candidate;
    final ruleId = resolution.ruleId;
    if (candidate != null && ruleId != null) {
      for (final part in candidate.parts) {
        if (!_channelBelongsToPass(part.channel, pass)) continue;
        final planned = _planPartVisual(
          part: part,
          cellX: x,
          cellY: y,
          deterministicHash: resolution.deterministicHash ?? 0,
          transform: composeSmartTileSpriteTransforms(
            first: part.transform,
            second: resolution.transform,
          ),
          ruleId: ruleId,
          candidateId: candidate.id,
          drawOrder: part.drawOrder,
        );
        if (planned != null) (items ??= []).add(planned);
      }
    }
    final patternOwner = _patternOwners[y * _map.size.width + x];
    if (patternOwner != null) {
      final patternCell = smartTilePatternCellAt(
        pattern: patternOwner.pattern,
        stroke: patternOwner.stroke,
        cell: GridPos(x: x, y: y),
      );
      if (patternCell != null) {
        final deterministicHash = stableHash32(
          '${_map.id}|${layer.id}|${patternOwner.pattern.id}|$x|$y|'
          '$_projectSeed|${layer.layerSeed}',
        );
        for (final part in patternCell.parts) {
          if (!_channelBelongsToPass(part.channel, pass)) continue;
          final planned = _planPartVisual(
            part: part,
            cellX: x,
            cellY: y,
            deterministicHash: deterministicHash,
            transform: part.transform,
            ruleId: 'pattern:${patternOwner.pattern.id}',
            candidateId: 'pattern-cell-${patternCell.x}-${patternCell.y}',
            drawOrder: patternOwner.pattern.drawOrder + part.drawOrder,
          );
          if (planned != null) (items ??= []).add(planned);
        }
      }
    }
    return items ?? _emptyCellPlan;
  }

  _PlannedSmartTileVisual? _planPartVisual({
    required SmartTileVisualPart part,
    required int cellX,
    required int cellY,
    required int deterministicHash,
    required SmartTileSpriteTransform transform,
    required String ruleId,
    required String candidateId,
    required int drawOrder,
  }) {
    SmartTileLayerVisual? build(SmartTileFrameRef frame) => _buildPartVisual(
          frame: frame,
          part: part,
          atlases: _atlases,
          cellX: cellX,
          cellY: cellY,
          deterministicHash: deterministicHash,
          transform: transform,
          ruleId: ruleId,
          candidateId: candidateId,
          drawOrder: drawOrder,
          destinationCellWidth: _destinationCellWidth,
          destinationCellHeight: _destinationCellHeight,
          sourceCellWidth: _sourceCellWidth,
          sourceCellHeight: _sourceCellHeight,
        );

    return part.source.map(
      frame: (source) {
        final visual = build(source.frame);
        return visual == null ? null : _PlannedSmartTileVisual.fixed(visual);
      },
      animation: (source) {
        final animation = _animations[source.animationId];
        if (animation == null || animation.frames.isEmpty) return null;
        final timeline = _animationTimeline(animation);
        final totalDurationMs = timeline.fold<int>(
          0,
          (sum, frame) => sum + frame.durationMs,
        );
        if (totalDurationMs <= 0) {
          final visual = build(timeline.first.frame);
          return visual == null ? null : _PlannedSmartTileVisual.fixed(visual);
        }
        final variants = <SmartTileLayerVisual?>[];
        final cumulativeMs = <int>[];
        var cursor = 0;
        var hasAnyVisual = false;
        for (final entry in timeline) {
          cursor += entry.durationMs;
          cumulativeMs.add(cursor);
          final visual = build(entry.frame);
          if (visual != null) hasAnyVisual = true;
          variants.add(visual);
        }
        if (!hasAnyVisual) return null;
        return _PlannedSmartTileVisual.animated(
          variants: variants,
          cumulativeMs: cumulativeMs,
          totalDurationMs: totalDurationMs,
          syncOffsetMs: animation.sync == SmartTileAnimationSync.perCell
              ? deterministicHash % totalDurationMs
              : 0,
          loopOnce: animation.loop == SmartTileAnimationLoop.once,
        );
      },
    );
  }
}

typedef SmartTileAnimationElapsedMsForCell = int Function({
  required int cellX,
  required int cellY,
  required int elapsedMs,
});

/// One planned cell part: either a fixed visual or prebuilt animation
/// variants selected by elapsed time, mirroring [_resolveVisualFrame].
final class _PlannedSmartTileVisual {
  const _PlannedSmartTileVisual.fixed(SmartTileLayerVisual visual)
      : _fixed = visual,
        _variants = null,
        _cumulativeMs = const <int>[],
        totalDurationMs = 0,
        syncOffsetMs = 0,
        loopOnce = false;

  const _PlannedSmartTileVisual.animated({
    required List<SmartTileLayerVisual?> variants,
    required List<int> cumulativeMs,
    required this.totalDurationMs,
    required this.syncOffsetMs,
    required this.loopOnce,
  })  : _fixed = null,
        _variants = variants,
        _cumulativeMs = cumulativeMs;

  final SmartTileLayerVisual? _fixed;
  final List<SmartTileLayerVisual?>? _variants;
  final List<int> _cumulativeMs;
  final int totalDurationMs;
  final int syncOffsetMs;
  final bool loopOnce;

  SmartTileLayerVisual? visualAt(int elapsedMs) {
    final variants = _variants;
    if (variants == null) return _fixed;
    var time = elapsedMs < 0 ? 0 : elapsedMs;
    time += syncOffsetMs;
    if (loopOnce) {
      if (time >= totalDurationMs) return variants.last;
    } else {
      time %= totalDurationMs;
    }
    for (var index = 0; index < _cumulativeMs.length; index += 1) {
      if (time < _cumulativeMs[index]) return variants[index];
    }
    return variants.last;
  }
}
