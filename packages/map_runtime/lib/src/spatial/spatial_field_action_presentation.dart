import 'dart:async';

import 'package:map_core/map_core.dart';

final class SpatialFieldActionPresentation {
  CharacterAnimationState? state;
  double elapsedSeconds = 0;
  double _durationSeconds = 0;
  Completer<bool>? _completion;

  bool get isActive => _completion != null;

  Future<bool> play(FieldAbility ability, {required int durationMs}) {
    final next = switch (ability) {
      FieldAbility.cut => CharacterAnimationState.cut,
      FieldAbility.rockSmash => CharacterAnimationState.rockSmash,
      _ => throw ArgumentError.value(ability, 'ability'),
    };
    if (durationMs <= 0) throw ArgumentError.value(durationMs, 'durationMs');
    if (isActive) return Future.value(false);
    state = next;
    elapsedSeconds = 0;
    _durationSeconds = durationMs / 1000;
    final completion = _completion = Completer<bool>();
    return completion.future;
  }

  void update(double dt, {bool paused = false}) {
    if (!isActive || paused || !dt.isFinite || dt <= 0) return;
    elapsedSeconds += dt;
    if (elapsedSeconds + 1e-9 >= _durationSeconds) _finish(true);
  }

  void cancel() => _finish(false);

  void _finish(bool completed) {
    final completion = _completion;
    _completion = null;
    state = null;
    if (completion != null && !completion.isCompleted)
      completion.complete(completed);
  }
}
