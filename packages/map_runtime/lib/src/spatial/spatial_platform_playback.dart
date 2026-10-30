import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

final class SpatialPlatformPlayback {
  SpatialPlatformPlayback({
    required this.readMap,
    required this.readState,
    required this.writeState,
    required this.readFact,
    required this.canOccupy,
    this.onStart,
    this.onPreview,
    this.onFinished,
  });
  final MapData Function() readMap;
  final GameState Function() readState;
  final void Function(GameState) writeState;
  final bool Function(String factId) readFact;
  final bool Function(
    SpatialPlatformDefinition platform,
    double offsetX,
    double offsetZ,
  )
  canOccupy;
  final void Function(
    SpatialPlatformDefinition definition,
    SpatialPlatformStop offset,
  )?
  onStart;
  final void Function(
    double deltaX,
    double deltaZ,
    SpatialPlatformDefinition definition,
  )?
  onPreview;
  final void Function(bool moved)? onFinished;
  SpatialPlatformMotion? _motion;
  Completer<String>? _completion;
  String? _mapId;
  GameState? _before;
  SpatialModelRuntimeState? _base, _saved;
  PlayerSpatialPosition? _player;
  bool get isPlaying => _motion != null;
  PlayerSpatialPosition? get playerPosition {
    final motion = _motion;
    if (motion == null) return null;
    return PlayerSpatialPosition(
      x: _player!.x + motion.offset.x - motion.sourceOffset.x,
      z: _player!.z + motion.offset.z - motion.sourceOffset.z,
    );
  }

  SpatialModelRuntimeState? modelPose(String mapId, String instanceId) {
    final motion = _motion;
    if (motion != null &&
        mapId == _mapId &&
        instanceId == motion.definition.instanceId) {
      return _base!.copyWith(
        translationX: motion.offset.x,
        translationZ: motion.offset.z,
        blocksMovement: false,
      );
    }
    final map = readMap();
    if (mapId != map.id ||
        !map.spatialScene!.platforms.any(
          (value) => value.instanceId == instanceId,
        )) {
      return null;
    }
    final instance = map.spatialScene!.instances.singleWhere(
      (value) => value.id == instanceId,
    );
    return (readState().spatialWorldState.modelState(mapId, instanceId) ??
            SpatialModelRuntimeState(
              modelId: instance.modelId,
              animationIndex: null,
              normalizedTime: 0,
              blocksMovement: false,
            ))
        .copyWith(blocksMovement: false);
  }

  SpatialPlatformStop _savedOffset(SpatialPlatformDefinition platform) {
    final state = readState().spatialWorldState.modelState(
      readMap().id,
      platform.instanceId,
    );
    final offset = SpatialPlatformStop(
      x: state?.translationX ?? 0,
      z: state?.translationZ ?? 0,
    );
    if (!platform.routes.any(
      (route) => [route.waypoints.first, route.waypoints.last].any(
        (point) =>
            (point.x - offset.x).abs() < 1e-6 &&
            (point.z - offset.z).abs() < 1e-6,
      ),
    )) {
      throw StateError('The saved platform is not at a dock.');
    }
    return offset;
  }

  double? heightAt(String mapId, double x, double z) {
    final map = readMap();
    if (map.id != mapId) return null;
    for (final platform in map.spatialScene!.platforms) {
      final offset = _motion?.definition.id == platform.id
          ? _motion!.offset
          : _savedOffset(platform);
      if (platform.contains(x, z, offsetX: offset.x, offsetZ: offset.z)) {
        return platform.height;
      }
    }
    return null;
  }

  Future<String> play(SceneInteractiveCommand command) {
    if (command is! SceneMovePlatformInteractiveCommand ||
        isPlaying ||
        command.mapId != readMap().id ||
        command.motion == MovingPlatformMotion.rotateClockwise) {
      return Future.value('blocked');
    }
    final map = readMap();
    final platform = map.spatialScene!.platforms
        .where((value) => value.id == command.platformId)
        .firstOrNull;
    if (platform == null) return Future.value('blocked');
    final state = readState();
    if (state.currentMapId != map.id) return Future.value('blocked');
    final player =
        state.playerSpatialPosition ??
        PlayerSpatialPosition(
          x: state.playerPosition.x + .5,
          z: state.playerPosition.y + .5,
        );
    final offset = _savedOffset(platform);
    if (!platform.contains(
      player.x,
      player.z,
      offsetX: offset.x,
      offsetZ: offset.z,
      margin: .2,
    )) {
      return Future.value('notRiding');
    }
    final selected = platform.selectRoute(readFact);
    SpatialPlatformMotion motion;
    try {
      motion = SpatialPlatformMotion(
        definition: platform,
        route: selected,
        sourceOffset: offset,
        motion: command.motion,
      );
    } on FormatException {
      return Future.value('blocked');
    }
    final instance = map.spatialScene!.instances.singleWhere(
      (value) => value.id == platform.instanceId,
    );
    _saved = state.spatialWorldState.modelState(map.id, instance.id);
    _base =
        _saved ??
        SpatialModelRuntimeState(
          modelId: instance.modelId,
          animationIndex: null,
          normalizedTime: 0,
          blocksMovement: false,
        );
    if (_base!.modelId != instance.modelId || _base!.translationY != 0) {
      return Future.value('blocked');
    }
    _before = state;
    _mapId = map.id;
    _player = player;
    _motion = motion;
    _completion = Completer<String>();
    try {
      onStart?.call(platform, offset);
      onPreview?.call(0, 0, platform);
    } catch (error, stack) {
      final completion = _completion!;
      onFinished?.call(false);
      _clear();
      completion.completeError(error, stack);
      return completion.future;
    }
    return _completion!.future;
  }

  bool _clearAt(double offsetX, double offsetZ) {
    final platform = _motion!.definition;
    for (final other in readMap().spatialScene!.platforms.where(
      (value) => value.id != platform.id,
    )) {
      final pose = _savedOffset(other);
      if ((other.height - platform.height).abs() < .5 &&
          platform.x + offsetX < other.x + pose.x + other.width &&
          other.x + pose.x < platform.x + offsetX + platform.width &&
          platform.z + offsetZ < other.z + pose.z + other.depth &&
          other.z + pose.z < platform.z + offsetZ + platform.depth) {
        return false;
      }
    }
    return canOccupy(platform, offsetX, offsetZ);
  }

  void update(double seconds, {required bool paused}) {
    final motion = _motion;
    if (motion == null) return;
    final completion = _completion!;
    try {
      motion.advance(seconds, paused: paused, canOccupy: _clearAt);
      if (!paused) {
        onPreview?.call(
          motion.offset.x - motion.sourceOffset.x,
          motion.offset.z - motion.sourceOffset.z,
          motion.definition,
        );
      }
      if (!motion.complete) return;
      final moved = motion.outcome == 'moved';
      if (moved) {
        final current = readState();
        if (readMap().id != _mapId ||
            current.currentMapId != _mapId ||
            current.playerSpatialPosition != _before!.playerSpatialPosition ||
            current.playerPosition != _before!.playerPosition ||
            current.spatialWorldState.modelState(
                  _mapId!,
                  motion.definition.instanceId,
                ) !=
                _saved) {
          throw StateError(
            'The platform occupants or source pose changed during transport.',
          );
        }
        final player = playerPosition!;
        final world = current.spatialWorldState.setModelState(
          _mapId!,
          motion.definition.instanceId,
          _base!.copyWith(
            translationX: motion.targetOffset.x,
            translationZ: motion.targetOffset.z,
            blocksMovement: false,
          ),
        );
        writeState(
          current.copyWith(
            spatialWorldState: world,
            playerSpatialPosition: player,
            playerPosition: GridPos(x: player.x.floor(), y: player.z.floor()),
          ),
        );
      }
      onFinished?.call(moved);
      _clear();
      completion.complete(motion.outcome);
    } catch (error, stack) {
      onFinished?.call(false);
      _clear();
      completion.completeError(error, stack);
    }
  }

  void cancel() {
    final completion = _completion;
    if (_motion != null) {
      _motion!.cancel();
      onFinished?.call(false);
    }
    _clear();
    if (completion != null && !completion.isCompleted) {
      completion.complete('blocked');
    }
  }

  void _clear() {
    _motion = null;
    _completion = null;
    _mapId = null;
    _before = null;
    _base = null;
    _saved = null;
    _player = null;
  }
}
