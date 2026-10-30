import 'dart:async';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const base = GameState(
      saveId: 'checkpoint',
      bag: Bag(entries: [BagEntry(itemId: 'fruit', quantity: 4)]));
  GameState next(GameState state) => state.copyWith(
      bag: const Bag(entries: [BagEntry(itemId: 'fruit', quantity: 2)]),
      gameplayCalendarState:
          GameplayCalendarState(observedLocalDay: '2026-10-30', dayRevision: 0),
      deferredCraftingState: DeferredCraftingState(servicesById: {
        'artisan': DeferredCraftingServiceState(
            revision: 1,
            pendingOrder: DeferredCraftingOrder(
                orderId: 'artisan:1',
                recipeId: 'ball',
                inputItemId: 'fruit',
                inputQuantity: 2,
                outputItemId: 'ball',
                outputQuantity: 1,
                submittedDayRevision: 0,
                requiredDayChanges: 1))
      }));

  test(
      'multiple durable checkpoints reconcile a stale final draft without replay',
      () async {
    final transactions = NarrativeEventStateTransactions(base);
    var writes = 0;
    final first = next(base);
    final second = first.copyWith(
        bag: const Bag(entries: [
          BagEntry(itemId: 'fruit', quantity: 2),
          BagEntry(itemId: 'ball', quantity: 1)
        ]),
        gameplayCalendarState: GameplayCalendarState(
            observedLocalDay: '2026-10-31', dayRevision: 1),
        deferredCraftingState: DeferredCraftingState(servicesById: {
          'artisan': DeferredCraftingServiceState(revision: 2)
        }));
    await transactions.transact<void>((_) async {
      final owner = transactions.captureCheckpointOwner()!;
      var draft = await checkpointDeferredCrafting(
          owner: owner,
          currentDraft: base,
          nextDraft: first,
          persist: (_) async {
            writes++;
          });
      draft = await checkpointDeferredCrafting(
          owner: owner,
          currentDraft: draft,
          nextDraft: second,
          persist: (_) async {
            writes++;
          });
      expect(draft.deferredCraftingState.serviceFor('artisan').revision, 2);
      return NarrativeEventStateTransaction.commit(
          base.copyWith(
              trainerProfile: const TrainerProfile(name: 'Leaf', money: 80)),
          null);
    });
    final committed = await transactions.read();
    expect(committed.bag, second.bag);
    expect(committed.deferredCraftingState, second.deferredCraftingState);
    expect(committed.trainerProfile.money, 80);
    expect(writes, 2);
  });
  test(
      'failed after-commit work restores durable checkpoint rather than pre-Scene state',
      () async {
    final transactions = NarrativeEventStateTransactions(base);
    await expectLater(transactions.transact<void>((_) async {
      final owner = transactions.captureCheckpointOwner()!;
      await checkpointDeferredCrafting(
          owner: owner,
          currentDraft: base,
          nextDraft: next(base),
          persist: (_) async {});
      transactions.deferAfterCurrentCommit(
          (_) => throw StateError('publication failed'));
      return NarrativeEventStateTransaction.commit(
          next(base).copyWith(
              trainerProfile: const TrainerProfile(name: 'Leaf', money: 80)),
          null);
    }), throwsStateError);
    final committed = await transactions.read();
    expect(committed.bag, next(base).bag);
    expect(committed.trainerProfile.money, 0);
  });
  test(
      'same-revision order replacement cannot erase a durable order on final commit',
      () async {
    final transactions = NarrativeEventStateTransactions(base);
    await expectLater(transactions.transact<void>((_) async {
      final owner = transactions.captureCheckpointOwner()!;
      final durable = next(base);
      await checkpointDeferredCrafting(
          owner: owner,
          currentDraft: base,
          nextDraft: durable,
          persist: (_) async {});
      final tampered = durable.copyWith(
          deferredCraftingState: DeferredCraftingState(servicesById: {
        'artisan': DeferredCraftingServiceState(revision: 1)
      }));
      return NarrativeEventStateTransaction.commit(tampered, null);
    }), throwsStateError);
    expect((await transactions.read()).deferredCraftingState,
        next(base).deferredCraftingState);
  });
  for (final failure in [false, true]) {
    test(
        'explicit outside-Zone owner persists then survives outer failure=$failure',
        () async {
      final transactions = NarrativeEventStateTransactions(base);
      final captured = Completer<NarrativeEventStateCheckpointOwner>();
      final release = Completer<void>();
      final draft = base.copyWith(
          trainerProfile: const TrainerProfile(name: 'Leaf', money: 80));
      final running = transactions.transact<void>((_) async {
        captured.complete(transactions.captureCheckpointOwner()!);
        await release.future;
        if (failure) throw StateError('later Scene failed');
        return NarrativeEventStateTransaction.commit(draft, null);
      });
      if (failure) unawaited(running.catchError((_) {}));
      final owner = await captured.future;
      GameState? persisted;
      final projected = await checkpointDeferredCrafting(
          owner: owner,
          currentDraft: draft,
          nextDraft: next(draft),
          persist: (state) async => persisted = state);
      expect(persisted!.trainerProfile.money, base.trainerProfile.money);
      expect(projected.trainerProfile.money, 80);
      expect(projected.bag, next(base).bag);
      release.complete();
      if (failure) {
        await expectLater(running, throwsStateError);
      } else {
        await running;
      }
      final committed = await transactions.read();
      expect(committed.bag, next(base).bag);
      expect(committed.deferredCraftingState, next(base).deferredCraftingState);
      expect(committed.trainerProfile.money,
          failure ? base.trainerProfile.money : 80);
      expect(() => owner.committedState, throwsStateError);
    });
  }
  test(
      'failed persistence keeps original rollback baseline and rejects changed affected draft',
      () async {
    final transactions = NarrativeEventStateTransactions(base);
    await transactions.transact<void>((_) async {
      final owner = transactions.captureCheckpointOwner()!;
      await expectLater(
          checkpointDeferredCrafting(
              owner: owner,
              currentDraft: base,
              nextDraft: next(base),
              persist: (_) async => throw StateError('disk full')),
          throwsStateError);
      expect(owner.committedState, same(base));
      await expectLater(
          checkpointDeferredCrafting(
              owner: owner,
              currentDraft: base.copyWith(bag: const Bag()),
              nextDraft: next(base),
              persist: (_) async => fail('stale draft cannot persist')),
          throwsStateError);
      return NarrativeEventStateTransaction.rollback(null);
    });
    expect(await transactions.read(), same(base));
  });
  test('outer cancellation waits for pending durable checkpoint and keeps it',
      () async {
    final transactions = NarrativeEventStateTransactions(base);
    final captured = Completer<NarrativeEventStateCheckpointOwner>();
    final cancel = Completer<void>();
    final persisted = Completer<void>();
    var finished = false;
    final running = transactions.transact<void>((_) async {
      captured.complete(transactions.captureCheckpointOwner()!);
      await cancel.future;
      return NarrativeEventStateTransaction.rollback(null);
    }).then((_) => finished = true);
    final owner = await captured.future;
    final saving = checkpointDeferredCrafting(
        owner: owner,
        currentDraft: base,
        nextDraft: next(base),
        persist: (_) => persisted.future);
    cancel.complete();
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    await expectLater(
        checkpointDeferredCrafting(
            owner: owner,
            currentDraft: base,
            nextDraft: next(base),
            persist: (_) async => fail('duplicate')),
        throwsStateError);
    persisted.complete();
    await saving;
    await running;
    expect((await transactions.read()).bag, next(base).bag);
  });
}
