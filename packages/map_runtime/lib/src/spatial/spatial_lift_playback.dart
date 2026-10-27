import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

final class SpatialLiftPlayback {
  SpatialLiftPlayback({
    required this.readMap,
    required this.readWorld,
    required this.writeWorld,
  });
  final MapData Function() readMap;
  final SpatialWorldState Function() readWorld;
  final void Function(SpatialWorldState) writeWorld;
  SpatialLiftMotion? _motion;
  Completer<String>? _completion;
  String? _mapId;
  SpatialModelRuntimeState? _before;
  SpatialModelRuntimeState? _base;
  bool get isPlaying => _motion != null;

  SpatialModelRuntimeState? modelPose(String mapId, String instanceId) {
    final motion = _motion;
    if (motion == null ||
        mapId != _mapId ||
        instanceId != motion.definition.instanceId) {
      return null;
    }
    return _base!.copyWith(translationY: motion.offset);
  }

  double? heightAt(String mapId, double x, double z) {
    final map = readMap();
    if (map.id != mapId) return null;
    for (final lift in map.spatialScene!.lifts) {
      if (!lift.contains(x, z)) continue;
      final preview = modelPose(mapId, lift.instanceId);
      final offset =
          preview?.translationY ??
          readWorld().modelState(mapId, lift.instanceId)?.translationY ??
          0;
      if (!offset.isFinite || offset < 0 || offset > lift.travelHeight + 1e-6) {
        throw StateError('Invalid saved lift height.');
      }
      if (preview == null &&
          offset.abs() > 1e-6 &&
          (offset - lift.travelHeight).abs() > 1e-6) {
        throw StateError('A saved lift must be at one of its stops.');
      }
      return lift.lowerHeight + offset;
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
    final lift = map.spatialScene!.lifts
        .where((v) => v.id == command.platformId)
        .firstOrNull;
    if (lift == null) return Future.value('blocked');
    final instance = map.spatialScene!.instances.singleWhere(
      (v) => v.id == lift.instanceId,
    );
    _before = readWorld().modelState(map.id, instance.id);
    _base =
        _before ??
        SpatialModelRuntimeState(
          modelId: instance.modelId,
          animationIndex: null,
          normalizedTime: 0,
          blocksMovement: instance.blocksMovement,
        );
    if (_base!.modelId != instance.modelId) {
      throw StateError('The lift runtime model no longer matches its source.');
    }
    _motion = SpatialLiftMotion(
      definition: lift,
      sourceOffset: _base!.translationY,
      raised: command.motion == MovingPlatformMotion.forward,
    );
    _mapId = map.id;
    _completion = Completer<String>();
    return _completion!.future;
  }

  void update(double seconds, {required bool paused}) {
    final motion = _motion;
    if (motion == null) return;
    motion.advance(seconds, paused: paused);
    if (!motion.complete) return;
    final completion = _completion!;
    try {
      if (readMap().id != _mapId ||
          readWorld().modelState(_mapId!, motion.definition.instanceId) !=
              _before) {
        throw StateError('The lift state changed during playback.');
      }
      writeWorld(
        readWorld().setModelState(
          _mapId!,
          motion.definition.instanceId,
          _base!.copyWith(translationY: motion.targetOffset),
        ),
      );
      _clear();
      completion.complete('moved');
    } catch (error, stack) {
      _clear();
      completion.completeError(error, stack);
    }
  }

  void cancel() {
    final completion = _completion;
    _motion?.cancel();
    _clear();
    if (completion != null && !completion.isCompleted) {
      completion.complete('blocked');
    }
  }

  void _clear() {
    _motion = null;
    _completion = null;
    _mapId = null;
    _base = null;
    _before = null;
  }
}
