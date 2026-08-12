import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/debug/marionette_personalization_qa_seed.dart';
import 'package:map_editor/src/debug/marionette_project_bootstrap.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'creates a complete personalization project inside the sandbox',
    () async {
      final sandbox = Directory.systemTemp.createTempSync(
        'pokemap_personalization_seed_',
      );
      addTearDown(() => sandbox.deleteSync(recursive: true));

      final projectRoot = await MarionettePersonalizationQaSeed.create(
        sandboxRoot: sandbox,
        runId: 'phase-b2-seed',
        loadAsset: (path) async => path.endsWith('mark.png')
            ? const <int>[1, 2, 3]
            : const <int>[4, 5, 6],
      );
      final bootstrap = MarionetteProjectBootstrap.load(projectRoot.path);

      expect(bootstrap.manifest.name, 'QA Personalization Studio');
      expect(bootstrap.manifest.maps.single.id, 'qa_village');
      expect(bootstrap.manifest.dialogues.single.id, 'qa_welcome');
      expect(bootstrap.manifest.characters.single.id, 'qa_leo');
      expect(bootstrap.manifest.encounterTables.single.id, 'qa_grass');
      expect(
        File(
          p.join(projectRoot.path, 'assets', '.pokemap-assets.json'),
        ).existsSync(),
        isTrue,
      );
    },
  );

  test(
    'reuses the same seed root after restart without erasing saves',
    () async {
      final sandbox = Directory.systemTemp.createTempSync(
        'pokemap_personalization_seed_',
      );
      addTearDown(() => sandbox.deleteSync(recursive: true));
      Future<List<int>> loadAsset(String _) async => const <int>[1, 2, 3];
      final first = await MarionettePersonalizationQaSeed.create(
        sandboxRoot: sandbox,
        runId: 'restart-proof',
        loadAsset: loadAsset,
      );
      final manifestFile = File(p.join(first.path, 'project.json'));
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      manifest['name'] = 'Persisted after restart';
      manifestFile.writeAsStringSync(jsonEncode(manifest));

      final second = await MarionettePersonalizationQaSeed.create(
        sandboxRoot: sandbox,
        runId: 'restart-proof',
        loadAsset: loadAsset,
      );

      expect(second.path, first.path);
      expect(
        MarionetteProjectBootstrap.load(second.path).manifest.name,
        'Persisted after restart',
      );
    },
  );

  test('rejects unsafe seed run identifiers', () async {
    final sandbox = Directory.systemTemp.createTempSync(
      'pokemap_personalization_seed_',
    );
    addTearDown(() => sandbox.deleteSync(recursive: true));

    expect(
      () => MarionettePersonalizationQaSeed.create(
        sandboxRoot: sandbox,
        runId: '../escape',
        loadAsset: (_) async => const <int>[1],
      ),
      throwsArgumentError,
    );
  });
}
