import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/application/models/narrative_document_route.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_graph_read_only_view.dart';
import 'package:map_editor/src/ui/canvas/scenes_workspace.dart';

void main() {
  testWidgets('Create and link guides creation then opens the exact document', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    ScenePresentationCreateAndLinkOutcome? created;
    ({
      String sceneId,
      String returnNodeId,
      String cinematicId,
      SceneGraphViewport viewport,
      NarrativeSceneInspector inspector,
    })?
    opened;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: ScenesWorkspace(
            scenes: <NarrativeSceneSummary>[_scene()],
            requestedViewportX: 31,
            requestedViewportY: 47,
            requestedZoom: 1.5,
            requestedInspector: NarrativeSceneInspector.properties,
            onCreateSceneDraft: ({required name, description}) async => null,
            onAddNodeDraft: ({required sceneId, required kind}) async => null,
            onAddLinkedAssetNodeDraft:
                ({required sceneId, required payload, title}) async => null,
            onAddConsequenceActionNodeDraft:
                ({required sceneId, required consequence, title}) async => null,
            onAddEdgeDraft:
                ({
                  required sceneId,
                  required fromNodeId,
                  required fromPortId,
                  required toNodeId,
                }) async => null,
            onRemoveEdgeDraft: ({required sceneId, required edgeId}) async =>
                false,
            onRemoveNodeDraft: ({required sceneId, required nodeId}) async =>
                false,
            onUpdateNodeLayout:
                ({
                  required sceneId,
                  required nodeId,
                  required x,
                  required y,
                }) async {},
            onUpdateConditionSource:
                ({required sceneId, required nodeId, required source}) async =>
                    false,
            onUpdateYarnDialoguePayload:
                ({
                  required sceneId,
                  required nodeId,
                  required dialogueId,
                  yarnNodeName,
                  required expectedOutcomes,
                }) async => false,
            onUpdateBattlePayload:
                ({
                  required sceneId,
                  required nodeId,
                  required trainerId,
                  required battleKind,
                  battleTemplateId,
                }) async => false,
            onUpdateCinematicPayload:
                ({
                  required sceneId,
                  required nodeId,
                  required cinematicId,
                }) async => false,
            onUpdateActionConsequence:
                ({
                  required sceneId,
                  required nodeId,
                  required consequence,
                }) async => false,
            onCreateAndLinkPresentation:
                ({
                  required sceneId,
                  required targetNodeId,
                  required title,
                  required templateId,
                  required templateVersion,
                  required folderId,
                }) async {
                  expect(sceneId, 'scene_pre_session');
                  expect(targetNodeId, 'node_end');
                  expect(title, 'Ouverture guidée');
                  expect(templateId, 'blank');
                  expect(templateVersion, 1);
                  expect(folderId, isNull);
                  return created = const ScenePresentationCreateAndLinkOutcome(
                    cinematicId: 'ouverture-guidee',
                    nodeId: 'presentation_ouverture-guidee',
                  );
                },
            onOpenCreatedPresentation:
                ({
                  required sceneId,
                  required returnNodeId,
                  required cinematicId,
                  required viewport,
                  required inspector,
                }) {
                  opened = (
                    sceneId: sceneId,
                    returnNodeId: returnNodeId,
                    cinematicId: cinematicId,
                    viewport: viewport,
                    inspector: inspector,
                  );
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final add = find.byKey(
      const ValueKey('scenes-add-node-presentation-cinematic'),
    );
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('scene-presentation-picker-create-and-link')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('cinematic-create-title')),
      'Ouverture guidée',
    );
    await tester.tap(find.byKey(const ValueKey('cinematic-create-submit')));
    await tester.pumpAndSettle();

    expect(created, isNotNull);
    expect(opened, (
      sceneId: 'scene_pre_session',
      returnNodeId: 'node_start',
      cinematicId: 'ouverture-guidee',
      viewport: const SceneGraphViewport(pan: Offset(31, 47), zoom: 1.5),
      inspector: NarrativeSceneInspector.properties,
    ));
    expect(
      find.byKey(const ValueKey('scene-presentation-picker-sheet')),
      findsNothing,
    );
  });
}

NarrativeSceneSummary _scene() {
  final graph = SceneGraph(
    startNodeId: 'node_start',
    nodes: <SceneNode>[
      SceneNode(id: 'node_start', kind: SceneNodeKind.start),
      SceneNode(id: 'node_end', kind: SceneNodeKind.end),
    ],
    edges: <SceneEdge>[
      SceneEdge(
        id: 'edge_start_end',
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  );
  final scene = SceneAsset(
    id: 'scene_pre_session',
    name: 'Avant la partie',
    executionProfile: SceneExecutionProfile.preSession,
    graph: graph,
  );
  return NarrativeSceneSummary(
    id: scene.id,
    name: scene.name,
    executionProfile: scene.executionProfile,
    nodeCount: graph.nodes.length,
    edgeCount: graph.edges.length,
    declaredOutcomeCount: 0,
    declaredOutcomes: const <String>[],
    tags: const <String>[],
    graph: graph,
    layout: scene.layout,
    diagnostics: diagnoseScene(scene),
  );
}
