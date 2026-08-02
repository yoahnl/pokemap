import 'package:meta/meta.dart' show immutable;

import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/smart_tile.dart';
import 'smart_tile_layer_context.dart';
import 'smart_tile_resolver.dart';

enum SmartTileVisualPass { background, foreground }

@immutable
final class SmartTileLayerVisual {
  const SmartTileLayerVisual({
    required this.cellX,
    required this.cellY,
    required this.ruleId,
    required this.candidateId,
    required this.channel,
    required this.tilesetId,
    required this.sourceRect,
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
  final String tilesetId;
  final SmartTileSourceRect sourceRect;
  final SmartTileOffsetUnit offsetUnit;
  final int offsetX;
  final int offsetY;
  final int footprintWidth;
  final int footprintHeight;
  final int anchorX;
  final int anchorY;
  final int drawOrder;
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
}) {
  ProjectSmartTilePreset? preset;
  for (final candidate in catalog.presets) {
    if (candidate.id == layer.presetId) {
      preset = candidate;
      break;
    }
  }
  if (preset == null || preset.usage != layer.usage) {
    return const <SmartTileLayerVisual>[];
  }

  final atlases = <String, ProjectSmartTileAtlas>{
    for (final atlas in catalog.atlases) atlas.id: atlas,
  };
  final animations = <String, ProjectSmartTileAnimation>{
    for (final animation in catalog.animations) animation.id: animation,
  };
  final visuals = <SmartTileLayerVisual>[];
  final resolvedStartX = startX.clamp(0, map.size.width);
  final resolvedStartY = startY.clamp(0, map.size.height);
  final resolvedEndX = (endX ?? map.size.width).clamp(
    resolvedStartX,
    map.size.width,
  );
  final resolvedEndY = (endY ?? map.size.height).clamp(
    resolvedStartY,
    map.size.height,
  );
  for (var y = resolvedStartY; y < resolvedEndY; y++) {
    for (var x = resolvedStartX; x < resolvedEndX; x++) {
      final context = smartTileCellContextForLayerCell(
        layer: layer,
        map: map,
        preset: preset,
        x: x,
        y: y,
      );
      final resolution = resolveSmartTile(
        preset: preset,
        materials: catalog.materials,
        context: context,
        x: x,
        y: y,
        mapId: map.id,
        layerId: layer.id,
        projectSeed: projectSeed,
        layerSeed: layer.layerSeed,
      );
      final candidate = resolution.candidate;
      if (candidate == null || resolution.ruleId == null) continue;
      for (final part in candidate.parts) {
        if (!_channelBelongsToPass(part.channel, pass)) continue;
        final frame = _resolveVisualFrame(
          source: part.source,
          animations: animations,
          elapsedMs: elapsedMs,
          deterministicHash: resolution.deterministicHash ?? 0,
        );
        if (frame == null) continue;
        final atlas = atlases[frame.atlasId];
        if (atlas == null) continue;
        final sampledFrame = _sampleVisualFrame(
          frame: frame,
          sampling: part.frameSampling,
          cellX: x,
          cellY: y,
          deterministicHash: resolution.deterministicHash ?? 0,
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
          continue;
        }
        visuals.add(
          SmartTileLayerVisual(
            cellX: x,
            cellY: y,
            ruleId: resolution.ruleId!,
            candidateId: candidate.id,
            channel: part.channel,
            tilesetId: atlas.tilesetId,
            sourceRect: sourceRect,
            offsetUnit: part.offsetUnit,
            offsetX: part.offsetX + atlas.pixelOffsetX,
            offsetY: part.offsetY + atlas.pixelOffsetY,
            footprintWidth: part.footprintWidth,
            footprintHeight: part.footprintHeight,
            anchorX: part.anchorX,
            anchorY: part.anchorY,
            drawOrder: part.drawOrder,
          ),
        );
      }
    }
  }
  visuals.sort((a, b) {
    final order = a.drawOrder.compareTo(b.drawOrder);
    if (order != 0) return order;
    final y = a.cellY.compareTo(b.cellY);
    if (y != 0) return y;
    return a.cellX.compareTo(b.cellX);
  });
  return List<SmartTileLayerVisual>.unmodifiable(visuals);
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
