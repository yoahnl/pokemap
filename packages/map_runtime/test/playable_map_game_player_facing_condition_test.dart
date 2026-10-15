import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final actual in Direction.values) {
    for (final direction in EntityFacing.values) {
      testWidgets(
        'mounted Player reads $actual against $direction from its live world',
        (tester) async {
          await tester.runAsync(() async {
            final bundle = _bundle(direction);
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
              projectFilePath: '/tmp/scene-facing/project.json',
              saveData: saveDataFromGameState(
                GameState(
                  saveId: 'facing-test',
                  trainerProfile: const TrainerProfile(name: 'Player'),
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
            game.debugSetPlayerStateForTest(
              position: const GridPos(x: 1, y: 1),
              facing: actual,
            );
            final result = await game.debugExecuteNarrativeSceneForTest(
              NarrativeSceneExecutionRequest(
                eventId: 'facing-event',
                sceneId: 'facing-check',
                executionId: 'facing-run',
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
                  .overridesByFactId['matches-facing'],
              actual.asFacing == direction ? isTrue : isNull,
            );
          });
        },
      );
    }
  }
}

RuntimeMapBundle _bundle(EntityFacing direction) => RuntimeMapBundle(
  projectRootDirectory: '/tmp/scene-facing',
  tilesetAbsolutePathsById: const {},
  map: const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 8, height: 8),
    layers: [],
  ),
  manifest: ProjectManifest(
    name: 'Facing scene',
    maps: [
      const ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'maps/map.json',
      ),
    ],
    tilesets: [],
    facts: [
      NarrativeFactDefinition(id: 'matches-facing', label: 'Facing checked'),
    ],
    scenes: [
      SceneAsset(
        id: 'facing-check',
        name: 'Facing check',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'condition',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource.playerFacing(
                  direction: direction,
                ),
              ),
            ),
            SceneNode(
              id: 'award',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: 'matches-facing', value: true),
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
