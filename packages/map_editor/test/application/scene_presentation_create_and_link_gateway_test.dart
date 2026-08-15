import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/scene_presentation_create_and_link_gateway.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:path/path.dart' as p;

void main() {
  test('creates, links and undoes one Presentation transaction', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);

    final draft = fixture.gateway.prepareDraft(
      expectedProject: fixture.project,
      sceneId: 'new_game_intro',
      targetNodeId: 'end',
      title: 'Ouverture d’Avelune',
      templateId: 'blank',
      templateVersion: 1,
      folderId: 'presentation-folder',
    );
    expect(draft.cinematicId, 'ouverture-d-avelune');
    expect(draft.nodeId, 'presentation_ouverture-d-avelune');
    expect(draft.manifest.presentationCinematics, hasLength(1));
    final beforePublish = ProjectManifest.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
              await File(
                p.join(fixture.root.path, 'project.json'),
              ).readAsString(),
            )
            as Map,
      ),
    );
    expect(beforePublish, fixture.project);

    final created = await fixture.gateway.createAndLink(
      fixture.root.path,
      expectedProject: fixture.project,
      sceneId: 'new_game_intro',
      targetNodeId: 'end',
      title: 'Ouverture d’Avelune',
      templateId: 'blank',
      templateVersion: 1,
      folderId: 'presentation-folder',
    );

    expect(created.cinematicId, 'ouverture-d-avelune');
    expect(created.nodeId, 'presentation_ouverture-d-avelune');
    expect(created.receiptId, isNotEmpty);
    expect(created.manifest.presentationCinematics, hasLength(1));
    expect(
      created.manifest.cinematicLibraryCatalog.entryFor(
        CinematicLibraryFamily.presentation,
        created.cinematicId,
      ),
      isNotNull,
    );
    final scene = created.manifest.scenes.single;
    final node = scene.graph.nodes.singleWhere(
      (candidate) => candidate.id == created.nodeId,
    );
    expect(
      (node.payload as ScenePresentationCinematicPayload)
          .presentationCinematicId,
      created.cinematicId,
    );

    final undone = await fixture.gateway.undo(
      fixture.root.path,
      expectedProject: created.manifest,
      transaction: created,
    );

    expect(undone.presentationCinematics, isEmpty);
    expect(undone.cinematicLibraryCatalog.entries, isEmpty);
    expect(undone.scenes.single.graph.nodes, hasLength(2));
  });

  test('guides collisions without asking for an identifier', () async {
    final fixture = await _Fixture.create(
      project: _project().copyWith(
        presentationCinematics: <PresentationCinematicAsset>[
          PresentationCinematicAsset(
            id: 'ouverture',
            title: 'Ouverture existante',
            durationUs: 1000000,
          ),
        ],
        cinematicLibraryCatalog: CinematicLibraryCatalog(
          folders: _folders(),
          entries: <CinematicLibraryEntry>[
            CinematicLibraryEntry(
              family: CinematicLibraryFamily.presentation,
              cinematicId: 'ouverture',
              sortOrder: 0,
            ),
          ],
        ),
      ),
    );
    addTearDown(fixture.dispose);

    final created = await fixture.gateway.createAndLink(
      fixture.root.path,
      expectedProject: fixture.project,
      sceneId: 'new_game_intro',
      targetNodeId: 'end',
      title: 'Ouverture',
      templateId: 'blank',
      templateVersion: 1,
      folderId: null,
    );

    expect(created.cinematicId, 'ouverture-2');
    expect(
      created.manifest.presentationCinematics.map((asset) => asset.id),
      containsAll(<String>['ouverture', 'ouverture-2']),
    );
  });

  test('stale project fails before writing any object', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final stale = fixture.project.copyWith(name: 'Stale projection');

    await expectLater(
      fixture.gateway.createAndLink(
        fixture.root.path,
        expectedProject: stale,
        sceneId: 'new_game_intro',
        targetNodeId: 'end',
        title: 'Ouverture',
        templateId: 'blank',
        templateVersion: 1,
        folderId: null,
      ),
      throwsA(isA<EditorConflictException>()),
    );

    final disk = ProjectManifest.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
              await File(
                p.join(fixture.root.path, 'project.json'),
              ).readAsString(),
            )
            as Map,
      ),
    );
    expect(disk, fixture.project);
    expect(disk.presentationCinematics, isEmpty);
    expect(disk.cinematicLibraryCatalog.entries, isEmpty);
  });
}

final class _Fixture {
  const _Fixture({
    required this.root,
    required this.project,
    required this.gateway,
    required this.mutations,
    required this.queries,
  });

  static Future<_Fixture> create({ProjectManifest? project}) async {
    final root = await Directory.systemTemp.createTemp(
      'scene_presentation_create_link_',
    );
    final initial = project ?? _project();
    await File(p.join(root.path, 'project.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(initial.toJson()),
      flush: true,
    );
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: reader,
    );
    return _Fixture(
      root: root,
      project: initial,
      gateway: CanonicalScenePresentationCreateAndLinkGateway(
        mutations: mutations,
        queries: queries,
      ),
      mutations: mutations,
      queries: queries,
    );
  }

  final Directory root;
  final ProjectManifest project;
  final CanonicalScenePresentationCreateAndLinkGateway gateway;
  final AuthoringMutationAdapter mutations;
  final AuthoringQueryAdapter queries;

  Future<void> dispose() async {
    await mutations.closeAll();
    await queries.closeAll();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

List<CinematicLibraryFolder> _folders() => <CinematicLibraryFolder>[
  CinematicLibraryFolder(
    id: 'presentation-folder',
    family: CinematicLibraryFamily.presentation,
    name: 'Présentation',
    sortOrder: 0,
  ),
];

ProjectManifest _project() => ProjectManifest(
  name: 'Create and link gateway',
  version: ProjectVersion.v7,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  cinematicLibraryCatalog: CinematicLibraryCatalog(folders: _folders()),
  scenes: <SceneAsset>[
    SceneAsset(
      id: 'new_game_intro',
      name: 'Nouvelle partie',
      executionProfile: SceneExecutionProfile.preSession,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: 'ready',
              outcomePolicy: SceneOutcomePolicy.progression,
            ),
          ),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
      declaredOutcomes: <SceneOutcome>[
        SceneOutcome(id: 'ready', label: 'Prêt'),
      ],
    ),
  ],
);
