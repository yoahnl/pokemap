import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene project diagnostics', () {
    test('detects missing dialogue reference without parsing Yarn', () {
      final scene = _sceneWithMiddleNode(
        SceneNode(
          id: 'node_dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_test'),
        ),
      );

      final missingReport = diagnoseSceneAgainstProject(scene, _project());

      final missingDiagnostic =
          missingReport.byCode(SceneDiagnosticCode.dialogueRefUnknown).single;
      expect(missingDiagnostic.severity, SceneDiagnosticSeverity.error);
      expect(missingDiagnostic.nodeId, 'node_dialogue');

      final validReport = diagnoseSceneAgainstProject(
        scene,
        _project(
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue_test',
              name: 'Dialogue Test',
              relativePath: 'dialogues/dialogue_test.yarn',
            ),
          ],
        ),
      );

      expect(
          validReport.byCode(SceneDiagnosticCode.dialogueRefUnknown), isEmpty);
    });

    test('detects missing trainer reference for trainer battle', () {
      final scene = _sceneWithMiddleNode(
        SceneNode(
          id: 'node_battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_test',
            declaredOutcomes: const ['victory', 'defeat'],
          ),
        ),
        outgoingPortId: 'victory',
        outgoingKind: SceneEdgeKind.battleVictory,
      );

      final missingReport = diagnoseSceneAgainstProject(scene, _project());

      final missingDiagnostic = missingReport
          .byCode(SceneDiagnosticCode.battleTrainerRefUnknown)
          .single;
      expect(missingDiagnostic.severity, SceneDiagnosticSeverity.error);
      expect(missingDiagnostic.nodeId, 'node_battle');

      final validReport = diagnoseSceneAgainstProject(
        scene,
        _project(
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_test',
              name: 'Trainer Test',
              trainerClass: 'Tester',
            ),
          ],
        ),
      );

      expect(validReport.byCode(SceneDiagnosticCode.battleTrainerRefUnknown),
          isEmpty);
    });

    test('detects missing cinematic bridge reference as warning', () {
      final scene = _sceneWithMiddleNode(
        SceneNode(
          id: 'node_cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: 'cinematic_test'),
        ),
        outgoingKind: SceneEdgeKind.cinematicCompleted,
      );

      final missingReport = diagnoseSceneAgainstProject(scene, _project());

      final missingDiagnostic =
          missingReport.byCode(SceneDiagnosticCode.cinematicRefUnknown).single;
      expect(missingDiagnostic.severity, SceneDiagnosticSeverity.warning);
      expect(missingDiagnostic.nodeId, 'node_cinematic');

      final validReport = diagnoseSceneAgainstProject(
        scene,
        _project(
          scenarios: const [
            ScenarioAsset(
              id: 'cinematic_test',
              name: 'Cinematic Test',
              entryNodeId: 'scenario_start',
              metadata: {'authoring.cutsceneSchema': 'v0'},
            ),
          ],
        ),
      );

      expect(
          validReport.byCode(SceneDiagnosticCode.cinematicRefUnknown), isEmpty);
    });

    test('detects missing world rule reference from future world state source',
        () {
      final scene = _sceneWithMiddleNode(
        SceneNode(
          id: 'node_condition',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.worldState,
              sourceId: 'world_rule_test',
              operator: SceneConditionOperator.equals,
              value: 'active',
              label: 'World rule test',
            ),
          ),
        ),
        outgoingPortId: 'true',
        outgoingKind: SceneEdgeKind.conditionTrue,
      );

      final missingReport = diagnoseSceneAgainstProject(scene, _project());

      final missingDiagnostic = missingReport
          .byCode(SceneDiagnosticCode.conditionWorldRuleRefUnknown)
          .single;
      expect(missingDiagnostic.severity, SceneDiagnosticSeverity.warning);
      expect(missingDiagnostic.nodeId, 'node_condition');

      final validReport = diagnoseSceneAgainstProject(
        scene,
        _project(
          worldRules: [_worldRule()],
        ),
      );

      expect(
        validReport.byCode(SceneDiagnosticCode.conditionWorldRuleRefUnknown),
        isEmpty,
      );
    });

    test('does not import runtime or battle packages', () {
      final source =
          File('lib/src/diagnostics/scene_diagnostics.dart').readAsStringSync();

      expect(source, isNot(contains('map_runtime')));
      expect(source, isNot(contains('map_battle')));
    });
  });
}

SceneAsset _sceneWithMiddleNode(
  SceneNode middleNode, {
  String outgoingPortId = 'completed',
  SceneEdgeKind outgoingKind = SceneEdgeKind.defaultFlow,
}) {
  return SceneAsset(
    id: 'scene_test',
    name: 'Scene Test',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        middleNode,
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_middle',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: middleNode.id,
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_middle_end',
          fromNodeId: middleNode.id,
          fromPortId: outgoingPortId,
          toNodeId: 'node_end',
          kind: outgoingKind,
        ),
      ],
    ),
  );
}

ProjectManifest _project({
  List<ProjectDialogueEntry> dialogues = const [],
  List<ProjectTrainerEntry> trainers = const [],
  List<ScenarioAsset> scenarios = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Project diagnostics test',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Map Test',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    dialogues: dialogues,
    trainers: trainers,
    scenarios: scenarios,
    worldRules: worldRules,
  );
}

WorldRuleDefinition _worldRule() {
  return WorldRuleDefinition(
    id: 'world_rule_test',
    label: 'World Rule Test',
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact_test',
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEvent,
      mapId: 'map_test',
      eventId: 'event_test',
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
  );
}
