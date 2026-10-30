import 'dart:async';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const base = GameState(saveId: 'puzzle');
  final definition = ImagePuzzleDefinition(
      puzzleId: 'mosaic', imageResourceId: 'image', rows: 2, columns: 2);
  final first = const ImagePuzzleOperations()
      .open(base, definition: definition, seed: 3)
      .state;
  final second = const ImagePuzzleOperations()
      .rotate(first, definition: definition, pieceId: 0)
      .state;
  for (final rollback in [false, true]) {
    test(
        'outside-Zone checkpoint preserves unrelated Scene draft rollback=$rollback',
        () async {
      final queue = NarrativeEventStateTransactions(base);
      final capture = Completer<NarrativeEventStateCheckpointOwner>();
      final release = Completer<void>();
      final draft =
          base.copyWith(storyFlags: StoryFlags(activeFlags: {'pending'}));
      final run = queue.transact<void>((_) async {
        capture.complete(queue.captureCheckpointOwner()!);
        await release.future;
        if (rollback) throw StateError('later Scene failure');
        return NarrativeEventStateTransaction.commit(
            draft.copyWith(
                bag: const Bag(
                    entries: [BagEntry(itemId: 'reward', quantity: 1)])),
            null);
      });
      final owner = await capture.future;
      final writes = <GameState>[];
      final updated = await checkpointImagePuzzle(
          owner: owner,
          currentDraft: draft,
          nextDraft: first,
          persist: (state) async {
            writes.add(state);
          });
      expect(updated.storyFlags, draft.storyFlags);
      expect(writes.single.storyFlags, base.storyFlags);
      await checkpointImagePuzzle(
          owner: owner,
          currentDraft: updated,
          nextDraft: second,
          persist: (state) async {
            writes.add(state);
          });
      release.complete();
      if (rollback) {
        await expectLater(run, throwsStateError);
      } else {
        await run;
      }
      final actual = await queue.read();
      expect(actual.imagePuzzleState, second.imagePuzzleState);
      expect(actual.bag.entries.length, rollback ? 0 : 1);
      expect(actual.storyFlags, rollback ? base.storyFlags : draft.storyFlags);
      expect(writes.length, 2);
    });
  }
  test(
      'checkpoint owner exposes no durable state after its transaction expires',
      () async {
    final queue = NarrativeEventStateTransactions(base);
    late NarrativeEventStateCheckpointOwner expired;
    await queue.transact<void>((_) {
      expired = queue.captureCheckpointOwner()!;
      return NarrativeEventStateTransaction.rollback(null);
    });
    expect(() => expired.latestCheckpointState, throwsStateError);
    expect(() => expired.committedState, throwsStateError);
  });
  test('pending puzzle conflict and IO failure preserve the durable base',
      () async {
    final queue = NarrativeEventStateTransactions(base);
    await queue.transact<void>((_) async {
      final owner = queue.captureCheckpointOwner()!;
      var writes = 0;
      await expectLater(
          checkpointImagePuzzle(
              owner: owner,
              currentDraft: first,
              nextDraft: second,
              persist: (_) async {
                writes++;
              }),
          throwsStateError);
      expect(writes, 0);
      await expectLater(
          checkpointImagePuzzle(
              owner: owner,
              currentDraft: base,
              nextDraft: first,
              persist: (_) async {
                throw StateError('disk');
              }),
          throwsStateError);
      expect(owner.committedState, base);
      return NarrativeEventStateTransaction.rollback(null);
    });
    expect(await queue.read(), base);
  });
}
