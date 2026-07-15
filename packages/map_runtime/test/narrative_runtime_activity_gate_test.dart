import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_port.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';

void main() {
  group('NarrativeRuntimeActivityGate', () {
    test('starts idle and permits a checkpoint', () async {
      final gate = NarrativeRuntimeActivityGate();

      final result = await gate.runCheckpoint(
        NarrativeRuntimeCheckpointOperation.save,
        () async => 42,
      );

      expect(result, 42);
      expect(gate.activity, NarrativeRuntimeActivity.idle);
      expect(gate.checkpointInProgress, isFalse);
    });

    for (final activity in NarrativeRuntimeActivity.values.where(
      (value) => value != NarrativeRuntimeActivity.idle,
    )) {
      test('$activity blocks save and load checkpoints', () async {
        final gate = NarrativeRuntimeActivityGate();
        final lease = gate.enter(activity);

        for (final operation in NarrativeRuntimeCheckpointOperation.values) {
          await expectLater(
            gate.runCheckpoint(operation, () async {}),
            throwsA(
              isA<NarrativeRuntimeCheckpointBlockedException>()
                  .having((error) => error.activity, 'activity', activity)
                  .having((error) => error.operation, 'operation', operation)
                  .having(
                    (error) => error.reasonCode,
                    'reasonCode',
                    activity.name,
                  ),
            ),
          );
        }

        lease.close();
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      });
    }

    test('restores activity after exceptions and nested leases', () async {
      final gate = NarrativeRuntimeActivityGate();
      final dispatch = gate.enter(NarrativeRuntimeActivity.dispatching);
      final scene = gate.enter(NarrativeRuntimeActivity.sceneActive);

      expect(gate.activity, NarrativeRuntimeActivity.sceneActive);
      scene.close();
      expect(gate.activity, NarrativeRuntimeActivity.dispatching);
      dispatch.close();
      dispatch.close();
      expect(gate.activity, NarrativeRuntimeActivity.idle);

      await expectLater(
        gate.runWithActivity(
          NarrativeRuntimeActivity.outboxProcessing,
          () async => throw StateError('failed'),
        ),
        throwsStateError,
      );
      expect(gate.activity, NarrativeRuntimeActivity.idle);
    });

    test('checkpoint reservation rejects activity until IO completes',
        () async {
      final gate = NarrativeRuntimeActivityGate();
      final release = Completer<void>();
      final checkpoint = gate.runCheckpoint(
        NarrativeRuntimeCheckpointOperation.save,
        () => release.future,
      );

      expect(gate.checkpointInProgress, isTrue);
      expect(
        () => gate.enter(NarrativeRuntimeActivity.dispatching),
        throwsA(isA<NarrativeRuntimeActivityBlockedException>()),
      );

      release.complete();
      await checkpoint;
      expect(gate.checkpointInProgress, isFalse);
    });

    test('gameplay activity port and checkpoint use the same gate', () async {
      final gate = NarrativeRuntimeActivityGate();
      final port = NarrativeRuntimeActivityPort(gate);
      final entered = Completer<void>();
      final release = Completer<void>();

      final dispatch = port.runWithActivity(
        NarrativeEventActivity.dispatching,
        () async {
          entered.complete();
          await release.future;
        },
      );
      await entered.future;

      expect(gate.activity, NarrativeRuntimeActivity.dispatching);
      await expectLater(
        gate.runCheckpoint(
          NarrativeRuntimeCheckpointOperation.save,
          () async {},
        ),
        throwsA(
          isA<NarrativeRuntimeCheckpointBlockedException>().having(
            (error) => error.reasonCode,
            'reasonCode',
            NarrativeRuntimeActivity.dispatching.name,
          ),
        ),
      );

      release.complete();
      await dispatch;
      expect(gate.activity, NarrativeRuntimeActivity.idle);
    });

    test('gameplay idle activity is checkpoint-neutral', () async {
      final gate = NarrativeRuntimeActivityGate();
      final port = NarrativeRuntimeActivityPort(gate);

      final result = await port.runWithActivity(
        NarrativeEventActivity.idle,
        () => gate.runCheckpoint(
          NarrativeRuntimeCheckpointOperation.save,
          () async => 42,
        ),
      );

      expect(result, 42);
      expect(gate.activity, NarrativeRuntimeActivity.idle);
    });
  });
}
