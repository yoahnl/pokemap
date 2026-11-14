part of 'map_builder_story_binding.dart';

extension MapStoryHistory on MapBuilderStoryBinding {
  bool get canUndo =>
      _done.any((step) => _matches(step, undo: true)) ||
      (maps.active?.canUndo ?? false);

  bool get canRedo => _undone.any((step) => _matches(step, undo: false));

  void undo() {
    while (_done.isNotEmpty) {
      final step = _done.removeLast();
      if (!_matches(step, undo: true)) continue;
      _undone.add(_step(step.$1, undo: true));
      return;
    }
    if (maps.active?.canUndo ?? false) {
      maps.restore(redo: false);
      _undone.add((_StorySide.map, maps.active?.redoToken));
      changed();
    }
  }

  void redo() {
    while (_undone.isNotEmpty) {
      final step = _undone.removeLast();
      if (!_matches(step, undo: false)) continue;
      _done.add(_step(step.$1, undo: false));
      return;
    }
  }

  bool _matches((_StorySide, Object?) step, {required bool undo}) =>
      switch (step.$1) {
        _StorySide.behaviours => undo ? behaviours.canUndo : behaviours.canRedo,
        _StorySide.map => identical(
          undo ? maps.active?.undoToken : maps.active?.redoToken,
          step.$2,
        ),
      };

  (_StorySide, Object?) _step(_StorySide side, {required bool undo}) {
    switch (side) {
      case _StorySide.behaviours:
        undo ? behaviours.undo() : behaviours.redo();
        changed();
        return (side, null);
      case _StorySide.map:
        maps.restore(redo: !undo);
        changed();
        return (side, undo ? maps.active?.redoToken : maps.active?.undoToken);
    }
  }

  void recordBehaviourStep() => _record(_StorySide.behaviours, null);

  void _record(_StorySide side, Object? token) {
    _done.add((side, token));
    _undone.clear();
  }
}
