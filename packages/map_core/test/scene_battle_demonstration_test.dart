import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _demonstration() => {
  'playerTrainerId': 'guide',
  'bagItems': [
    {'itemId': 'poke-ball', 'quantity': 20},
  ],
  'choices': [
    {'kind': 'fight', 'moveIndex': 0},
    {'kind': 'capture', 'itemId': 'poke-ball'},
  ],
  'captureAlwaysSucceeds': true,
  'stepDelayMs': 500,
};

void main() {
  test(
    'battle demonstration survives strict payload serialization and planning',
    () {
      final payload = SceneBattlePayload.fromJson({
        'battleKind': 'wild',
        'battleTemplateId': 'capture-target',
        'demonstration': _demonstration(),
      });
      expect(payload.toJson()['demonstration'], _demonstration());
      expect(SceneBattlePayload.fromJson(payload.toJson()), payload);
      final plan = buildSceneRuntimePlan(_scene(payload)).plan!;
      expect(plan.nodes[1].intent.battleDemonstration, payload.demonstration);
      final updated = updateSceneBattlePayload(
        _scene(payload),
        nodeId: 'battle',
        battleKind: 'wild',
        battleTemplateId: 'other',
      );
      expect(updated.updatedPayload.demonstration, payload.demonstration);
    },
  );

  for (final dimension in ProjectDimension.values) {
    test('demonstration support is explicit for $dimension', () {
      final payload = SceneBattlePayload.fromJson({
        'battleKind': 'wild',
        'battleTemplateId': 'capture-target',
        'demonstration': _demonstration(),
      });
      final project = ProjectManifest(
        name: 'Demo',
        maps: [],
        tilesets: [],
        settings: ProjectSettings(dimension: dimension),
        trainers: const [
          ProjectTrainerEntry(
            id: 'guide',
            name: 'Guide',
            trainerClass: 'Guide',
            team: [ProjectTrainerPokemonEntry(speciesId: 'bird', level: 5)],
          ),
        ],
        encounterTables: const [
          ProjectEncounterTable(
            id: 'capture-target',
            name: 'Target',
            encounterKind: EncounterKind.walk,
            entries: [
              ProjectEncounterEntry(
                speciesId: 'rodent',
                minLevel: 2,
                maxLevel: 2,
              ),
            ],
          ),
        ],
      );
      final report = diagnoseSceneAgainstProject(_scene(payload), project);
      expect(
        report.diagnostics.any(
          (issue) => issue.code.name == 'battleDemonstrationInvalid',
        ),
        dimension == ProjectDimension.twoD,
      );
      final missing = diagnoseSceneAgainstProject(
        _scene(payload),
        project.copyWith(trainers: []),
      );
      expect(
        missing.diagnostics.any(
          (issue) => issue.code.name == 'battleDemonstrationInvalid',
        ),
        isTrue,
      );
    });
  }

  for (final invalid in [
    {..._demonstration(), 'extraField': true},
    {..._demonstration(), 'playerTrainerId': ''},
    {..._demonstration(), 'choices': []},
    {..._demonstration(), 'stepDelayMs': 0},
    {
      ..._demonstration(),
      'choices': [
        {'kind': 'fight', 'moveIndex': 4},
      ],
    },
    {
      ..._demonstration(),
      'choices': [
        {'kind': 'capture', 'itemId': ''},
      ],
    },
    {
      ..._demonstration(),
      'bagItems': [
        {'itemId': 'poke-ball', 'quantity': 0},
      ],
    },
  ]) {
    test('invalid demonstration is rejected: $invalid', () {
      expect(
        () => SceneBattlePayload.fromJson({
          'battleKind': 'wild',
          'battleTemplateId': 'capture-target',
          'demonstration': invalid,
        }),
        throwsFormatException,
      );
    });
  }
}

SceneAsset _scene(SceneBattlePayload payload) => SceneAsset(
  id: 'demo',
  name: 'Demo',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'battle', kind: SceneNodeKind.battle, payload: payload),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'begin',
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
);
