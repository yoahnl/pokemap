import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../tool/verify_narrative_project.dart';

void main() {
  test('host and core produce the same complete project fingerprint', () async {
    final root = await Directory.systemTemp.createTemp('host_fingerprint_');
    addTearDown(() => root.delete(recursive: true));
    final project = File(p.join(root.path, 'project.json'));
    final map = File(p.join(root.path, 'maps', 'a.json'));
    await map.parent.create(recursive: true);
    await project.writeAsString('{}');
    await map.writeAsString('{"id":"a"}');

    final host = await fingerprintNarrativeProjectDirectory(root.path);
    final core = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: await project.readAsBytes(),
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/a.json',
        bytes: await map.readAsBytes(),
      ),
    ]);
    expect(host, core);
  });

  test('release verification records every mandatory suite', () async {
    final root = await Directory.systemTemp.createTemp('host_verify_');
    addTearDown(() => root.delete(recursive: true));
    await File(p.join(root.path, 'project.json')).writeAsString('{}');
    final executed = <String>[];
    final receipt = await verifyNarrativeProject(
      projectRoot: root.path,
      profile: selbrumeReleaseV1Profile,
      suiteRunner: (suiteId, _) async {
        executed.add(suiteId);
        return true;
      },
      completedAt: DateTime.utc(2026),
    );
    expect(executed, selbrumeReleaseV1Profile.requiredSuiteIds);
    expect(receipt?.result, NarrativeRuntimeSmokeResult.pass);
  });
}
