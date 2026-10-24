import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_runtime_host_callbacks.dart';

void main() {
  for (final alreadyConsumed in [false, true]) {
    test(
      'a demonstration does not consume or depend on unique encounter state: $alreadyConsumed',
      () async {
        final configuration = SceneBattleDemonstration(
          playerTrainerId: 'guide',
          bagItems: const [BagEntry(itemId: 'poke-ball', quantity: 20)],
          choices: [SceneBattleDemonstrationChoice.capture('poke-ball')],
        );
        final scene = SceneAsset(
          id: 'demo',
          name: 'Demo',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'battle',
                kind: SceneNodeKind.battle,
                payload: SceneBattlePayload(
                  battleKind: 'wild',
                  battleTemplateId: 'target',
                  demonstration: configuration,
                  declaredOutcomes: ['captured'],
                ),
              ),
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
                id: 'capture',
                fromNodeId: 'battle',
                fromPortId: 'captured',
                toNodeId: 'end',
                kind: SceneEdgeKind.branchOutcome,
              ),
            ],
          ),
        );
        final project = ProjectManifest(
          name: 'Demo',
          maps: [],
          tilesets: [],
          scenes: [scene],
          settings: const ProjectSettings(dimension: ProjectDimension.threeD),
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
              id: 'target',
              name: 'Target',
              encounterKind: EncounterKind.special,
              tags: ['studio:unique'],
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
        const base = GameState(saveId: 'demo-save');
        final state = alreadyConsumed
            ? const GameStateMutations().setFlag(
                base,
                uniqueEncounterConsumedFlag('target'),
              )
            : base;
        var battles = 0;
        final result = await executeNarrativeEventScene(
          request: NarrativeSceneExecutionRequest(
            eventId: 'demo-event',
            sceneId: scene.id,
            executionId: 'demo-run',
            gameState: state,
          ),
          project: project,
          mapsById: {},
          currentGameState: () => state,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => 'true',
            showDialogue: (_) => 'completed',
            startBattle: (intent) {
              battles++;
              expect(intent.battleDemonstration, configuration);
              return 'captured';
            },
            playCinematic: (_) => 'completed',
          ),
        );
        expect(result, isA<NarrativeSceneExecutionCompleted>());
        expect(battles, 1);
        expect(
          (result as NarrativeSceneExecutionCompleted).updatedGameState
              .toJson(),
          state.toJson(),
        );
      },
    );
  }
}
