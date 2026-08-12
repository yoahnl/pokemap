import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/debug/marionette_personalization_qa_seed.dart';
import 'package:map_editor/src/debug/marionette_project_bootstrap.dart';
import 'package:map_editor/src/features/personalization/application/personalization_preview_context_source.dart';
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
      expect(bootstrap.manifest.scenes.single.id, 'scene.personalization.qa');
      expect(bootstrap.manifest.eventRegistry?.records, hasLength(1));
      expect(bootstrap.manifest.pokemon.enabled, isTrue);
      expect(
        File(
          p.join(projectRoot.path, 'assets', '.pokemap-assets.json'),
        ).existsSync(),
        isTrue,
      );
      for (final relativePath in <String>[
        'data/pokemon/catalogs/moves.json',
        'data/pokemon/species/0001-bulbasaur.json',
        'data/pokemon/learnsets/bulbasaur.json',
        'data/pokemon/evolutions/bulbasaur.json',
      ]) {
        expect(
          File(p.join(projectRoot.path, relativePath)).existsSync(),
          isTrue,
          reason: relativePath,
        );
      }
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

  test('exposes ready map dialogue portrait and encounter contexts', () async {
    final sandbox = Directory.systemTemp.createTempSync(
      'pokemap_personalization_seed_',
    );
    addTearDown(() => sandbox.deleteSync(recursive: true));
    final projectRoot = await MarionettePersonalizationQaSeed.create(
      sandboxRoot: sandbox,
      runId: 'preview-contexts',
      loadAsset: (_) async => const <int>[1, 2, 3],
    );
    final container = ProviderContainer();
    addTearDown(() async {
      await container.read(editorAuthoringSessionLifecycleProvider).closeAll();
      container.dispose();
    });

    final contexts = await container
        .read(personalizationPreviewContextSourceProvider)
        .load(projectRoot.path);

    for (final kind in <PersonalizationPreviewContextKind>[
      PersonalizationPreviewContextKind.map,
      PersonalizationPreviewContextKind.dialogueScenario,
      PersonalizationPreviewContextKind.characterPortrait,
      PersonalizationPreviewContextKind.encounter,
    ]) {
      expect(
        contexts.where((context) => context.kind == kind && context.isReady),
        isNotEmpty,
        reason: '$kind: ${contexts.map((context) => context.detail)}',
      );
    }
  });
}
