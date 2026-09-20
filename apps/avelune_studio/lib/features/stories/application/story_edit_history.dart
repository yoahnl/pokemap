import 'package:map_core/map_core_domain.dart';

class StoryEditDelta {
  StoryEditDelta(this.before, this.after);
  final Map<String, StorylineAsset?> before;
  final Map<String, StorylineAsset?> after;
}

class StoryEditHistory {
  static const capacity = 80;
  final _undo = <StoryEditDelta>[];
  final _redo = <StoryEditDelta>[];
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void add(StoryEditDelta delta) {
    _undo.add(delta);
    if (_undo.length > capacity) _undo.removeAt(0);
    _redo.clear();
  }

  StoryEditDelta? take({required bool redo}) {
    final from = redo ? _redo : _undo;
    if (from.isEmpty) return null;
    final delta = from.removeLast();
    (redo ? _undo : _redo).add(delta);
    return delta;
  }

  void invalidate(Set<String> ids) {
    bool affected(StoryEditDelta d) => d.before.keys.any(ids.contains);
    _undo.removeWhere(affected);
    _redo.removeWhere(affected);
  }
}
