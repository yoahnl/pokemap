import 'package:flame/components.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../presentation/flame/cinematic_emote_sprite_cache.dart';

final class SpatialCinematicEmoteVisuals {
  SpatialCinematicEmoteVisuals(this.resourceBudget)
    : _cache = CinematicEmoteSpriteCache(resourceBudget: resourceBudget);

  final RuntimeResourceBudget resourceBudget;
  final CinematicEmoteSpriteCache _cache;
  final _textures = <String, Future<SpatialActorTexture>>{};
  final _reservations = <RuntimeResourceReservation>[];
  final _frames = <String, (SpatialActorTexture, List<Sprite>)>{};
  bool _disposed = false;

  Future<void> prepare(Iterable<CinematicAsset> cinematics) async {
    final ids = {
      for (final cinematic in cinematics)
        for (final step in cinematic.timeline.steps)
          if (step.kind == CinematicTimelineStepKind.actorEmote)
            cinematicTimelineActorEmoteEmoteIdOf(step),
    };
    for (final id in ids) {
      if (_frames.containsKey(id)) continue;
      final entry = cinematicEmoteCatalogEntryById(id);
      if (entry == null) throw StateError('Spatial emote "$id" is unknown.');
      final frames = await _cache.loadEmoteFrames(id);
      if (_disposed) throw StateError('Spatial emote cache is disposed.');
      if (frames.isEmpty) {
        throw StateError('Spatial emote "$id" has no frames.');
      }
      final texture = await _textures.putIfAbsent(entry.atlasId, () async {
        final image = frames.first.image;
        final lease = await resourceBudget.acquire(
          residentBytes: runtimeImageRgbaByteLength(
            image.width,
            image.height,
            maximumBytes: resourceBudget.profile.maximumResidentBytes,
          ),
          isCurrent: () => !_disposed,
        );
        try {
          final texture = await SpatialActorTexture.fromImage(image);
          lease.ensureCurrent();
          lease.commit();
          _reservations.add(lease);
          return texture;
        } on Object {
          lease.release();
          rethrow;
        }
      });
      if (_disposed) throw StateError('Spatial emote cache is disposed.');
      _frames[entry.id] = (texture, frames);
    }
  }

  SpatialActorVisual frame({
    required SpatialActorVisual actor,
    required String emoteId,
    required double elapsedSeconds,
  }) {
    final prepared = _frames[emoteId];
    if (prepared == null) {
      throw StateError('Spatial emote "$emoteId" was not prepared.');
    }
    final index =
        ((elapsedSeconds / .28).floor().clamp(0, 0x7fffffff)) %
        prepared.$2.length;
    final sprite = prepared.$2[index];
    final height = actor.height * .6;
    return SpatialActorVisual(
      x: actor.x,
      z: actor.z,
      y: actor.y,
      billboardVerticalOffset: actor.height + .15,
      texture: prepared.$1,
      frame: sprite.src,
      height: height,
      width: height * sprite.srcSize.x / sprite.srcSize.y,
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _frames.clear();
    _textures.clear();
    for (final lease in _reservations) {
      lease.release();
    }
    _reservations.clear();
    _cache.dispose();
  }
}
