import 'dart:ui'
    show Canvas, Color, FilterQuality, Image, Paint, PaintingStyle, Rect;

import 'package:flutter/painting.dart' show HSVColor;
import 'package:map_core/map_core.dart';

import 'surface_tile_preview_resolver.dart';

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
}) {
  if (!layer.isVisible ||
      layer.opacity <= 0 ||
      mapSize.width <= 0 ||
      mapSize.height <= 0 ||
      layer.placements.isEmpty) {
    return const <SurfaceLayerStaticPreviewCell>[];
  }

  final cells = <SurfaceLayerStaticPreviewCell>[];
  for (final placement in layer.placements) {
    if (placement.x < 0 ||
        placement.y < 0 ||
        placement.x >= mapSize.width ||
        placement.y >= mapSize.height) {
      continue;
    }
    cells.add(
      SurfaceLayerStaticPreviewCell(
        placement: placement,
        role: resolveSurfaceVariantRoleForPlacement(
          placements: layer.placements,
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
}) {
  if (tileWidth <= 0 || tileHeight <= 0 || zoom <= 0) {
    return;
  }

  final cells = buildSurfaceLayerStaticPreviewCells(
    layer: layer,
    mapSize: mapSize,
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
}) {
  if (tileWidth <= 0 || tileHeight <= 0 || zoom <= 0) {
    return;
  }

  final cells = buildSurfaceLayerStaticPreviewCells(
    layer: layer,
    mapSize: mapSize,
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
