import '../domain/story_draft_entry.dart';

typedef StoryDraftStepChange = ({
  StoryDraftEntry<Object> before,
  StoryDraftEntry<Object> after,
});

typedef StoryDraftStep = Map<StoryDraftRef, StoryDraftStepChange>;

typedef StoryDraftIdentityChange = ({StoryDraftRef from, StoryDraftRef to});

typedef _StoryDraftTransaction = ({
  StoryDraftStep entries,
  Set<StoryDraftIdentityChange> identities,
});

final class StoryDraftHistory {
  static const capacity = 80;

  final _undo = <_StoryDraftTransaction>[];
  final _redo = <_StoryDraftTransaction>[];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  Set<StoryDraftRef> next({required bool redo}) => {
    ...?(redo ? _redo : _undo).lastOrNull?.entries.keys,
  };

  Iterable<StoryDraftEntry<Object>> nextEntries({required bool redo}) => [
    for (final change
        in (redo ? _redo : _undo).lastOrNull?.entries.values ??
            const <StoryDraftStepChange>[]) ...[change.before, change.after],
  ];

  Set<StoryDraftIdentityChange> nextIdentities({required bool redo}) =>
      (redo ? _redo : _undo).lastOrNull?.identities ?? const {};

  void record(
    StoryDraftStep step, {
    Iterable<StoryDraftIdentityChange> identities = const [],
  }) {
    _undo.add((
      entries: step,
      identities: Set.unmodifiable(
        identities.where(
          (change) =>
              step.containsKey(change.from) && step.containsKey(change.to),
        ),
      ),
    ));
    if (_undo.length > capacity) _undo.removeAt(0);
    _redo.clear();
  }

  StoryDraftStep? take({required bool redo}) {
    final from = redo ? _redo : _undo;
    if (from.isEmpty) return null;
    final step = from.removeLast();
    (redo ? _undo : _redo).add(step);
    return step.entries;
  }

  void rebase(StoryDraftRef ref, Object? from, Object? to) {
    for (final transaction in [..._undo, ..._redo]) {
      final step = transaction.entries;
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
