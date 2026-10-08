import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

final class SpatialEntityVisualPlan {
  factory SpatialEntityVisualPlan(MapData map, ProjectManifest project) {
    final scene = map.spatialScene;
    if (scene == null ||
        scene.width != map.size.width ||
        scene.depth != map.size.height ||
        project.settings.dimension != ProjectDimension.threeD) {
      throw StateError('Entity visuals require a native 3D map.');
    }
    final tileWidth = project.settings.tileWidth;
    final tileHeight = project.settings.tileHeight;
    if (tileWidth <= 0 || tileHeight <= 0) {
      throw StateError('Entity visual texture cells must have positive sizes.');
    }
    final elements = {
      for (final element in project.elements) element.id: element
    };
    final entries = <_SpatialEntityVisualEntry>[];
    for (final entity in map.entities) {
      if (entity.kind == MapEntityKind.npc &&
          (entity.npc?.characterId?.trim().isNotEmpty ?? false)) {
        continue;
      }
      final id = entity.canonicalEditorVisualProjectElementId;
      if (id == null) continue;
      final element = elements[id];
      if (element == null || element.frames.isEmpty) {
        throw StateError('Entity visual element "$id" is unavailable.');
      }
      if (entity.size.width <= 0 || entity.size.height <= 0) {
        throw StateError('Entity visual "${entity.id}" has an invalid size.');
      }
      final frames = <_SpatialEntityVisualFrame>[];
      for (final frame in element.frames) {
        final imageId = frame.tilesetId.trim().isEmpty
            ? element.tilesetId.trim()
            : frame.tilesetId.trim();
        final source = frame.source;
        if (imageId.isEmpty ||
            source.x < 0 ||
            source.y < 0 ||
            source.width <= 0 ||
            source.height <= 0) {
          throw StateError(
              'Entity visual "${entity.id}" has an invalid frame.');
        }
        frames.add(_SpatialEntityVisualFrame(
          imageId,
          ui.Rect.fromLTWH(
            (source.x * tileWidth).toDouble(),
            (source.y * tileHeight).toDouble(),
            (source.width * tileWidth).toDouble(),
            (source.height * tileHeight).toDouble(),
          ),
          frame.durationMs == null || frame.durationMs! <= 0
              ? 200
              : frame.durationMs!,
        ));
      }
      entries.add(_SpatialEntityVisualEntry(entity, List.unmodifiable(frames)));
    }
    return SpatialEntityVisualPlan._(
      map,
      List.unmodifiable(entries),
      Map.unmodifiable({
        for (final tileset in project.tilesets)
          if (tileset.transparentColor case final color?) tileset.id: color,
      }),
    );
  }

  SpatialEntityVisualPlan._(this.map, this._entries, this._transparentColors)
      : imageIds = Set.unmodifiable({
          for (final entry in _entries)
            for (final frame in entry.frames) frame.imageId,
        });

  final MapData map;
  final List<_SpatialEntityVisualEntry> _entries;
  final Map<String, TilesetTransparentColor> _transparentColors;
  final Set<String> imageIds;

  Future<SpatialActorTexture> createTexture(String imageId, ui.Image image) =>
      SpatialActorTexture.fromImage(
        image,
        transparentColor: _transparentColors[imageId],
      );

  void validateImages(Map<String, ui.Image> images) {
    for (final entry in _entries) {
      for (final frame in entry.frames) {
        final image = images[frame.imageId];
        if (image == null ||
            frame.rect.right > image.width ||
            frame.rect.bottom > image.height) {
          throw StateError(
              'Entity visual "${entry.entity.id}" exceeds texture "${frame.imageId}".');
        }
      }
    }
  }

  Map<String, SpatialActorVisual> frames({
    required Map<String, SpatialActorTexture> textures,
    required int elapsedMs,
    bool Function(MapEntity entity)? isPresent,
  }) {
    if (elapsedMs < 0) {
      throw ArgumentError.value(elapsedMs, 'elapsedMs');
    }
    final result = <String, SpatialActorVisual>{};
    for (final entry in _entries) {
      final entity = entry.entity;
      if (!(isPresent?.call(entity) ?? true)) continue;
      final frame = entry.frameAt(elapsedMs);
      final texture = textures[frame.imageId];
      if (texture == null) {
        throw StateError(
            'Entity visual texture "${frame.imageId}" is unavailable.');
      }
      final boundsWidth = entity.size.width.toDouble();
      final boundsHeight = entity.size.height.toDouble();
      final aspect = frame.rect.width / frame.rect.height;
      final width = aspect > boundsWidth / boundsHeight
          ? boundsWidth
          : boundsHeight * aspect;
      final height = aspect > boundsWidth / boundsHeight
          ? boundsWidth / aspect
          : boundsHeight;
      final x = entity.pos.x + boundsWidth / 2;
      final z = entity.pos.y + boundsHeight / 2;
      result['entity:${entity.id}'] = SpatialActorVisual(
        x: x,
        y: map.spatialScene!.worldHeightAt(x, z),
        z: z,
        texture: texture,
        frame: frame.rect,
        width: width,
        height: height,
      );
    }
    return result;
  }
}

final class _SpatialEntityVisualEntry {
  _SpatialEntityVisualEntry(this.entity, this.frames)
      : totalDurationMs =
            frames.fold(0, (sum, frame) => sum + frame.durationMs);

  final MapEntity entity;
  final List<_SpatialEntityVisualFrame> frames;
  final int totalDurationMs;

  _SpatialEntityVisualFrame frameAt(int elapsedMs) {
    var remaining = elapsedMs % totalDurationMs;
    for (final frame in frames) {
      if (remaining < frame.durationMs) return frame;
      remaining -= frame.durationMs;
    }
    return frames.last;
  }
}

final class _SpatialEntityVisualFrame {
  const _SpatialEntityVisualFrame(this.imageId, this.rect, this.durationMs);

  final String imageId;
  final ui.Rect rect;
  final int durationMs;
}
