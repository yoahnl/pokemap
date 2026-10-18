import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

import 'support/scene_catalog_pokemon_gift_fixture.dart';

void main() {
  for (final (eventV2, forced) in [
    for (final eventV2 in [false, true])
      for (final forced in [false, true]) (eventV2, forced),
  ]) {
    for (final destination in ['party', 'pc', 'noCapacity']) {
      test(
        'native gift forced=$forced V2=$eventV2 destination=$destination commits suffix and preserves one-shot on noCapacity',
        () async {
          final root = await Directory.systemTemp.createTemp(
            'native-gift-host-',
          );
          addTearDown(() => root.delete(recursive: true));
          final config = await writeSceneCatalogPokemonGiftFixture(root);
          if (forced) {
            final file = File('${root.path}/custom/moves.json');
            final document =
                jsonDecode(await file.readAsString()) as Map<String, dynamic>;
            (document['entries'] as List<dynamic>).addAll([
              for (final entry in {'swift-gift': 5, 'echo-gift': 7}.entries)
                PokemonMove(
                  id: entry.key,
                  name: entry.key,
                  type: 'steel',
                  category: PokemonMoveCategory.physical,
                  accuracy: const PokemonMoveAccuracy.percent(value: 100),
                  pp: entry.value,
                ).toJson(),
            ]);
            await file.writeAsString(jsonEncode(document));
          }
          final scene = _scene(forced: forced);
          final project = ProjectManifest(
            name: 'Gift integration',
            maps: [],
            tilesets: [],
            scenes: [scene],
            pokemon: config,
          );
          final catalog = await loadRuntimeScenePokemonCatalog(
            scene: scene,
            projectRootDirectory: root.path,
            pokemonConfig: config,
          );
          expect(catalog, isNotNull);
          expect(catalog!.failures, isEmpty);
          var initial = const GameState(
            saveId: 'gift-native',
            currentMapId: 'lab',
          );
          if (destination != 'party') {
            final seed = catalog.generate(
              consequence: SceneGivePokemonFromCatalogConsequence(
                speciesId: 'clockbird',
                formId: 'bronze',
                level: 7,
              ),
              state: initial,
              operationId: 'seed',
              ruleset: config.ruleset,
            );
            for (var i = 0; i < 6; i++) {
              initial = const GameStateMutations().givePokemonOnce(
                initial,
                grantOperationId: 'seed$i',
                pokemon: seed.copyWith(
                  speciesId: 'seed-species',
                  individualId: 'seed$i',
                ),
              );
            }
            if (destination == 'noCapacity') {
              initial = initial.copyWith(
                pokemonStorage: PokemonStorage(
                  boxes: [
                    PokemonBox(
                      id: 'full',
                      label: 'Full',
                      capacity: 1,
                      pokemon: [
                        seed.copyWith(
                          speciesId: 'seed-species',
                          individualId: 'stored',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          }
          final requests = <OpenPokemonGiftInteractionService>[];
          final locks = <bool>[];
          var immediateWrites = 0;
          final controller = PlayerServiceRuntimeController.contextual(
            currentGameState: () => initial,
            commitAndSave: (_) async {
              immediateWrites++;
            },
            setInputLocked: locks.add,
            loadRecoveryCaps: (_) async =>
                const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
            projectRootDirectory: root.path,
            pokemonConfig: config,
          );
          addTearDown(controller.dispose);
          final subscription = controller.worldServiceSnapshots.listen((
            snapshot,
          ) {
            if (snapshot?.request
                case final OpenPokemonGiftInteractionService request) {
              requests.add(request);
              final interaction = request.interaction;
              final result = switch (interaction) {
                SceneConfirmationInteractionRequest() =>
                  SceneInteractionResult.confirmed(
                    requestId: interaction.requestId,
                    revision: interaction.revision,
                    value: true,
                  ),
                SceneTextInteractionRequest() =>
                  SceneInteractionResult.textSubmitted(
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
                  interactionResult: result,
                ),
              );
            }
          });
          addTearDown(subscription.cancel);
          final callbacks = SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => 'true',
            showDialogue: (_) => 'completed',
            startBattle: (_) => 'victory',
            playCinematic: (_) => 'completed',
            presentPokemonGift: (request) async {
              expect(
                initial.appliedPokemonGrantOperationIds,
                isNot(contains('scene:gift:run:receive')),
              );
              expect(
                request.projectedState.trainerProfile.money,
                initial.trainerProfile.money + 25,
              );
              return controller.openPokemonGiftInteraction(request: request);
            },
          );
          final writer = SceneConsequenceRuntimeWriter(
            project: project,
            pokemonCatalog: catalog,
          );
          final committed = await _execute(
            eventV2,
            project,
            writer,
            initial,
            callbacks,
          );
          expect(immediateWrites, 0);
          expect(
            committed.trainerProfile.money,
            initial.trainerProfile.money + 75,
          );
          if (destination == 'noCapacity') {
            expect(requests, isEmpty);
            expect(committed.party, initial.party);
            expect(committed.pokemonStorage, initial.pokemonStorage);
            expect(committed.progression, initial.progression);
            expect(
              committed.appliedPokemonGrantOperationIds,
              initial.appliedPokemonGrantOperationIds,
            );
            final freed = committed.copyWith(
              party: committed.party.copyWith(
                members: committed.party.members.skip(1).toList(),
              ),
            );
            final retry = await _execute(
              eventV2,
              project,
              writer,
              freed,
              SceneRuntimeHostCallbacks(
                evaluateCondition: (_) => 'true',
                showDialogue: (_) => 'completed',
                startBattle: (_) => 'victory',
                playCinematic: (_) => 'completed',
                presentPokemonGift: (r) async => switch (r.interaction) {
                  SceneConfirmationInteractionRequest() =>
                    SceneInteractionResult.confirmed(
                      requestId: r.interaction.requestId,
                      revision: r.interaction.revision,
                      value: false,
                    ),
                  _ => SceneInteractionResult.acknowledged(
                    requestId: r.interaction.requestId,
                    revision: r.interaction.revision,
                  ),
                },
              ),
            );
            expect(retry.party.members.last.speciesId, 'clockbird');
            expect(
              retry.party.members.last.knownMoveIds,
              forced ? ['swift-gift', 'echo-gift'] : ['tick', 'tock'],
            );
            expect(
              retry.appliedPokemonGrantOperationIds,
              contains('scene:gift:run:receive'),
            );
          } else {
            expect(requests.map((r) => r.stage), [
              PokemonGiftInteractionStage.received,
              PokemonGiftInteractionStage.pokedex,
              PokemonGiftInteractionStage.nicknameConfirmation,
              PokemonGiftInteractionStage.nickname,
              PokemonGiftInteractionStage.destination,
            ]);
            final dex = requests
                .singleWhere(
                  (r) => r.stage == PokemonGiftInteractionStage.pokedex,
                )
                .pokedexDetail!;
            expect(dex.entries, hasLength(1));
            expect(
              dex.entries.single.pokedexEntry!.knowledge,
              RuntimePlayerPokedexKnowledge.caught,
            );
            expect(
              dex.entries.single.pokedexEntry!.identity!.speciesId,
              'clockbird',
            );
            expect(dex.entries.single.pokedexEntry!.identity!.formId, 'bronze');
            expect(dex.entries.single.pokedexEntry!.typeIds, ['steel']);
            final shown = requests.last.pokemon;
            final granted = destination == 'party'
                ? committed.party.members.last
                : committed.pokemonStorage.storedPokemon.single;
            expect(granted, shown);
            expect(granted.nickname, 'Pendule');
            expect(
              granted.knownMoveIds,
              forced ? ['swift-gift', 'echo-gift'] : ['tick', 'tock'],
            );
            expect(
              granted.currentPpByMoveId,
              forced
                  ? {'swift-gift': 5, 'echo-gift': 7}
                  : {'tick': 13, 'tock': 19},
            );
            expect(
              committed.progression.caughtSpeciesIds,
              contains('clockbird'),
            );
            expect(
              committed.appliedPokemonGrantOperationIds,
              contains('scene:gift:run:receive'),
            );
            final reloaded = GameState.fromJson(
              jsonDecode(jsonEncode(committed.toJson()))
                  as Map<String, dynamic>,
            );
            expect(reloaded.party, committed.party);
            expect(reloaded.pokemonStorage, committed.pokemonStorage);
            expect(reloaded.progression, committed.progression);
            final replay = await _execute(
              eventV2,
              project,
              writer,
              reloaded,
              SceneRuntimeHostCallbacks(
                evaluateCondition: (_) => 'true',
                showDialogue: (_) => 'completed',
                startBattle: (_) => 'victory',
                playCinematic: (_) => 'completed',
                presentPokemonGift: (_) => throw StateError(
                  'An applied gift must not be presented again',
                ),
              ),
            );
            expect(replay.party, committed.party);
            expect(replay.pokemonStorage, committed.pokemonStorage);
            expect(locks.where((v) => v).length, requests.length);
            expect(locks.where((v) => !v).length, requests.length);
          }
        },
      );
    }
  }
}

Future<GameState> _execute(
  bool eventV2,
  ProjectManifest project,
  SceneConsequenceRuntimeWriter writer,
  GameState initial,
  SceneRuntimeHostCallbacks callbacks,
) async {
  if (eventV2) {
    final result = await executeNarrativeEventScene(
      request: NarrativeSceneExecutionRequest(
        eventId: 'event',
        sceneId: 'gift',
        executionId: 'run',
        gameState: initial,
      ),
      project: project,
      mapsById: {},
      currentGameState: () => initial,
      callbacks: callbacks,
      consequenceWriter: writer,
    );
    expect(result, isA<NarrativeSceneExecutionCompleted>());
    final completed = result as NarrativeSceneExecutionCompleted;
    expect(
      completed.consumeOneShot,
      initial.party.members.length < 6 ||
          initial.pokemonStorage.boxes.any(
            (box) => box.pokemon.length < box.capacity,
          ),
    );
    return completed.updatedGameState;
  }
  const page = MapEventPage(
    pageNumber: 0,
    sceneTarget: MapEventSceneTarget(sceneId: 'gift'),
  );
  const event = MapEventDefinition(
    id: 'event',
    pages: [page],
    position: EventPosition(layerId: 'base', x: 0, y: 0),
  );
  final map = MapData(
    id: 'lab',
    name: 'Lab',
    size: const GridSize(width: 1, height: 1),
    layers: [],
  );
  final result =
      await SceneEventRuntimeHook(
        callbacks: callbacks,
        consequenceWriter: writer,
      ).runForEventPage(
        project: project,
        map: map,
        event: event,
        page: page,
        gameState: initial,
        executionId: 'run',
      );
  expect(result.success, isTrue, reason: result.message);
  return result.updatedGameState!;
}

SceneAsset _scene({bool forced = false}) => SceneAsset(
  id: 'gift',
  name: 'Gift',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'before',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.giveMoney(amount: 25),
        ),
      ),
      SceneNode(
        id: 'receive',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.receivePokemonFromCatalog(
            speciesId: 'clockbird',
            formId: 'bronze',
            level: 7,
            moveIds: forced ? ['swift-gift', 'echo-gift'] : null,
            nicknamePolicy: ScenePokemonGiftNicknamePolicy.offer,
            nicknameMaxGraphemes: 10,
            pokedexPresentationPolicy: ScenePokemonGiftPokedexPresentationPolicy
                .whenNewAndPokedexVisible,
          ),
        ),
      ),
      SceneNode(
        id: 'route',
        kind: SceneNodeKind.branchByOutcome,
        payload: SceneBranchByOutcomePayload(
          sourceNodeId: 'receive',
          sourceOutcomeSetRef: 'receive',
          fallbackPolicy: SceneBranchOutcomeFallbackPolicy.exact,
        ),
      ),
      for (final port in ['party', 'pc', 'noCapacity']) ...[
        SceneNode(
          id: 'after-$port',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.giveMoney(amount: 50),
          ),
        ),
        SceneNode(id: 'end-$port', kind: SceneNodeKind.end),
      ],
    ],
    edges: [
      SceneEdge(
        id: 'a',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'before',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'b',
        fromNodeId: 'before',
        fromPortId: 'completed',
        toNodeId: 'receive',
        kind: SceneEdgeKind.actionCompleted,
      ),
      for (final port in ['party', 'pc', 'noCapacity']) ...[
        SceneEdge(
          id: port,
          fromNodeId: 'receive',
          fromPortId: port,
          toNodeId: 'route',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'route-$port',
          fromNodeId: 'route',
          fromPortId: port,
          toNodeId: 'after-$port',
          kind: SceneEdgeKind.branchOutcome,
        ),
        SceneEdge(
          id: 'end-$port',
          fromNodeId: 'after-$port',
          fromPortId: 'completed',
          toNodeId: 'end-$port',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ],
  ),
);
