import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const _originDoor = RailJourneyEndpointDoor(
  side: RailJourneyDoorSide.west,
  stationPlacedElementId: 'door_origin_west',
  vehiclePlacedElementId: 'door_vehicle_west',
);

const _destinationDoor = RailJourneyEndpointDoor(
  side: RailJourneyDoorSide.west,
  stationPlacedElementId: 'door_destination_west',
  vehiclePlacedElementId: 'door_vehicle_west',
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
  trainEntryPos: GridPos(x: 2, y: 10),
  stationArrivalPos: GridPos(x: 8, y: 8),
  doors: <RailJourneyEndpointDoor>[_destinationDoor],
);

const _requirements = RailJourneyRequirements(
  completedStoryStepIds: <String>{'step_ready'},
  requiredFactIds: <String>{'fact_signal_seen'},
  requiredAnyFactIds: <String>{'fact_victory', 'fact_defeat'},
  requiredItemIds: <String>{'item_ticket'},
  requiredStampIds: <String>{'stamp_origin'},
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
  requirements: _requirements,
);

const _access = RailJourneyAccessState(
  completedStoryStepIds: <String>{'step_ready'},
  activeFactIds: <String>{'fact_signal_seen', 'fact_victory'},
  itemIds: <String>{'item_ticket'},
  stampIds: <String>{'stamp_origin'},
);

RailJourneyProgress _progress({int tokens = 4}) {
  return RailJourneyProgress(
    semanticCurrencyBalances: <String, int>{'line_tokens': tokens},
  );
}

RailJourneyBeginResult _begin(
  RailJourneyProgress progress, {
  RailJourneyDefinition definition = _journey,
  String operationInstanceId = 'board-t1:run-1',
  RailJourneyDirection direction = RailJourneyDirection.outbound,
  String currentStationMapId = 'map_origin',
  RailJourneyAccessState access = _access,
  RailJourneyDoorSide doorSide = RailJourneyDoorSide.west,
}) {
  return const RailJourneyService().begin(
    definition: definition,
    progress: progress,
    access: access,
    operationInstanceId: operationInstanceId,
    direction: direction,
    currentStationMapId: currentStationMapId,
    doorSide: doorSide,
  );
}

RailJourneyProgress _completeJourney(RailJourneyProgress progress) {
  const service = RailJourneyService();
  final inTransit = service.advance(
    progress: progress,
    operationInstanceId: 'doors-closed:run-1',
    journeyId: 'T1',
    event: RailJourneyAdvanceEvent.doorsClosed,
  ) as RailJourneyAdvanceApplied;
  final arrived = service.advance(
    progress: inTransit.progress,
    operationInstanceId: 'arrival:run-1',
    journeyId: 'T1',
    event: RailJourneyAdvanceEvent.arrivalReached,
  ) as RailJourneyAdvanceApplied;
  return (service.advance(
    progress: arrived.progress,
    operationInstanceId: 'destination-door:run-1',
    journeyId: 'T1',
    event: RailJourneyAdvanceEvent.destinationDoorUsed,
    doorSide: RailJourneyDoorSide.west,
  ) as RailJourneyAdvanceApplied)
      .progress;
}

void main() {
  group('RailJourneyService.begin', () {
    test('atomically charges and enters boarding on the first unlock', () {
      final initial = _progress();

      final result = _begin(initial) as RailJourneyBeginApplied;

      expect(result.chargedAmount, 3);
      expect(result.progress.lifecycle, RailJourneyLifecycle.boarding);
      expect(result.progress.activeJourneyId, 'T1');
      expect(result.progress.direction, RailJourneyDirection.outbound);
      expect(result.progress.semanticCurrencyBalances['line_tokens'], 1);
      expect(result.progress.unlockedJourneyIds, contains('T1'));
      expect(result.progress.firstUnlockPaidJourneyIds, contains('T1'));
      expect(
        result.progress.unlockedStationMapIds,
        containsAll(<String>['map_origin', 'map_destination']),
      );
      expect(
        result.progress.appliedOperations['board-t1:run-1'],
        const RailJourneyOperationBinding(
          kind: RailJourneyOperationKind.begin,
          journeyId: 'T1',
          direction: RailJourneyDirection.outbound,
          stationMapId: 'map_origin',
          doorSide: RailJourneyDoorSide.west,
        ),
      );
      expect(initial.semanticCurrencyBalances['line_tokens'], 4);
      expect(initial.unlockedJourneyIds, isEmpty);
    });

    test('refuses insufficient funds without mutating the input', () {
      final initial = _progress(tokens: 2);

      final result = _begin(initial) as RailJourneyBeginRefused;

      expect(result.reason, RailJourneyBeginRefusal.insufficientFunds);
      expect(identical(result.progress, initial), isTrue);
    });

    test('refuses missing requirements without mutating the input', () {
      final initial = _progress();

      final result = _begin(
        initial,
        access: const RailJourneyAccessState(),
      ) as RailJourneyBeginRefused;

      expect(result.reason, RailJourneyBeginRefusal.requirementsNotMet);
      expect(identical(result.progress, initial), isTrue);
    });

    test('replaying the same operation is idempotent', () {
      final first = _begin(_progress()) as RailJourneyBeginApplied;

      final replay = _begin(first.progress);

      expect(replay, isA<RailJourneyBeginAlreadyApplied>());
      expect(identical(replay.progress, first.progress), isTrue);
      expect(replay.progress.semanticCurrencyBalances['line_tokens'], 1);
    });

    test('replaying after the station-to-vehicle warp is idempotent', () {
      final first = _begin(_progress()) as RailJourneyBeginApplied;

      final replay = _begin(
        first.progress,
        currentStationMapId: 'map_vehicle',
      );

      expect(replay, isA<RailJourneyBeginAlreadyApplied>());
      expect(identical(replay.progress, first.progress), isTrue);
      expect(replay.progress.semanticCurrencyBalances['line_tokens'], 1);
    });

    test('refuses a first operation from the wrong station', () {
      final initial = _progress();

      final refused = _begin(
        initial,
        currentStationMapId: 'map_other',
      ) as RailJourneyBeginRefused;

      expect(refused.reason, RailJourneyBeginRefusal.wrongStation);
      expect(identical(refused.progress, initial), isTrue);
    });

    test('refuses an orphan idempotency binding as invalid state', () {
      const corrupted = RailJourneyProgress(
        appliedOperations: <String, RailJourneyOperationBinding>{
          'board-t1:run-1': RailJourneyOperationBinding(
            kind: RailJourneyOperationKind.begin,
            journeyId: 'T1',
            direction: RailJourneyDirection.outbound,
            stationMapId: 'map_origin',
            doorSide: RailJourneyDoorSide.west,
          ),
        },
      );

      final result = _begin(corrupted) as RailJourneyBeginRefused;

      expect(result.reason, RailJourneyBeginRefusal.invalidRequest);
      expect(identical(result.progress, corrupted), isTrue);
    });

    test('reusing an operation for another direction is a conflict', () {
      final first = _begin(_progress()) as RailJourneyBeginApplied;

      final conflict = _begin(
        first.progress,
        direction: RailJourneyDirection.returnJourney,
        currentStationMapId: 'map_destination',
      ) as RailJourneyBeginRefused;

      expect(conflict.reason, RailJourneyBeginRefusal.idempotencyConflict);
      expect(identical(conflict.progress, first.progress), isTrue);
    });

    test('replaying an applied operation from another map is idempotent', () {
      final first = _begin(_progress()) as RailJourneyBeginApplied;

      final replay = _begin(
        first.progress,
        currentStationMapId: 'map_other',
      );

      expect(replay, isA<RailJourneyBeginAlreadyApplied>());
      expect(identical(replay.progress, first.progress), isTrue);
    });

    test('reusing an operation for another journey is a conflict', () {
      final first = _begin(_progress()) as RailJourneyBeginApplied;
      final otherJourney = _journey.copyWith(id: 'T2', label: 'Other journey');

      final conflict = _begin(
        first.progress,
        definition: otherJourney,
      ) as RailJourneyBeginRefused;

      expect(conflict.reason, RailJourneyBeginRefusal.idempotencyConflict);
      expect(identical(conflict.progress, first.progress), isTrue);
    });

    test('a later outbound trip never pays the first unlock twice', () {
      final first = _begin(_progress(tokens: 10)) as RailJourneyBeginApplied;
      final disembarked = _completeJourney(first.progress);
      final readyAgain = (const RailJourneyService().acknowledgeDisembark(
        progress: disembarked,
        operationInstanceId: 'ack:run-1',
        journeyId: 'T1',
      ) as RailJourneyAdvanceApplied)
          .progress;

      final second = _begin(
        readyAgain,
        operationInstanceId: 'board-t1:run-2',
      ) as RailJourneyBeginApplied;

      expect(second.chargedAmount, 0);
      expect(second.progress.semanticCurrencyBalances['line_tokens'], 7);
    });

    test('a return on an unlocked segment is free', () {
      final first = _begin(_progress(tokens: 10)) as RailJourneyBeginApplied;
      final disembarked = _completeJourney(first.progress);
      final atDestination = (const RailJourneyService().acknowledgeDisembark(
        progress: disembarked,
        operationInstanceId: 'ack:run-1',
        journeyId: 'T1',
      ) as RailJourneyAdvanceApplied)
          .progress;

      final returned = _begin(
        atDestination,
        operationInstanceId: 'return-t1:run-2',
        direction: RailJourneyDirection.returnJourney,
        currentStationMapId: 'map_destination',
      ) as RailJourneyBeginApplied;

      expect(returned.chargedAmount, 0);
      expect(returned.progress.semanticCurrencyBalances['line_tokens'], 7);
      expect(returned.progress.direction, RailJourneyDirection.returnJourney);
    });

    test('a return on a locked segment is refused without mutation', () {
      final initial = _progress(tokens: 10);

      final result = _begin(
        initial,
        operationInstanceId: 'return-locked-t1:run-1',
        direction: RailJourneyDirection.returnJourney,
        currentStationMapId: 'map_destination',
      ) as RailJourneyBeginRefused;

      expect(result.reason, RailJourneyBeginRefusal.segmentLocked);
      expect(identical(result.progress, initial), isTrue);
    });
  });

  group('RailJourneyService.advance', () {
    test('applies the canonical lifecycle in order', () {
      final boarding =
          (_begin(_progress()) as RailJourneyBeginApplied).progress;
      final service = const RailJourneyService();

      final inTransit = service.advance(
        progress: boarding,
        operationInstanceId: 'doors-closed:run-1',
        journeyId: 'T1',
        event: RailJourneyAdvanceEvent.doorsClosed,
      ) as RailJourneyAdvanceApplied;
      final arrived = service.advance(
        progress: inTransit.progress,
        operationInstanceId: 'arrival:run-1',
        journeyId: 'T1',
        event: RailJourneyAdvanceEvent.arrivalReached,
      ) as RailJourneyAdvanceApplied;
      final disembarked = service.advance(
        progress: arrived.progress,
        operationInstanceId: 'destination-door:run-1',
        journeyId: 'T1',
        event: RailJourneyAdvanceEvent.destinationDoorUsed,
        doorSide: RailJourneyDoorSide.west,
      ) as RailJourneyAdvanceApplied;

      expect(inTransit.progress.lifecycle, RailJourneyLifecycle.inTransit);
      expect(arrived.progress.lifecycle, RailJourneyLifecycle.arrived);
      expect(
        disembarked.progress.lifecycle,
        RailJourneyLifecycle.disembarked,
      );
    });

    test('refuses an out-of-order transition without mutation', () {
      final boarding =
          (_begin(_progress()) as RailJourneyBeginApplied).progress;

      final result = const RailJourneyService().advance(
        progress: boarding,
        operationInstanceId: 'arrival-too-early:run-1',
        journeyId: 'T1',
        event: RailJourneyAdvanceEvent.arrivalReached,
      ) as RailJourneyAdvanceRefused;

      expect(result.reason, RailJourneyAdvanceRefusal.invalidLifecycle);
      expect(identical(result.progress, boarding), isTrue);
    });

    test('advance receipts resolve before lifecycle guards and bind payload',
        () {
      final boarding =
          (_begin(_progress()) as RailJourneyBeginApplied).progress;
      const service = RailJourneyService();
      final first = service.advance(
        progress: boarding,
        operationInstanceId: 'doors-closed:run-1',
        journeyId: 'T1',
        event: RailJourneyAdvanceEvent.doorsClosed,
      ) as RailJourneyAdvanceApplied;

      final replay = service.advance(
        progress: first.progress,
        operationInstanceId: 'doors-closed:run-1',
        journeyId: 'T1',
        event: RailJourneyAdvanceEvent.doorsClosed,
      );
      final conflict = service.advance(
        progress: first.progress,
        operationInstanceId: 'doors-closed:run-1',
        journeyId: 'T1',
        event: RailJourneyAdvanceEvent.arrivalReached,
      ) as RailJourneyAdvanceRefused;

      expect(replay, isA<RailJourneyAdvanceAlreadyApplied>());
      expect(identical(replay.progress, first.progress), isTrue);
      expect(conflict.reason, RailJourneyAdvanceRefusal.idempotencyConflict);
      expect(identical(conflict.progress, first.progress), isTrue);
    });

    test('acknowledges disembark and clears the active journey', () {
      final boarding =
          (_begin(_progress()) as RailJourneyBeginApplied).progress;
      final disembarked = _completeJourney(boarding);

      final acknowledged = const RailJourneyService().acknowledgeDisembark(
        progress: disembarked,
        operationInstanceId: 'ack:run-1',
        journeyId: 'T1',
      ) as RailJourneyAdvanceApplied;

      expect(
        acknowledged.progress.lifecycle,
        RailJourneyLifecycle.idleAtOrigin,
      );
      expect(acknowledged.progress.activeJourneyId, isNull);
      expect(acknowledged.progress.direction, isNull);
      expect(acknowledged.progress.unlockedJourneyIds, contains('T1'));

      final replay = const RailJourneyService().acknowledgeDisembark(
        progress: acknowledged.progress,
        operationInstanceId: 'ack:run-1',
        journeyId: 'T1',
      );

      expect(replay, isA<RailJourneyAdvanceAlreadyApplied>());
      expect(identical(replay.progress, acknowledged.progress), isTrue);
    });

    test('refuses acknowledgement before disembark without mutation', () {
      final boarding =
          (_begin(_progress()) as RailJourneyBeginApplied).progress;

      final refused = const RailJourneyService().acknowledgeDisembark(
        progress: boarding,
        operationInstanceId: 'ack-too-early:run-1',
        journeyId: 'T1',
      ) as RailJourneyAdvanceRefused;

      expect(refused.reason, RailJourneyAdvanceRefusal.invalidLifecycle);
      expect(identical(refused.progress, boarding), isTrue);
    });
  });

  group('RailJourneyService.nextFareReserve', () {
    const t2 = RailJourneyDefinition(
      id: 'T2',
      label: 'Second segment',
      origin: _origin,
      destination: _destination,
      vehicleMapId: 'map_vehicle',
      vehicleVariant: RailJourneyVehicleVariant.regular,
      shellState: 'day',
      fare: RailJourneyFare(
        policy: RailJourneyFarePolicy.firstUnlockOnly,
        semanticCurrencyId: 'line_tokens',
        amount: 4,
      ),
    );

    test('reserves the next unpaid fare and exposes only the buffer', () {
      const progress = RailJourneyProgress(
        unlockedJourneyIds: <String>{'T1'},
        firstUnlockPaidJourneyIds: <String>{'T1'},
        semanticCurrencyBalances: <String, int>{'line_tokens': 6},
      );

      final projection = const RailJourneyService().nextFareReserve(
        progress: progress,
        orderedJourneys: const <RailJourneyDefinition>[_journey, t2],
        semanticCurrencyId: 'line_tokens',
      );

      expect(projection.nextJourneyId, 'T2');
      expect(projection.requiredAmount, 4);
      expect(projection.reservedAmount, 4);
      expect(projection.spendableAmount, 2);
      expect(projection.shortfallAmount, 0);
    });

    test('reserves the whole balance when the next fare is not covered', () {
      const progress = RailJourneyProgress(
        unlockedJourneyIds: <String>{'T1'},
        firstUnlockPaidJourneyIds: <String>{'T1'},
        semanticCurrencyBalances: <String, int>{'line_tokens': 2},
      );

      final projection = const RailJourneyService().nextFareReserve(
        progress: progress,
        orderedJourneys: const <RailJourneyDefinition>[_journey, t2],
        semanticCurrencyId: 'line_tokens',
      );

      expect(projection.reservedAmount, 2);
      expect(projection.spendableAmount, 0);
      expect(projection.shortfallAmount, 2);
    });
  });
}
