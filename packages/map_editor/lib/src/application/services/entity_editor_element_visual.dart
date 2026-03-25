import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:map_core/map_core.dart';

class ResolvedEntityElementVisual {
  const ResolvedEntityElementVisual({
    required this.image,
    required this.srcRect,
  });

  final ui.Image image;
  final Rect srcRect;
}

ResolvedEntityElementVisual? resolveEntityPrimaryFrameVisual({
  required MapEntity entity,
  required ProjectManifest? project,
  required Map<String, ui.Image?> tilesetImagesById,
  required int sourceTileWidth,
  required int sourceTileHeight,
}) {
  if (project == null) {
    return null;
  }
  final elementId = entity.resolvedProjectElementIdForEditor;
  if (elementId == null) {
    return null;
  }
  ProjectElementEntry? entry;
  for (final e in project.elements) {
    if (e.id == elementId) {
      entry = e;
      break;
    }
  }
  if (entry == null || entry.frames.isEmpty) {
    return null;
  }
  final frame = entry.frames.first;
  final tilesetId = frame.tilesetId.trim().isNotEmpty
      ? frame.tilesetId.trim()
      : entry.tilesetId.trim();
  if (tilesetId.isEmpty) {
    return null;
  }
  final image = tilesetImagesById[tilesetId];
  if (image == null || sourceTileWidth <= 0 || sourceTileHeight <= 0) {
    return null;
  }
  final src = frame.source;
  final wTiles = src.width <= 0 ? 1 : src.width;
  final hTiles = src.height <= 0 ? 1 : src.height;
  final px = src.x * sourceTileWidth;
  final py = src.y * sourceTileHeight;
  final pw = wTiles * sourceTileWidth;
  final ph = hTiles * sourceTileHeight;
  if (px < 0 ||
      py < 0 ||
      px + pw > image.width ||
      py + ph > image.height) {
    return null;
  }
  return ResolvedEntityElementVisual(
    image: image,
    srcRect: Rect.fromLTWH(
      px.toDouble(),
      py.toDouble(),
      pw.toDouble(),
      ph.toDouble(),
    ),
  );
}

void collectTilesetIdsForEntityEditorVisuals({
  required MapData map,
  required ProjectManifest? project,
  required void Function(String tilesetId) onTilesetId,
}) {
  if (project == null) {
    return;
  }
  final byId = <String, ProjectElementEntry>{
    for (final e in project.elements) e.id: e,
  };
  for (final ent in map.entities) {
    final id = ent.resolvedProjectElementIdForEditor;
    if (id == null) {
      continue;
    }
    final entry = byId[id];
    if (entry == null || entry.frames.isEmpty) {
      continue;
    }
    final frame = entry.frames.first;
    final tid = frame.tilesetId.trim().isNotEmpty
        ? frame.tilesetId.trim()
        : entry.tilesetId.trim();
    if (tid.isNotEmpty) {
      onTilesetId(tid);
    }
  }
}
