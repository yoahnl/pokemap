import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/state/narrative_validator_providers.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'the project item catalog resolves Scene references and refreshes',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'narrative_item_catalog_',
      );
      addTearDown(() => root.delete(recursive: true));
      final project = _project();
      await _writeProject(root, project);
      await _writeCatalog(root, const []);
      final request = NarrativeValidatorSnapshotRequest.fromProject(
        projectRootPath: root.path,
        project: project,
      );
      final catalogRequest =
          NarrativeValidatorPokemonCatalogRequest.fromValidationRequest(
            request,
          );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = narrativeValidatorReportProvider(request);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      final first = await container.read(provider.future);
      final firstCatalog = await container.read(
        narrativeValidatorPokemonCatalogSnapshotProvider(catalogRequest).future,
      );
      expect(first.byCode('consequenceUnknownItem'), hasLength(1));
      expect(
        first.byCode('consequenceUnknownItem').single.severity,
        NarrativeProjectDiagnosticSeverity.error,
      );

      await _writeCatalog(root, const [_item]);
      container.invalidate(
        narrativeValidatorPokemonCatalogSnapshotProvider(catalogRequest),
      );
      container.invalidate(provider);
      final second = await container.read(provider.future);
      final secondCatalog = await container.read(
        narrativeValidatorPokemonCatalogSnapshotProvider(catalogRequest).future,
      );

      expect(secondCatalog.fingerprint, isNot(firstCatalog.fingerprint));
      expect(second.byCode('consequenceUnknownItem'), isEmpty);
      expect(
        second.diagnostics.where(
          (entry) => entry.code.contains('ItemCatalogUnavailable'),
        ),
        isEmpty,
      );
    },
  );

  for (final present in [false, true]) {
    test(
      'the snapshot item catalog wins over a contradictory bootstrap catalog '
      'when the item is ${present ? 'present' : 'absent'}',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'narrative_item_catalog_precedence_',
        );
        addTearDown(() => root.delete(recursive: true));
        final project = _project();
        await _writeProject(root, project);
        await _writeCatalog(root, present ? const [_item] : const []);
        await _writeCatalog(
          root,
          present ? const [] : const [_item],
          relativePath: 'data/pokemon/catalogs/items.json',
        );
        await File(
          p.join(root.path, 'data/pokemon/pokemon_data_manifest.json'),
        ).writeAsString(
          jsonEncode({
            'schemaVersion': 1,
            'kind': 'pokemonData',
            'meta': <String, Object?>{},
            'catalogFiles': {'items': 'catalogs/items.json'},
            'futureDataFolders': <String, String>{},
          }),
        );
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = narrativeValidatorReportProvider(
          NarrativeValidatorSnapshotRequest.fromProject(
            projectRootPath: root.path,
            project: project,
          ),
        );
        final subscription = container.listen(provider, (_, _) {});
        addTearDown(subscription.close);

        final report = await container.read(provider.future);

        expect(
          report.byCode('consequenceUnknownItem'),
          present ? isEmpty : hasLength(1),
        );
        if (!present) {
          expect(
            report.byCode('consequenceUnknownItem').single.severity,
            NarrativeProjectDiagnosticSeverity.error,
          );
        }
      },
    );
  }

  test(
    'an unsaved item catalog path wins over the saved project config',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'narrative_item_catalog_unsaved_',
      );
      addTearDown(() => root.delete(recursive: true));
      final saved = _project();
      await _writeProject(root, saved);
      await _writeCatalog(root, const [_item]);
      const unsavedPath = 'draft/items.json';
      await _writeCatalog(root, const [], relativePath: unsavedPath);
      final project = saved.copyWith(
        pokemon: saved.pokemon.copyWith(
          catalogFiles: const {'items': unsavedPath},
        ),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = narrativeValidatorReportProvider(
        NarrativeValidatorSnapshotRequest.fromProject(
          projectRootPath: root.path,
          project: project,
        ),
      );
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      final report = await container.read(provider.future);

      expect(report.byCode('consequenceUnknownItem'), hasLength(1));
      expect(
        report.byCode('consequenceUnknownItem').single.severity,
        NarrativeProjectDiagnosticSeverity.error,
      );
    },
  );

  for (final corrupt in [false, true]) {
    test(
      'a ${corrupt ? 'corrupt' : 'missing'} declared item catalog blocks validation',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'narrative_item_failure_',
        );
        addTearDown(() => root.delete(recursive: true));
        final project = _project();
        await _writeProject(root, project);
        if (corrupt) {
          final file = File(p.join(root.path, _catalogPath));
          await file.parent.create(recursive: true);
          await file.writeAsString('{broken');
        }
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = narrativeValidatorReportProvider(
          NarrativeValidatorSnapshotRequest.fromProject(
            projectRootPath: root.path,
            project: project,
          ),
        );
        final subscription = container.listen(provider, (_, _) {});
        addTearDown(subscription.close);

        await expectLater(
          container.read(provider.future),
          throwsA(
            predicate<Object>(
              (failure) => failure.toString().contains(_catalogPath),
            ),
          ),
        );
      },
    );
  }

  test('an unconfigured item catalog remains explicitly unavailable', () async {
    final root = await Directory.systemTemp.createTemp('narrative_item_unset_');
    addTearDown(() => root.delete(recursive: true));
    final project = _project(configured: false);
    await _writeProject(root, project);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = narrativeValidatorReportProvider(
      NarrativeValidatorSnapshotRequest.fromProject(
        projectRootPath: root.path,
        project: project,
      ),
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    final report = await container.read(provider.future);

    expect(
      report.diagnostics.where(
        (entry) => entry.code.contains('ItemCatalogUnavailable'),
      ),
      hasLength(1),
    );
    expect(report.byCode('consequenceUnknownItem'), isEmpty);
  });

  test('a dialogue Scene needs no item catalog file', () async {
    final root = await Directory.systemTemp.createTemp('narrative_no_items_');
    addTearDown(() => root.delete(recursive: true));
    final project = _project(itemReferences: false);
    await _writeProject(root, project);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = narrativeValidatorReportProvider(
      NarrativeValidatorSnapshotRequest.fromProject(
        projectRootPath: root.path,
        project: project,
      ),
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    expect(
      await container.read(provider.future),
      isA<NarrativeProjectValidationReport>(),
    );
  });
}

const _catalogPath = 'custom/items.json';
const _item = ProjectItemDefinition(
  id: 'ticket_ferry',
  displayName: 'Billet du ferry',
  pocketId: 'key-items',
);

ProjectManifest _project({
  bool configured = true,
  bool itemReferences = true,
}) => ProjectManifest(
  name: 'Item validation',
  maps: const [],
  tilesets: const [],
  pokemon: ProjectPokemonConfig(
    enabled: false,
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    catalogFiles: configured ? const {'items': _catalogPath} : const {},
  ),
  dialogues: [
    if (!itemReferences)
      const ProjectDialogueEntry(
        id: 'welcome',
        name: 'Accueil',
        relativePath: 'dialogues/welcome.yarn',
      ),
  ],
  scenes: [
    SceneAsset(
      id: 'scene.items',
      name: 'Objets',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'give',
            kind: itemReferences
                ? SceneNodeKind.action
                : SceneNodeKind.yarnDialogue,
            payload: itemReferences
                ? SceneActionPayload.consequence(
                    SceneConsequence.giveItem(itemId: _item.id, quantity: 1),
                  )
                : SceneYarnDialoguePayload(dialogueId: 'welcome'),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start.give',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'give',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'give.end',
            fromNodeId: 'give',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    ),
  ],
);

Future<void> _writeProject(Directory root, ProjectManifest project) => File(
  p.join(root.path, 'project.json'),
).writeAsString(jsonEncode(project.toJson()));

Future<void> _writeCatalog(
  Directory root,
  List<ProjectItemDefinition> entries, {
  String relativePath = _catalogPath,
}) async {
  final file = File(p.join(root.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(
    jsonEncode(
      encodeProjectItemCatalog(
        ProjectItemCatalog(schemaVersion: 1, entries: entries),
      ),
    ),
  );
}
