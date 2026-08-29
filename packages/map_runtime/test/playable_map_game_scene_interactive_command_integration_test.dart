import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PlayableMapGame installs shop and PC Scene command callbacks',
      () async {
    const initial = GameState(saveId: 'scene-services');
    final host = _PlayerServiceHost();
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/scene-services/project.json',
      saveData: saveDataFromGameState(initial),
    );
    final controller = PlayerServiceRuntimeController(
      currentGameState: () => game.playerServiceGameStateSnapshot,
      host: host,
      commitAndSave: (_) async {},
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );
    game.setPlayerServiceRuntimeController(controller);

    final shopPort = await game.debugExecuteSceneInteractiveCommand(
      SceneInteractiveCommand.openShop(shopId: 'shop.port'),
    );
    final healPort = await game.debugExecuteSceneInteractiveCommand(
      SceneInteractiveCommand.openHeal(),
    );
    final pcPort = await game.debugExecuteSceneInteractiveCommand(
      SceneInteractiveCommand.openPc(),
    );

    expect(shopPort, 'completed');
    expect(healPort, 'completed');
    expect(pcPort, 'cancelled');
    expect(host.shopCalls, 1);
    expect(host.healCalls, 1);
    expect(host.pcCalls, 1);
  });

  test('PlayableMapGame maps missing services to declared Scene ports',
      () async {
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/scene-services/project.json',
    );

    expect(
      await game.debugExecuteSceneInteractiveCommand(
        SceneInteractiveCommand.openShop(shopId: 'shop.missing'),
      ),
      'cancelled',
    );
    expect(
      await game.debugExecuteSceneInteractiveCommand(
        SceneInteractiveCommand.openHeal(),
      ),
      'cancelled',
    );
    expect(
      await game.debugExecuteSceneInteractiveCommand(
        SceneInteractiveCommand.openPc(),
      ),
      'cancelled',
    );
  });

  test(
      'PlayableMapGame commits one exact RailJourney transition and persists it',
      () async {
    final animatedDoorIds = <String>[];
    final transitions = <RailJourneyRuntimeTransition>[];
    final game = PlayableMapGame(
      bundle: _railBundle(),
      projectFilePath: '/tmp/scene-rail/project.json',
      saveData: saveDataFromGameState(_railReadyState()),
      railJourneyDoorAnimation: (placedElementId) async {
        animatedDoorIds.add(placedElementId);
        return true;
      },
      railJourneySpatialTransition: (transition) async {
        transitions.add(transition);
        return true;
      },
    );

    final before = game.playerServiceGameStateSnapshot;
    expect(before.currentMapId, 'map_origin');
    expect(before.playerPosition, const GridPos(x: 3, y: 3));
    expect(before.progression.completedStepIds, contains('step_ready'));
    expect(
      before.bag.entries,
      contains(const BagEntry(itemId: 'item_ticket', quantity: 1)),
    );
    expect(
      before.narrativeFactRuntimeState.valuesByFactId['fact_signal_seen'],
      const NarrativeValue.boolean(true),
    );
    expect(
      before.railJourneyProgress.semanticCurrencyBalances['line_tokens'],
      4,
    );

    final firstPort = await game.debugExecuteSceneInteractiveCommand(
      _railBeginCommand(),
      executionId: 'rail-execution-1',
    );
    final committed = game.playerServiceGameStateSnapshot;

    expect(animatedDoorIds, <String>['door_origin_west']);
    expect(
      transitions,
      const <RailJourneyRuntimeTransition>[
        RailJourneyRuntimeTransition(
          destinationMapId: 'map_vehicle',
          destinationPosition: GridPos(x: 2, y: 10),
          doorSide: RailJourneyDoorSide.west,
          sourceDoorPlacedElementId: 'door_origin_west',
          destinationDoorPlacedElementId: 'door_vehicle_west',
        ),
      ],
    );
    expect(firstPort, 'completed');
    expect(committed.currentMapId, 'map_vehicle');
    expect(committed.playerPosition, const GridPos(x: 2, y: 10));
    expect(
      committed.railJourneyProgress.lifecycle,
      RailJourneyLifecycle.boarding,
    );
    expect(
      committed.railJourneyProgress.semanticCurrencyBalances['line_tokens'],
      1,
    );
    expect(
      committed.railJourneyProgress.appliedOperations.keys,
      contains(
        'rail:debug:interactive-command:rail-execution-1:board-t1',
      ),
    );

    final replayPort = await game.debugExecuteSceneInteractiveCommand(
      _railBeginCommand(),
      executionId: 'rail-execution-1',
    );

    expect(replayPort, 'completed');
    expect(animatedDoorIds, hasLength(1));
    expect(transitions, hasLength(1));
    expect(
      game.playerServiceGameStateSnapshot.railJourneyProgress
          .semanticCurrencyBalances['line_tokens'],
      1,
    );

    final encoded = jsonEncode(saveDataFromGameState(committed).toJson());
    final restoredSave = SaveData.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    final restoredGame = PlayableMapGame(
      bundle: _railBundle(),
      projectFilePath: '/tmp/scene-rail/project.json',
      saveData: restoredSave,
      railJourneyDoorAnimation: (_) async => true,
      railJourneySpatialTransition: (_) async => true,
    );
    final restored = restoredGame.playerServiceGameStateSnapshot;

    expect(restored.currentMapId, 'map_vehicle');
    expect(restored.playerPosition, const GridPos(x: 2, y: 10));
    expect(
      restored.railJourneyProgress,
      committed.railJourneyProgress,
    );
  });

  test(
      'separate executions of the same RailJourney command use distinct receipts',
      () async {
    Future<GameState> execute(String executionId) async {
      final game = PlayableMapGame(
        bundle: _railBundle(),
        projectFilePath: '/tmp/scene-rail/project.json',
        saveData: saveDataFromGameState(_railReadyState()),
        railJourneyDoorAnimation: (_) async => true,
        railJourneySpatialTransition: (_) async => true,
      );

      expect(
        await game.debugExecuteSceneInteractiveCommand(
          _railBeginCommand(),
          executionId: executionId,
        ),
        'completed',
      );
      return game.playerServiceGameStateSnapshot;
    }

    final first = await execute('rail-execution-a');
    final second = await execute('rail-execution-b');

    expect(
      first.railJourneyProgress.appliedOperations.keys,
      contains(
        'rail:debug:interactive-command:rail-execution-a:board-t1',
      ),
    );
    expect(
      second.railJourneyProgress.appliedOperations.keys,
      contains(
        'rail:debug:interactive-command:rail-execution-b:board-t1',
      ),
    );
    expect(
      first.railJourneyProgress.appliedOperations.keys.single,
      isNot(second.railJourneyProgress.appliedOperations.keys.single),
    );
  });

  test('two complete Scene cycles keep execution identity and replay safety',
      () async {
    final scene = _railScene();

    PlayableMapGame createGame(
      GameState state,
      List<RailJourneyRuntimeTransition> transitions,
    ) {
      return PlayableMapGame(
        bundle: _railBundle(scenes: <SceneAsset>[scene]),
        projectFilePath: '/tmp/scene-rail/project.json',
        saveData: saveDataFromGameState(state),
        runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
          return Future<RuntimeMapBundle>.value(
            _railBundle(
              scenes: <SceneAsset>[scene],
              mapId: mapId,
            ),
          );
        },
        railJourneyDoorAnimation: (_) async => true,
        railJourneySpatialTransition: (transition) async {
          transitions.add(transition);
          return true;
        },
      );
    }

    Future<NarrativeSceneExecutionCompleted> execute(
      PlayableMapGame game,
      String executionId,
    ) async {
      final initial = game.playerServiceGameStateSnapshot;
      final result = await game.debugExecuteNarrativeSceneForTest(
        NarrativeSceneExecutionRequest(
          eventId: 'event_rail_cycle',
          sceneId: scene.id,
          executionId: executionId,
          gameState: initial,
        ),
      );
      expect(result, isA<NarrativeSceneExecutionCompleted>());
      return result as NarrativeSceneExecutionCompleted;
    }

    final firstTransitions = <RailJourneyRuntimeTransition>[];
    final first = await execute(
      createGame(_railReadyState(), firstTransitions),
      'rail-scene-cycle-a',
    );
    final secondTransitions = <RailJourneyRuntimeTransition>[];
    final second = await execute(
      createGame(_railReadyState(), secondTransitions),
      'rail-scene-cycle-b',
    );
    final replayTransitions = <RailJourneyRuntimeTransition>[];
    final replay = await execute(
      createGame(first.updatedGameState, replayTransitions),
      'rail-scene-cycle-a',
    );

    const firstOperationId =
        'rail:event-v2:event_rail_cycle:rail-scene-cycle-a:board-t1';
    const secondOperationId =
        'rail:event-v2:event_rail_cycle:rail-scene-cycle-b:board-t1';
    expect(firstTransitions, hasLength(1));
    expect(secondTransitions, hasLength(1));
    expect(replayTransitions, isEmpty);
    expect(
      first.updatedGameState.railJourneyProgress.appliedOperations.keys,
      contains(firstOperationId),
    );
    expect(
      second.updatedGameState.railJourneyProgress.appliedOperations.keys,
      contains(secondOperationId),
    );
    expect(replay.updatedGameState, first.updatedGameState);
  });

  test('later Scene failure compensates a completed RailJourney command',
      () async {
    final scene = _railScene(failAfterRail: true);
    var animationCalls = 0;
    var transitionCalls = 0;
    final game = PlayableMapGame(
      bundle: _railBundle(scenes: <SceneAsset>[scene]),
      projectFilePath: '/tmp/scene-rail/project.json',
      saveData: saveDataFromGameState(_railReadyState()),
      runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
        return Future<RuntimeMapBundle>.value(
          _railBundle(
            scenes: <SceneAsset>[scene],
            mapId: mapId,
          ),
        );
      },
      railJourneyDoorAnimation: (_) async {
        animationCalls += 1;
        return true;
      },
      railJourneySpatialTransition: (_) async {
        transitionCalls += 1;
        return true;
      },
    );
    final initial = game.playerServiceGameStateSnapshot;

    final result = await game.debugExecuteNarrativeSceneForTest(
      NarrativeSceneExecutionRequest(
        eventId: 'event_rail_then_fail',
        sceneId: scene.id,
        executionId: 'rail-scene-failure-1',
        gameState: initial,
      ),
    );
    final restored = game.playerServiceGameStateSnapshot;

    expect(result, isA<NarrativeSceneExecutionFailed>());
    expect(animationCalls, 1);
    expect(transitionCalls, 1);
    expect(restored.currentMapId, initial.currentMapId);
    expect(restored.playerPosition, initial.playerPosition);
    expect(restored.railJourneyProgress, initial.railJourneyProgress);
  });

  test('PlayableMapGame keeps RailJourney progress atomic on spatial failure',
      () async {
    final initial = _railReadyState();
    var animationCalls = 0;
    var transitionCalls = 0;
    final game = PlayableMapGame(
      bundle: _railBundle(),
      projectFilePath: '/tmp/scene-rail/project.json',
      saveData: saveDataFromGameState(initial),
      railJourneyDoorAnimation: (placedElementId) async {
        animationCalls += 1;
        expect(placedElementId, 'door_origin_west');
        return true;
      },
      railJourneySpatialTransition: (transition) async {
        transitionCalls += 1;
        expect(transition.destinationMapId, 'map_vehicle');
        return false;
      },
    );

    final port = await game.debugExecuteSceneInteractiveCommand(
      _railBeginCommand(),
    );
    final unchanged = game.playerServiceGameStateSnapshot;

    expect(port, 'blocked');
    expect(animationCalls, 1);
    expect(transitionCalls, 1);
    expect(unchanged.currentMapId, 'map_origin');
    expect(unchanged.playerPosition, const GridPos(x: 3, y: 3));
    expect(
      unchanged.railJourneyProgress.lifecycle,
      RailJourneyLifecycle.idleAtOrigin,
    );
    expect(
      unchanged.railJourneyProgress.semanticCurrencyBalances['line_tokens'],
      4,
    );
    expect(unchanged.railJourneyProgress.appliedOperations, isEmpty);
  });
}

final class _PlayerServiceHost implements PlayerServiceOverlayHost {
  int shopCalls = 0;
  int healCalls = 0;
  int pcCalls = 0;

  @override
  Future<PlayerServiceHostResult> openShop(PlayerServiceShopRequest request) {
    shopCalls += 1;
    expect(request.worldRequest?.interactionId, 'scene.openShop:shop.port');
    expect(request.worldRequest?.shopId, 'shop.port');
    return Future<PlayerServiceHostResult>.value(
      PlayerServiceHostResult.completed(request.gameState),
    );
  }

  @override
  Future<PlayerServiceHostResult> openPc(PlayerServicePcRequest request) {
    pcCalls += 1;
    expect(request.worldRequest?.interactionId, 'scene.openPc:default');
    return Future<PlayerServiceHostResult>.value(
      const PlayerServiceHostResult.cancelled(),
    );
  }

  @override
  Future<PlayerServiceHostResult> openHealCenter(
    PlayerServiceHealRequest request,
  ) {
    healCalls += 1;
    expect(request.worldRequest?.interactionId, 'scene.openHeal');
    expect(request.worldRequest?.requiresConfirmation, isTrue);
    return Future<PlayerServiceHostResult>.value(
      PlayerServiceHostResult.completed(request.gameState),
    );
  }
}

RuntimeMapBundle _bundle() => RuntimeMapBundle(
      manifest: const ProjectManifest(
        name: 'Scene services',
        maps: <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: <ProjectTilesetEntry>[],
        shops: <ShopDefinition>[
          ShopDefinition(id: 'shop.port', label: 'Boutique du port'),
        ],
      ),
      map: const MapData(
        id: 'map.port',
        name: 'Port',
        size: GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          MapLayer.object(id: 'objects', name: 'Objects'),
        ],
      ),
      projectRootDirectory: '/tmp/scene-services',
      tilesetAbsolutePathsById: const <String, String>{},
    );

const _railOrigin = RailJourneyEndpoint(
  stationMapId: 'map_origin',
  boardingArea: MapRect(
    pos: GridPos(x: 2, y: 3),
    size: GridSize(width: 4, height: 2),
  ),
  trainEntryPos: GridPos(x: 2, y: 10),
  stationArrivalPos: GridPos(x: 4, y: 4),
  doors: <RailJourneyEndpointDoor>[
    RailJourneyEndpointDoor(
      side: RailJourneyDoorSide.west,
      stationPlacedElementId: 'door_origin_west',
      vehiclePlacedElementId: 'door_vehicle_west',
    ),
  ],
);

const _railDestination = RailJourneyEndpoint(
  stationMapId: 'map_destination',
  boardingArea: MapRect(
    pos: GridPos(x: 8, y: 3),
    size: GridSize(width: 4, height: 2),
  ),
  trainEntryPos: GridPos(x: 30, y: 10),
  stationArrivalPos: GridPos(x: 8, y: 8),
  doors: <RailJourneyEndpointDoor>[
    RailJourneyEndpointDoor(
      side: RailJourneyDoorSide.east,
      stationPlacedElementId: 'door_destination_east',
      vehiclePlacedElementId: 'door_vehicle_east',
    ),
  ],
);

const _railCatalog = RailJourneyCatalog(
  journeys: <RailJourneyDefinition>[
    RailJourneyDefinition(
      id: 'T1',
      label: 'Origin vers destination',
      origin: _railOrigin,
      destination: _railDestination,
      vehicleMapId: 'map_vehicle',
      vehicleVariant: RailJourneyVehicleVariant.regular,
      shellState: 'dusk',
      fare: RailJourneyFare(
        policy: RailJourneyFarePolicy.firstUnlockOnly,
        semanticCurrencyId: 'line_tokens',
        amount: 3,
      ),
      requirements: RailJourneyRequirements(
        completedStoryStepIds: <String>{'step_ready'},
        requiredFactIds: <String>{'fact_signal_seen'},
        requiredItemIds: <String>{'item_ticket'},
      ),
    ),
  ],
);

GameState _railReadyState() => GameState(
      saveId: 'scene-rail',
      currentMapId: 'map_origin',
      playerPosition: const GridPos(x: 3, y: 3),
      progression: const PlayerProgression(
        completedStepIds: <String>['step_ready'],
      ),
      bag: const Bag(
        entries: <BagEntry>[
          BagEntry(itemId: 'item_ticket', quantity: 1),
        ],
      ),
      narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
        valuesByFactId: const <String, NarrativeValue>{
          'fact_signal_seen': NarrativeValue.boolean(true),
        },
      ),
      railJourneyProgress: const RailJourneyProgress(
        semanticCurrencyBalances: <String, int>{'line_tokens': 4},
      ),
    );

SceneRailJourneyInteractiveCommand _railBeginCommand() =>
    SceneInteractiveCommand.railJourney(
      commandId: 'board-t1',
      journeyId: 'T1',
      operation: SceneRailJourneyOperation.begin,
      direction: RailJourneyDirection.outbound,
      doorSide: RailJourneyDoorSide.west,
    ) as SceneRailJourneyInteractiveCommand;

SceneAsset _railScene({bool failAfterRail = false}) => SceneAsset(
      id: failAfterRail ? 'scene_rail_then_fail' : 'scene_rail_cycle',
      name: failAfterRail ? 'Rail then fail' : 'Rail cycle',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'rail',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(_railBeginCommand()),
          ),
          if (failAfterRail)
            SceneNode(
              id: 'fail',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.takeItem(
                  itemId: 'missing_item',
                  quantity: 1,
                ),
              ),
            ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start-rail',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'rail',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'rail-completed',
            fromNodeId: 'rail',
            fromPortId: 'completed',
            toNodeId: failAfterRail ? 'fail' : 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
          SceneEdge(
            id: 'rail-blocked',
            fromNodeId: 'rail',
            fromPortId: 'blocked',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
          if (failAfterRail)
            SceneEdge(
              id: 'fail-end',
              fromNodeId: 'fail',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
        ],
      ),
    );

RuntimeMapBundle _railBundle({
  List<SceneAsset> scenes = const <SceneAsset>[],
  String mapId = 'map_origin',
}) =>
    RuntimeMapBundle(
      manifest: ProjectManifest(
        name: 'Scene rail journey',
        maps: <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map_origin',
            name: 'Origin',
            relativePath: 'maps/origin.json',
          ),
          ProjectMapEntry(
            id: 'map_vehicle',
            name: 'Train',
            relativePath: 'maps/vehicle.json',
          ),
          ProjectMapEntry(
            id: 'map_destination',
            name: 'Destination',
            relativePath: 'maps/destination.json',
          ),
        ],
        tilesets: <ProjectTilesetEntry>[],
        railJourneyCatalog: _railCatalog,
        scenes: scenes,
      ),
      map: MapData(
        id: mapId,
        name: mapId,
        size: const GridSize(width: 16, height: 16),
        layers: const <MapLayer>[
          MapLayer.object(id: 'objects', name: 'Objects'),
        ],
      ),
      projectRootDirectory: '/tmp/scene-rail',
      tilesetAbsolutePathsById: const <String, String>{},
    );
