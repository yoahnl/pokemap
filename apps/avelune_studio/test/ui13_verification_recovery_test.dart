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

/// A real publication through the scene adapter: the workspace adopts a new
/// manifest instance, exactly as saving from the editor does.
Future<void> saveScene(Ui13VerificationHarness h, String name) async {
  expect(
    h.scenes.open(Ui13VerificationHarness.sceneId),
    isTrue,
    reason: h.scenes.error ?? '',
  );
  expect(h.scenes.active!.rename(name), isTrue);
  expect(await h.scenes.save(), isTrue, reason: h.scenes.error ?? '');
}

void main() {
  test('saving during an analysis leaves no ghost control', () async {
    final (h, executor) = await controlled();
    addTearDown(h.dispose);
    final controller = h.withPort(executor);
    addTearDown(controller.dispose);

    final running = controller.run();
    await pumpEventQueue();
    expect(controller.running, isTrue);
    final frozen = controller.workingRevision();
    final manifest = h.narrative.project;

    await saveScene(h, 'Quai enregistré pendant l’analyse');
    expect(
      identical(h.narrative.project, manifest),
      isFalse,
      reason: 'the workspace really adopted another manifest',
    );

    executor.complete(0, project: h.narrative.project, maps: executor.maps);
    expect(await running, isTrue, reason: controller.error);

    expect(
      controller.running,
      isFalse,
      reason: 'a save in the same project never leaves a control in flight',
    );
    expect(controller.phase, VerificationPhase.ready);
    expect(
      controller.report!.freshnessKey,
      frozen,
      reason: 'the result keeps the revision of what it analysed',
    );
    expect(
      controller.stale,
      isTrue,
      reason: 'it stays consultable as old, with its own revision',
    );

    final second = controller.run();
    await pumpEventQueue();
    expect(
      executor.analyses,
      2,
      reason: 'a second control starts without clicking Abandonner',
    );
    executor.complete(1, project: h.narrative.project, maps: executor.maps);
    expect(await second, isTrue, reason: controller.error);
    expect(controller.stale, isFalse);

    final reopened = await Ui13VerificationHarness.open(h.directory);
    addTearDown(() => reopened.dispose(deleteDirectory: false));
    expect(
      reopened.narrative.project.scenes
          .firstWhere((scene) => scene.id == Ui13VerificationHarness.sceneId)
          .name,
      'Quai enregistré pendant l’analyse',
      reason: 'the save really happened and survives a fresh adapter',
    );
  });

  test('a revision that moves during the reads is prepared again', () async {
    final (h, executor) = await controlled();
    addTearDown(h.dispose);
    final controller = h.withPort(executor);
    addTearDown(controller.dispose);

    executor.beforeMaps = () async {
      executor.beforeMaps = null;
      await saveScene(h, 'Quai enregistré pendant la lecture');
    };
    final running = controller.run();
    for (var i = 0; i < 60 && executor.analyses == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(
      executor.analyses,
      1,
      reason: 'the preparation restarts, it does not analyse twice',
    );

    executor.complete(0, project: h.narrative.project, maps: executor.maps);
    expect(await running, isTrue, reason: controller.error);
    expect(controller.running, isFalse);
    expect(
      controller.stale,
      isFalse,
      reason: 'the snapshot was taken after the project settled',
    );
  });

  test('a failed preparation still frees the page', () async {
    final (h, executor) = await controlled();
    addTearDown(h.dispose);
    executor.readFailure = const VerificationFailure('Lecture refusée.');
    final controller = h.withPort(executor);
    addTearDown(controller.dispose);

    expect(await controller.run(), isFalse);
    expect(controller.running, isFalse);
    expect(controller.phase, VerificationPhase.failed);
    expect(controller.error, contains('Lecture refusée'));

    executor.readFailure = null;
    final second = controller.run();
    await pumpEventQueue();
    expect(executor.analyses, 1);
    executor.complete(0, project: h.narrative.project, maps: executor.maps);
    expect(await second, isTrue, reason: controller.error);
  });

  test('a refused input check frees the page too', () async {
    final (h, executor) = await controlled();
    addTearDown(h.dispose);
    final controller = h.withPort(executor)..flushEdits = () async => false;
    addTearDown(controller.dispose);

    expect(await controller.run(), isFalse);
    expect(controller.running, isFalse);
    expect(controller.phase, VerificationPhase.failed);
    expect(controller.error, contains('saisies refusées'));

    controller.flushEdits = () async => true;
    final second = controller.run();
    await pumpEventQueue();
    executor.complete(0, project: h.narrative.project, maps: executor.maps);
    expect(await second, isTrue, reason: controller.error);
  });

  test('the end of a replaced request does not disturb the new one', () async {
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
    expect(controller.running, isTrue);

    // Request A answers late, while B is still working.
    executor.complete(0, project: h.narrative.project, maps: executor.maps);
    await pumpEventQueue();
    expect(
      controller.running,
      isTrue,
      reason: 'the older request never takes B out of its work',
    );
    expect(controller.report, isNull);
    expect(controller.error, isNull);

    executor.complete(1, project: h.narrative.project, maps: executor.maps);
    expect(await second, isTrue, reason: controller.error);
    expect(controller.report, isNotNull);
    expect(controller.phase, VerificationPhase.ready);
  });
}
