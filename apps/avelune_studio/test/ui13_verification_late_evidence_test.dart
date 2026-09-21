import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/ui13_controllable_verification_port.dart';
import 'support/ui13_verification_harness.dart';

Future<(Ui13VerificationHarness, Ui13ControllableVerificationPort)>
controlled() async {
  final h = await Ui13VerificationHarness.create();
  final executor = Ui13ControllableVerificationPort(
    revision: await h.port.projectRevision(),
    maps: await h.port.loadMaps(),
    evidence: await h.port.readRuntimeEvidence(selbrumeReleaseV1Profile),
    sources: await h.port.readDialogueSources(h.narrative.project.dialogues),
  );
  return (h, executor);
}

/// Brings a request up to its held runtime proof read: its analysis is done,
/// only the last read is still open.
Future<void> reachEvidence(
  Ui13VerificationHarness h,
  Ui13ControllableVerificationPort executor,
  int index,
) async {
  for (var i = 0; i < 20 && executor.analyses <= index; i++) {
    await pumpEventQueue();
  }
  executor.complete(index, project: h.narrative.project, maps: executor.maps);
  for (var i = 0; i < 20 && executor.evidenceCalls.length <= index; i++) {
    await pumpEventQueue();
  }
  expect(
    executor.evidenceCalls.length,
    index + 1,
    reason: 'the request is waiting on its runtime proof',
  );
}

void main() {
  test(
    'an abandoned control never replaces the report that followed',
    () async {
      final (h, executor) = await controlled();
      addTearDown(h.dispose);
      final controller = h.withPort(executor);
      addTearDown(controller.dispose);

      executor.holdEvidence = true;
      final first = controller.run();
      await reachEvidence(h, executor, 0);
      controller.abandon();

      executor.holdEvidence = false;
      final second = controller.run();
      for (var i = 0; i < 20 && executor.analyses < 2; i++) {
        await pumpEventQueue();
      }
      executor.complete(1, project: h.narrative.project, maps: executor.maps);
      expect(await second, isTrue, reason: controller.error);

      final adopted = controller.report!;
      controller.select(adopted.diagnostics.first.stableKey);
      final selection = controller.selectedKey;
      final phase = controller.phase;

      // The abandoned request answers now, after the newer one settled.
      executor.releaseEvidence(0);
      expect(await first, isFalse);

      expect(
        identical(controller.report, adopted),
        isTrue,
        reason: 'the report stays the one the last request produced',
      );
      expect(controller.report!.requestId, adopted.requestId);
      expect(controller.selectedKey, selection);
      expect(controller.selectionNotice, isNull);
      expect(controller.phase, phase);
      expect(controller.error, isNull);
    },
  );

  test('an abandoned control does not disturb the one still working', () async {
    final (h, executor) = await controlled();
    addTearDown(h.dispose);
    final controller = h.withPort(executor);
    addTearDown(controller.dispose);

    executor.holdEvidence = true;
    final first = controller.run();
    await reachEvidence(h, executor, 0);
    controller.abandon();

    final second = controller.run();
    for (var i = 0; i < 20 && executor.analyses < 2; i++) {
      await pumpEventQueue();
    }
    expect(controller.running, isTrue);

    executor.releaseEvidence(0);
    expect(await first, isFalse);
    expect(
      controller.running,
      isTrue,
      reason: 'the newer request keeps working',
    );
    expect(controller.report, isNull);
    expect(controller.error, isNull);

    executor.complete(1, project: h.narrative.project, maps: executor.maps);
    for (var i = 0; i < 20 && executor.evidenceCalls.length < 2; i++) {
      await pumpEventQueue();
    }
    executor.releaseEvidence(1);
    expect(await second, isTrue, reason: controller.error);
    expect(controller.report, isNotNull);
    expect(controller.phase, VerificationPhase.ready);
  });

  test(
    'closing during the proof read adopts nothing and stays quiet',
    () async {
      final (h, executor) = await controlled();
      addTearDown(h.dispose);
      final controller = h.withPort(executor);

      executor.holdEvidence = true;
      final first = controller.run();
      await reachEvidence(h, executor, 0);

      controller.dispose();
      final notifications = h.changes;
      executor.releaseEvidence(0);
      expect(await first, isFalse);
      expect(controller.report, isNull);
      expect(
        h.changes,
        notifications,
        reason: 'a disposed view is never notified again',
      );
    },
  );

  test('a failed proof read stays recoverable', () async {
    final (h, executor) = await controlled();
    addTearDown(h.dispose);
    final controller = h.withPort(executor);
    addTearDown(controller.dispose);

    executor.holdEvidence = true;
    final first = controller.run();
    await reachEvidence(h, executor, 0);
    executor.releaseEvidence(
      0,
      failure: const VerificationFailure('Preuve illisible.'),
    );
    expect(await first, isFalse);
    expect(controller.phase, VerificationPhase.failed);
    expect(controller.error, contains('Preuve illisible'));
    expect(controller.report, isNull);

    executor.holdEvidence = false;
    final second = controller.run();
    for (var i = 0; i < 20 && executor.analyses < 2; i++) {
      await pumpEventQueue();
    }
    executor.complete(1, project: h.narrative.project, maps: executor.maps);
    expect(await second, isTrue, reason: controller.error);
    expect(controller.error, isNull);
  });

  test('a late failure of a replaced request is not the new error', () async {
    final (h, executor) = await controlled();
    addTearDown(h.dispose);
    final controller = h.withPort(executor);
    addTearDown(controller.dispose);

    executor.holdEvidence = true;
    final first = controller.run();
    await reachEvidence(h, executor, 0);
    controller.abandon();

    executor.holdEvidence = false;
    final second = controller.run();
    for (var i = 0; i < 20 && executor.analyses < 2; i++) {
      await pumpEventQueue();
    }
    executor.complete(1, project: h.narrative.project, maps: executor.maps);
    expect(await second, isTrue, reason: controller.error);

    executor.releaseEvidence(
      0,
      failure: const VerificationFailure('Preuve illisible.'),
    );
    expect(await first, isFalse);
    expect(
      controller.error,
      isNull,
      reason: 'the older request’s failure never becomes the newer one’s',
    );
    expect(controller.phase, VerificationPhase.ready);
    expect(controller.report, isNotNull);
  });
}
