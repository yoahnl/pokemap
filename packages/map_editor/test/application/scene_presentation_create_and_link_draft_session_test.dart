import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/scene_presentation_create_and_link_gateway.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';

void main() {
  test(
    'draft stays unpublished, recovers, publishes once or discards cleanly',
    () async {
      final project = _project();
      final gateway = _MemoryGateway(project);
      final recovery = _MemoryRecoveryStore<ProjectManifest>();
      final draft = prepareScenePresentationCreateAndLinkDraft(
        expectedProject: project,
        sceneId: 'new_game_intro',
        targetNodeId: 'end',
        title: 'Ouverture',
        templateId: 'blank',
        templateVersion: 1,
        folderId: null,
      );
      final first = NarrativeDocumentSession<ProjectManifest>(
        documentId: 'scene-presentation-create-link',
        initialDocument: project,
        gateway: gateway,
        recoveryStore: recovery,
      );
      await first.initialize();
      expect(
        await first.apply(
          operationId: 'create-link-draft',
          label: 'Créer et lier',
          document: draft.manifest,
        ),
        isTrue,
      );

      expect(gateway.document, project);
      expect(gateway.document.presentationCinematics, isEmpty);
      expect(recovery.record, isNotNull);
      expect(first.state.history.undoEntries, hasLength(1));
      first.dispose();

      final recovered = NarrativeDocumentSession<ProjectManifest>(
        documentId: 'scene-presentation-create-link',
        initialDocument: project,
        gateway: gateway,
        recoveryStore: recovery,
      );
      addTearDown(recovered.dispose);
      await recovered.initialize();

      expect(recovered.state.status, NarrativeDocumentSessionStatus.recovered);
      expect(recovered.state.document, draft.manifest);
      expect(await recovered.save(operationId: 'publish-create-link'), isTrue);
      expect(gateway.document, draft.manifest);
      expect(gateway.saveCount, 1);
      expect(recovery.record, isNull);
      expect(
        PresentationReferenceGraph.build(
          cinematics: gateway.document.presentationCinematics,
          scenes: gateway.document.scenes,
        ).diagnostics,
        isEmpty,
      );

      final discardRecovery = _MemoryRecoveryStore<ProjectManifest>();
      final discardGateway = _MemoryGateway(project);
      final discarded = NarrativeDocumentSession<ProjectManifest>(
        documentId: 'scene-presentation-discard',
        initialDocument: project,
        gateway: discardGateway,
        recoveryStore: discardRecovery,
      );
      addTearDown(discarded.dispose);
      await discarded.initialize();
      await discarded.apply(
        operationId: 'discarded-draft',
        label: 'Créer et lier',
        document: draft.manifest,
      );
      expect(await discarded.discard(), isTrue);
      expect(discardGateway.document, project);
      expect(discardRecovery.record, isNull);
    },
  );

  test(
    'revision conflict keeps the external project and recoverable draft',
    () async {
      final project = _project();
      final gateway = _MemoryGateway(project);
      final recovery = _MemoryRecoveryStore<ProjectManifest>();
      final draft = prepareScenePresentationCreateAndLinkDraft(
        expectedProject: project,
        sceneId: 'new_game_intro',
        targetNodeId: 'end',
        title: 'Ouverture',
        templateId: 'blank',
        templateVersion: 1,
        folderId: null,
      );
      final session = NarrativeDocumentSession<ProjectManifest>(
        documentId: 'scene-presentation-conflict',
        initialDocument: project,
        gateway: gateway,
        recoveryStore: recovery,
      );
      addTearDown(session.dispose);
      await session.initialize();
      await session.apply(
        operationId: 'conflicting-draft',
        label: 'Créer et lier',
        document: draft.manifest,
      );
      gateway
        ..document = project.copyWith(name: 'Projet externe')
        ..revision = 'revision-external';

      expect(await session.save(operationId: 'publish-conflict'), isFalse);
      expect(session.state.status, NarrativeDocumentSessionStatus.conflicted);
      expect(gateway.document.name, 'Projet externe');
      expect(gateway.document.presentationCinematics, isEmpty);
      expect(recovery.record?.document, draft.manifest);
    },
  );
}

final class _MemoryGateway
    implements NarrativeDocumentGateway<ProjectManifest> {
  _MemoryGateway(this.document);

  ProjectManifest document;
  String revision = 'revision-1';
  int saveCount = 0;

  @override
  Future<NarrativeDocumentVersion<ProjectManifest>> read() async =>
      NarrativeDocumentVersion<ProjectManifest>(
        revision: revision,
        document: document,
      );

  @override
  Future<NarrativeDocumentSaveResult<ProjectManifest>> save({
    required String expectedRevision,
    required ProjectManifest before,
    required ProjectManifest after,
    required String operationId,
  }) async {
    if (expectedRevision != revision || before != document) {
      return NarrativeDocumentSaveResult<ProjectManifest>.conflicted(
        code: 'revisionConflict',
        message: 'Le projet a changé.',
        external: NarrativeDocumentVersion<ProjectManifest>(
          revision: revision,
          document: document,
        ),
      );
    }
    saveCount += 1;
    document = after;
    revision = 'revision-${saveCount + 1}';
    return NarrativeDocumentSaveResult<ProjectManifest>.saved(
      NarrativeDocumentVersion<ProjectManifest>(
        revision: revision,
        document: document,
      ),
    );
  }
}

final class _MemoryRecoveryStore<T>
    implements NarrativeDocumentRecoveryStore<T> {
  NarrativeDocumentRecoveryRecord<T>? record;

  @override
  Future<void> clear() async => record = null;

  @override
  Future<NarrativeDocumentRecoveryRecord<T>?> read() async => record;

  @override
  Future<void> write(NarrativeDocumentRecoveryRecord<T> record) async {
    this.record = record;
  }
}

ProjectManifest _project() => ProjectManifest(
  name: 'Draft session fixture',
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
