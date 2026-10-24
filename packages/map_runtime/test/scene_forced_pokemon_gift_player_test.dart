import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/scene_catalog_pokemon_gift_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final destination in ['party', 'pc', 'noCapacity']) {
    testWidgets(
      'Player forced gift $destination survives nickname and reload',
      (tester) async {
        await tester.runAsync(() async {
          final root = await Directory.systemTemp.createTemp(
            'forced-gift-player-',
          );
          addTearDown(() => root.delete(recursive: true));
          final config = await writeSceneCatalogPokemonGiftFixture(root);
          final movesFile = File('${root.path}/custom/moves.json');
          final moves = jsonDecode(
            await movesFile.readAsString(),
          ) as Map<String, dynamic>;
          (moves['entries'] as List<dynamic>).add(
            const PokemonMove(
              id: 'extreme_speed',
              name: 'Vitesse Extrême',
              type: 'steel',
              category: PokemonMoveCategory.physical,
              accuracy: PokemonMoveAccuracy.percent(value: 100),
              pp: 5,
            ).toJson(),
          );
          await movesFile.writeAsString(jsonEncode(moves));
          final bundle = _bundle(root, config);
          final initial = GameState(
            saveId: 'forced-gift-player',
            currentMapId: 'map',
            party: PlayerParty(
              members: [
                if (destination != 'party')
                  for (var index = 0; index < 6; index++)
                    _owned('owned-$index'),
              ],
            ),
            pokemonStorage: PokemonStorage(
              boxes: [
                PokemonBox(
                  id: 'box',
                  label: 'Box',
                  capacity: 1,
                  pokemon: [if (destination == 'noCapacity') _owned('stored')],
                ),
              ],
            ),
          );
          final first = await _start(tester, bundle, initial);
          var snapshot = first.game.gameStateSnapshot;
          if (destination == 'noCapacity') {
            expect(snapshot.party, initial.party);
            expect(snapshot.pokemonStorage, initial.pokemonStorage);
            expect(snapshot.appliedPokemonGrantOperationIds, isEmpty);
            expect(first.requests, isEmpty);
            expect(snapshot.trainerProfile.money, initial.trainerProfile.money);
            snapshot = snapshot.copyWith(
              party: snapshot.party.copyWith(
                members: snapshot.party.members.skip(1).toList(),
              ),
            );
          } else {
            _expectGift(snapshot, destination);
            expect(first.requests.map((request) => request.stage), [
              PokemonGiftInteractionStage.received,
              PokemonGiftInteractionStage.nickname,
              PokemonGiftInteractionStage.received,
            ]);
            expect(
              snapshot.trainerProfile.money,
              initial.trainerProfile.money + 5,
            );
          }
          final saveFile = File('${root.path}/save.json');
          await saveFile.writeAsString(
            jsonEncode(saveDataFromGameState(snapshot).toJson()),
          );
          final save = SaveData.fromJson(
            jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>,
          );
          final second = await _start(
            tester,
            bundle,
            gameStateFromSaveData(save),
            restoring: true,
          );
          final restored = second.game.gameStateSnapshot;
          _expectGift(
            restored,
            destination == 'noCapacity' ? 'party' : destination,
          );
          expect(
            restored.trainerProfile.money,
            initial.trainerProfile.money + 5,
          );
          expect(restored.appliedPokemonGrantOperationIds, hasLength(1));
          expect(
            second.requests,
            destination == 'noCapacity' ? isNotEmpty : isEmpty,
          );
          expect(restored.progression.caughtSpeciesIds, contains('clockbird'));
          if (destination == 'noCapacity') {
            await saveFile.writeAsString(
              jsonEncode(saveDataFromGameState(restored).toJson()),
            );
            final afterRetry = SaveData.fromJson(
              jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>,
            );
            final third = await _start(
              tester,
              bundle,
              gameStateFromSaveData(afterRetry),
              restoring: true,
            );
            expect(third.requests, isEmpty);
            expect(third.game.gameStateSnapshot.party, restored.party);
            expect(
              third.game.gameStateSnapshot.pokemonStorage,
              restored.pokemonStorage,
            );
            expect(
              third.game.gameStateSnapshot.trainerProfile.money,
              restored.trainerProfile.money,
            );
            expect(
              third.game.gameStateSnapshot.appliedPokemonGrantOperationIds,
              restored.appliedPokemonGrantOperationIds,
            );
          }
        });
      },
    );
  }
}

void _expectGift(GameState state, String destination) {
  final pokemon = destination == 'party'
      ? state.party.members.last
      : state.pokemonStorage.storedPokemon.single;
  expect(pokemon.nickname, 'Pendule');
  expect(pokemon.knownMoveIds, ['extreme_speed']);
  expect(pokemon.currentPpByMoveId, {'extreme_speed': 5});
  expect(pokemon.provenance!.kind, PlayerPokemonOriginKind.gift);
}

Future<
  ({PlayableMapGame game, List<OpenPokemonGiftInteractionService> requests})
>
_start(
  WidgetTester tester,
  RuntimeMapBundle bundle,
  GameState state, {
  bool restoring = false,
}) async {
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: '${bundle.projectRootDirectory}/project.json',
    saveData: saveDataFromGameState(state),
    initialMapActivationReason: restoring
        ? MapActivationReason.saveRestore
        : MapActivationReason.initialBoot,
  );
  addTearDown(game.onRemove);
  final controller = PlayerServiceRuntimeController.contextual(
    currentGameState: () => game.gameStateSnapshot,
    commitAndSave: (_) async =>
        fail('The interactive presenter must not commit privately.'),
    setInputLocked: (_) {},
    loadRecoveryCaps: (_) async =>
        const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
    projectRootDirectory: bundle.projectRootDirectory,
    pokemonConfig: bundle.manifest.pokemon,
  );
  addTearDown(controller.dispose);
  game.setPlayerServiceRuntimeController(controller);
  final requests = <OpenPokemonGiftInteractionService>[];
  final subscription = controller.worldServiceSnapshots.listen((snapshot) {
    if (snapshot?.request
        case final OpenPokemonGiftInteractionService request) {
      requests.add(request);
      final interaction = request.interaction;
      final response = switch (interaction) {
        SceneChoiceInteractionRequest() =>
          SceneInteractionResult.choiceSelected(
            requestId: interaction.requestId,
            revision: interaction.revision,
            selectedOptionId: interaction.revision == 0
                ? 'nickname'
                : 'continue',
          ),
        SceneTextInteractionRequest() => SceneInteractionResult.textSubmitted(
          requestId: interaction.requestId,
          revision: interaction.revision,
          value: 'Pendule',
        ),
        _ => SceneInteractionResult.acknowledged(
          requestId: interaction.requestId,
          revision: interaction.revision,
        ),
      };
      controller.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.confirm,
          snapshotRevision: snapshot!.revision,
          interactionResult: response,
        ),
      );
    }
  });
  addTearDown(subscription.cancel);
  game.onGameResize(Vector2(320, 240));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  await game.loaded;
  await tester.pump();
  await game.debugWaitForBattlePrewarm();
  for (
    var index = 0;
    index < 1500 && game.debugIsMapActivationDispatchInFlight;
    index++
  ) {
    game.update(0);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(game.debugIsMapActivationDispatchInFlight, isFalse);
  return (game: game, requests: requests);
}

RuntimeMapBundle _bundle(Directory root, ProjectPokemonConfig config) =>
    RuntimeMapBundle(
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: const {},
      map: const MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 8, height: 8),
        layers: [],
        entities: [
          MapEntity(
            id: 'spawn',
            name: 'Spawn',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 1, y: 1),
            blocksMovement: false,
            spawn: MapEntitySpawnData(
              role: EntitySpawnRole.playerStart,
              facing: EntityFacing.south,
            ),
          ),
        ],
        mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
      ),
      manifest: ProjectManifest(
        name: 'Forced gift fixture',
        pokemon: config,
        tilesets: [],
        maps: [
          const ProjectMapEntry(
            id: 'map',
            name: 'Map',
            relativePath: 'maps/map.json',
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          legacyClaims: const [],
          records: [
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: 'evt_019abcde-1200-7000-8000-000000000001',
                name: 'Gift on entry',
                source: NarrativeEventSourceRef.mapEnter('map'),
                sceneId: 'gift',
                conditions: const [],
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
              enabled: true,
            ),
          ],
        ),
        scenes: [
          SceneAsset(
            id: 'gift',
            name: 'Gift',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                  id: 'receive',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.interactive(
                    SceneInteractiveCommand.receivePokemonFromCatalog(
                      speciesId: 'clockbird',
                      formId: 'bronze',
                      level: 7,
                      moveIds: ['extreme_speed'],
                      nicknamePolicy: ScenePokemonGiftNicknamePolicy.offer,
                      nicknameMaxGraphemes: 12,
                      pokedexPresentationPolicy:
                          ScenePokemonGiftPokedexPresentationPolicy.never,
                    ),
                  ),
                ),
                SceneNode(
                  id: 'reward',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.consequence(
                    SceneConsequence.giveMoney(amount: 5),
                  ),
                ),
                SceneNode(id: 'received', kind: SceneNodeKind.end),
                SceneNode(id: 'refused', kind: SceneNodeKind.end),
              ],
              edges: [
                _edge('start', 'start', 'completed', 'receive'),
                _edge('party', 'receive', 'party', 'reward'),
                _edge('pc', 'receive', 'pc', 'reward'),
                _edge('full', 'receive', 'noCapacity', 'refused'),
                _edge('reward', 'reward', 'completed', 'received'),
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
  kind: port == 'completed' && from == 'start'
      ? SceneEdgeKind.defaultFlow
      : SceneEdgeKind.actionCompleted,
);

PlayerPokemon _owned(String id) => PlayerPokemon(
  individualId: id,
  speciesId: 'clockbird',
  formId: 'bronze',
  natureId: 'hardy',
  abilityId: 'clockwork',
  level: 7,
  experience: 343,
  currentHp: 10,
  knownMoveIds: const ['tick'],
  currentPpByMoveId: const {'tick': 13},
);
