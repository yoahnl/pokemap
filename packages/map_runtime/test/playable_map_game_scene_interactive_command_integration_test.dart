import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
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
      contains('rail:debug:interactive-command:board-t1'),
    );

    final replayPort = await game.debugExecuteSceneInteractiveCommand(
      _railBeginCommand(),
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

RuntimeMapBundle _railBundle() => RuntimeMapBundle(
      manifest: const ProjectManifest(
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
      ),
      map: const MapData(
        id: 'map_origin',
        name: 'Origin',
        size: GridSize(width: 16, height: 16),
        layers: <MapLayer>[
          MapLayer.object(id: 'objects', name: 'Objects'),
        ],
      ),
      projectRootDirectory: '/tmp/scene-rail',
      tilesetAbsolutePathsById: const <String, String>{},
    );
