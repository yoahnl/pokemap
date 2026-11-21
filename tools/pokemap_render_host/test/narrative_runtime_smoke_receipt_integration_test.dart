import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../tool/verify_narrative_project.dart';

import 'support/runtime_smoke_profile_fixture.dart';

void main() {
  test('generic harness keeps its explicit policy and suite data', () async {
    final profile = NarrativeRuntimeSmokeProfile.fromJson(
      jsonDecode(
        await File('test/fixtures/runtime_smoke_profile.json').readAsString(),
      ),
    );
    final suites = await loadNarrativeSuiteManifest(
      File('test/runtime_smoke_suites.json'),
    );
    expect(suites.keys.toSet(), profile.requiredSuiteIds.toSet());
    for (final path in suites.values) {
      expect(await File(path).exists(), isTrue);
    }
  });

  test(
    'suite mappings are explicit data and cannot escape their directory',
    () async {
      final root = await Directory.systemTemp.createTemp('suite-manifest-');
      addTearDown(() => root.delete(recursive: true));
      final suite = File('${root.path}/smoke_test.dart');
      await suite.writeAsString('void main() {}');
      final manifest = File('${root.path}/suites.json');
      await manifest.writeAsString(
        jsonEncode({
          'schemaVersion': 1,
          'suites': {'arbitrary-suite': 'smoke_test.dart'},
        }),
      );
      expect(await loadNarrativeSuiteManifest(manifest), {
        'arbitrary-suite': await suite.resolveSymbolicLinks(),
      });
      for (final path in [
        '../outside.dart',
        '/tmp/outside.dart',
        'folder/../smoke_test.dart',
      ]) {
        await manifest.writeAsString(
          jsonEncode({
            'schemaVersion': 1,
            'suites': {'suite': path},
          }),
        );
        await expectLater(
          loadNarrativeSuiteManifest(manifest),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'verification does not invent a policy or certify a changing project',
    () async {
      final root = await Directory.systemTemp.createTemp('explicit-policy-');
      addTearDown(() => root.delete(recursive: true));
      final projectFile = File('${root.path}/project.json');
      final project = ProjectManifest(
        name: 'No default policy',
        maps: [],
        tilesets: [],
      );
      await projectFile.writeAsString(jsonEncode(project.toJson()));
      var runs = 0;
      Future<bool> run(String id, String path) async {
        runs++;
        return true;
      }

      expect(
        await verifyNarrativeProject(
          projectRoot: root.path,
          suitePaths: {},
          suiteRunner: run,
        ),
        isNull,
      );
      expect(runs, 0);
      await projectFile.writeAsString(
        jsonEncode(
          project
              .copyWith(runtimeSmokeProfile: runtimeSmokeProfileFixture)
              .toJson(),
        ),
      );
      final paths = {
        for (final id in runtimeSmokeProfileFixture.requiredSuiteIds)
          id: '$id.dart',
      };
      expect(
        await verifyNarrativeProject(
          projectRoot: root.path,
          suitePaths: {},
          suiteRunner: run,
        ),
        isNull,
      );
      expect(
        await verifyNarrativeProject(
          projectRoot: root.path,
          suitePaths: paths,
          suiteRunner: (id, path) async {
            await File('${root.path}/changed.json').writeAsString(id);
            return true;
          },
        ),
        isNull,
      );
    },
  );

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
    await File(p.join(root.path, 'project.json')).writeAsString(
      jsonEncode(
        ProjectManifest(
          name: 'Smoke fixture',
          maps: [],
          tilesets: [],
          runtimeSmokeProfile: runtimeSmokeProfileFixture,
        ).toJson(),
      ),
    );
    final executed = <String>[];
    final receipt = await verifyNarrativeProject(
      projectRoot: root.path,
      suitePaths: {
        for (final id in runtimeSmokeProfileFixture.requiredSuiteIds)
          id: 'test/$id.dart',
      },
      suiteRunner: (suiteId, _) async {
        executed.add(suiteId);
        return true;
      },
      completedAt: DateTime.utc(2026),
    );
    expect(executed, runtimeSmokeProfileFixture.requiredSuiteIds);
    expect(receipt?.result, NarrativeRuntimeSmokeResult.pass);
    expect(
      receipt?.limitations,
      contains(
        'PARTIAL / NO-GO baseline: runtime smoke only; FG-185 is not promoted.',
      ),
    );
  });
}
