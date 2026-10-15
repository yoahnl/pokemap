import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final captured in [19, 20, 21]) {
    testWidgets(
      'mounted Player resolves caught history $captured through its native species catalogue',
      (tester) async {
        await tester.runAsync(() async {
          final root = await Directory.systemTemp.createTemp(
            'native-pokedex-scene-',
          );
          addTearDown(() => root.delete(recursive: true));
          for (var i = 1; i <= 20; i++) {
            final file = File('${root.path}/data/pokemon/species/mon$i.json');
            await file.parent.create(recursive: true);
            await file.writeAsString(
              jsonEncode({
                'schemaVersion': currentPokemonDataSchemaVersion,
                'id': 'mon$i',
                'nationalDex': i,
                'typing': {
                  'types': ['grass'],
                },
                'baseStats': {
                  'hp': 45,
                  'atk': 49,
                  'def': 49,
                  'spa': 65,
                  'spd': 65,
                  'spe': 45,
                },
                'abilities': {'primary': 'overgrow'},
                'refs': {'learnset': 'mon$i'},
                'progression': {
                  'growthRateId': 'medium_slow',
                  'baseExp': 64,
                  'catchRate': 45,
                },
              }),
            );
          }
          final bundle = _bundle(root.path);
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
            projectFilePath: '${root.path}/project.json',
            saveData: saveDataFromGameState(
              GameState(
                saveId: 'pokedex-test',
                trainerProfile: const TrainerProfile(name: 'Player'),
                progression: PlayerProgression(
                  caughtSpeciesIds: [
                    for (var i = 1; i <= captured; i++) 'mon$i',
                  ],
                ),
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
          var finished = false;
          final resultFuture = game.debugExecuteNarrativeSceneForTest(
            NarrativeSceneExecutionRequest(
              eventId: 'pokedex-event',
              sceneId: 'pokedex-check',
              executionId: 'pokedex-run',
              gameState: game.gameStateSnapshot,
            ),
          );
          final observed = resultFuture.whenComplete(() => finished = true);
          var snapshotReads = 0;
          while (!finished) {
            final revision = game.debugGameStateRevision;
            game.gameStateSnapshot;
            game.saveLoadInfo;
            expect(game.debugGameStateRevision, revision);
            snapshotReads += 1;
            game.update(0);
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          final result = await observed;
          expect(snapshotReads, greaterThan(0));
          if (captured == 21) {
            expect(result, isA<NarrativeSceneExecutionFailed>());
            expect(
              game
                  .gameStateSnapshot
                  .narrativeFactRuntimeState
                  .overridesByFactId['captured-threshold'],
              isNull,
            );
            return;
          }
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
                .overridesByFactId['captured-threshold'],
            captured >= 20 ? isTrue : isNull,
          );
        });
      },
    );
  }
}

RuntimeMapBundle _bundle(String root) => RuntimeMapBundle(
  projectRootDirectory: root,
  tilesetAbsolutePathsById: const {},
  map: const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 8, height: 8),
    layers: [],
  ),
  manifest: ProjectManifest(
    name: 'Pokédex scene',
    maps: [
      const ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'maps/map.json',
      ),
    ],
    tilesets: [],
    facts: [
      NarrativeFactDefinition(id: 'captured-threshold', label: 'Pokédex checked'),
    ],
    scenes: [
      SceneAsset(
        id: 'pokedex-check',
        name: 'Pokédex check',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'condition',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource.pokedexCaughtAtLeast(
                  range: PokedexSpeciesRange(
                    firstNationalDex: 1,
                    lastNationalDex: 151,
                  ),
                  minimum: 20,
                ),
              ),
            ),
            SceneNode(
              id: 'award',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: 'captured-threshold', value: true),
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
