import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'spatial_package_fixture.dart';

Map<String, List<int>> battleDemonstrationPayload() {
  final files = spatialPayload();
  final project = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!)));
  final scene = SceneAsset(
      id: 'capture-demo',
      name: 'Capture demo',
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
            id: 'battle',
            kind: SceneNodeKind.battle,
            payload: SceneBattlePayload(
              battleKind: 'wild',
              battleTemplateId: 'target',
              declaredOutcomes: ['victory', 'defeat', 'captured', 'runaway'],
              demonstration: SceneBattleDemonstration(
                  playerTrainerId: 'guide',
                  bagItems: const [BagEntry(itemId: 'poke-ball', quantity: 20)],
                  choices: [
                    SceneBattleDemonstrationChoice.capture('poke-ball')
                  ],
                  captureAlwaysSucceeds: true),
            )),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(
            id: 'begin',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'battle',
            kind: SceneEdgeKind.defaultFlow),
        for (final outcome in ['victory', 'defeat', 'captured', 'runaway'])
          SceneEdge(
              id: outcome,
              fromNodeId: 'battle',
              fromPortId: outcome,
              toNodeId: 'end',
              kind: switch (outcome) {
                'victory' => SceneEdgeKind.battleVictory,
                'defeat' => SceneEdgeKind.battleDefeat,
                _ => SceneEdgeKind.branchOutcome,
              }),
      ]));
  files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(
    scenes: [scene],
    trainers: const [
      ProjectTrainerEntry(
          id: 'guide',
          name: 'Guide',
          trainerClass: 'Demo',
          team: [ProjectTrainerPokemonEntry(speciesId: 'bird', level: 5)])
    ],
    encounterTables: const [
      ProjectEncounterTable(
          id: 'target',
          name: 'Target',
          encounterKind: EncounterKind.walk,
          entries: [
            ProjectEncounterEntry(speciesId: 'rodent', minLevel: 2, maxLevel: 2)
          ])
    ],
  ).toJson()));
  return files;
}
