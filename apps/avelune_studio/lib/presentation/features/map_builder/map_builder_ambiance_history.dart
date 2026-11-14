part of 'map_builder_ambiance_binding.dart';

extension MapAmbianceHistory on MapBuilderAmbianceBinding {
  bool get canUndo =>
      _canUndo(_AmbianceSide.visuals) ||
      _canUndo(_AmbianceSide.atmosphere) ||
      (_trail?.done.any((step) => _matches(step, undo: true)) ?? false);

  bool get canRedo =>
      _trail?.undone.any((step) => _matches(step, undo: false)) ?? false;

  void undo() {
    final trail = _trail;
    while (trail != null && trail.done.isNotEmpty) {
      final step = trail.done.removeLast();
      if (!_matches(step, undo: true)) continue;
      _apply(step.side, undo: true);
      trail.undone.add(_reissue(step, undo: true));
      return;
    }
    for (final side in const [
      _AmbianceSide.visuals,
      _AmbianceSide.atmosphere,
    ].where(_canUndo)) {
      _apply(side, undo: true);
      trail?.undone.add(_AmbianceStep(side));
      return;
    }
  }

  void redo() {
    final trail = _trail;
    while (trail != null && trail.undone.isNotEmpty) {
      final step = trail.undone.removeLast();
      if (!_matches(step, undo: false)) continue;
      _apply(step.side, undo: false);
      trail.done.add(_reissue(step, undo: false));
      return;
    }
  }

  _AmbianceTrail? get _trail {
    final document = maps.active;
    return document == null ? null : _trails[document] ??= _AmbianceTrail();
  }

  void _record(_AmbianceSide side, {Object? token}) {
    final trail = _trail;
    if (trail == null) return;
    trail.done.add(_AmbianceStep(side, token));
    trail.undone.clear();
  }

  bool _canUndo(_AmbianceSide side) => switch (side) {
    _AmbianceSide.visuals => _visuals?.canUndo ?? false,
    _AmbianceSide.atmosphere => _atmosphere?.canUndo ?? false,
    _AmbianceSide.map => maps.active?.canUndo ?? false,
  };

  bool _canRedo(_AmbianceSide side) => switch (side) {
    _AmbianceSide.visuals => _visuals?.canRedo ?? false,
    _AmbianceSide.atmosphere => _atmosphere?.canRedo ?? false,
    _AmbianceSide.map => maps.active?.canRedo ?? false,
  };

  bool _matches(_AmbianceStep step, {required bool undo}) {
    if (!(undo ? _canUndo(step.side) : _canRedo(step.side))) return false;
    if (step.side != _AmbianceSide.map) return true;
    final document = maps.active!;
    return identical(
      undo ? document.undoToken : document.redoToken,
      step.token,
    );
  }

  _AmbianceStep _reissue(_AmbianceStep step, {required bool undo}) =>
      step.side == _AmbianceSide.map
      ? _AmbianceStep(
          step.side,
          undo ? maps.active?.redoToken : maps.active?.undoToken,
        )
      : step;

  void _apply(_AmbianceSide side, {required bool undo}) =>
      switch ((side, undo)) {
        (_AmbianceSide.visuals, true) => _visuals?.undo(),
        (_AmbianceSide.visuals, false) => _visuals?.redo(),
        (_AmbianceSide.atmosphere, true) => _atmosphere?.undo(),
        (_AmbianceSide.atmosphere, false) => _atmosphere?.redo(),
        (_AmbianceSide.map, final undo) => _restoreMap(undo: undo),
      };

  void _restoreMap({required bool undo}) {
    maps.restore(redo: !undo);
    changed();
  }
}

final class _AmbianceStep {
  const _AmbianceStep(this.side, [this.token]);
  final _AmbianceSide side;
  final Object? token;
}

final class _AmbianceTrail {
  final done = <_AmbianceStep>[];
  final undone = <_AmbianceStep>[];
}
