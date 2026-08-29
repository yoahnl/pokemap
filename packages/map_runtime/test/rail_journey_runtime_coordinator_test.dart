import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

const _originDoor = RailJourneyEndpointDoor(
  side: RailJourneyDoorSide.west,
  stationPlacedElementId: 'door_origin_west',
  vehiclePlacedElementId: 'door_vehicle_west',
);

const _destinationDoor = RailJourneyEndpointDoor(
  side: RailJourneyDoorSide.east,
  stationPlacedElementId: 'door_destination_east',
  vehiclePlacedElementId: 'door_vehicle_east',
);

const _origin = RailJourneyEndpoint(
  stationMapId: 'map_origin',
  boardingArea: MapRect(
    pos: GridPos(x: 2, y: 3),
    size: GridSize(width: 4, height: 2),
  ),
  trainEntryPos: GridPos(x: 2, y: 10),
  stationArrivalPos: GridPos(x: 4, y: 4),
  doors: <RailJourneyEndpointDoor>[_originDoor],
);

const _destination = RailJourneyEndpoint(
  stationMapId: 'map_destination',
  boardingArea: MapRect(
    pos: GridPos(x: 8, y: 3),
    size: GridSize(width: 4, height: 2),
  ),
  trainEntryPos: GridPos(x: 30, y: 10),
  stationArrivalPos: GridPos(x: 8, y: 8),
  doors: <RailJourneyEndpointDoor>[_destinationDoor],
);

const _journey = RailJourneyDefinition(
  id: 'T1',
  label: 'Origin vers destination',
  origin: _origin,
  destination: _destination,
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
);

const _catalog =
    RailJourneyCatalog(journeys: <RailJourneyDefinition>[_journey]);

GameState _readyState() => GameState(
      saveId: 'save',
      currentMapId: 'map_origin',
      playerPosition: const GridPos(x: 3, y: 3),
      progression: const PlayerProgression(
        completedStepIds: <String>['step_ready'],
      ),
      bag: const Bag(
        entries: <BagEntry>[BagEntry(itemId: 'item_ticket', quantity: 1)],
      ),
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: const <String, bool>{'fact_signal_seen': true},
      ),
      railJourneyProgress: const RailJourneyProgress(
        semanticCurrencyBalances: <String, int>{'line_tokens': 4},
      ),
    );

SceneRailJourneyInteractiveCommand _beginCommand() =>
    SceneInteractiveCommand.railJourney(
      commandId: 'board-t1',
      journeyId: 'T1',
      operation: SceneRailJourneyOperation.begin,
      direction: RailJourneyDirection.outbound,
      doorSide: RailJourneyDoorSide.west,
    ) as SceneRailJourneyInteractiveCommand;

void main() {
  test('begin returns an atomic vehicle transition plan', () {
    final initial = _readyState();

    final result = const RailJourneyRuntimeCoordinator().execute(
      command: _beginCommand(),
      operationInstanceId: 'runtime:board-t1:run-1',
      catalog: _catalog,
      gameState: initial,
    ) as RailJourneyRuntimeCompleted;

    expect(result.outputPortId, 'completed');
    expect(result.gameState.railJourneyProgress.lifecycle,
        RailJourneyLifecycle.boarding);
    expect(
      result.gameState.railJourneyProgress
          .semanticCurrencyBalances['line_tokens'],
      1,
    );
    expect(
      result.transition,
      const RailJourneyRuntimeTransition(
        destinationMapId: 'map_vehicle',
        destinationPosition: GridPos(x: 2, y: 10),
        doorSide: RailJourneyDoorSide.west,
        sourceDoorPlacedElementId: 'door_origin_west',
        destinationDoorPlacedElementId: 'door_vehicle_west',
      ),
    );
    expect(
      result.gameState.railJourneyProgress.appliedOperations.keys,
      contains('runtime:board-t1:run-1'),
    );
    expect(
      result.gameState.railJourneyProgress.appliedOperations.keys,
      isNot(contains('board-t1')),
    );
    expect(initial.railJourneyProgress.lifecycle,
        RailJourneyLifecycle.idleAtOrigin);
    expect(
        initial.railJourneyProgress.semanticCurrencyBalances['line_tokens'], 4);
  });

  test('begin rejects map, boarding area and door mismatches without mutation',
      () {
    final initial = _readyState();
    final coordinator = const RailJourneyRuntimeCoordinator();
    final cases = <(
      GameState,
      SceneRailJourneyInteractiveCommand,
      RailJourneyRuntimeBlockReason
    )>[
      (
        initial.copyWith(currentMapId: 'map_other'),
        _beginCommand(),
        RailJourneyRuntimeBlockReason.wrongMap,
      ),
      (
        initial.copyWith(playerPosition: const GridPos(x: 6, y: 3)),
        _beginCommand(),
        RailJourneyRuntimeBlockReason.outsideBoardingArea,
      ),
      (
        initial,
        SceneInteractiveCommand.railJourney(
          commandId: 'board-t1-east',
          journeyId: 'T1',
          operation: SceneRailJourneyOperation.begin,
          direction: RailJourneyDirection.outbound,
          doorSide: RailJourneyDoorSide.east,
        ) as SceneRailJourneyInteractiveCommand,
        RailJourneyRuntimeBlockReason.doorSideNotAllowed,
      ),
    ];

    for (final (state, command, reason) in cases) {
      final result = coordinator.execute(
        command: command,
        operationInstanceId: 'runtime:${command.commandId}:invalid-case',
        catalog: _catalog,
        gameState: state,
      ) as RailJourneyRuntimeBlocked;

      expect(result.outputPortId, 'blocked');
      expect(result.reason, reason);
      expect(identical(result.gameState, state), isTrue);
      expect(state.railJourneyProgress.lifecycle,
          RailJourneyLifecycle.idleAtOrigin);
      expect(
        state.railJourneyProgress.semanticCurrencyBalances['line_tokens'],
        4,
      );
    }
  });

  test('begin projects only true boolean Facts into access requirements', () {
    final initial = _readyState().copyWith(
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: const <String, bool>{'fact_signal_seen': false},
      ),
    );

    final result = const RailJourneyRuntimeCoordinator().execute(
      command: _beginCommand(),
      operationInstanceId: 'runtime:board-t1:fact-blocked',
      catalog: _catalog,
      gameState: initial,
    ) as RailJourneyRuntimeBlocked;

    expect(result.reason, RailJourneyRuntimeBlockReason.serviceRefused);
    expect(result.serviceReason, RailJourneyBeginRefusal.requirementsNotMet);
    expect(identical(result.gameState, initial), isTrue);
  });

  test('begin projects only typed earned rail stamps into access', () {
    final stampedJourney = _journey.copyWith(
      requirements: _journey.requirements.copyWith(
        requiredStampIds: <String>{'hanazuki_stamp'},
      ),
    );
    final catalog = RailJourneyCatalog(
      journeys: <RailJourneyDefinition>[stampedJourney],
    );
    final missing = const RailJourneyRuntimeCoordinator().execute(
      command: _beginCommand(),
      operationInstanceId: 'runtime:board-t1:without-stamp',
      catalog: catalog,
      gameState: _readyState(),
    ) as RailJourneyRuntimeBlocked;
    final granted = const RailJourneyRuntimeCoordinator().execute(
      command: _beginCommand(),
      operationInstanceId: 'runtime:board-t1:with-stamp',
      catalog: catalog,
      gameState: _readyState().copyWith(
        railJourneyProgress: const RailJourneyProgress(
          semanticCurrencyBalances: <String, int>{'line_tokens': 4},
          earnedStampIds: <String>{'hanazuki_stamp'},
        ),
      ),
    );

    expect(missing.serviceReason, RailJourneyBeginRefusal.requirementsNotMet);
    expect(granted, isA<RailJourneyRuntimeCompleted>());
  });

  test('unknown journey is blocked without touching progress', () {
    final initial = _readyState();
    final command = SceneInteractiveCommand.railJourney(
      commandId: 'board-unknown',
      journeyId: 'unknown',
      operation: SceneRailJourneyOperation.begin,
      direction: RailJourneyDirection.outbound,
      doorSide: RailJourneyDoorSide.west,
    ) as SceneRailJourneyInteractiveCommand;

    final result = const RailJourneyRuntimeCoordinator().execute(
      command: command,
      operationInstanceId: 'runtime:board-unknown:run-1',
      catalog: _catalog,
      gameState: initial,
    ) as RailJourneyRuntimeBlocked;

    expect(result.reason, RailJourneyRuntimeBlockReason.unknownJourney);
    expect(identical(result.gameState, initial), isTrue);
  });

  test('advance and acknowledge produce the full arrival lifecycle', () {
    const coordinator = RailJourneyRuntimeCoordinator();
    final boarding = coordinator.execute(
      command: _beginCommand(),
      operationInstanceId: 'runtime:board-t1:run-1',
      catalog: _catalog,
      gameState: _readyState(),
    ) as RailJourneyRuntimeCompleted;
    var vehicleState = boarding.gameState.copyWith(
      currentMapId: 'map_vehicle',
      playerPosition: const GridPos(x: 2, y: 10),
    );

    final inTransit = coordinator.execute(
      command: SceneInteractiveCommand.railJourney(
        commandId: 'doors-closed-t1',
        journeyId: 'T1',
        operation: SceneRailJourneyOperation.advance,
        advanceEvent: SceneRailJourneyAdvanceEvent.doorsClosed,
      ) as SceneRailJourneyInteractiveCommand,
      operationInstanceId: 'runtime:doors-closed-t1:run-1',
      catalog: _catalog,
      gameState: vehicleState,
    ) as RailJourneyRuntimeCompleted;
    expect(inTransit.transition, isNull);
    expect(inTransit.gameState.railJourneyProgress.lifecycle,
        RailJourneyLifecycle.inTransit);

    final arrived = coordinator.execute(
      command: SceneInteractiveCommand.railJourney(
        commandId: 'arrival-t1',
        journeyId: 'T1',
        operation: SceneRailJourneyOperation.advance,
        advanceEvent: SceneRailJourneyAdvanceEvent.arrivalReached,
      ) as SceneRailJourneyInteractiveCommand,
      operationInstanceId: 'runtime:arrival-t1:run-1',
      catalog: _catalog,
      gameState: inTransit.gameState,
    ) as RailJourneyRuntimeCompleted;
    expect(arrived.transition, isNull);
    expect(arrived.gameState.railJourneyProgress.lifecycle,
        RailJourneyLifecycle.arrived);

    final destinationDoorCommand = SceneInteractiveCommand.railJourney(
      commandId: 'destination-door-t1',
      journeyId: 'T1',
      operation: SceneRailJourneyOperation.advance,
      advanceEvent: SceneRailJourneyAdvanceEvent.destinationDoorUsed,
      doorSide: RailJourneyDoorSide.east,
    ) as SceneRailJourneyInteractiveCommand;
    final disembarked = coordinator.execute(
      command: destinationDoorCommand,
      operationInstanceId: 'runtime:destination-door-t1:run-1',
      catalog: _catalog,
      gameState: arrived.gameState,
    ) as RailJourneyRuntimeCompleted;
    expect(disembarked.gameState.railJourneyProgress.lifecycle,
        RailJourneyLifecycle.disembarked);
    expect(
      disembarked.transition,
      const RailJourneyRuntimeTransition(
        destinationMapId: 'map_destination',
        destinationPosition: GridPos(x: 8, y: 8),
        doorSide: RailJourneyDoorSide.east,
        sourceDoorPlacedElementId: 'door_vehicle_east',
        destinationDoorPlacedElementId: 'door_destination_east',
      ),
    );
    final disembarkReplay = coordinator.execute(
      command: destinationDoorCommand,
      operationInstanceId: 'runtime:destination-door-t1:run-1',
      catalog: _catalog,
      gameState: disembarked.gameState,
    ) as RailJourneyRuntimeCompleted;
    expect(disembarkReplay.alreadyApplied, isTrue);
    expect(disembarkReplay.transition, isNull);

    final atStation = disembarked.gameState.copyWith(
      currentMapId: 'map_destination',
      playerPosition: const GridPos(x: 8, y: 8),
    );
    final acknowledged = coordinator.execute(
      command: SceneInteractiveCommand.railJourney(
        commandId: 'ack-t1',
        journeyId: 'T1',
        operation: SceneRailJourneyOperation.acknowledge,
      ) as SceneRailJourneyInteractiveCommand,
      operationInstanceId: 'runtime:ack-t1:run-1',
      catalog: _catalog,
      gameState: atStation,
    ) as RailJourneyRuntimeCompleted;

    expect(acknowledged.transition, isNull);
    expect(acknowledged.gameState.railJourneyProgress.lifecycle,
        RailJourneyLifecycle.idleAtOrigin);
    expect(acknowledged.gameState.railJourneyProgress.activeJourneyId, isNull);
  });

  test('arrival operations reject the wrong map, door and position atomically',
      () {
    const coordinator = RailJourneyRuntimeCoordinator();
    final boarding = coordinator.execute(
      command: _beginCommand(),
      operationInstanceId: 'runtime:board-t1:run-1',
      catalog: _catalog,
      gameState: _readyState(),
    ) as RailJourneyRuntimeCompleted;
    final wrongMapAdvance = coordinator.execute(
      command: SceneInteractiveCommand.railJourney(
        commandId: 'doors-closed-t1',
        journeyId: 'T1',
        operation: SceneRailJourneyOperation.advance,
        advanceEvent: SceneRailJourneyAdvanceEvent.doorsClosed,
      ) as SceneRailJourneyInteractiveCommand,
      operationInstanceId: 'runtime:doors-closed-wrong-map:run-1',
      catalog: _catalog,
      gameState: boarding.gameState,
    ) as RailJourneyRuntimeBlocked;

    expect(wrongMapAdvance.reason, RailJourneyRuntimeBlockReason.wrongMap);
    expect(identical(wrongMapAdvance.gameState, boarding.gameState), isTrue);

    final vehicle = boarding.gameState.copyWith(currentMapId: 'map_vehicle');
    final inTransit = coordinator.execute(
      command: SceneInteractiveCommand.railJourney(
        commandId: 'doors-closed-t1',
        journeyId: 'T1',
        operation: SceneRailJourneyOperation.advance,
        advanceEvent: SceneRailJourneyAdvanceEvent.doorsClosed,
      ) as SceneRailJourneyInteractiveCommand,
      operationInstanceId: 'runtime:doors-closed-t1:run-1',
      catalog: _catalog,
      gameState: vehicle,
    ) as RailJourneyRuntimeCompleted;
    final arrived = coordinator.execute(
      command: SceneInteractiveCommand.railJourney(
        commandId: 'arrival-t1',
        journeyId: 'T1',
        operation: SceneRailJourneyOperation.advance,
        advanceEvent: SceneRailJourneyAdvanceEvent.arrivalReached,
      ) as SceneRailJourneyInteractiveCommand,
      operationInstanceId: 'runtime:arrival-t1:run-1',
      catalog: _catalog,
      gameState: inTransit.gameState,
    ) as RailJourneyRuntimeCompleted;
    final wrongDoor = coordinator.execute(
      command: SceneInteractiveCommand.railJourney(
        commandId: 'destination-door-t1',
        journeyId: 'T1',
        operation: SceneRailJourneyOperation.advance,
        advanceEvent: SceneRailJourneyAdvanceEvent.destinationDoorUsed,
        doorSide: RailJourneyDoorSide.west,
      ) as SceneRailJourneyInteractiveCommand,
      operationInstanceId: 'runtime:destination-door-wrong:run-1',
      catalog: _catalog,
      gameState: arrived.gameState,
    ) as RailJourneyRuntimeBlocked;

    expect(wrongDoor.reason, RailJourneyRuntimeBlockReason.doorSideNotAllowed);
    expect(identical(wrongDoor.gameState, arrived.gameState), isTrue);

    final disembarkedProgress = const RailJourneyService()
        .advance(
          progress: arrived.gameState.railJourneyProgress,
          operationInstanceId: 'runtime:destination-door-manual:run-1',
          journeyId: 'T1',
          event: RailJourneyAdvanceEvent.destinationDoorUsed,
          doorSide: RailJourneyDoorSide.east,
        )
        .progress;
    final wrongArrival = arrived.gameState.copyWith(
      currentMapId: 'map_destination',
      playerPosition: const GridPos(x: 7, y: 8),
      railJourneyProgress: disembarkedProgress,
    );
    final wrongPosition = coordinator.execute(
      command: SceneInteractiveCommand.railJourney(
        commandId: 'ack-t1',
        journeyId: 'T1',
        operation: SceneRailJourneyOperation.acknowledge,
      ) as SceneRailJourneyInteractiveCommand,
      operationInstanceId: 'runtime:ack-wrong-position:run-1',
      catalog: _catalog,
      gameState: wrongArrival,
    ) as RailJourneyRuntimeBlocked;

    expect(wrongPosition.reason,
        RailJourneyRuntimeBlockReason.invalidArrivalPosition);
    expect(identical(wrongPosition.gameState, wrongArrival), isTrue);
  });

  test('replaying an identical begin reports completion without a second debit',
      () {
    const coordinator = RailJourneyRuntimeCoordinator();
    final first = coordinator.execute(
      command: _beginCommand(),
      operationInstanceId: 'runtime:board-t1:run-1',
      catalog: _catalog,
      gameState: _readyState(),
    ) as RailJourneyRuntimeCompleted;

    final replay = coordinator.execute(
      command: _beginCommand(),
      operationInstanceId: 'runtime:board-t1:run-1',
      catalog: _catalog,
      gameState: first.gameState,
    ) as RailJourneyRuntimeCompleted;

    expect(replay.alreadyApplied, isTrue);
    expect(replay.transition, isNull);
    expect(
        replay.gameState.railJourneyProgress
            .semanticCurrencyBalances['line_tokens'],
        1);
    expect(
        identical(replay.gameState.railJourneyProgress,
            first.gameState.railJourneyProgress),
        isTrue);
  });

  test('advance replay resolves before spatial guards and conflicts by payload',
      () {
    const coordinator = RailJourneyRuntimeCoordinator();
    final boarding = coordinator.execute(
      command: _beginCommand(),
      operationInstanceId: 'runtime:board-t1:run-1',
      catalog: _catalog,
      gameState: _readyState(),
    ) as RailJourneyRuntimeCompleted;
    final vehicle = boarding.gameState.copyWith(currentMapId: 'map_vehicle');
    final command = SceneInteractiveCommand.railJourney(
      commandId: 'doors-closed-t1',
      journeyId: 'T1',
      operation: SceneRailJourneyOperation.advance,
      advanceEvent: SceneRailJourneyAdvanceEvent.doorsClosed,
    ) as SceneRailJourneyInteractiveCommand;
    final first = coordinator.execute(
      command: command,
      operationInstanceId: 'runtime:doors-closed-t1:run-1',
      catalog: _catalog,
      gameState: vehicle,
    ) as RailJourneyRuntimeCompleted;
    final replay = coordinator.execute(
      command: command,
      operationInstanceId: 'runtime:doors-closed-t1:run-1',
      catalog: _catalog,
      gameState: first.gameState.copyWith(currentMapId: 'map_wrong'),
    ) as RailJourneyRuntimeCompleted;
    final conflict = coordinator.execute(
      command: SceneInteractiveCommand.railJourney(
        commandId: 'arrival-t1',
        journeyId: 'T1',
        operation: SceneRailJourneyOperation.advance,
        advanceEvent: SceneRailJourneyAdvanceEvent.arrivalReached,
      ) as SceneRailJourneyInteractiveCommand,
      operationInstanceId: 'runtime:doors-closed-t1:run-1',
      catalog: _catalog,
      gameState: first.gameState.copyWith(currentMapId: 'map_wrong'),
    ) as RailJourneyRuntimeBlocked;

    expect(replay.alreadyApplied, isTrue);
    expect(
        conflict.serviceReason, RailJourneyAdvanceRefusal.idempotencyConflict);
  });
}
