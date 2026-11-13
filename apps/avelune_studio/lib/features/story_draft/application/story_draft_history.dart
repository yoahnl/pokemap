import '../domain/story_draft_entry.dart';

typedef StoryDraftStepChange = ({
  StoryDraftEntry<Object> before,
  StoryDraftEntry<Object> after,
});

typedef StoryDraftStep = Map<StoryDraftRef, StoryDraftStepChange>;

final class StoryDraftHistory {
  static const capacity = 80;

  final _undo = <StoryDraftStep>[];
  final _redo = <StoryDraftStep>[];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void record(StoryDraftStep step) {
    _undo.add(step);
    if (_undo.length > capacity) _undo.removeAt(0);
    _redo.clear();
  }

  StoryDraftStep? take({required bool redo}) {
    final from = redo ? _redo : _undo;
    if (from.isEmpty) return null;
    final step = from.removeLast();
    (redo ? _undo : _redo).add(step);
    return step;
  }

  void rebase(StoryDraftRef ref, Object? from, Object? to) {
    for (final step in [..._undo, ..._redo]) {
      final change = step[ref];
      if (change == null) continue;
      step[ref] = (
        before: _rebased(change.before, from, to),
        after: _rebased(change.after, from, to),
      );
    }
  }

  StoryDraftEntry<Object> _rebased(
    StoryDraftEntry<Object> entry,
    Object? from,
    Object? to,
  ) => entry.base == from
      ? entry.kind.entry(entry.id, base: to, current: entry.current)
      : entry;
}
