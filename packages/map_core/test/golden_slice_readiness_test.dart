import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('GoldenSliceReadiness', () {

    test('reports missing scene, dialogue, trainer, plan and world rule gaps',
        () {
      final fixture = _controlledFixture();

      expect(
        buildGoldenSliceReadinessReport(
          fixture.project.copyWith(scenes: const []),
          maps: [fixture.map],
        ).byCode(GoldenSliceReadinessIssueCode.goldenSliceSceneMissing),
        isNotEmpty,
      );

      expect(
        buildGoldenSliceReadinessReport(
          fixture.project.copyWith(dialogues: const []),
          maps: [fixture.map],
        ).byCode(GoldenSliceReadinessIssueCode.goldenSliceDialogueRefMissing),
        isNotEmpty,
      );

      expect(
        buildGoldenSliceReadinessReport(
          fixture.project.copyWith(trainers: const []),
          maps: [fixture.map],
        ).byCode(GoldenSliceReadinessIssueCode.goldenSliceBattleRefMissing),
        isNotEmpty,
      );

      expect(
        buildGoldenSliceReadinessReport(
          fixture.project.copyWith(scenes: [_sceneWithoutEnd()]),
          maps: [fixture.map],
        ).byCode(
          GoldenSliceReadinessIssueCode.goldenSliceRuntimePlanNotBuildable,
        ),
        isNotEmpty,
      );

      expect(
        buildGoldenSliceReadinessReport(
          fixture.project.copyWith(worldRules: const []),
          maps: [fixture.map],
        ).byCode(GoldenSliceReadinessIssueCode.goldenSliceWorldRuleMissing),
        isNotEmpty,
      );

      expect(
        buildGoldenSliceReadinessReport(
          fixture.project,
          maps: [
            fixture.map.copyWith(
              events: [
                fixture.map.events.single.copyWith(
                  pages: const [MapEventPage(pageNumber: 0)],
                ),
              ],
            ),
          ],
        ).byCode(GoldenSliceReadinessIssueCode.goldenSliceNoEventSceneTarget),
        isNotEmpty,
      );
    });
  });
}

_GoldenSliceFixture _controlledFixture() {
  final scene = _scene();
  final project = ProjectManifest(
    name: 'Golden slice readiness test project',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Test Map',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'dialogue_test_intro',
        name: 'Test Intro Dialogue',
        relativePath: 'dialogues/dialogue_test_intro.yarn',
      ),
    ],
    trainers: const [
      ProjectTrainerEntry(
        id: 'trainer_test_rival',
        name: 'Test Trainer',
        trainerClass: 'Tester',
        team: [
          ProjectTrainerPokemonEntry(speciesId: 'pichu', level: 5),
        ],
      ),
    ],
    facts: [
      NarrativeFactDefinition(
        id: 'fact_test_rival_defeated',
        label: 'Test rival defeated',
      ),
    ],
    worldRules: [
      WorldRuleDefinition(
        id: 'world_rule_test_unlock_gate',
        label: 'Unlock test gate',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'fact_test_rival_defeated',
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEvent,
          mapId: 'map_test',
          eventId: 'event_gate',
          label: 'Test gate event',
        ),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
      ),
    ],
    scenes: [scene],
  );
  final map = MapData(
    id: 'map_test',
    name: 'Test Map',
    size: const GridSize(width: 8, height: 8),
    layers: [
      MapLayer.tile(
        id: 'l_base',
        name: 'Base',
        cells: List<int>.filled(64, 0),
      ),
    ],
    events: const [
      MapEventDefinition(
        id: 'event_gate',
        title: 'Test Gate',
        position: EventPosition(layerId: 'l_base', x: 2, y: 2),
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_test_rival'),
          ),
        ],
      ),
    ],
  );
  return _GoldenSliceFixture(project: project, map: map, scene: scene);
}

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_test_rival',
    name: 'Test Rival Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_test_intro'),
        ),
        SceneNode(
          id: 'node_battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_test_rival',
            declaredOutcomes: const ['victory', 'defeat'],
          ),
        ),
        SceneNode(
          id: 'node_mark_victory',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_test_rival_defeated',
              value: true,
              label: 'Mark test rival defeated',
            ),
          ),
        ),
        SceneNode(id: 'node_end_victory', kind: SceneNodeKind.end),
        SceneNode(id: 'node_end_defeat', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_dialogue',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_dialogue',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_dialogue_battle',
          fromNodeId: 'node_dialogue',
          fromPortId: 'completed',
          toNodeId: 'node_battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_battle_mark_victory',
          fromNodeId: 'node_battle',
          fromPortId: 'victory',
          toNodeId: 'node_mark_victory',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'edge_mark_victory_end',
          fromNodeId: 'node_mark_victory',
          fromPortId: 'completed',
          toNodeId: 'node_end_victory',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_battle_defeat',
          fromNodeId: 'node_battle',
          fromPortId: 'defeat',
          toNodeId: 'node_end_defeat',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
        SceneNodeLayout(nodeId: 'node_dialogue', x: 280, y: 0),
        SceneNodeLayout(nodeId: 'node_battle', x: 560, y: 0),
        SceneNodeLayout(nodeId: 'node_mark_victory', x: 840, y: -90),
        SceneNodeLayout(nodeId: 'node_end_victory', x: 1120, y: -90),
        SceneNodeLayout(nodeId: 'node_end_defeat', x: 840, y: 90),
      ],
    ),
  );
}

SceneAsset _sceneWithoutEnd() {
  return SceneAsset(
    id: 'scene_test_rival',
    name: 'Test Rival Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [SceneNode(id: 'node_start', kind: SceneNodeKind.start)],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0)],
    ),
  );
}

final class _GoldenSliceFixture {
  const _GoldenSliceFixture({
    required this.project,
    required this.map,
    required this.scene,
  });

  final ProjectManifest project;
  final MapData map;
  final SceneAsset scene;
}
