import 'dart:ui';

import 'package:map_core/map_core.dart';

import '../../application/runtime_map_bundle.dart';
import '../../infrastructure/runtime_tileset_image.dart';
import '../../player/runtime_world_service_models.dart';

final class RuntimeHealingDisplayRenderer {
  RuntimeHealingDisplayRenderer({required this.bundle, required this.images});

  final RuntimeMapBundle bundle;
  final Map<String, RuntimeTilesetImage> images;
  final _validationByEntityId = <String, bool>{};
  final _frames = <(String, int), (String, ProjectTilesetVisualResolution)>{};
  RuntimeHealingDisplaySnapshot? _active;
  var _startedAtMs = 0;

  void render(
    Canvas canvas, {
    required RuntimeHealingDisplaySnapshot? snapshot,
    required int elapsedMs,
    Rect? visibleRect,
    bool Function(String mapId, MapEntity entity)? entityPresence,
  }) {
    if (snapshot == null || snapshot.mapId != bundle.map.id) {
      _active = null;
      return;
    }
    final entity = resolveHealingDisplayEntity(bundle.map, snapshot.entityId);
    if (entity == null ||
        (entityPresence != null && !entityPresence(bundle.map.id, entity))) {
      _active = null;
      return;
    }
    final valid = _validationByEntityId.putIfAbsent(entity.id, () {
      try {
        assertHealingDisplayVisualsAgainstProject(entity, bundle.manifest);
        return true;
      } on ValidationException {
        return false;
      }
    });
    if (!valid) {
      return;
    }
    if (!identical(snapshot, _active)) {
      _active = snapshot;
      _startedAtMs = elapsedMs;
    }
    final elementId = entity.healingDisplay!.elementIdForMemberCount(
      snapshot.memberCount,
    )!;
    final element = bundle.manifest.elements.singleWhere(
      (element) => element.id == elementId,
    );
    final sinceStart = elapsedMs < _startedAtMs ? 0 : elapsedMs - _startedAtMs;
    final timeline = resolveTileVisualFrameTimeline(
      frames: element.frames,
      elapsedMs: sinceStart.toDouble(),
      mode: TileVisualFrameTimelinePlaybackMode.loop,
    );
    final prepared = _frames.putIfAbsent((elementId, timeline.frameIndex), () {
      final frame = timeline.frame!;
      final tilesetId = frame.tilesetId.isEmpty
          ? element.tilesetId
          : frame.tilesetId;
      final source =
          bundle.manifest.tilesets
                  .singleWhere((tileset) => tileset.id == tilesetId)
                  .source!
              as ProjectRegularAtlasTilesetSource;
      final resolution = const ProjectTilesetVisualResolver().resolve(
        source: source,
        selection: ProjectTilesetVisualSelection.regularAtlas(
          source: frame.source,
        ),
        cellWidth: source.tileWidth,
        cellHeight: source.tileHeight,
      );
      return (tilesetId, resolution);
    });
    final frame = prepared.$2.frameAt(sinceStart);
    final settings = bundle.manifest.settings;
    if (settings.tileWidth <= 0 || settings.tileHeight <= 0) {
      return;
    }
    final scaleX = bundle.cellWidth / settings.tileWidth;
    final scaleY = bundle.cellHeight / settings.tileHeight;
    final bounds = frame.bounds;
    final destination = Rect.fromLTWH(
      entity.pos.x * bundle.cellWidth +
          (bundle.cellWidth - bounds.width * scaleX) / 2,
      (entity.pos.y + 1) * bundle.cellHeight - bounds.height * scaleY,
      bounds.width * scaleX,
      bounds.height * scaleY,
    );
    if (visibleRect != null && !destination.overlaps(visibleRect)) {
      return;
    }
    final draws = <(RuntimeTilesetImage, Rect, Rect)>[];
    for (final slice in frame.slices) {
      final image = images[slice.assetId] ?? images[prepared.$1];
      final source = Rect.fromLTWH(
        slice.sourceRect.x.toDouble(),
        slice.sourceRect.y.toDouble(),
        slice.sourceRect.width.toDouble(),
        slice.sourceRect.height.toDouble(),
      );
      if (image == null ||
          image.isDisposed ||
          !image.containsSourceRect(source)) {
        return;
      }
      final target = Rect.fromLTWH(
        destination.left + (slice.destinationRect.x - bounds.x) * scaleX,
        destination.top + (slice.destinationRect.y - bounds.y) * scaleY,
        slice.destinationRect.width * scaleX,
        slice.destinationRect.height * scaleY,
      );
      draws.add((image, source, target));
    }
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    for (final (image, source, target) in draws) {
      image.drawImageRect(canvas, source, target, paint);
    }
  }
}
