import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('GoldenSliceReadiness', () {
    test('proves a controlled event to scene dialogue battle chain', () async {
      final fixture = _controlledFixture();
      final projectBefore = fixture.project.toJson();
      final mapBefore = fixture.map.toJson();

      final report = buildGoldenSliceReadinessReport(
        fixture.project,
        maps: [fixture.map],
      );

      expect(report.isReady, isTrue);
      expect(report.eventSceneTargetCount, 1);
      expect(report.issues, isEmpty);
      final target = report.eventTargets.single;
      expect(target.mapId, 'map_test');
      expect(target.eventId, 'event_gate');
      expect(target.sceneId, 'scene_test_rival');
      expect(target.sceneExists, isTrue);
      expect(target.runtimePlanBuildable, isTrue);
      expect(target.containsDialogue, isTrue);
      expect(target.containsBattle, isTrue);
      expect(target.battleVictoryReachable, isTrue);
      expect(target.battleDefeatReachable, isTrue);
      expect(target.worldRuleCount, 1);

      final sceneDiagnostics = diagnoseSceneAgainstProject(
        fixture.scene,
        fixture.project,
      );
      expect(sceneDiagnostics.hasErrors, isFalse);
      expect(
        sceneDiagnostics.byCode(SceneDiagnosticCode.dialogueRefUnknown),
        isEmpty,
      );
      expect(
        sceneDiagnostics.byCode(SceneDiagnosticCode.battleTrainerRefUnknown),
        isEmpty,
      );

      final eventDiagnostics = diagnoseEventSceneLinks(
        project: fixture.project,
        maps: [fixture.map],
      );
      expect(eventDiagnostics.hasErrors, isFalse);

      final planResult = buildSceneRuntimePlan(fixture.scene);
      expect(planResult.canBuild, isTrue);
      final plan = planResult.plan!;
      expect(
        plan.nodes.map((node) => node.intent.kind),
        containsAll([
          SceneRuntimePlanIntentKind.showDialogue,
          SceneRuntimePlanIntentKind.startBattle,
        ]),
      );

      final victory = await _execute(plan, battleResult: 'victory');
      expect(victory.status, SceneRuntimeExecutionStatus.completed);
      expect(victory.finalNodeId, 'node_end_victory');
      expect(
        victory.trace.map((entry) => (entry.nodeId, entry.outputPortId)),
        [
          ('node_start', 'completed'),
          ('node_dialogue', 'completed'),
          ('node_battle', 'victory'),
          ('node_end_victory', null),
        ],
      );

      final defeat = await _execute(plan, battleResult: 'defeat');
      expect(defeat.status, SceneRuntimeExecutionStatus.completed);
      expect(defeat.finalNodeId, 'node_end_defeat');

      final worldRuleContext = buildWorldRuleTargetContextReadModel(
        fixture.project,
        maps: [fixture.map],
        targetKind: WorldRuleTargetKind.mapEvent,
        mapId: 'map_test',
        eventId: 'event_gate',
      );
      expect(worldRuleContext.ruleCount, 1);
      expect(worldRuleContext.rules.single.id, 'world_rule_test_unlock_gate');
      expect(worldRuleContext.hasDiagnostics, isFalse);
      expect(
        diagnoseWorldRules(fixture.project, maps: [fixture.map]).hasErrors,
        isFalse,
      );

      expect(fixture.project.toJson(), projectBefore);
      expect(fixture.map.toJson(), mapBefore);
      expect(_fixtureIds(fixture), containsAll(_allowedFixtureIds));
    });

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

Future<SceneRuntimeExecutionResult> _execute(
  SceneRuntimePlan plan, {
  required String battleResult,
}) {
  return SceneRuntimeExecutor(
    callbacks: SceneRuntimeExecutionCallbacks(
      evaluateCondition: (_) => 'true',
      showDialogue: (_) => 'completed',
      startBattle: (_) => battleResult,
      playCinematic: (_) => 'completed',
      applyConsequence: (_) => 'completed',
    ),
  ).execute(plan);
}

const _allowedFixtureIds = {
  'map_test',
  'event_gate',
  'scene_test_rival',
  'dialogue_test_intro',
  'trainer_test_rival',
  'fact_test_rival_defeated',
  'world_rule_test_unlock_gate',
  'node_start',
  'node_dialogue',
  'node_battle',
  'node_end_victory',
  'node_end_defeat',
};

Set<String> _fixtureIds(_GoldenSliceFixture fixture) {
  return {
    for (final map in fixture.project.maps) map.id,
    for (final dialogue in fixture.project.dialogues) dialogue.id,
    for (final trainer in fixture.project.trainers) trainer.id,
    for (final fact in fixture.project.facts) fact.id,
    for (final rule in fixture.project.worldRules) rule.id,
    for (final scene in fixture.project.scenes) scene.id,
    for (final map in [fixture.map]) map.id,
    for (final event in fixture.map.events) event.id,
    for (final node in fixture.scene.graph.nodes) node.id,
  };
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
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  final map = MapData(
    id: 'map_test',
    name: 'Test Map',
    size: const GridSize(width: 8, height: 8),
    layers: [
      MapLayer.tile(
        id: 'l_base',
        name: 'Base',
        tiles: List<int>.filled(64, 0),
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
          id: 'edge_battle_victory',
          fromNodeId: 'node_battle',
          fromPortId: 'victory',
          toNodeId: 'node_end_victory',
          kind: SceneEdgeKind.battleVictory,
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
        SceneNodeLayout(nodeId: 'node_end_victory', x: 840, y: -90),
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
