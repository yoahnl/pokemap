import 'dart:async';

import 'package:map_core/map_core.dart';

final class SpatialModelAnimationController {
  SpatialModelAnimationController({
    required this.mapId,
    required this.instances,
    required this.models,
    required SpatialWorldState state,
    required this.canClose,
    required this.commit,
  }) : _state = state;

  final String Function() mapId;
  final Iterable<SpatialModelInstance> Function() instances;
  final Iterable<ProjectModel3dEntry> Function() models;
  final bool Function(SpatialModelInstance) canClose;
  final void Function(SpatialWorldState) commit;
  SpatialWorldState _state;
  _ModelAnimationOperation? _operation;
  bool _disposed = false;

  SpatialWorldState get worldState => _state;
  bool get isPlaying => _operation != null;

  void synchronize(SpatialWorldState state) {
    if (_operation != null) {
      throw StateError('Cannot replace the world during a model animation.');
    }
    _state = state;
  }

  Future<String> play(ScenePlayModelAnimationInteractiveCommand command) {
    if (_disposed || isPlaying || command.mapId != mapId()) {
      return Future.value('blocked');
    }
    final targets =
        instances().where((value) => value.id == command.instanceId);
    if (targets.length != 1) return Future.value('blocked');
    final instance = targets.single;
    final resources = models().where((value) => value.id == instance.modelId);
    if (resources.length != 1) return Future.value('blocked');
    final animations = resources.single.inspection.animations
        .where((value) => value.index == command.animationIndex);
    if (animations.length != 1 ||
        (command.blocksMovementAfter == true && !canClose(instance))) {
      return Future.value('blocked');
    }
    final previous = _state.modelState(command.mapId, command.instanceId);
    final pose = SpatialModelRuntimeState(
      modelId: instance.modelId,
      animationIndex: command.animationIndex,
      normalizedTime: 0,
      blocksMovement: previous?.blocksMovement ?? instance.blocksMovement,
    );
    final operation = _ModelAnimationOperation(
      command: command,
      instance: instance,
      before: _state,
      duration: animations.single.durationSeconds / command.speed,
    );
    _operation = operation;
    _state = _state.setModelState(command.mapId, command.instanceId, pose);
    return operation.completion.future;
  }

  void update(double dt, {bool paused = false}) {
    final operation = _operation;
    if (operation == null || paused || !dt.isFinite || dt <= 0) return;
    if (_disposed || operation.command.mapId != mapId()) {
      cancel();
      return;
    }
    operation.elapsed += dt;
    final progress = (operation.elapsed / operation.duration).clamp(0.0, 1.0);
    final command = operation.command;
    final pose = _state.modelState(command.mapId, command.instanceId)!;
    _state = _state.setModelState(command.mapId, command.instanceId,
        pose.copyWith(normalizedTime: progress));
    if (progress < 1) return;
    if (command.blocksMovementAfter == true && !canClose(operation.instance)) {
      _finish('blocked', restore: true);
      return;
    }
    _state = _state.setModelState(
        command.mapId,
        command.instanceId,
        pose.copyWith(
            normalizedTime: 1, blocksMovement: command.blocksMovementAfter));
    try {
      commit(_state);
      _finish('completed');
    } catch (error, stack) {
      _state = operation.before;
      _operation = null;
      operation.completion.completeError(error, stack);
    }
  }

  void cancel() => _finish('cancelled', restore: true);

  void _finish(String result, {bool restore = false}) {
    final operation = _operation;
    if (operation == null) return;
    if (restore) _state = operation.before;
    _operation = null;
    operation.completion.complete(result);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    cancel();
  }
}

final class _ModelAnimationOperation {
  _ModelAnimationOperation({
    required this.command,
    required this.instance,
    required this.before,
    required this.duration,
  });
  final ScenePlayModelAnimationInteractiveCommand command;
  final SpatialModelInstance instance;
  final SpatialWorldState before;
  final double duration;
  final completion = Completer<String>();
  double elapsed = 0;
}
