import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final defeated in [false, true]) {
    testWidgets(
      'mounted Player selects trainer branch when canonical victory is $defeated',
      (tester) async {
        await tester.runAsync(() async {
          final bundle = _bundle();
          final diagnostics = diagnoseSceneAgainstProject(
            bundle.manifest.scenes.single,
            bundle.manifest,
            mapsById: {'map': bundle.map},
          );
          expect(
            diagnostics.hasErrors,
            isFalse,
            reason: diagnostics.diagnostics
                .map((item) => '${item.code}: ${item.message}')
                .join('\n'),
          );
          final game = PlayableMapGame(
            bundle: bundle,
            projectFilePath: '/tmp/scene-trainer/project.json',
            saveData: saveDataFromGameState(
              GameState(
                saveId: 'trainer-test',
                storyFlags: StoryFlags(
                  activeFlags: defeated ? {'trainer_defeated:clair'} : {},
                ),
                trainerProfile: TrainerProfile(name: 'Player'),
              ),
            ),
          );
          game.onGameResize(Vector2(320, 240));
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: GameWidget(game: game),
            ),
          );
          await game.loaded;
          await tester.pump();
          addTearDown(game.onRemove);
          for (
            var i = 0;
            i < 100 && game.debugIsMapActivationDispatchInFlight;
            i++
          ) {
            game.update(0);
            await Future<void>.value();
          }
          final result = await game.debugExecuteNarrativeSceneForTest(
            NarrativeSceneExecutionRequest(
              eventId: 'trainer-event',
              sceneId: 'trainer-check',
              executionId: 'trainer-run',
              gameState: game.gameStateSnapshot,
            ),
          );
          expect(
            result,
            isA<NarrativeSceneExecutionCompleted>(),
            reason: result is NarrativeSceneExecutionFailed
                ? result.failure.toString()
                : null,
          );
          final completed = result as NarrativeSceneExecutionCompleted;
          expect(
            completed
                .updatedGameState
                .narrativeFactRuntimeState
                .overridesByFactId['checked-trainer-branch'],
            defeated ? isTrue : isNull,
          );
        });
      },
    );
  }
}

RuntimeMapBundle _bundle() => RuntimeMapBundle(
  projectRootDirectory: '/tmp/scene-trainer',
  tilesetAbsolutePathsById: const {},
  map: const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 8, height: 8),
    layers: [],
  ),
  manifest: ProjectManifest(
    name: 'Trainer scene',
    maps: [
      const ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'maps/map.json',
      ),
    ],
    tilesets: [],
    trainers: const [
      ProjectTrainerEntry(
        id: 'clair',
        name: 'Sandra',
        trainerClass: 'Championne',
      ),
    ],
    facts: [
      NarrativeFactDefinition(
        id: 'checked-trainer-branch',
        label: 'Trainer checked',
      ),
    ],
    scenes: [
      SceneAsset(
        id: 'trainer-check',
        name: 'Trainer check',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'condition',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                  sourceKind: SceneConditionSourceKind.trainerDefeated,
                  sourceId: 'clair',
                  operator: SceneConditionOperator.isTrue,
                ),
              ),
            ),
            SceneNode(
              id: 'award',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(
                  factId: 'checked-trainer-branch',
                  value: true,
                ),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            _edge('enter', 'start', 'completed', 'condition'),
            _edge('owned', 'condition', 'true', 'award'),
            _edge('not-owned', 'condition', 'false', 'end'),
            _edge('finish', 'award', 'completed', 'end'),
          ],
        ),
      ),
    ],
  ),
);

SceneEdge _edge(String id, String from, String port, String to) => SceneEdge(
  id: id,
  fromNodeId: from,
  fromPortId: port,
  toNodeId: to,
  kind: switch (port) {
    'true' => SceneEdgeKind.conditionTrue,
    'false' => SceneEdgeKind.conditionFalse,
    _ => SceneEdgeKind.defaultFlow,
  },
);
