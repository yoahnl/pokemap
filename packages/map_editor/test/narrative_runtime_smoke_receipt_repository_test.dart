import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  test('fingerprint includes manifest, maps and Yarn but excludes receipt',
      () async {
    final root = await Directory.systemTemp.createTemp('receipt_repo_');
    addTearDown(() => root.delete(recursive: true));
    await File(p.join(root.path, 'project.json')).writeAsString('{}');
    await Directory(p.join(root.path, 'maps')).create();
    await File(p.join(root.path, 'maps', 'a.json')).writeAsString('{"id":"a"}');
    await Directory(p.join(root.path, 'dialogues')).create();
    final yarn = File(p.join(root.path, 'dialogues', 'intro.yarn'));
    await yarn.writeAsString('title: Intro');
    await Directory(p.join(root.path, 'assets')).create();
    final media = File(p.join(root.path, 'assets', 'large.bin'));
    await media.writeAsBytes(
      List<int>.generate(200000, (index) => index % 251),
    );
    const repository = NarrativeRuntimeSmokeReceiptRepository();

    final before = await repository.computeProjectFingerprint(root.path);
    expect(
      before,
      computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'assets/large.bin',
          bytes: await media.readAsBytes(),
        ),
        NarrativeProjectFingerprintEntry(
          relativePath: 'dialogues/intro.yarn',
          bytes: await yarn.readAsBytes(),
        ),
        NarrativeProjectFingerprintEntry(
          relativePath: 'maps/a.json',
          bytes: await File(p.join(root.path, 'maps', 'a.json')).readAsBytes(),
        ),
        NarrativeProjectFingerprintEntry(
          relativePath: 'project.json',
          bytes: await File(p.join(root.path, 'project.json')).readAsBytes(),
        ),
      ]),
    );
    await yarn.writeAsString('title: Changed');
    final afterYarn = await repository.computeProjectFingerprint(root.path);
    expect(afterYarn, isNot(before));

    final receiptFile = File(
      p.join(root.path,
          NarrativeRuntimeSmokeReceiptRepository.relativeReceiptPath),
    );
    await receiptFile.parent.create(recursive: true);
    await receiptFile.writeAsString('{}');
    expect(await repository.computeProjectFingerprint(root.path), afterYarn);
  });

  test('absent, stale, partial and fresh receipts never alias', () async {
    final root = await Directory.systemTemp.createTemp('receipt_states_');
    addTearDown(() => root.delete(recursive: true));
    await File(p.join(root.path, 'project.json')).writeAsString('{}');
    const repository = NarrativeRuntimeSmokeReceiptRepository();
    final fingerprint = await repository.computeProjectFingerprint(root.path);
    final absent = await repository.read(
      projectRoot: root.path,
      expectedFingerprint: fingerprint,
      profile: selbrumeReleaseV1Profile,
    );
    expect(absent.state, NarrativeRuntimeReceiptState.absent);

    final file = File(
      p.join(root.path,
          NarrativeRuntimeSmokeReceiptRepository.relativeReceiptPath),
    );
    await file.parent.create(recursive: true);
    Future<void> write(
            {required String digest, required List<String> suites}) =>
        file.writeAsString(jsonEncode(NarrativeRuntimeSmokeReceipt(
          projectFingerprint: digest,
          validatorVersion: 'v1',
          profileId: selbrumeReleaseV1Profile.id,
          profileVersion: 1,
          suiteIds: suites,
          fixtureId: 'selbrume',
          result: NarrativeRuntimeSmokeResult.pass,
          completedAt: DateTime.utc(2026),
        ).toJson()));

    await write(
        digest: 'sha256:${'d' * 64}',
        suites: selbrumeReleaseV1Profile.requiredSuiteIds);
    expect(
      (await repository.read(
              projectRoot: root.path,
              expectedFingerprint: fingerprint,
              profile: selbrumeReleaseV1Profile))
          .state,
      NarrativeRuntimeReceiptState.stale,
    );
    await write(digest: fingerprint, suites: ['selbrume-lighthouse-retry']);
    expect(
      (await repository.read(
              projectRoot: root.path,
              expectedFingerprint: fingerprint,
              profile: selbrumeReleaseV1Profile))
          .state,
      NarrativeRuntimeReceiptState.incompleteSuites,
    );
    await write(
        digest: fingerprint, suites: selbrumeReleaseV1Profile.requiredSuiteIds);
    expect(
      (await repository.read(
              projectRoot: root.path,
              expectedFingerprint: fingerprint,
              profile: selbrumeReleaseV1Profile))
          .state,
      NarrativeRuntimeReceiptState.freshPass,
    );
  });
}
