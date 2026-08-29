import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _origin = RailJourneyEndpoint(
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

const _destination = RailJourneyEndpoint(
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

const _catalog = RailJourneyCatalog(
  journeys: <RailJourneyDefinition>[
    RailJourneyDefinition(
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
    ),
  ],
);

GameState _readyState() => GameState(
      saveId: 'rail-transaction',
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

SceneRailJourneyInteractiveCommand _beginCommand() =>
    SceneInteractiveCommand.railJourney(
      commandId: 'board-t1',
      journeyId: 'T1',
      operation: SceneRailJourneyOperation.begin,
      direction: RailJourneyDirection.outbound,
      doorSide: RailJourneyDoorSide.west,
    ) as SceneRailJourneyInteractiveCommand;

void main() {
  group('RailJourneyRuntimeTransaction', () {
    test('animates the exact door, transitions, then commits progress',
        () async {
      final events = <String>[];
      RailJourneyProgress? committedProgress;

      final result = await const RailJourneyRuntimeTransaction().execute(
        command: _beginCommand(),
        operationInstanceId: 'runtime:board-t1:success',
        catalog: _catalog,
        gameState: _readyState(),
        animateDoor: (placedElementId) async {
          events.add('animate:$placedElementId');
          return true;
        },
        performTransition: (transition) async {
          events.add(
            'transition:${transition.destinationMapId}:'
            '${transition.destinationDoorPlacedElementId}',
          );
          return true;
        },
        commitProgress: (progress) async {
          events.add('commit');
          committedProgress = progress;
        },
        rollback: () async {},
      );

      expect(result, isA<RailJourneyRuntimeTransactionCompleted>());
      expect(
        result,
        isA<RailJourneyRuntimeTransactionCompleted>()
            .having((value) => value.alreadyApplied, 'alreadyApplied', isFalse)
            .having(
              (value) => value.transition,
              'transition',
              const RailJourneyRuntimeTransition(
                destinationMapId: 'map_vehicle',
                destinationPosition: GridPos(x: 2, y: 10),
                doorSide: RailJourneyDoorSide.west,
                sourceDoorPlacedElementId: 'door_origin_west',
                destinationDoorPlacedElementId: 'door_vehicle_west',
              ),
            ),
      );
      expect(
        events,
        <String>[
          'animate:door_origin_west',
          'transition:map_vehicle:door_vehicle_west',
          'commit',
        ],
      );
      expect(committedProgress?.lifecycle, RailJourneyLifecycle.boarding);
      expect(
        committedProgress?.semanticCurrencyBalances['line_tokens'],
        1,
      );
      expect(
        committedProgress?.appliedOperations.keys,
        contains('runtime:board-t1:success'),
      );
    });

    test('replay skips animation, transition and commit', () async {
      RailJourneyProgress? firstProgress;
      await const RailJourneyRuntimeTransaction().execute(
        command: _beginCommand(),
        operationInstanceId: 'runtime:board-t1:replay',
        catalog: _catalog,
        gameState: _readyState(),
        animateDoor: (_) async => true,
        performTransition: (_) async => true,
        commitProgress: (progress) async => firstProgress = progress,
        rollback: () async {},
      );
      var animationCalls = 0;
      var transitionCalls = 0;
      var commitCalls = 0;
      var rollbackCalls = 0;

      final result = await const RailJourneyRuntimeTransaction().execute(
        command: _beginCommand(),
        operationInstanceId: 'runtime:board-t1:replay',
        catalog: _catalog,
        gameState: _readyState().copyWith(
          currentMapId: 'map_vehicle',
          playerPosition: const GridPos(x: 2, y: 10),
          railJourneyProgress: firstProgress!,
        ),
        animateDoor: (_) async {
          animationCalls += 1;
          return true;
        },
        performTransition: (_) async {
          transitionCalls += 1;
          return true;
        },
        commitProgress: (_) async {
          commitCalls += 1;
        },
        rollback: () async {
          rollbackCalls += 1;
        },
      );

      expect(
        result,
        isA<RailJourneyRuntimeTransactionCompleted>()
            .having((value) => value.alreadyApplied, 'alreadyApplied', isTrue)
            .having((value) => value.transition, 'transition', isNull),
      );
      expect(animationCalls, 0);
      expect(transitionCalls, 0);
      expect(commitCalls, 0);
      expect(rollbackCalls, 0);
    });

    test('animation failure blocks before transition and commit', () async {
      var transitionCalls = 0;
      var commitCalls = 0;

      final result = await const RailJourneyRuntimeTransaction().execute(
        command: _beginCommand(),
        operationInstanceId: 'runtime:board-t1:animation-failure',
        catalog: _catalog,
        gameState: _readyState(),
        animateDoor: (placedElementId) async {
          expect(placedElementId, 'door_origin_west');
          return false;
        },
        performTransition: (_) async {
          transitionCalls += 1;
          return true;
        },
        commitProgress: (_) async {
          commitCalls += 1;
        },
        rollback: () async {},
      );

      expect(
        result,
        isA<RailJourneyRuntimeTransactionBlocked>().having(
          (value) => value.reason,
          'reason',
          RailJourneyRuntimeTransactionBlockReason.doorAnimationFailed,
        ),
      );
      expect(transitionCalls, 0);
      expect(commitCalls, 0);
    });

    test('spatial failure blocks without committing progress', () async {
      var animationCalls = 0;
      var transitionCalls = 0;
      var commitCalls = 0;
      var rollbackCalls = 0;

      final result = await const RailJourneyRuntimeTransaction().execute(
        command: _beginCommand(),
        operationInstanceId: 'runtime:board-t1:spatial-failure',
        catalog: _catalog,
        gameState: _readyState(),
        animateDoor: (_) async {
          animationCalls += 1;
          return true;
        },
        performTransition: (transition) async {
          transitionCalls += 1;
          expect(transition.sourceDoorPlacedElementId, 'door_origin_west');
          expect(
            transition.destinationDoorPlacedElementId,
            'door_vehicle_west',
          );
          return false;
        },
        commitProgress: (_) async {
          commitCalls += 1;
        },
        rollback: () async {
          rollbackCalls += 1;
        },
      );

      expect(
        result,
        isA<RailJourneyRuntimeTransactionBlocked>().having(
          (value) => value.reason,
          'reason',
          RailJourneyRuntimeTransactionBlockReason.spatialTransitionFailed,
        ),
      );
      expect(animationCalls, 1);
      expect(transitionCalls, 1);
      expect(commitCalls, 0);
      expect(rollbackCalls, 1);
    });

    test('partial spatial exception is compensated before rethrow', () async {
      final events = <String>[];

      await expectLater(
        const RailJourneyRuntimeTransaction().execute(
          command: _beginCommand(),
          operationInstanceId: 'runtime:board-t1:spatial-exception',
          catalog: _catalog,
          gameState: _readyState(),
          animateDoor: (_) async => true,
          performTransition: (_) async {
            events.add('transition-partial');
            throw StateError('transition exploded after mutation');
          },
          commitProgress: (_) async => events.add('commit'),
          rollback: () async => events.add('rollback'),
        ),
        throwsA(isA<StateError>()),
      );

      expect(events, <String>['transition-partial', 'rollback']);
    });

    test('commit exception restores spatial and progress mutations', () async {
      final events = <String>[];

      await expectLater(
        const RailJourneyRuntimeTransaction().execute(
          command: _beginCommand(),
          operationInstanceId: 'runtime:board-t1:commit-exception',
          catalog: _catalog,
          gameState: _readyState(),
          animateDoor: (_) async => true,
          performTransition: (_) async {
            events.add('transition');
            return true;
          },
          commitProgress: (_) async {
            events.add('commit-partial');
            throw StateError('commit exploded after mutation');
          },
          rollback: () async => events.add('rollback'),
        ),
        throwsA(isA<StateError>()),
      );

      expect(events, <String>['transition', 'commit-partial', 'rollback']);
    });
  });
}
