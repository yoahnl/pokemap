import 'package:avelune_studio/features/events/application/behaviour/behaviour_record_edit.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_reuse.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

final _outcome = NarrativeOutcomeRef(
  producerKind: NarrativeOutcomeProducerKind.scene,
  producerId: 'scene_battle',
  outcomeId: 'won',
);
final _otherOutcome = NarrativeOutcomeRef(
  producerKind: NarrativeOutcomeProducerKind.scene,
  producerId: 'scene_battle',
  outcomeId: 'lost',
);

NarrativeEventRecord _record({
  NarrativeEventReusePolicy reuse = NarrativeEventReusePolicy.oneShot,
  NarrativeEventResetPolicy reset = const NarrativeEventResetPolicy.never(),
  NarrativeEventSourceRef? source,
  NarrativeEventParallelPolicy? parallel,
}) => NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: 'evt_01a16b62-614a-741c-be2e-18a338e7bcd6',
    name: 'Case',
    source: source ?? NarrativeEventSourceRef.entityInteract('map', 'npc'),
    conditions: const [],
    sceneId: 'scene',
    reusePolicy: reuse,
    priority: 3,
    order: 2,
    resetPolicy: reset,
    parallelPolicy: parallel,
  ),
  enabled: false,
);

NarrativeEventRecord _draft({NarrativeEventReusePolicy? reuse}) =>
    NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: 'evt_01a16b62-614a-741c-be2e-18a338e7bcd7',
        name: 'Draft',
        source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
        conditions: const [],
        reusePolicy: reuse,
        priority: 0,
        order: 0,
      ),
    );

BehaviourAfterApplied _applied(BehaviourAfterChange change) {
  expect(change, isA<BehaviourAfterApplied>());
  return change as BehaviourAfterApplied;
}

void main() {
  final untilOutcome = _record(
    reset: NarrativeEventResetPolicy.onOutcomeReceived(_outcome),
  );

  test('reads every policy including the outcome re-arm', () {
    expect(readBehaviourAfter(_draft()), isNull);
    expect(
      readBehaviourAfter(_record(reuse: NarrativeEventReusePolicy.reusable)),
      BehaviourAfter.eachTime,
    );
    expect(readBehaviourAfter(_record()), BehaviourAfter.once);
    expect(
      readBehaviourAfter(
        _record(reset: const NarrativeEventResetPolicy.onMapReentry()),
      ),
      BehaviourAfter.oncePerVisit,
    );
    expect(readBehaviourAfter(untilOutcome), BehaviourAfter.onceUntilOutcome);
    expect(behaviourRearmOutcome(untilOutcome), _outcome);
  });

  test('simple choices never silently erase the outcome re-arm', () {
    for (final after in [
      BehaviourAfter.once,
      BehaviourAfter.eachTime,
      BehaviourAfter.oncePerVisit,
    ]) {
      final change = changeBehaviourAfter(untilOutcome, after);
      expect(change, isA<BehaviourAfterRefused>(), reason: after.name);
      final refused = change as BehaviourAfterRefused;
      expect(refused.reason, BehaviourAfterRefusal.wouldDropOutcomeRearm);
      expect(refused.outcome, _outcome);
      expect(
        changeBehaviourAfter(untilOutcome, after, outcome: _otherOutcome),
        isA<BehaviourAfterRefused>(),
        reason: after.name,
      );
    }
  });

  test('re-choosing until-outcome keeps the existing outcome', () {
    expect(
      changeBehaviourAfter(untilOutcome, BehaviourAfter.onceUntilOutcome),
      isA<BehaviourAfterUnchanged>(),
    );
    final changed = _applied(
      changeBehaviourAfter(
        untilOutcome,
        BehaviourAfter.onceUntilOutcome,
        outcome: _otherOutcome,
      ),
    );
    expect(behaviourRearmOutcome(changed.record), _otherOutcome);
    expect(changed.steps.single.resetPolicy, isNotNull);
  });

  test('dropping the re-arm only on explicit request', () {
    final applied = _applied(
      changeBehaviourAfter(
        untilOutcome,
        BehaviourAfter.eachTime,
        dropOutcomeRearm: true,
      ),
    );
    expect(applied.record.reusePolicy, NarrativeEventReusePolicy.reusable);
    expect(applied.record.resetPolicy, const NarrativeEventResetPolicy.never());
    expect(applied.steps.map((step) => step.resetPolicy != null), [
      true,
      false,
    ]);
  });

  test('steps are ordered so each one is valid on its own', () {
    final toVisit = _applied(
      changeBehaviourAfter(
        _record(reuse: NarrativeEventReusePolicy.reusable),
        BehaviourAfter.oncePerVisit,
      ),
    );
    expect(toVisit.steps.first.reusePolicy, NarrativeEventReusePolicy.oneShot);
    expect(
      toVisit.steps.last.resetPolicy,
      const NarrativeEventResetPolicy.onMapReentry(),
    );
    final toEach = _applied(
      changeBehaviourAfter(
        _record(reset: const NarrativeEventResetPolicy.onMapReentry()),
        BehaviourAfter.eachTime,
      ),
    );
    expect(
      toEach.steps.first.resetPolicy,
      const NarrativeEventResetPolicy.never(),
    );
    expect(toEach.steps.last.reusePolicy, NarrativeEventReusePolicy.reusable);
  });

  test('each step yields a record the model accepts', () {
    NarrativeEventRecord step(
      NarrativeEventRecord record,
      BehaviourAfterStep s,
    ) => editBehaviourRecord(
      record,
      policy: (
        reuse: s.reusePolicy ?? record.reusePolicy,
        reset: s.resetPolicy ?? record.resetPolicy,
      ),
    );
    final starts = [
      _record(reuse: NarrativeEventReusePolicy.reusable),
      _record(),
      _record(reset: const NarrativeEventResetPolicy.onMapReentry()),
      untilOutcome,
    ];
    for (final start in starts) {
      for (final after in BehaviourAfter.values) {
        final change = changeBehaviourAfter(
          start,
          after,
          dropOutcomeRearm: true,
          outcome: after == BehaviourAfter.onceUntilOutcome
              ? _otherOutcome
              : null,
        );
        if (change is! BehaviourAfterApplied) continue;
        var record = start;
        for (final s in change.steps) {
          record = step(record, s);
        }
        expect(
          record,
          change.record,
          reason: '${readBehaviourAfter(start)} -> $after',
        );
      }
    }
    expect(
      () => editBehaviourRecord(
        _record(reuse: NarrativeEventReusePolicy.reusable),
        policy: (
          reuse: NarrativeEventReusePolicy.reusable,
          reset: const NarrativeEventResetPolicy.onMapReentry(),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('only the policy changes on the record', () {
    final before = _record();
    final after = _applied(
      changeBehaviourAfter(before, BehaviourAfter.eachTime),
    ).record;
    final beforeJson = Map<String, Object?>.of(
      before.toJson()['definition']! as Map<String, Object?>,
    )..remove('reusePolicy');
    final afterJson = Map<String, Object?>.of(
      after.toJson()['definition']! as Map<String, Object?>,
    )..remove('reusePolicy');
    expect(afterJson, beforeJson);
    expect(after.enabledOrNull, before.enabledOrNull);
  });

  test('a draft without policy gets one', () {
    final applied = _applied(
      changeBehaviourAfter(_draft(), BehaviourAfter.once),
    );
    expect(applied.record.reusePolicy, NarrativeEventReusePolicy.oneShot);
    expect(applied.record.draftOrNull, isNotNull);
    expect(
      changeBehaviourAfter(
        _draft(reuse: NarrativeEventReusePolicy.oneShot),
        BehaviourAfter.once,
      ),
      isA<BehaviourAfterUnchanged>(),
    );
  });

  test('refuses combinations the model rejects', () {
    expect(
      (changeBehaviourAfter(
        _record(),
        BehaviourAfter.onceUntilOutcome,
      ) as BehaviourAfterRefused).reason,
      BehaviourAfterRefusal.outcomeRequired,
    );
    final parallel = _record(
      reuse: NarrativeEventReusePolicy.reusable,
      source: NarrativeEventSourceRef.entityAutorun('map', 'npc'),
      parallel: NarrativeEventParallelPolicy(cadenceMs: 500),
    );
    expect(
      (changeBehaviourAfter(
        parallel,
        BehaviourAfter.once,
      ) as BehaviourAfterRefused).reason,
      BehaviourAfterRefusal.parallelNeedsEachTime,
    );
    final fromOutcome = _record(
      source: NarrativeEventSourceRef.outcomeReceived(_outcome),
    );
    expect(
      (changeBehaviourAfter(
        fromOutcome,
        BehaviourAfter.oncePerVisit,
      ) as BehaviourAfterRefused).reason,
      BehaviourAfterRefusal.visitNeedsPlace,
    );
  });
}
