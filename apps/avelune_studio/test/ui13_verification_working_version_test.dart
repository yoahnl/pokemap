import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:avelune_studio/features/verification/data/local_verification_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/ui13_controllable_verification_port.dart';
import 'support/ui13_verification_harness.dart';

Future<void> renameScene(Ui13VerificationHarness h, String name) async {
  expect(
    h.scenes.open(Ui13VerificationHarness.sceneId),
    isTrue,
    reason: h.scenes.error ?? '',
  );
  expect(h.scenes.active!.rename(name), isTrue);
}

bool labelled(VerificationReport report, String name) =>
    report.labels.values.contains(name);

Future<String> projectJson(Ui13VerificationHarness h) =>
    File('${h.directory.path}/project.json').readAsString();

void main() {
  test('a scene renamed in its editor is analysed without saving', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    final before = await projectJson(h);
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    expect(labelled(h.verification.report!, 'Rencontre en gare'), isTrue);
    expect(
      h.verification.report!.drafted,
      isFalse,
      reason: 'nothing was open yet, so the saved version was the subject',
    );

    await renameScene(h, 'Quai réaménagé');
    expect(
      h.verification.stale,
      isTrue,
      reason: 'an unsaved scene moves the working version',
    );
    expect(
      labelled(h.verification.report!, 'Quai réaménagé'),
      isFalse,
      reason: 'the old report is a snapshot, never recomputed in silence',
    );

    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    expect(
      labelled(h.verification.report!, 'Quai réaménagé'),
      isTrue,
      reason: 'the draft is what the new control analysed',
    );
    expect(h.verification.report!.drafted, isTrue);
    expect(h.verification.stale, isFalse);
    expect(
      await projectJson(h),
      before,
      reason: 'analysing a draft never publishes it',
    );
  });

  test('a second change and an undo then another change both count', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    final first = h.verification.report!.freshnessKey;

    await renameScene(h, 'Quai un');
    final second = h.verification.workingRevision();
    expect(second, isNot(first));

    await renameScene(h, 'Quai deux');
    final third = h.verification.workingRevision();
    expect(
      third,
      isNot(second),
      reason: 'a second edit of an already edited document still counts',
    );

    expect(h.scenes.active!.canUndo, isTrue);
    h.scenes.active!.restore(redo: false);
    await renameScene(h, 'Quai trois');
    expect(
      h.verification.workingRevision(),
      isNot(third),
      reason: 'undo then another edit is a new content, not the old one',
    );
    expect(h.verification.stale, isTrue);
  });

  test('a change during a held analysis leaves the report old', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    final maps = await h.port.loadMaps();
    final executor = Ui13ControllableVerificationPort(
      revision: await h.port.projectRevision(),
      maps: maps,
      evidence: await h.port.readRuntimeEvidence(selbrumeReleaseV1Profile),
    );
    final controller = h.withPort(executor);
    addTearDown(controller.dispose);

    final frozen = controller.workingRevision();
    final running = controller.run();
    await pumpEventQueue();
    expect(executor.analyses, 1);

    await renameScene(h, 'Quai changé pendant l’analyse');
    expect(controller.workingRevision(), isNot(frozen));

    executor.complete(0, project: h.narrative.project, maps: maps);
    expect(await running, isTrue, reason: controller.error);
    expect(
      controller.report!.freshnessKey,
      frozen,
      reason: 'the result keeps the revision of what it analysed',
    );
    expect(
      controller.stale,
      isTrue,
      reason: 'it is kept as old, never stamped with the newer revision',
    );
  });

  test('the fingerprint describes the analysed inputs, nothing else', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    final adapter = LocalVerificationAdapter(
      session: h.session,
      mapAdapter: h.adapter,
    );
    final disk = await adapter.projectFingerprint();
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    final report = h.verification.report!;

    expect(report.inputFingerprint, startsWith('sha256:'));
    expect(
      report.dimensions.projectFingerprint,
      report.inputFingerprint,
      reason: 'the multidimensional report describes its own entries',
    );
    expect(
      report.dimensions.projectFingerprint,
      isNot(disk),
      reason: 'a manifest re-encoding is not the raw file tree contract',
    );
    expect(
      report.dimensions.projectFingerprint,
      isNot(contains('0000000000000000')),
      reason: 'a missing receipt never becomes a fingerprint of zeros',
    );

    final firstPrint = report.inputFingerprint;
    await renameScene(h, 'Quai autrement');
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    expect(
      h.verification.report!.inputFingerprint,
      isNot(firstPrint),
      reason: 'different entries, different fingerprint',
    );
  });

  test('a receipt of the saved version does not certify a draft', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    final adapter = LocalVerificationAdapter(
      session: h.session,
      mapAdapter: h.adapter,
    );
    final file = File(
      '${h.directory.path}/${LocalVerificationAdapter.receiptPath}',
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'projectFingerprint': await adapter.projectFingerprint(),
        'validatorVersion': 'narrative-validator-v1',
        'profileId': selbrumeReleaseV1Profile.id,
        'profileVersion': selbrumeReleaseV1Profile.version,
        'suiteIds': selbrumeReleaseV1Profile.requiredSuiteIds,
        'fixtureId': 'fixture-ui13',
        'result': 'pass',
        'completedAt': DateTime.utc(2026, 9, 21, 12).toIso8601String(),
        'limitations': <String>[],
      }),
    );

    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    expect(
      h.verification.report!.dimensions.runtimeSmokeVerified.status,
      NarrativeValidationStatus.pass,
      reason: 'with no draft, the saved version is what was analysed',
    );

    await renameScene(h, 'Quai non enregistré');
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    final runtime = h.verification.report!.dimensions.runtimeSmokeVerified;
    expect(
      runtime.status,
      NarrativeValidationStatus.notRun,
      reason: 'the proof describes the disk, not these entries',
    );
    expect(runtime.limitations.first, contains('ne certifie pas ces entrées'));
    expect(
      h.verification.report!.runtime.state,
      VerificationRuntimeState.freshPass,
      reason: 'the saved proof stays consultable, with its own scope',
    );
  });
}
