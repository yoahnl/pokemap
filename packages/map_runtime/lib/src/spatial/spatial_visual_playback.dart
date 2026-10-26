import 'dart:async';

import 'package:map_core/map_core.dart';

final class SpatialVisualPlayback {
  SpatialVisualPlayback({required this.readBase, required this.publish});
  final SpatialVisualPatch Function() readBase;
  final void Function(SpatialVisualPatch) publish;
  SpatialVisualPatch _map = SpatialVisualPatch(), _scene = SpatialVisualPatch();
  Object? _sceneOwner;
  _VisualTransition? _transition;
  SpatialVisualPatch get current => _map.overriddenBy(_scene);

  Future<String> execute(
    SceneWorldPresentationInteractiveCommand command, {
    Object? owner,
  }) {
    if (command.operation != SceneWorldPresentationOperation.atmosphere &&
        command.operation != SceneWorldPresentationOperation.restoreAtmosphere)
      return Future.value('blocked');
    if (command.scope == SceneVisualScope.scene &&
        _sceneOwner != null &&
        !identical(owner, _sceneOwner))
      return Future.value('blocked');
    _cancelTransition();
    final before = readBase().overriddenBy(current);
    final restoring =
        command.operation == SceneWorldPresentationOperation.restoreAtmosphere;
    if (command.scope == SceneVisualScope.scene) {
      _sceneOwner = restoring ? null : owner;
      _scene = restoring
          ? SpatialVisualPatch()
          : _scene.overriddenBy(command.visualSettings!);
    } else {
      _map = restoring
          ? SpatialVisualPatch()
          : _map.overriddenBy(command.visualSettings!);
    }
    final after = readBase().overriddenBy(current);
    if (command.durationMs == 0) {
      publish(current);
      return Future.value('completed');
    }
    final keys = before.values.keys
        .where((key) => before.value(key) != after.value(key))
        .toSet();
    final transition = _transition = _VisualTransition(
      from: SpatialVisualPatch({
        for (final key in keys) key: before.value(key)!,
      }),
      to: SpatialVisualPatch({for (final key in keys) if (after.value(key) != null) key: after.value(key)!}),
      duration: command.durationMs / 1000,
      owner: owner,
      scope: command.scope,
    );
    publish(current.overriddenBy(transition.from));
    return command.waitForCompletion
        ? transition.completed.future
        : Future.value('completed');
  }

  void advance(double dt) {
    final transition = _transition;
    if (transition == null || !dt.isFinite || dt <= 0) return;
    transition.elapsed += dt;
    final progress = (transition.elapsed / transition.duration).clamp(0.0, 1.0);
    publish(
      current.overriddenBy(
        SpatialVisualPatch.interpolate(
          transition.from,
          transition.to,
          progress,
        ),
      ),
    );
    if (progress >= 1) {
      _transition = null;
      publish(current);
      transition.completed.complete('completed');
    }
  }

  void releaseScene(Object owner) {
    if (!identical(owner, _sceneOwner)) return;
    if (_transition?.scope == SceneVisualScope.scene) _cancelTransition();
    _sceneOwner = null;
    _scene = SpatialVisualPatch();
    publish(current);
  }

  void reset() {
    _cancelTransition();
    _sceneOwner = null;
    _map = _scene = SpatialVisualPatch();
    publish(current);
  }

  void _cancelTransition() {
    final transition = _transition;
    _transition = null;
    if (transition != null && !transition.completed.isCompleted)
      transition.completed.complete('cancelled');
  }
}

final class _VisualTransition {
  _VisualTransition({
    required this.from,
    required this.to,
    required this.duration,
    required this.owner,
    required this.scope,
  });
  final SpatialVisualPatch from, to;
  final double duration;
  final Object? owner;
  final SceneVisualScope scope;
  final completed = Completer<String>();
  double elapsed = 0;
}
