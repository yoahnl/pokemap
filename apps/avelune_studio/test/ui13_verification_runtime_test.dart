import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:avelune_studio/features/verification/data/local_verification_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/ui13_verification_harness.dart';

Future<void> writeReceipt(
  Ui13VerificationHarness h,
  Map<String, Object?> body,
) async {
  final file = File(
    '${h.directory.path}/${LocalVerificationAdapter.receiptPath}',
  );
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(body));
}

Map<String, Object?> receipt({
  required String fingerprint,
  String profileId = 'selbrume-release-v1',
  int profileVersion = 1,
  List<String> suiteIds = const [
    'selbrume-lighthouse-retry',
    'selbrume-player-journey',
  ],
  String result = 'pass',
}) => {
  'schemaVersion': 1,
  'projectFingerprint': fingerprint,
  'validatorVersion': 'narrative-validator-v1',
  'profileId': profileId,
  'profileVersion': profileVersion,
  'suiteIds': suiteIds,
  'fixtureId': 'fixture-ui13',
  'result': result,
  'completedAt': DateTime.utc(2026, 9, 21, 12).toIso8601String(),
  'limitations': <String>[],
};

const _otherFingerprint =
    'sha256:1111111111111111111111111111111111111111111111111111111111111111';

Future<VerificationRuntimeEvidence> evidenceOf(Ui13VerificationHarness h) =>
    h.port.readRuntimeEvidence(selbrumeReleaseV1Profile);

void main() {
  test('a receipt of another version is stale, never a success', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    await writeReceipt(h, receipt(fingerprint: _otherFingerprint));
    final evidence = await evidenceOf(h);
    expect(evidence.state, VerificationRuntimeState.stale);
    expect(evidence.status, NarrativeValidationStatus.notRun);
    expect(evidence.reason, contains('une autre version'));
  });

  test('a receipt of another profile is refused with its provenance', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    await writeReceipt(
      h,
      receipt(fingerprint: _otherFingerprint, profileId: 'autre-profil'),
    );
    final evidence = await evidenceOf(h);
    expect(evidence.state, VerificationRuntimeState.profileMismatch);
    expect(evidence.status, NarrativeValidationStatus.notRun);
    expect(evidence.reason, contains('autre-profil'));
    expect(evidence.receipt, isNotNull);
  });

  test('a receipt missing a required suite stays inconclusive', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    await writeReceipt(
      h,
      receipt(
        fingerprint: _otherFingerprint,
        suiteIds: const ['selbrume-lighthouse-retry'],
      ),
    );
    final evidence = await evidenceOf(h);
    expect(evidence.state, VerificationRuntimeState.incompleteSuites);
    expect(evidence.reason, contains('selbrume-player-journey'));
  });

  test('an unreadable receipt is reported, not ignored', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    await writeReceipt(h, {'schemaVersion': 1});
    final evidence = await evidenceOf(h);
    expect(evidence.state, VerificationRuntimeState.invalid);
    expect(evidence.status, NarrativeValidationStatus.notRun);
  });

  test('a matching receipt is the only one that verifies runtime', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    final adapter = LocalVerificationAdapter(
      session: h.session,
      mapAdapter: h.adapter,
    );
    final fingerprint = await adapter.projectFingerprint();
    await writeReceipt(h, receipt(fingerprint: fingerprint));
    final evidence = await evidenceOf(h);
    expect(evidence.state, VerificationRuntimeState.freshPass);
    expect(evidence.status, NarrativeValidationStatus.pass);

    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    final dimensions = h.verification.report!.dimensions;
    expect(
      dimensions.runtimeSmokeVerified.status,
      NarrativeValidationStatus.pass,
    );
    expect(
      dimensions.isPlayable,
      isFalse,
      reason: 'a green runtime never covers a failing structure',
    );
  });

  test('a failed run of this version is a failure, not a notRun', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    final adapter = LocalVerificationAdapter(
      session: h.session,
      mapAdapter: h.adapter,
    );
    await writeReceipt(
      h,
      receipt(fingerprint: await adapter.projectFingerprint(), result: 'fail'),
    );
    final evidence = await evidenceOf(h);
    expect(evidence.state, VerificationRuntimeState.freshFail);
    expect(evidence.status, NarrativeValidationStatus.fail);
  });
}
