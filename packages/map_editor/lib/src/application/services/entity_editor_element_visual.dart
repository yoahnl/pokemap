import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:map_core/map_core.dart';

const int kEntityEditorFrameDurationFallbackMs = 200;

class ResolvedEntityElementVisual {
  const ResolvedEntityElementVisual({
    required this.image,
    required this.srcRect,
  });

  final ui.Image image;
  final Rect srcRect;
}

int entityEditorFrameDurationMs(TilesetVisualFrame frame) {
  final d = frame.durationMs;
  if (d == null || d <= 0) {
    return kEntityEditorFrameDurationFallbackMs;
  }
  return d;
}

TilesetVisualFrame entityEditorPickFrame(
  List<TilesetVisualFrame> frames,
  int elapsedMs,
) {
  if (frames.isEmpty) {
    throw StateError('ProjectElementEntry.frames must not be empty');
  }
  if (frames.length == 1) {
    return frames.first;
  }
  var total = 0;
  for (final f in frames) {
    total += entityEditorFrameDurationMs(f);
  }
  if (total <= 0) {
    return frames.first;
  }
  var t = elapsedMs % total;
  if (t < 0) {
    t = (t % total + total) % total;
  }
  for (final f in frames) {
    final d = entityEditorFrameDurationMs(f);
    if (t < d) {
      return f;
    }
    t -= d;
  }
  return frames.last;
}

Rect? _sourceRectForFrameInImage({
  required TilesetVisualFrame frame,
  required ui.Image image,
  required int sourceTileWidth,
  required int sourceTileHeight,
}) {
  if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
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
  return Rect.fromLTWH(
    px.toDouble(),
    py.toDouble(),
    pw.toDouble(),
    ph.toDouble(),
  );
}

ResolvedEntityElementVisual? resolveEntityElementVisualForEditor({
  required MapEntity entity,
  required ProjectManifest? project,
  required Map<String, ui.Image?> tilesetImagesById,
  required int sourceTileWidth,
  required int sourceTileHeight,
  required int editorAnimationTimeMs,
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
  final frame =
      entityEditorPickFrame(entry.frames, editorAnimationTimeMs);
  final tilesetId = frame.tilesetId.trim().isNotEmpty
      ? frame.tilesetId.trim()
      : entry.tilesetId.trim();
  if (tilesetId.isEmpty) {
    return null;
  }
  final image = tilesetImagesById[tilesetId];
  if (image == null) {
    return null;
  }
  final srcRect = _sourceRectForFrameInImage(
    frame: frame,
    image: image,
    sourceTileWidth: sourceTileWidth,
    sourceTileHeight: sourceTileHeight,
  );
  if (srcRect == null) {
    return null;
  }
  return ResolvedEntityElementVisual(image: image, srcRect: srcRect);
}

bool mapEntitiesNeedEditorFrameAnimation(
  MapData map,
  ProjectManifest? project,
) {
  if (project == null || map.entities.isEmpty) {
    return false;
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
    if (entry != null && entry.frames.length > 1) {
      return true;
    }
  }
  return false;
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
    for (final frame in entry.frames) {
      final tid = frame.tilesetId.trim().isNotEmpty
          ? frame.tilesetId.trim()
          : entry.tilesetId.trim();
      if (tid.isNotEmpty) {
        onTilesetId(tid);
      }
    }
  }
}
