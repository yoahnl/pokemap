import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/verification/data/local_verification_adapter.dart';
import 'package:avelune_studio/features/verification/domain/verification_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

void main() {
  for (final present in [true, false]) {
    test(
      'verification loads the project item catalog with item ${present ? 'present' : 'absent'}',
      () async {
        final root = await _root();
        final project = _project();
        await _writeCatalog(root, present ? const [_item] : const []);

        final analysis = await _adapter(root)
            .analyse(project: project, maps: const [], sources: const [])
            .result;

        final usage = analysis.dependencies.usages.singleWhere(
          (entry) => entry.target.kind == NarrativeDependencyTargetKind.item,
        );
        expect(usage.target.id, _item.id);
        expect(
          usage.resolution,
          present
              ? NarrativeDependencyResolution.resolved
              : NarrativeDependencyResolution.missing,
        );
        expect(
          usage.criticality,
          NarrativeDependencyCriticality.runtimeBlocking,
        );
        expect(
          analysis.validation.byCode('consequenceUnknownItem'),
          present ? isEmpty : hasLength(1),
        );
        if (!present) {
          expect(
            analysis.validation
                .byCode('consequenceUnknownItem')
                .single
                .severity,
            NarrativeProjectDiagnosticSeverity.error,
          );
        }
        expect(
          analysis.validation.diagnostics.where(
            (entry) => entry.code.contains('ItemCatalogUnavailable'),
          ),
          isEmpty,
        );
        expect(analysis.isolateName, 'avelune-verification');
      },
    );
  }

  for (final corrupt in [false, true]) {
    test(
      'a ${corrupt ? 'corrupt' : 'missing'} declared item catalog blocks verification',
      () async {
        final root = await _root();
        if (corrupt) {
          final file = File(p.join(root.path, _catalogPath));
          await file.parent.create(recursive: true);
          await file.writeAsString('{broken');
        }

        await expectLater(
          _adapter(root)
              .analyse(project: _project(), maps: const [], sources: const [])
              .result,
          throwsA(
            isA<VerificationFailure>().having(
              (failure) => failure.message,
              'message',
              contains(_catalogPath),
            ),
          ),
        );
      },
    );
  }

  test(
    'an unconfigured item catalog keeps dependencies unavailable and blocking',
    () async {
      final root = await _root();

      final analysis = await _adapter(root)
          .analyse(
            project: _project(configured: false),
            maps: const [],
            sources: const [],
          )
          .result;

      final usage = analysis.dependencies.usages.singleWhere(
        (entry) => entry.target.kind == NarrativeDependencyTargetKind.item,
      );
      expect(usage.resolution, NarrativeDependencyResolution.unavailable);
      expect(usage.criticality, NarrativeDependencyCriticality.runtimeBlocking);
      expect(
        analysis.validation.diagnostics.where(
          (entry) => entry.code.contains('ItemCatalogUnavailable'),
        ),
        hasLength(1),
      );
    },
  );

  test('a dialogue Scene needs no item catalog file', () async {
    final root = await _root();

    final analysis = await _adapter(root)
        .analyse(
          project: _project(itemReferences: false),
          maps: const [],
          sources: const [],
        )
        .result;

    expect(
      analysis.dependencies.usages.where(
        (entry) => entry.target.kind == NarrativeDependencyTargetKind.item,
      ),
      isEmpty,
    );
  });
}

const _catalogPath = 'custom/items.json';
const _item = ProjectItemDefinition(
  id: 'ticket_ferry',
  displayName: 'Billet du ferry',
  pocketId: 'key-items',
);

Future<Directory> _root() async {
  final temporary = await Directory.systemTemp.createTemp(
    'studio_item_catalog_',
  );
  final root = Directory(await temporary.resolveSymbolicLinks());
  addTearDown(() => root.delete(recursive: true));
  return root;
}

LocalVerificationAdapter _adapter(Directory root) => LocalVerificationAdapter(
  session: ProjectSession(
    sessionId: root.path,
    name: 'Item verification',
    directoryPath: root.path,
  ),
  mapAdapter: LocalMapWorkspaceAdapter(),
);

ProjectManifest _project({
  bool configured = true,
  bool itemReferences = true,
}) => ProjectManifest(
  name: 'Item verification',
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

Future<void> _writeCatalog(
  Directory root,
  List<ProjectItemDefinition> entries,
) async {
  final file = File(p.join(root.path, _catalogPath));
  await file.parent.create(recursive: true);
  await file.writeAsString(
    jsonEncode(
      encodeProjectItemCatalog(
        ProjectItemCatalog(schemaVersion: 1, entries: entries),
      ),
    ),
  );
}
