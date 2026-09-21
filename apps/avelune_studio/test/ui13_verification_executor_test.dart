import 'dart:isolate';

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
  );
  return (h, executor);
}

void main() {
  test('the real analysis runs outside the interface isolate', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    final name = h.verification.report!.isolateName;
    expect(
      name,
      isNot(Isolate.current.debugName),
      reason: 'the validators must not run where the interface builds',
    );
    expect(name, 'avelune-verification');
  });

  test('abandoning stops the work and adopts nothing', () async {
    final (h, executor) = await controlled();
    addTearDown(h.dispose);
    final controller = h.withPort(executor);
    addTearDown(controller.dispose);

    final running = controller.run();
    await pumpEventQueue();
    expect(executor.analyses, 1);
    expect(controller.running, isTrue);

    controller.abandon();
    expect(
      executor.cancelled,
      [0],
      reason: 'the job owned by this request is the one that stops',
    );
    expect(await running, isFalse);
    expect(controller.report, isNull);
    expect(controller.phase, VerificationPhase.cancelled);
  });

  test('a late reply never takes the place of the current state', () async {
    final (h, executor) = await controlled();
    addTearDown(h.dispose);
    final controller = h.withPort(executor);
    addTearDown(controller.dispose);

    final running = controller.run();
    await pumpEventQueue();
    controller.abandon();
    expect(await running, isFalse);

    executor.complete(0, project: h.narrative.project, maps: executor.maps);
    await pumpEventQueue();
    expect(
      controller.report,
      isNull,
      reason: 'an answer from an abandoned request is dropped',
    );
    expect(controller.phase, VerificationPhase.cancelled);
  });

  test('a replacing request keeps only its own answer', () async {
    final (h, executor) = await controlled();
    addTearDown(h.dispose);
    final controller = h.withPort(executor);
    addTearDown(controller.dispose);

    final first = controller.run();
    await pumpEventQueue();
    controller.abandon();
    expect(await first, isFalse);

    final second = controller.run();
    await pumpEventQueue();
    expect(executor.analyses, 2);

    executor.complete(0, project: h.narrative.project, maps: executor.maps);
    await pumpEventQueue();
    expect(
      controller.report,
      isNull,
      reason: 'the replaced request answers into the void',
    );

    executor.complete(1, project: h.narrative.project, maps: executor.maps);
    expect(await second, isTrue, reason: controller.error);
    expect(controller.report, isNotNull);
  });

  test('closing the page drops the work and its answer', () async {
    final (h, executor) = await controlled();
    addTearDown(h.dispose);
    final controller = h.withPort(executor);

    final running = controller.run();
    await pumpEventQueue();
    controller.dispose();
    expect(executor.cancelled, [0]);
    expect(await running, isFalse);

    executor.complete(0, project: h.narrative.project, maps: executor.maps);
    await pumpEventQueue();
    expect(controller.report, isNull);
  });

  test('a failed read leaves no synthetic green report', () async {
    final (h, executor) = await controlled();
    addTearDown(h.dispose);
    executor.readFailure = const VerificationFailure('Lecture refusée.');
    final controller = h.withPort(executor);
    addTearDown(controller.dispose);

    expect(await controller.run(), isFalse);
    expect(controller.phase, VerificationPhase.failed);
    expect(controller.report, isNull);
    expect(controller.error, contains('Lecture refusée'));
    expect(
      executor.analyses,
      0,
      reason: 'nothing is analysed when the entries could not be read',
    );
  });

  test('a second launch while one runs starts no second job', () async {
    final (h, executor) = await controlled();
    addTearDown(h.dispose);
    final controller = h.withPort(executor);
    addTearDown(controller.dispose);

    final first = controller.run();
    await pumpEventQueue();
    expect(await controller.run(), isFalse);
    expect(executor.analyses, 1);
    executor.complete(0, project: h.narrative.project, maps: executor.maps);
    expect(await first, isTrue, reason: controller.error);
  });
}
