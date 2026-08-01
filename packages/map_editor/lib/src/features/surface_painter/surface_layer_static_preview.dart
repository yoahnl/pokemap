import 'dart:collection';
import 'dart:ui'
    show Canvas, Color, FilterQuality, Image, Paint, PaintingStyle, Rect;

import 'package:flutter/painting.dart' show HSVColor;
import 'package:map_core/map_core.dart';

import 'surface_tile_preview_resolver.dart';

/// Half-open cell bounds for the editor Surface preview.
///
/// The full topology is still used for role resolution; these bounds only
/// limit cells that reach the painter, avoiding seams at viewport edges.
final class SurfacePreviewCellViewport {
  const SurfacePreviewCellViewport({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;

  bool contains(SurfaceCellPlacement placement) =>
      placement.x >= left &&
      placement.x < right &&
      placement.y >= top &&
      placement.y < bottom;
}

/// Editor-owned row index for one immutable Surface layer.
///
/// The complete topology is retained for neighbour roles, while viewport
/// queries enumerate only indexed rows and then restore authoring order for
/// visually overlapping duplicate placements.
final class SurfacePreviewLayerIndex {
  SurfacePreviewLayerIndex._({
    required SurfaceLayer sourceLayer,
    required List<SurfaceCellPlacement> placements,
  })  : _sourceLayer = sourceLayer,
        _placements = placements,
        topology = SurfacePlacementTopology(placements),
        _placementsByRow = _indexPreviewPlacementsByRow(placements) {
    if (placements.isEmpty) {
      _firstIndexedRow = null;
      _lastIndexedRow = null;
    } else {
      var first = placements.first.y;
      var last = first;
      for (final placement in placements.skip(1)) {
        if (placement.y < first) first = placement.y;
        if (placement.y > last) last = placement.y;
      }
      _firstIndexedRow = first;
      _lastIndexedRow = last;
    }
  }

  factory SurfacePreviewLayerIndex.fromLayer(SurfaceLayer layer) {
    return SurfacePreviewLayerIndex._(
      sourceLayer: layer,
      placements: List<SurfaceCellPlacement>.unmodifiable(layer.placements),
    );
  }

  final SurfaceLayer _sourceLayer;
  final List<SurfaceCellPlacement> _placements;
  final Map<int, List<_IndexedSurfacePreviewPlacement>> _placementsByRow;
  final SurfacePlacementTopology topology;
  late final int? _firstIndexedRow;
  late final int? _lastIndexedRow;

  bool belongsTo(SurfaceLayer layer) => identical(_sourceLayer, layer);

  Iterable<SurfaceCellPlacement> placementsIn(
    SurfacePreviewCellViewport? viewport,
  ) sync* {
    if (viewport == null) {
      yield* _placements;
      return;
    }
    if (_placements.isEmpty ||
        viewport.right <= viewport.left ||
        viewport.bottom <= viewport.top) {
      return;
    }
    final firstIndexedRow = _firstIndexedRow!;
    final lastIndexedRow = _lastIndexedRow!;
    final startRow =
        viewport.top > firstIndexedRow ? viewport.top : firstIndexedRow;
    final endRowExclusive = viewport.bottom < lastIndexedRow + 1
        ? viewport.bottom
        : lastIndexedRow + 1;
    final visible = <_IndexedSurfacePreviewPlacement>[];
    for (var y = startRow; y < endRowExclusive; y += 1) {
      final row = _placementsByRow[y];
      if (row == null) continue;
      for (final indexed in row) {
        final x = indexed.placement.x;
        if (x >= viewport.left && x < viewport.right) {
          visible.add(indexed);
        }
      }
    }
    visible.sort((a, b) => a.authoringIndex.compareTo(b.authoringIndex));
    for (final indexed in visible) {
      yield indexed.placement;
    }
  }
}

/// Owns Surface preview indexes across editor rebuilds.
///
/// Surface layers are immutable value objects in the editor state. Reusing the
/// exact layer instance therefore means its placements are unchanged; replacing
/// it (including with the same authoring id) rebuilds only that layer's index.
/// Stale layers are dropped on every synchronization.
final class SurfacePreviewLayerIndexOwner {
  Map<SurfaceLayer, SurfacePreviewLayerIndex> _indexes =
      Map<SurfaceLayer, SurfacePreviewLayerIndex>.identity();

  Map<SurfaceLayer, SurfacePreviewLayerIndex> indexesFor(
    Iterable<MapLayer> layers,
  ) {
    final next = Map<SurfaceLayer, SurfacePreviewLayerIndex>.identity();
    for (final layer in layers.whereType<SurfaceLayer>()) {
      next[layer] =
          _indexes[layer] ?? SurfacePreviewLayerIndex.fromLayer(layer);
    }
    _indexes = next;
    return UnmodifiableMapView<SurfaceLayer, SurfacePreviewLayerIndex>(next);
  }

  void clear() {
    _indexes = Map<SurfaceLayer, SurfacePreviewLayerIndex>.identity();
  }
}

/// One editor-only preview cell for a sparse Surface placement.
///
/// The preview carries the resolved role so the editor can already show that
/// placements connect by preset, while still avoiding any atlas image lookup.
final class SurfaceLayerStaticPreviewCell {
  const SurfaceLayerStaticPreviewCell({
    required this.placement,
    required this.role,
    required this.color,
  });

  final SurfaceCellPlacement placement;
  final SurfaceVariantRole role;
  final Color color;
}

/// Builds deterministic preview cells for an editor SurfaceLayer.
///
/// This is intentionally not the final Surface renderer. It only makes sparse
/// placements visible in the map editor; real atlas tiles, frames, and animation
/// clocks stay out of Lot 86.
List<SurfaceLayerStaticPreviewCell> buildSurfaceLayerStaticPreviewCells({
  required SurfaceLayer layer,
  required GridSize mapSize,
  SurfacePlacementTopology? topology,
  SurfacePreviewLayerIndex? layerIndex,
  SurfacePreviewCellViewport? viewport,
}) {
  if (!layer.isVisible ||
      layer.opacity <= 0 ||
      mapSize.width <= 0 ||
      mapSize.height <= 0 ||
      layer.placements.isEmpty) {
    return const <SurfaceLayerStaticPreviewCell>[];
  }

  if (layerIndex != null && !layerIndex.belongsTo(layer)) {
    throw ArgumentError.value(
      layer.id,
      'layerIndex',
      'must belong to the provided SurfaceLayer instance',
    );
  }
  if (topology != null && layerIndex != null) {
    throw ArgumentError('Provide topology or layerIndex, not both.');
  }

  final resolvedTopology = topology ??
      layerIndex?.topology ??
      SurfacePlacementTopology(layer.placements);
  final cells = <SurfaceLayerStaticPreviewCell>[];
  final placements = layerIndex?.placementsIn(viewport) ?? layer.placements;
  for (final placement in placements) {
    if (placement.x < 0 ||
        placement.y < 0 ||
        placement.x >= mapSize.width ||
        placement.y >= mapSize.height) {
      continue;
    }
    if (layerIndex == null &&
        viewport != null &&
        !viewport.contains(placement)) {
      continue;
    }
    cells.add(
      SurfaceLayerStaticPreviewCell(
        placement: placement,
        role: resolvedTopology.roleAt(
          x: placement.x,
          y: placement.y,
          surfacePresetId: placement.surfacePresetId,
        ),
        color: surfaceStaticPreviewColorForPresetId(
          placement.surfacePresetId,
        ),
      ),
    );
  }
  return List<SurfaceLayerStaticPreviewCell>.unmodifiable(cells);
}

/// Stable editor color for a preset id.
///
/// A seeded hash keeps previews deterministic across runs and tests; no random
/// state is involved, and no ProjectSurfacePreset lookup is needed.
Color surfaceStaticPreviewColorForPresetId(String surfacePresetId) {
  final normalized = surfacePresetId.trim();
  var hash = 0x811c9dc5;
  for (final codeUnit in normalized.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  final hue = (hash % 360).toDouble();
  return HSVColor.fromAHSV(1, hue, 0.62, 0.95).toColor();
}

/// Paints the editor-only static Surface placement overlay.
void paintSurfaceLayerStaticPreview({
  required Canvas canvas,
  required SurfaceLayer layer,
  required GridSize mapSize,
  required double tileWidth,
  required double tileHeight,
  required double zoom,
  SurfacePlacementTopology? topology,
  SurfacePreviewLayerIndex? layerIndex,
  SurfacePreviewCellViewport? viewport,
}) {
  if (tileWidth <= 0 || tileHeight <= 0 || zoom <= 0) {
    return;
  }

  final cells = buildSurfaceLayerStaticPreviewCells(
    layer: layer,
    mapSize: mapSize,
    topology: topology,
    layerIndex: layerIndex,
    viewport: viewport,
  );
  if (cells.isEmpty) {
    return;
  }

  final alphaScale = layer.opacity.clamp(0.0, 1.0).toDouble();
  for (final cell in cells) {
    _paintSurfaceDebugCell(
      canvas,
      cell: cell,
      rect: _surfaceCellRect(
        cell,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        zoom: zoom,
      ),
      alphaScale: alphaScale,
      zoom: zoom,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
  }
}

/// Paints real atlas tiles for Surface placements when the editor already has
/// the referenced tileset image loaded; otherwise it keeps the Lot 86 debug
/// overlay so every painted Surface remains visible.
void paintSurfaceLayerAtlasTilePreview({
  required Canvas canvas,
  required SurfaceLayer layer,
  required GridSize mapSize,
  required ProjectManifest? project,
  required Map<String, Image?> tilesetImagesById,
  required double tileWidth,
  required double tileHeight,
  required double zoom,
  int elapsedMs = 0,
  SurfacePlacementTopology? topology,
  SurfacePreviewLayerIndex? layerIndex,
  SurfacePreviewCellViewport? viewport,
}) {
  if (tileWidth <= 0 || tileHeight <= 0 || zoom <= 0) {
    return;
  }

  final cells = buildSurfaceLayerStaticPreviewCells(
    layer: layer,
    mapSize: mapSize,
    topology: topology,
    layerIndex: layerIndex,
    viewport: viewport,
  );
  if (cells.isEmpty) {
    return;
  }

  final availableTilesetIds = <String>{
    for (final entry in tilesetImagesById.entries)
      if (entry.value != null) entry.key,
  };
  final catalog = project?.surfaceCatalog;
  final alphaScale = layer.opacity.clamp(0.0, 1.0).toDouble();

  for (final cell in cells) {
    final rect = _surfaceCellRect(
      cell,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      zoom: zoom,
    );
    SurfaceTilePreviewInstruction? instruction;
    if (catalog != null) {
      instruction = resolveSurfaceTilePreviewInstruction(
        layer: layer,
        placement: cell.placement,
        catalog: catalog,
        availableTilesetIds: availableTilesetIds,
        elapsedMs: elapsedMs,
        precomputedRole: cell.role,
      );
    }
    final image =
        instruction == null ? null : tilesetImagesById[instruction.tilesetId];
    if (instruction != null &&
        image != null &&
        _sourceRectFitsImage(instruction.sourceRect, image)) {
      canvas.drawImageRect(
        image,
        instruction.sourceRect,
        rect,
        Paint()
          ..filterQuality = FilterQuality.none
          ..color = const Color(0xFFFFFFFF).withValues(alpha: alphaScale),
      );
      continue;
    }

    _paintSurfaceDebugCell(
      canvas,
      cell: cell,
      rect: rect,
      alphaScale: alphaScale,
      zoom: zoom,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
  }
}

Map<int, List<_IndexedSurfacePreviewPlacement>> _indexPreviewPlacementsByRow(
    List<SurfaceCellPlacement> placements) {
  final rows = <int, List<_IndexedSurfacePreviewPlacement>>{};
  for (var index = 0; index < placements.length; index += 1) {
    final placement = placements[index];
    rows
        .putIfAbsent(placement.y, () => <_IndexedSurfacePreviewPlacement>[])
        .add(
          _IndexedSurfacePreviewPlacement(
            authoringIndex: index,
            placement: placement,
          ),
        );
  }
  return Map<int, List<_IndexedSurfacePreviewPlacement>>.unmodifiable(
    <int, List<_IndexedSurfacePreviewPlacement>>{
      for (final entry in rows.entries)
        entry.key:
            List<_IndexedSurfacePreviewPlacement>.unmodifiable(entry.value),
    },
  );
}

final class _IndexedSurfacePreviewPlacement {
  const _IndexedSurfacePreviewPlacement({
    required this.authoringIndex,
    required this.placement,
  });

  final int authoringIndex;
  final SurfaceCellPlacement placement;
}

Rect _surfaceCellRect(
  SurfaceLayerStaticPreviewCell cell, {
  required double tileWidth,
  required double tileHeight,
  required double zoom,
}) {
  return Rect.fromLTWH(
    cell.placement.x * tileWidth,
    cell.placement.y * tileHeight,
    tileWidth,
    tileHeight,
  ).deflate(1.0 / zoom);
}

void _paintSurfaceDebugCell(
  Canvas canvas, {
  required SurfaceLayerStaticPreviewCell cell,
  required Rect rect,
  required double alphaScale,
  required double zoom,
  required double tileWidth,
  required double tileHeight,
}) {
  final fillAlpha = 0.28 * alphaScale;
  final borderAlpha = 0.86 * alphaScale;
  final markerAlpha = 0.72 * alphaScale;

  canvas.drawRect(
    rect,
    Paint()
      ..color = cell.color.withValues(alpha: fillAlpha)
      ..style = PaintingStyle.fill,
  );
  canvas.drawRect(
    rect,
    Paint()
      ..color = cell.color.withValues(alpha: borderAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 / zoom,
  );

  final markerRadius = _roleMarkerRadius(cell.role, tileWidth, tileHeight);
  canvas.drawCircle(
    rect.center,
    markerRadius,
    Paint()
      ..color = cell.color.withValues(alpha: markerAlpha)
      ..style = PaintingStyle.fill,
  );
}

bool _sourceRectFitsImage(Rect sourceRect, Image image) {
  return sourceRect.left >= 0 &&
      sourceRect.top >= 0 &&
      sourceRect.width > 0 &&
      sourceRect.height > 0 &&
      sourceRect.right <= image.width &&
      sourceRect.bottom <= image.height;
}

double _roleMarkerRadius(
  SurfaceVariantRole role,
  double tileWidth,
  double tileHeight,
) {
  final shortestSide = tileWidth < tileHeight ? tileWidth : tileHeight;
  final scale = role == SurfaceVariantRole.isolated ? 0.12 : 0.16;
  return shortestSide * scale;
}
