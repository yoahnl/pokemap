import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:map_core/map_core.dart';

import 'battle_live_attachment.dart';
import 'battle_particle_timeline.dart';

final class BattleParticleSyntheticComponent extends PositionComponent
    implements BattleLiveAttachment {
  BattleParticleSyntheticComponent({
    required BattleParticleDefinition definition,
    required Map<String, ui.Image> textures,
    required List<ui.Offset> centers,
    List<BattleLivePointResolver>? centerResolvers,
    required int maxTextures,
    required int maxDimension,
    required int maxTotalPixels,
    this.onComplete,
    this.onInvalidated,
  }) : _timeline = BattleParticleTimeline.fromDefinition(definition),
       _centers = [for (final center in centers) Vector2(center.dx, center.dy)],
       _centerResolvers = centerResolvers == null
           ? null
           : List.unmodifiable(centerResolvers) {
    final requiredIds = definition.emitters
        .map((value) => value.textureId)
        .toSet();
    if (maxTextures < 1 ||
        maxDimension < 1 ||
        maxTotalPixels < 1 ||
        requiredIds.length > maxTextures ||
        centers.length != definition.emitters.length ||
        centers.any((center) => !center.dx.isFinite || !center.dy.isFinite) ||
        (centerResolvers != null &&
            (centerResolvers.length != definition.emitters.length ||
                onInvalidated == null)) ||
        textures.length != requiredIds.length ||
        !requiredIds.containsAll(textures.keys)) {
      throw const FormatException('Invalid synthetic particle resources');
    }
    var totalPixels = 0;
    for (final image in textures.values) {
      if (image.width < 1 ||
          image.height < 1 ||
          image.width > maxDimension ||
          image.height > maxDimension) {
        throw const FormatException(
          'Synthetic particle texture exceeds dimensions',
        );
      }
      totalPixels += image.width * image.height;
      if (totalPixels > maxTotalPixels) {
        throw const FormatException(
          'Synthetic particle textures exceed pixel budget',
        );
      }
    }
    try {
      for (final entry in textures.entries) {
        _textures[entry.key] = entry.value.clone();
      }
    } catch (_) {
      for (final image in _textures.values) {
        image.dispose();
      }
      _textures.clear();
      rethrow;
    }
  }

  final BattleParticleTimeline _timeline;
  final List<Vector2> _centers;
  final List<BattleLivePointResolver>? _centerResolvers;
  final Map<String, ui.Image> _textures = {};
  final Map<(int, int), BattleParticleEvent> _activeBatches = {};
  final ui.Paint _paint = ui.Paint()..filterQuality = ui.FilterQuality.none;
  final void Function()? onComplete;
  final void Function()? onInvalidated;
  double _fractionalMicros = 0;
  bool _disposed = false;
  bool _completionNotified = false;

  bool get hasPendingEvents => _timeline.hasPendingEvents;
  bool get isComplete => _timeline.isComplete;
  int get activeParticles => _timeline.activeParticles;

  @override
  bool refreshAttachment() {
    if (_disposed || _timeline.isCancelled || _timeline.isComplete) {
      return false;
    }
    final resolvers = _centerResolvers;
    if (resolvers == null) return true;
    for (var index = 0; index < resolvers.length; index++) {
      if (!refreshBattleLivePoint(resolvers[index], _centers[index])) {
        dispose();
        try {
          onInvalidated!();
        } finally {
          removeBattleLiveAttachment(this);
        }
        return false;
      }
    }
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_disposed ||
        _timeline.isCancelled ||
        _timeline.isComplete ||
        !dt.isFinite ||
        dt < 0) {
      return;
    }
    if (!refreshAttachment()) return;
    final micros = math.min(dt, 120.0) * 1000000 + _fractionalMicros;
    final wholeMicros = micros.floor();
    _fractionalMicros = micros - wholeMicros;
    for (final event in _timeline.advance(
      Duration(microseconds: wholeMicros),
    )) {
      final key = (event.emitterIndex, event.batchIndex);
      if (event.kind == BattleParticleEventKind.emission) {
        _activeBatches[key] = event;
      } else {
        _activeBatches.remove(key);
      }
    }
    if (_timeline.isComplete && !_completionNotified) {
      _completionNotified = true;
      onComplete?.call();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (_disposed || _timeline.isCancelled) return;
    for (final event in _activeBatches.values) {
      final image = _textures[event.textureId]!;
      final center = _centers[event.emitterIndex];
      final offset = ui.Offset(
        center.x - image.width / 2,
        center.y - image.height / 2,
      );
      for (var index = 0; index < event.count; index++) {
        canvas.drawImage(image, offset, _paint);
      }
    }
  }

  void cancel() {
    if (_disposed || _timeline.isCancelled) return;
    if (!_timeline.isComplete) {
      _timeline.cancel();
    }
    _activeBatches.clear();
  }

  void dispose() {
    if (_disposed) return;
    cancel();
    _disposed = true;
    for (final image in _textures.values) {
      image.dispose();
    }
    _textures.clear();
  }

  @override
  void onRemove() {
    dispose();
    super.onRemove();
  }
}
