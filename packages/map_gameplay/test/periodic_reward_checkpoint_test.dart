import 'dart:async';
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const base = GameState(saveId: 'reward-save');
  final definition = PeriodicItemRewardDefinition(
    rewardId: 'daily-fruit',
    label: 'Fruit',
    itemId: 'fruit',
    quantity: 2,
  );
  final catalog = ItemCatalogSnapshot.fromCatalog(const ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(
          id: 'fruit', displayName: 'Fruit', pocketId: 'items'),
    ],
  ));
  GameState next(GameState state, {String day = '2026-10-30'}) {
    final observed = observeGameplayCalendar(state, localDay: day);
    return const PeriodicRewardOperations()
        .claim(observed,
            definition: definition,
            expectedRewardRevision:
                state.periodicRewardState.claimFor('daily-fruit')?.revision ??
                    0,
            expectedCalendar: observed.gameplayCalendarState,
            itemCatalog: catalog)
        .state;
  }

  test(
      'I/O failure leaves bag and eligibility untouched then retry Continue cannot duplicate',
      () async {
    final transactions = NarrativeEventStateTransactions(base);
    String? persisted;
    await transactions.transact<void>((state) async {
      final owner = transactions.captureCheckpointOwner()!;
      final after = next(state);
      await expectLater(
          checkpointPeriodicReward(
              owner: owner,
              currentDraft: state,
              nextDraft: after,
              persist: (_) async => throw StateError('disk full')),
          throwsStateError);
      expect(owner.committedState, same(state));
      final projected = await checkpointPeriodicReward(
          owner: owner,
          currentDraft: state,
          nextDraft: after,
          persist: (durable) async =>
              persisted = jsonEncode(strictGameStateSaveJson(durable)));
      return NarrativeEventStateTransaction.commit(projected, null);
    });
    final restored = gameStateFromStrictSaveJson(
        jsonDecode(persisted!) as Map<String, dynamic>);
    expect(next(restored), restored);
    expect(const BagOperations().quantityOf(restored.bag, 'fruit'), 2);
    expect(await transactions.read(), restored);
  });

  for (final failure in [false, true]) {
    test(
        'checkpoint preserves foreign Scene draft and survives later Scene failure=$failure',
        () async {
      final transactions = NarrativeEventStateTransactions(base);
      GameState? persisted;
      final draft =
          base.copyWith(storyFlags: const StoryFlags(activeFlags: {'pending'}));
      final running = transactions.transact<void>((_) async {
        final projected = await checkpointPeriodicReward(
            owner: transactions.captureCheckpointOwner()!,
            currentDraft: draft,
            nextDraft: next(draft),
            persist: (state) async => persisted = state);
        expect(persisted!.storyFlags, base.storyFlags);
        expect(projected.storyFlags, draft.storyFlags);
        if (failure) throw StateError('Scene failed');
        return NarrativeEventStateTransaction.commit(draft, null);
      });
      if (failure) {
        await expectLater(running, throwsStateError);
      } else {
        await running;
      }
      final state = await transactions.read();
      expect(state.periodicRewardState, next(base).periodicRewardState);
      expect(state.bag, next(base).bag);
      expect(state.storyFlags, failure ? base.storyFlags : draft.storyFlags);
    });
  }

  test(
      'multiple checkpoints reconcile stale intermediate drafts using final durable inventory',
      () async {
    final transactions = NarrativeEventStateTransactions(base);
    await transactions.transact<void>((_) async {
      final owner = transactions.captureCheckpointOwner()!;
      final first = await checkpointPeriodicReward(
          owner: owner,
          currentDraft: base,
          nextDraft: next(base),
          persist: (_) async {});
      await checkpointPeriodicReward(
          owner: owner,
          currentDraft: first,
          nextDraft: next(first, day: '2026-10-31'),
          persist: (_) async {});
      return NarrativeEventStateTransaction.commit(
          first.copyWith(metadata: {'foreign': 'kept'}), null);
    });
    final state = await transactions.read();
    expect(const BagOperations().quantityOf(state.bag, 'fruit'), 4);
    expect(state.periodicRewardState.claimFor('daily-fruit')!.revision, 2);
    expect(state.metadata, {'foreign': 'kept'});
  });

  test(
      'same-revision tampering and pending inventory changes reject without losing durable claim',
      () async {
    final transactions = NarrativeEventStateTransactions(base);
    await expectLater(transactions.transact<void>((_) async {
      final owner = transactions.captureCheckpointOwner()!;
      await expectLater(
          checkpointPeriodicReward(
              owner: owner,
              currentDraft: base.copyWith(
                  bag: const Bag(
                      entries: [BagEntry(itemId: 'fruit', quantity: 1)])),
              nextDraft: next(base),
              persist: (_) async => fail('must not write')),
          throwsStateError);
      final after = await checkpointPeriodicReward(
          owner: owner,
          currentDraft: base,
          nextDraft: next(base),
          persist: (_) async {});
      return NarrativeEventStateTransaction.commit(
          after.copyWith(bag: const Bag()), null);
    }), throwsStateError);
    expect((await transactions.read()).bag, next(base).bag);
  });

  test(
      'outside-Zone owner rejects concurrent duplicate checkpoints and expired owner',
      () async {
    final transactions = NarrativeEventStateTransactions(base);
    final captured = Completer<NarrativeEventStateCheckpointOwner>();
    final finish = Completer<void>();
    final disk = Completer<void>();
    final running = transactions.transact<void>((state) async {
      captured.complete(transactions.captureCheckpointOwner()!);
      await finish.future;
      return NarrativeEventStateTransaction.rollback(null);
    });
    final owner = await captured.future;
    final saving = checkpointPeriodicReward(
        owner: owner,
        currentDraft: base,
        nextDraft: next(base),
        persist: (_) => disk.future);
    await expectLater(
        checkpointPeriodicReward(
            owner: owner,
            currentDraft: base,
            nextDraft: next(base),
            persist: (_) async => fail('duplicate')),
        throwsStateError);
    finish.complete();
    disk.complete();
    await saving;
    await running;
    expect((await transactions.read()).bag, next(base).bag);
    expect(() => owner.committedState, throwsStateError);
  });

  for (final rewardFirst in [true, false]) {
    test('composes with crafting checkpoints rewardFirst=$rewardFirst',
        () async {
      final transactions = NarrativeEventStateTransactions(base);
      await transactions.transact<void>((_) async {
        final owner = transactions.captureCheckpointOwner()!;
        Future<GameState> reward(GameState draft) => checkpointPeriodicReward(
              owner: owner,
              currentDraft: draft,
              nextDraft: next(draft),
              persist: (_) async {},
            );
        Future<GameState> craft(GameState draft) => checkpointDeferredCrafting(
              owner: owner,
              currentDraft: draft,
              nextDraft: draft.copyWith(
                bag: const Bag(
                    entries: [BagEntry(itemId: 'fruit', quantity: 1)]),
                deferredCraftingState: DeferredCraftingState(servicesById: {
                  'artisan': DeferredCraftingServiceState(revision: 1),
                }),
              ),
              persist: (_) async {},
            );
        final finalDraft = rewardFirst
            ? await craft(await reward(base))
            : await reward(await craft(base));
        return NarrativeEventStateTransaction.commit(
            finalDraft.copyWith(
              metadata: {'foreign': 'kept'},
              storyFlags: const StoryFlags(activeFlags: {'scene-complete'}),
            ),
            null);
      });
      final state = await transactions.read();
      expect(state.periodicRewardState.claimFor('daily-fruit')!.revision, 1);
      expect(state.deferredCraftingState.serviceFor('artisan').revision, 1);
      expect(const BagOperations().quantityOf(state.bag, 'fruit'),
          rewardFirst ? 1 : 3);
      expect(state.metadata, {'foreign': 'kept'});
      expect(state.storyFlags.activeFlags, {'scene-complete'});
    });
  }

  for (final finalOutcome in ['commit', 'tamper', 'rollback']) {
    test(
        'three mixed checkpoints preserve durable fields with final outcome=$finalOutcome',
        () async {
      final transactions = NarrativeEventStateTransactions(base);
      final run = transactions.transact<void>((_) async {
        final owner = transactions.captureCheckpointOwner()!;
        var draft = await checkpointDeferredCrafting(
          owner: owner,
          currentDraft: base,
          nextDraft: base.copyWith(
              deferredCraftingState: DeferredCraftingState(servicesById: {
            'artisan': DeferredCraftingServiceState(revision: 1),
          })),
          persist: (_) async {},
        );
        draft = await checkpointPeriodicReward(
            owner: owner,
            currentDraft: draft,
            nextDraft: next(draft),
            persist: (_) async {});
        draft = await checkpointPeriodicReward(
            owner: owner,
            currentDraft: draft,
            nextDraft: next(draft, day: '2026-10-31'),
            persist: (_) async {});
        final finalDraft = draft.copyWith(
          storyFlags: const StoryFlags(activeFlags: {'scene-complete'}),
        );
        if (finalOutcome == 'rollback') throw StateError('later Scene failure');
        return NarrativeEventStateTransaction.commit(
          finalOutcome == 'tamper'
              ? finalDraft.copyWith(
                  bag: const Bag(
                      entries: [BagEntry(itemId: 'fruit', quantity: 99)]))
              : finalDraft,
          null,
        );
      });
      if (finalOutcome == 'commit') {
        await run;
      } else {
        await expectLater(run, throwsStateError);
      }
      final state = await transactions.read();
      expect(state.deferredCraftingState.serviceFor('artisan').revision, 1);
      expect(state.periodicRewardState.claimFor('daily-fruit')!.revision, 2);
      expect(state.gameplayCalendarState.observedLocalDay, '2026-10-31');
      expect(const BagOperations().quantityOf(state.bag, 'fruit'), 4);
      expect(state.storyFlags.activeFlags,
          finalOutcome == 'commit' ? {'scene-complete'} : isEmpty);
    });
  }

  test(
      'queued claims see latest durable claim instead of duplicating the reward',
      () async {
    final transactions = NarrativeEventStateTransactions(base);
    var writes = 0;
    Future<void> collect() => transactions.transact<void>((state) async {
          final after = next(state);
          if (after != state) {
            await checkpointPeriodicReward(
                owner: transactions.captureCheckpointOwner()!,
                currentDraft: state,
                nextDraft: after,
                persist: (_) async {
                  writes++;
                });
          }
          return NarrativeEventStateTransaction.rollback(null);
        });
    await Future.wait([collect(), collect()]);
    expect(writes, 1);
    expect(
        const BagOperations()
            .quantityOf((await transactions.read()).bag, 'fruit'),
        2);
  });
}
