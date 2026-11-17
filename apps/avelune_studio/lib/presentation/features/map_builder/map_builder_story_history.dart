part of 'map_builder_story_binding.dart';

typedef _PendingMapHistory = ({
  EditableMapDocument document,
  Object? beforeUndo,
  Object? original,
  Object? restored,
  bool undo,
});

extension MapStoryHistory on MapBuilderStoryBinding {
  bool get canUndo {
    _trackMapHistory();
    if (_pendingMapHistory != null) return false;
    return _done.any((step) => _matches(step, undo: true)) ||
        (maps.active?.canUndo ?? false);
  }

  bool get canRedo {
    _trackMapHistory();
    if (_pendingMapHistory != null) return false;
    return _undone.any((step) => _matches(step, undo: false));
  }

  void undo() {
    _trackMapHistory();
    if (_pendingMapHistory != null) return;
    while (_done.isNotEmpty) {
      final step = _done.last;
      if (!_matches(step, undo: true)) {
        _done.removeLast();
        continue;
      }
      final restored = _step(step.$1, undo: true);
      if (restored == null) return;
      _done.removeLast();
      _undone.add(restored);
      changed();
      return;
    }
    if (maps.active?.canUndo ?? false) {
      final restored = _step(_StorySide.map, undo: true);
      if (restored != null) _undone.add(restored);
      changed();
    }
  }

  void redo() {
    _trackMapHistory();
    if (_pendingMapHistory != null) return;
    while (_undone.isNotEmpty) {
      final step = _undone.last;
      if (!_matches(step, undo: false)) {
        _undone.removeLast();
        continue;
      }
      final restored = _step(step.$1, undo: false);
      if (restored == null) return;
      _undone.removeLast();
      _done.add(restored);
      changed();
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

  (_StorySide, Object?)? _step(_StorySide side, {required bool undo}) {
    switch (side) {
      case _StorySide.behaviours:
        undo ? behaviours.undo() : behaviours.redo();
        return (side, null);
      case _StorySide.map:
        final document = maps.active;
        final before = document?.undoToken;
        final original = undo ? document?.undoToken : document?.redoToken;
        _restoringMapHistory = true;
        try {
          maps.restore(redo: !undo);
          if (document == null || identical(before, document.undoToken)) {
            return null;
          }
          final token = undo ? document.redoToken : document.undoToken;
          if (token != null) _mapHistoryOwners[token] = document;
          if (document.saving) {
            _pendingMapHistory = (
              document: document,
              beforeUndo: before,
              original: original,
              restored: token,
              undo: undo,
            );
          }
          return (side, token);
        } finally {
          _restoringMapHistory = false;
        }
    }
  }

  bool canStepScope(StoryHistoryScope scope, {required bool redo}) {
    _trackMapHistory();
    if (_pendingMapHistory != null) return false;
    final stack = redo ? _undone : _done;
    final step = stack.lastWhere(
      (step) => step.$1 == _StorySide.behaviours
          ? _matches(step, undo: !redo)
          : step.$2 != null &&
                identical(
                  redo
                      ? _mapHistoryOwners[step.$2!]?.redoToken
                      : _mapHistoryOwners[step.$2!]?.undoToken,
                  step.$2,
                ),
      orElse: () => (_StorySide.map, null),
    );
    if (step.$1 != _StorySide.behaviours) return false;
    return scope.decision(behaviours.draft, redo: redo) ==
        StoryHistoryDecision.allowed;
  }

  void recordBehaviourStep() => _record(_StorySide.behaviours, null);

  void _trackMapHistory() {
    if (_restoringMapHistory) return;
    final pending = _pendingMapHistory;
    if (pending != null) {
      if (pending.document.saving) return;
      if (identical(pending.document.undoToken, pending.beforeUndo)) {
        final source = pending.undo ? _done : _undone;
        final target = pending.undo ? _undone : _done;
        if (target.lastOrNull == (_StorySide.map, pending.restored)) {
          target.removeLast();
          source.add((_StorySide.map, pending.original));
        }
      }
      _pendingMapHistory = null;
    }
    final document = maps.active;
    final token = document?.undoToken;
    if (document == null || token == null || _mapHistoryOwners[token] != null) {
      return;
    }
    _record(_StorySide.map, token);
  }

  void _record(_StorySide side, Object? token) {
    if (side == _StorySide.behaviours && onBehaviourRecorded != null) {
      onBehaviourRecorded!();
      return;
    }
    if (side == _StorySide.behaviours) _trackMapHistory();
    if (side == _StorySide.map && token != null) {
      final document = maps.active;
      if (document != null) _mapHistoryOwners[token] = document;
      if (_done.lastOrNull == (side, token)) return;
    }
    _done.add((side, token));
    _undone.clear();
  }
}
