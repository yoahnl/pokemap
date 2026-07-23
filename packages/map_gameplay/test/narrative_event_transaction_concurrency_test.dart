import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/f1_runtime_catalog_fixture.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000001';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000002';
const _executionA = 'evx_019abcde-0000-7000-8000-000000000003';
const _executionB = 'evx_019abcde-0000-7000-8000-000000000004';
const _correlationA = 'corr_019abcde-0000-7000-8000-000000000005';

void main() {
  test('distinct concurrent Events preserve both updates', () async {
    final transactions =
        NarrativeEventStateTransactions(const GameState(saveId: 'save'));
    final firstStarted = Completer<void>();
    final releaseFirst = Completer<void>();
    final seenStates = <String, Map<String, String>>{};
    final executions = [_executionA, _executionB].iterator;
    final coordinator = NarrativeEventExecutionCoordinator(
      activityPort: NoopNarrativeEventActivityPort(),
      stateTransactions: transactions,
      planner: NarrativeEventDispatchPlanner(),
      executeScene: (request) async {
        seenStates[request.eventId] = request.gameState.metadata;
        if (request.eventId == _eventA) {
          firstStarted.complete();
          await releaseFirst.future;
        }
        return NarrativeSceneExecutionResult.completed(
          updatedGameState: request.gameState.copyWith(
            metadata: {...request.gameState.metadata, request.eventId: 'done'},
          ),
          qualifiedOutcomes: const [],
        );
      },
      executionIdFactory: () {
        executions.moveNext();
        return executions.current;
      },
      correlationIdFactory: () => _correlationA,
      deliveryIdFactory: () => throw StateError('no outcomes'),
    );

    final first = coordinator.execute(authority: _authority(_eventA));
    await firstStarted.future;
    final second = coordinator.execute(authority: _authority(_eventB));
    await Future<void>.delayed(Duration.zero);
    expect(seenStates.containsKey(_eventB), isFalse);
    releaseFirst.complete();
    await Future.wait([first, second]);
    final committed = await transactions.read();

    expect(seenStates[_eventA], isEmpty);
    expect(seenStates[_eventB], containsPair(_eventA, 'done'));
    expect(committed.metadata, {_eventA: 'done', _eventB: 'done'});
    expect(
      committed.narrativeEventProgress.consumedNarrativeEventIds,
      {_eventA, _eventB},
    );
  });

  test('transaction callback is not rerun after rollback or exception',
      () async {
    final transactions =
        NarrativeEventStateTransactions(const GameState(saveId: 'save'));
    var rollbackCalls = 0;
    var exceptionCalls = 0;

    final value = await transactions.transact((state) {
      rollbackCalls++;
      return NarrativeEventStateTransaction.rollback('rolledBack');
    });
    await expectLater(
      transactions.transact<String>((state) {
        exceptionCalls++;
        throw StateError('failed');
      }),
      throwsStateError,
    );

    expect(value, 'rolledBack');
    expect(rollbackCalls, 1);
    expect(exceptionCalls, 1);
    expect(await transactions.read(), const GameState(saveId: 'save'));
  });

  test('deferred commit work observes the committed state before completion',
      () async {
    final transactions =
        NarrativeEventStateTransactions(const GameState(saveId: 'save'));
    GameState? persisted;

    final value = await transactions.transact((state) async {
      await Future<void>.delayed(Duration.zero);
      expect(
        transactions.deferAfterCurrentCommit((committedState) {
          persisted = committedState;
        }),
        isTrue,
      );
      return NarrativeEventStateTransaction.commit(
        state.copyWith(metadata: const <String, String>{'shop': 'used'}),
        'completed',
      );
    });

    expect(value, 'completed');
    expect(persisted?.metadata, const <String, String>{'shop': 'used'});
    expect((await transactions.read()).metadata, persisted?.metadata);
  });

  test('failed deferred commit work rolls back the transaction', () async {
    const original = GameState(saveId: 'save');
    final transactions = NarrativeEventStateTransactions(original);

    await expectLater(
      transactions.transact<void>((state) {
        expect(
          transactions.deferAfterCurrentCommit((_) {
            throw StateError('save failed');
          }),
          isTrue,
        );
        return NarrativeEventStateTransaction.commit(
          state.copyWith(metadata: const <String, String>{'shop': 'used'}),
          null,
        );
      }),
      throwsStateError,
    );

    expect(await transactions.read(), original);
    expect(
      transactions.deferAfterCurrentCommit((_) {}),
      isFalse,
    );
  });
}

NarrativeEventDispatchAuthorityReady _authority(String eventId) {
  final source = NarrativeEventSourceRef.mapEnter('map_$eventId');
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: [
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: eventId,
          name: eventId,
          source: source,
          conditions: const [],
          sceneId: 'scene_$eventId',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      ),
    ],
    legacyClaims: const [],
  );
  return NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: NarrativeEventOccurrence(source: source),
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    projectCatalog: f1ProjectCatalogForRegistry(registry),
  ) as NarrativeEventDispatchAuthorityReady;
}
