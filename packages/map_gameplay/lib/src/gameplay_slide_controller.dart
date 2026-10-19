import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'gameplay_intent.dart';
import 'gameplay_movement_effect.dart';
import 'gameplay_step_result.dart';
import 'gameplay_world_state.dart';

final class GameplaySlideController {
  Direction? _direction;
  String? _mapId;
  PixelPosition? _position;
  int _remainingPixels = 0;

  Direction? get direction => _direction;
  bool get isSliding => _direction != null;

  MoveIntent? nextIntent({
    required GameplayWorldState world,
    required int pixelsPerStep,
  }) {
    final direction = _direction;
    if (direction == null) return null;
    final tileExtent =
        direction.dx == 0 ? world.tileHeightPx : world.tileWidthPx;
    if (pixelsPerStep < 1 || pixelsPerStep > tileExtent) {
      throw ArgumentError.value(pixelsPerStep, 'pixelsPerStep');
    }
    if (!_matches(world) || _remainingPixels < pixelsPerStep) {
      reset();
      return null;
    }
    return MoveIntent(direction, pixelsPerStep: pixelsPerStep);
  }

  void recordStep({
    required GameplayWorldState previousWorld,
    required MoveIntent intent,
    required GameplayStepResult result,
  }) {
    final continuing = isSliding;
    if (continuing &&
        (!_matches(previousWorld) || _direction != intent.direction)) {
      reset();
      return;
    }
    if (result is! Moved ||
        result.platformControl != null ||
        result.movementEffect?.kind != GameplayMovementEffectKind.slide ||
        result.movementEffect?.direction != intent.direction ||
        result.world.map.id != previousWorld.map.id ||
        result.world.map.spatialScene != null ||
        result.world.map.version == ProjectVersion.v9) {
      reset();
      return;
    }
    final from = previousWorld.player.playerPositionPx;
    final to = result.world.player.playerPositionPx;
    final dx = to.leftPx - from.leftPx;
    final dy = to.topPx - from.topPx;
    final direction = intent.direction;
    final distance = dx * direction.dx + dy * direction.dy;
    if (distance <= 0 ||
        distance > intent.pixelsPerStep ||
        dx * direction.dy != 0 ||
        dy * direction.dx != 0) {
      reset();
      return;
    }
    final extent = direction.dx == 0
        ? (result.world.map.size.height + 1) * result.world.tileHeightPx
        : (result.world.map.size.width + 1) * result.world.tileWidthPx;
    _remainingPixels = (continuing ? _remainingPixels : extent) - distance;
    if (_remainingPixels <= 0) {
      reset();
      return;
    }
    _direction = direction;
    _mapId = result.world.map.id;
    _position = to;
  }

  void reset() {
    _direction = null;
    _mapId = null;
    _position = null;
    _remainingPixels = 0;
  }

  bool _matches(GameplayWorldState world) =>
      world.map.id == _mapId &&
      world.map.spatialScene == null &&
      world.map.version != ProjectVersion.v9 &&
      world.player.playerPositionPx.leftPx == _position?.leftPx &&
      world.player.playerPositionPx.topPx == _position?.topPx;
}
