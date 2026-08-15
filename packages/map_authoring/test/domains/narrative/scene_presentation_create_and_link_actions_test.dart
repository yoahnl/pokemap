import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene Presentation create-and-link action', () {
    test('publishes one atomic discoverable action', () {
      final descriptor = SceneActions.descriptors.singleWhere(
        (candidate) =>
            candidate.id == 'scene.preSession.presentation.createAndLink',
      );

      expect(
        descriptor.resourceKinds,
        containsAll(const <String>[
          'project',
          'scene',
          'presentationCinematic',
          'cinematicLibraryEntry',
        ]),
      );
      expect(
        descriptor.guarantees,
        containsAll(const <AuthoringGuarantee>[
          AuthoringGuarantee.atomic,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable,
        ]),
      );
    });

    test('creates, catalogs and links the Presentation in one change', () {
      final snapshot = _snapshot(_project());

      final draft = _build(snapshot, const <String, Object?>{
        'sceneId': 'new_game_intro',
        'nodeId': 'opening',
        'targetNodeId': 'end',
        'cinematicId': 'presentation_opening',
        'title': 'Ouverture',
        'templateId': 'blank',
        'templateVersion': 1,
        'targetFolderId': null,
        'targetIndex': 0,
      });

      expect(draft.changeSet.changes, hasLength(1));
      expect(draft.changeSet.diff.entries, hasLength(1));
      final projected = _projectedManifest(draft);
      final cinematic = projected.presentationCinematics.single;
      expect(cinematic.id, 'presentation_opening');
      expect(cinematic.title, 'Ouverture');
      final placement = projected.cinematicLibraryCatalog.entryFor(
        CinematicLibraryFamily.presentation,
        cinematic.id,
      );
      expect(placement, isNotNull);
      final scene = projected.scenes.single;
      final node = scene.graph.nodes.singleWhere(
        (candidate) => candidate.id == 'opening',
      );
      expect(node.kind, SceneNodeKind.presentationCinematic);
      expect(
        (node.payload as ScenePresentationCinematicPayload)
            .presentationCinematicId,
        cinematic.id,
      );
      expect(buildSceneRuntimePlan(scene).canBuild, isTrue);
      expect(
        PresentationReferenceGraph.build(
          cinematics: projected.presentationCinematics,
          scenes: projected.scenes,
        ).diagnostics,
        isEmpty,
      );
      expect(draft.preview, containsPair('cinematicId', cinematic.id));
      expect(draft.preview, containsPair('sceneId', scene.id));
      expect(draft.preview, containsPair('nodeId', node.id));
    });

    test('publishes the exact edited draft instead of reinstantiating it', () {
      final draftAsset = PresentationCinematicAsset(
        id: 'presentation_opening',
        title: 'Ouverture montée',
        description: 'Brouillon modifié dans le Studio',
        durationUs: 9000000,
        layers: <PresentationLayer>[
          PresentationLayer(id: 'title', label: 'Titre', zIndex: 0),
        ],
        tracks: <PresentationTrack>[
          PresentationTrack(
            id: 'title',
            label: 'Titre',
            kind: PresentationTrackKind.visual,
          ),
        ],
      );

      final projected = _projectedManifest(
        _build(_snapshot(_project()), <String, Object?>{
          'sceneId': 'new_game_intro',
          'nodeId': 'opening',
          'targetNodeId': 'end',
          'cinematic': encodePresentationCinematicAsset(draftAsset),
          'targetFolderId': null,
          'targetIndex': 0,
        }),
      );

      expect(projected.presentationCinematics.single, draftAsset);
    });

    test('rejects collisions without producing a partial projection', () {
      final project = _project().copyWith(
        presentationCinematics: <PresentationCinematicAsset>[
          PresentationCinematicAsset(
            id: 'presentation_opening',
            title: 'Existing',
            durationUs: 1000000,
          ),
        ],
      );

      expect(
        () => _build(_snapshot(project), const <String, Object?>{
          'sceneId': 'new_game_intro',
          'nodeId': 'opening',
          'targetNodeId': 'end',
          'cinematicId': 'presentation_opening',
          'title': 'Ouverture',
          'templateId': 'blank',
          'templateVersion': 1,
          'targetFolderId': null,
          'targetIndex': 0,
        }),
        throwsA(
          isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'scene.preSession.presentation.cinematic_id_unavailable',
          ),
        ),
      );
    });

    test('rejects a stale Scene target before publishing either object', () {
      expect(
        () => _build(_snapshot(_project()), const <String, Object?>{
          'sceneId': 'new_game_intro',
          'nodeId': 'opening',
          'targetNodeId': 'missing',
          'cinematicId': 'presentation_opening',
          'title': 'Ouverture',
          'templateId': 'blank',
          'templateVersion': 1,
          'targetFolderId': null,
          'targetIndex': 0,
        }),
        throwsA(
          isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'scene.preSession.target.unknown',
          ),
        ),
      );
    });
  });
}

AuthoringMutationDraft _build(
  ProjectSnapshot snapshot,
  Map<String, Object?> parameters,
) {
  return const SceneActions().build(
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'request-create-and-link',
        actionId: 'scene.preSession.presentation.createAndLink',
        actionVersion: 1,
        workspaceHandle: 'workspace-create-and-link',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idempotency-create-and-link',
      ),
      planId: 'plan-create-and-link',
      seed: 1,
    ),
  );
}

ProjectSnapshot _snapshot(ProjectManifest manifest) {
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_create_and_link'),
    revision:
        'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    manifest: manifest,
    maps: const <MapData>[],
    resourceFingerprints: <String, String>{
      'project': computeAuthoringBytesFingerprint(
        bytes,
        logicalName: 'project.json',
      ),
    },
    resourceBytes: <String, List<int>>{'project': bytes},
  );
}

ProjectManifest _projectedManifest(AuthoringMutationDraft draft) {
  final bytes = draft.changeSet.changes.single.afterBytes!;
  return ProjectManifest.fromJson(
    Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Create and link fixture',
    version: ProjectVersion.v7,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
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
}
