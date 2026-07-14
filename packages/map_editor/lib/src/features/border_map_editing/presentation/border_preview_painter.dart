import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show immutable;
import 'package:map_core/map_core.dart';

import '../application/border_preview_transaction.dart';

enum EditorBorderPaintEntryKind { ground, placement }

BorderMaterialization? editorBorderPreviewMaterializationForMap({
  required MapData map,
  required BorderPreviewTransaction? preview,
}) {
  if (preview == null ||
      preview.mapId != map.id ||
      !identical(preview.context.mapIdentity, map)) {
    return null;
  }
  final result = preview.result;
  return result?.canApply == true ? result!.materialization : null;
}

/// One passive editor draw entry derived from saved or preview materialization.
@immutable
final class EditorBorderPaintEntry {
  const EditorBorderPaintEntry._({
    required this.layerId,
    required this.featureId,
    required this.layerOpacity,
    required this.kind,
    required this.snapshotId,
    this.ground,
    this.placement,
  });

  factory EditorBorderPaintEntry.ground({
    required String layerId,
    required String featureId,
    required double layerOpacity,
    required BorderResolvedGroundCell ground,
  }) =>
      EditorBorderPaintEntry._(
        layerId: layerId,
        featureId: featureId,
        layerOpacity: layerOpacity,
        kind: EditorBorderPaintEntryKind.ground,
        snapshotId: ground.visualSnapshotId,
        ground: ground,
      );

  factory EditorBorderPaintEntry.placement({
    required String layerId,
    required String featureId,
    required double layerOpacity,
    required BorderResolvedPlacement placement,
  }) =>
      EditorBorderPaintEntry._(
        layerId: layerId,
        featureId: featureId,
        layerOpacity: layerOpacity,
        kind: EditorBorderPaintEntryKind.placement,
        snapshotId: placement.visualSnapshotId,
        placement: placement,
      );

  final String layerId;
  final String featureId;
  final double layerOpacity;
  final EditorBorderPaintEntryKind kind;
  final String snapshotId;
  final BorderResolvedGroundCell? ground;
  final BorderResolvedPlacement? placement;
}

/// Preserves authored layer/feature order and the ground-before-props contract.
List<EditorBorderPaintEntry> buildEditorBorderPaintEntries({
  required MapData map,
  BorderPreviewTransaction? preview,
}) {
  final result = <EditorBorderPaintEntry>[];
  for (final layer in map.layers) {
    if (layer is! BorderLayer || !layer.isVisible || layer.opacity <= 0) {
      continue;
    }
    result.addAll(
      buildEditorBorderLayerPaintEntries(
        map: map,
        layer: layer,
        preview: preview,
      ),
    );
  }
  return List<EditorBorderPaintEntry>.unmodifiable(result);
}

/// Builds exactly one authored Border layer pass.
///
/// All feature grounds precede every placement in the same layer. A resolved
/// preview replaces only its target feature; neighbouring features continue to
/// use their saved immutable materializations.
List<EditorBorderPaintEntry> buildEditorBorderLayerPaintEntries({
  required MapData map,
  required BorderLayer layer,
  BorderPreviewTransaction? preview,
}) {
  if (!layer.isVisible || layer.opacity <= 0) {
    return const <EditorBorderPaintEntry>[];
  }
  BorderMaterialization? materializationOf(BorderFeature feature) {
    final previewMatches = preview?.mapId == map.id &&
        identical(preview?.context.mapIdentity, map) &&
        preview?.layerId == layer.id &&
        preview?.featureId == feature.id &&
        preview?.result?.canApply == true;
    return previewMatches
        ? preview!.result!.materialization
        : feature.materialization;
  }

  final result = <EditorBorderPaintEntry>[];
  for (final feature in layer.content.features) {
    final materialization = materializationOf(feature);
    if (materialization == null) continue;
    for (final ground in materialization.ground) {
      result.add(
        EditorBorderPaintEntry.ground(
          layerId: layer.id,
          featureId: feature.id,
          layerOpacity: layer.opacity,
          ground: ground,
        ),
      );
    }
  }
  for (final feature in layer.content.features) {
    final materialization = materializationOf(feature);
    if (materialization == null) continue;
    for (final placement in materialization.placements) {
      result.add(
        EditorBorderPaintEntry.placement(
          layerId: layer.id,
          featureId: feature.id,
          layerOpacity: layer.opacity,
          placement: placement,
        ),
      );
    }
  }
  return List<EditorBorderPaintEntry>.unmodifiable(result);
}

String editorBorderFrameImageKey(String snapshotId, int frameIndex) =>
    'border-frame:$snapshotId:$frameIndex';

/// Draws immutable Border snapshot pixels into the existing editor canvas.
final class BorderPreviewPainter {
  const BorderPreviewPainter();

  void paint(
    ui.Canvas canvas, {
    required MapData map,
    required ProjectBorderCatalog catalog,
    required Map<String, ui.Image?> frameImagesByKey,
    required int sourceTileWidth,
    required int sourceTileHeight,
    required double displayScale,
    required int elapsedMs,
    BorderPreviewTransaction? preview,
  }) {
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0 || displayScale <= 0) {
      return;
    }
    final entries = buildEditorBorderPaintEntries(map: map, preview: preview);
    _paintEntries(
      canvas,
      entries: entries,
      catalog: catalog,
      frameImagesByKey: frameImagesByKey,
      sourceTileWidth: sourceTileWidth,
      sourceTileHeight: sourceTileHeight,
      displayScale: displayScale,
      elapsedMs: elapsedMs,
    );
  }

  void paintLayer(
    ui.Canvas canvas, {
    required MapData map,
    required BorderLayer layer,
    required ProjectBorderCatalog catalog,
    required Map<String, ui.Image?> frameImagesByKey,
    required int sourceTileWidth,
    required int sourceTileHeight,
    required double displayScale,
    required int elapsedMs,
    BorderPreviewTransaction? preview,
  }) {
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0 || displayScale <= 0) {
      return;
    }
    _paintEntries(
      canvas,
      entries: buildEditorBorderLayerPaintEntries(
        map: map,
        layer: layer,
        preview: preview,
      ),
      catalog: catalog,
      frameImagesByKey: frameImagesByKey,
      sourceTileWidth: sourceTileWidth,
      sourceTileHeight: sourceTileHeight,
      displayScale: displayScale,
      elapsedMs: elapsedMs,
    );
  }

  void _paintEntries(
    ui.Canvas canvas, {
    required List<EditorBorderPaintEntry> entries,
    required ProjectBorderCatalog catalog,
    required Map<String, ui.Image?> frameImagesByKey,
    required int sourceTileWidth,
    required int sourceTileHeight,
    required double displayScale,
    required int elapsedMs,
  }) {
    for (final entry in entries) {
      final snapshot = catalog.visualSnapshotById(entry.snapshotId);
      if (snapshot == null || snapshot.frames.isEmpty) continue;
      final frameIndex = _frameIndex(snapshot.frames, elapsedMs);
      final frame = snapshot.frames[frameIndex];
      final image =
          frameImagesByKey[editorBorderFrameImageKey(snapshot.id, frameIndex)];
      if (image == null || !_sourceRectFits(image, frame.sourceRectPx)) {
        continue;
      }
      final source = _rect(frame.sourceRectPx);
      final paint = ui.Paint()
        ..isAntiAlias = false
        ..filterQuality = ui.FilterQuality.none
        ..color = ui.Color.fromRGBO(255, 255, 255, entry.layerOpacity);
      switch (entry.kind) {
        case EditorBorderPaintEntryKind.ground:
          final ground = entry.ground!;
          canvas.drawImageRect(
            image,
            source,
            ui.Rect.fromLTWH(
              ground.x * sourceTileWidth * displayScale,
              ground.y * sourceTileHeight * displayScale,
              sourceTileWidth * displayScale,
              sourceTileHeight * displayScale,
            ),
            paint,
          );
        case EditorBorderPaintEntryKind.placement:
          _paintPlacement(
            canvas,
            image: image,
            source: source,
            placement: entry.placement!,
            displayScale: displayScale,
            paint: paint,
          );
      }
    }
  }
}

void _paintPlacement(
  ui.Canvas canvas, {
  required ui.Image image,
  required ui.Rect source,
  required BorderResolvedPlacement placement,
  required double displayScale,
  required ui.Paint paint,
}) {
  canvas.save();
  try {
    canvas.translate(
      placement.topLeftWorldPx.x * displayScale,
      placement.topLeftWorldPx.y * displayScale,
    );
    canvas.scale(displayScale);
    _applyPositiveBoundsClockwiseRotation(
      canvas,
      quarterTurns: placement.transform.quarterTurns,
      sourceWidth: source.width,
      sourceHeight: source.height,
    );
    if (placement.transform.flipX) {
      canvas.translate(source.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(
      image,
      source,
      ui.Rect.fromLTWH(0, 0, source.width, source.height),
      paint,
    );
  } finally {
    canvas.restore();
  }
}

void _applyPositiveBoundsClockwiseRotation(
  ui.Canvas canvas, {
  required int quarterTurns,
  required double sourceWidth,
  required double sourceHeight,
}) {
  switch (quarterTurns) {
    case 0:
      return;
    case 1:
      canvas.translate(sourceHeight, 0);
      canvas.rotate(math.pi / 2);
    case 2:
      canvas.translate(sourceWidth, sourceHeight);
      canvas.rotate(math.pi);
    case 3:
      canvas.translate(0, sourceWidth);
      canvas.rotate(3 * math.pi / 2);
  }
}

int _frameIndex(List<BorderVisualFrameSnapshot> frames, int elapsedMs) {
  var duration = 0;
  for (final frame in frames) {
    duration += frame.durationMs;
  }
  if (duration <= 0) return 0;
  final local = (elapsedMs < 0 ? 0 : elapsedMs) % duration;
  var boundary = 0;
  for (var index = 0; index < frames.length; index += 1) {
    boundary += frames[index].durationMs;
    if (local < boundary) return index;
  }
  return frames.length - 1;
}

bool _sourceRectFits(ui.Image image, BorderPixelRect source) =>
    source.x >= 0 &&
    source.y >= 0 &&
    source.right <= image.width &&
    source.bottom <= image.height;

ui.Rect _rect(BorderPixelRect value) => ui.Rect.fromLTWH(
      value.x.toDouble(),
      value.y.toDouble(),
      value.width.toDouble(),
      value.height.toDouble(),
    );
