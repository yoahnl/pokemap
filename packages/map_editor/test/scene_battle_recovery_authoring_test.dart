import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/scene_battle_recovery_authoring_gateway.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_node_read_only_inspector.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    testWidgets('battle recovery picker respects $dimension capabilities', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final project = _project(dimension);
      final scene = project.scenes.single;
      String? updatedNode;
      SceneBattleDefeatRecovery? updatedRecovery;
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 1600,
              child: SingleChildScrollView(
                child: SceneNodeReadOnlyInspector(
                  scene: NarrativeSceneSummary(
                    id: scene.id,
                    name: scene.name,
                    nodeCount: scene.graph.nodes.length,
                    edgeCount: scene.graph.edges.length,
                    declaredOutcomeCount: 0,
                    declaredOutcomes: const [],
                    tags: const [],
                    graph: scene.graph,
                    layout: scene.layout,
                    diagnostics: diagnoseScene(scene),
                  ),
                  project: project,
                  selectedNodeId: 'battle',
                  partyProjectDimension: dimension,
                  linkedAssetContracts: buildLinkedAssetContractsSnapshot(
                    project,
                  ),
                  onUpdateBattleDefeatRecovery:
                      ({required nodeId, required defeatRecovery}) async {
                        updatedNode = nodeId;
                        updatedRecovery = defeatRecovery;
                        return true;
                      },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final picker = tester.widget<PokeMapDropdownField<String>>(
        find.byKey(const ValueKey('scene-battle-defeat-recovery-picker')),
      );
      expect(picker.value, 'continueScene');
      expect(picker.enabled, dimension == ProjectDimension.twoD);
      picker.onChanged('returnToRecoveryPoint');
      await tester.pump();
      expect(updatedNode, dimension == ProjectDimension.twoD ? 'battle' : null);
      expect(
        updatedRecovery,
        dimension == ProjectDimension.twoD
            ? SceneBattleDefeatRecovery.returnToRecoveryPoint
            : null,
      );
    });
  }

  test(
    'editor gateway preserves the graph and persists the selected policy',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'scene-recovery-editor-',
      );
      final queries = AuthoringQueryAdapter(
        fileReader: const EditorProjectFileReader(),
      );
      addTearDown(() async {
        await queries.closeAll();
        await root.delete(recursive: true);
      });
      final project = _project(ProjectDimension.twoD);
      final file = File('${root.path}/project.json');
      await file.writeAsString(jsonEncode(project.toJson()));
      final before = await file.readAsBytes();
      final gateway = SceneBattleRecoveryAuthoringGateway(queries: queries);
      final updated = await gateway.updateDraft(
        root.path,
        project: project,
        sceneId: 'scene',
        nodeId: 'battle',
        defeatRecovery: SceneBattleDefeatRecovery.returnToRecoveryPoint,
      );
      expect(await file.readAsBytes(), before);
      expect(
        updated.scenes.single.graph.edges,
        project.scenes.single.graph.edges,
      );
      expect(updated.scenes.single.layout, project.scenes.single.layout);
      expect(updated.trainers, project.trainers);
      await file.writeAsString(jsonEncode(updated.toJson()));
      await queries.invalidate(root.path);
      final reloaded = (await queries.open(root.path)).manifest;
      final payload =
          reloaded.scenes.single.graph.nodes
                  .singleWhere((node) => node.id == 'battle')
                  .payload
              as SceneBattlePayload;
      expect(
        payload.defeatRecovery,
        SceneBattleDefeatRecovery.returnToRecoveryPoint,
      );
      expect(payload.trainerId, 'rival');
      final saved = await file.readAsBytes();
      await expectLater(
        gateway.updateDraft(
          root.path,
          project: reloaded,
          sceneId: 'scene',
          nodeId: 'start',
          defeatRecovery: SceneBattleDefeatRecovery.returnToRecoveryPoint,
        ),
        throwsA(isA<StateError>()),
      );
      expect(await file.readAsBytes(), saved);
    },
  );
}

ProjectManifest _project(ProjectDimension dimension) => ProjectManifest(
  name: 'Recovery editor',
  maps: const [],
  tilesets: const [],
  settings: ProjectSettings(dimension: dimension),
  trainers: const [
    ProjectTrainerEntry(
      id: 'rival',
      name: 'Rival',
      trainerClass: 'Rival',
      team: [ProjectTrainerPokemonEntry(speciesId: 'sproutle', level: 5)],
    ),
  ],
  scenes: [
    SceneAsset(
      id: 'scene',
      name: 'Rival',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'battle',
            kind: SceneNodeKind.battle,
            payload: SceneBattlePayload(
              battleKind: 'trainer',
              trainerId: 'rival',
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'battle',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'win',
            fromNodeId: 'battle',
            fromPortId: 'victory',
            toNodeId: 'end',
            kind: SceneEdgeKind.battleVictory,
          ),
          SceneEdge(
            id: 'lose',
            fromNodeId: 'battle',
            fromPortId: 'defeat',
            toNodeId: 'end',
            kind: SceneEdgeKind.battleDefeat,
          ),
        ],
      ),
    ),
  ],
);
