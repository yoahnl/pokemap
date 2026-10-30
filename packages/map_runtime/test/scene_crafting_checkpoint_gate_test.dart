import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';

void main() {
  test(
    'owned Scene checkpoint never opens ordinary save or another activity',
    () async {
      final gate = NarrativeRuntimeActivityGate();
      final scene = gate.enter(NarrativeRuntimeActivity.sceneActive);
      final owner = gate.captureSceneCheckpointOwner();
      final finish = Completer<void>();
      final saving = gate.runSceneCheckpoint(owner, () => finish.future);
      expect(gate.checkpointInProgress, isTrue);
      await expectLater(
        gate.runCheckpoint(
          NarrativeRuntimeCheckpointOperation.save,
          () async {},
        ),
        throwsA(isA<NarrativeRuntimeCheckpointBlockedException>()),
      );
      expect(
        () => gate.enter(NarrativeRuntimeActivity.dispatching),
        throwsA(isA<NarrativeRuntimeActivityBlockedException>()),
      );
      scene.close();
      finish.complete();
      await saving;
      expect(gate.checkpointInProgress, isFalse);
      await expectLater(
        gate.runSceneCheckpoint(owner, () async {}),
        throwsStateError,
      );
    },
  );
  test(
    'owner cannot survive a changed activity stack or authorize another gate',
    () async {
      final gate = NarrativeRuntimeActivityGate();
      expect(gate.captureSceneCheckpointOwner, throwsStateError);
      final scene = gate.enter(NarrativeRuntimeActivity.sceneActive);
      final owner = gate.captureSceneCheckpointOwner();
      final suspend = gate.enter(NarrativeRuntimeActivity.sceneSuspended);
      await expectLater(
        gate.runSceneCheckpoint(owner, () async {}),
        throwsStateError,
      );
      suspend.close();
      await expectLater(
        NarrativeRuntimeActivityGate().runSceneCheckpoint(owner, () async {}),
        throwsStateError,
      );
      scene.close();
    },
  );
}
