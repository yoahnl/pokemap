import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _originDoor = RailJourneyEndpointDoor(
  side: RailJourneyDoorSide.west,
  stationPlacedElementId: 'door_hanazuki_west',
  vehiclePlacedElementId: 'door_vehicle_west',
);

const _destinationDoor = RailJourneyEndpointDoor(
  side: RailJourneyDoorSide.west,
  stationPlacedElementId: 'door_aohara_west',
  vehiclePlacedElementId: 'door_vehicle_west',
);

const _origin = RailJourneyEndpoint(
  stationMapId: 'map_hanazuki_station',
  boardingArea: MapRect(
    pos: GridPos(x: 24, y: 16),
    size: GridSize(width: 4, height: 2),
  ),
  trainEntryPos: GridPos(x: 2, y: 10),
  stationArrivalPos: GridPos(x: 26, y: 14),
  doors: <RailJourneyEndpointDoor>[_originDoor],
);

const _destination = RailJourneyEndpoint(
  stationMapId: 'map_aohara_hamlet_station',
  boardingArea: MapRect(
    pos: GridPos(x: 24, y: 8),
    size: GridSize(width: 6, height: 3),
  ),
  trainEntryPos: GridPos(x: 2, y: 10),
  stationArrivalPos: GridPos(x: 27, y: 12),
  doors: <RailJourneyEndpointDoor>[_destinationDoor],
);

const _journey = RailJourneyDefinition(
  id: 'T1',
  label: 'Hanazuki vers Aohara',
  origin: _origin,
  destination: _destination,
  vehicleMapId: 'map_cedar_line_train_car',
  vehicleVariant: RailJourneyVehicleVariant.regular,
  shellState: 'dusk',
  fare: RailJourneyFare(
    policy: RailJourneyFarePolicy.firstUnlockOnly,
    semanticCurrencyId: 'line_tokens',
    amount: 3,
  ),
  requirements: RailJourneyRequirements(
    completedStoryStepIds: <String>{
      'step_earn_first_ticket',
      'step_face_haru_hanazuki',
      'step_witness_1742_signal',
    },
    requiredItemIds: <String>{'item_old_ticket_tsukikage'},
    requiredAnyFactIds: <String>{
      'fact_haru_hanazuki_victory',
      'fact_haru_hanazuki_defeat',
    },
    requiredStampIds: <String>{'hanazuki_stamp'},
  ),
);

void main() {
  group('RailJourney contract JSON', () {
    test('round-trips exact station and vehicle door instance bindings', () {
      final json = <String, dynamic>{
        ..._origin.toJson(),
        'doors': <Map<String, dynamic>>[
          <String, dynamic>{
            'side': 'west',
            'stationPlacedElementId': 'station_door_west',
            'vehiclePlacedElementId': 'vehicle_door_west',
          },
        ],
      }..remove('allowedDoorSides');

      final decoded = RailJourneyEndpoint.fromJson(json);

      expect(decoded.toJson()['doors'], json['doors']);
      expect(decoded.toJson(), isNot(contains('allowedDoorSides')));
    });

    test('rejects blank exact door instance ids', () {
      final json = <String, dynamic>{
        ..._origin.toJson(),
        'doors': <Map<String, dynamic>>[
          <String, dynamic>{
            'side': 'west',
            'stationPlacedElementId': '   ',
            'vehiclePlacedElementId': 'vehicle_door_west',
          },
        ],
      }..remove('allowedDoorSides');

      expect(
        () => RailJourneyEndpoint.fromJson(json),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects two exact door bindings for the same side', () {
      final json = <String, dynamic>{
        ..._origin.toJson(),
        'doors': <Map<String, dynamic>>[
          <String, dynamic>{
            'side': 'west',
            'stationPlacedElementId': 'station_door_west',
            'vehiclePlacedElementId': 'vehicle_door_west',
          },
          <String, dynamic>{
            'side': 'west',
            'stationPlacedElementId': 'station_door_west_other',
            'vehiclePlacedElementId': 'vehicle_door_west_other',
          },
        ],
      }..remove('allowedDoorSides');

      expect(
        () => RailJourneyEndpoint.fromJson(json),
        throwsA(isA<StateError>()),
      );
    });

    test('requires and round-trips the vehicle map id', () {
      final json = <String, dynamic>{
        ..._journey.toJson(),
        'vehicleMapId': 'map_cedar_line_train_car',
      };

      final decoded = RailJourneyDefinition.fromJson(json);

      expect(decoded.toJson()['vehicleMapId'], 'map_cedar_line_train_car');
      expect(
        () => RailJourneyDefinition.fromJson(
          Map<String, dynamic>.from(json)..remove('vehicleMapId'),
        ),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => RailJourneyDefinition.fromJson(<String, dynamic>{
          ...json,
          'vehicleMapId': '   ',
        }),
        throwsA(isA<StateError>()),
      );
    });

    test('round-trips a validated catalog without losing semantics', () {
      const catalog = RailJourneyCatalog(
        schemaVersion: 1,
        journeys: <RailJourneyDefinition>[_journey],
      );

      final decoded = RailJourneyCatalog.fromJson(catalog.toJson());

      expect(decoded, catalog.validated());
      expect(decoded.toJson(), catalog.validated().toJson());
    });

    test('round-trips progress needed for payment and idempotence', () {
      const progress = RailJourneyProgress(
        activeJourneyId: 'T1',
        direction: RailJourneyDirection.outbound,
        lifecycle: RailJourneyLifecycle.boarding,
        unlockedJourneyIds: <String>{'T1'},
        firstUnlockPaidJourneyIds: <String>{'T1'},
        unlockedStationMapIds: <String>{
          'map_hanazuki_station',
          'map_aohara_hamlet_station',
        },
        semanticCurrencyBalances: <String, int>{'line_tokens': 1},
        appliedOperations: <String, RailJourneyOperationBinding>{
          'board-t1': RailJourneyOperationBinding(
            kind: RailJourneyOperationKind.begin,
            journeyId: 'T1',
            direction: RailJourneyDirection.outbound,
            stationMapId: 'map_hanazuki_station',
            doorSide: RailJourneyDoorSide.west,
          ),
        },
      );

      final decoded = RailJourneyProgress.fromJson(progress.toJson());

      expect(decoded, progress.validated());
    });

    test('rejects duplicate journey ids', () {
      expect(
        () => const RailJourneyCatalog(
          schemaVersion: 1,
          journeys: <RailJourneyDefinition>[_journey, _journey],
        ).validated(),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects a paid fare without a positive amount and currency', () {
      expect(
        () => const RailJourneyFare(
          policy: RailJourneyFarePolicy.firstUnlockOnly,
          amount: 0,
        ).validated(),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects a free fare carrying a debit', () {
      expect(
        () => const RailJourneyFare(
          policy: RailJourneyFarePolicy.storyFree,
          semanticCurrencyId: 'line_tokens',
          amount: 1,
        ).validated(),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects identical origin and destination maps', () {
      expect(
        () => _journey.copyWith(destination: _origin).validated(),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects non-integer JSON fares', () {
      expect(
        () => RailJourneyFare.fromJson(<String, dynamic>{
          'policy': 'first_unlock_only',
          'semanticCurrencyId': 'line_tokens',
          'amount': '3',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects negative semantic currency balances', () {
      expect(
        () => const RailJourneyProgress(
          semanticCurrencyBalances: <String, int>{'line_tokens': -1},
        ).validated(),
        throwsA(isA<StateError>()),
      );
    });

    test('idle progress cannot retain an active journey', () {
      expect(
        () => const RailJourneyProgress(
          activeJourneyId: 'T1',
          direction: RailJourneyDirection.outbound,
          unlockedJourneyIds: <String>{'T1'},
        ).validated(),
        throwsA(isA<StateError>()),
      );
    });

    test('active progress must reference an unlocked journey', () {
      expect(
        () => const RailJourneyProgress(
          activeJourneyId: 'T1',
          direction: RailJourneyDirection.outbound,
          lifecycle: RailJourneyLifecycle.boarding,
        ).validated(),
        throwsA(isA<StateError>()),
      );
    });

    test('non-idle progress requires an active journey and direction', () {
      expect(
        () => const RailJourneyProgress(
          lifecycle: RailJourneyLifecycle.boarding,
        ).validated(),
        throwsA(isA<StateError>()),
      );
    });

    test('validated endpoints defensively copy exact door bindings', () {
      final doors = <RailJourneyEndpointDoor>[_originDoor];
      final endpoint = _origin.copyWith(doors: doors).validated();

      doors.add(
        const RailJourneyEndpointDoor(
          side: RailJourneyDoorSide.east,
          stationPlacedElementId: 'door_hanazuki_east',
          vehiclePlacedElementId: 'door_vehicle_east',
        ),
      );

      expect(endpoint.doors, <RailJourneyEndpointDoor>[_originDoor]);
    });

    test('rejects a JSON operation binding for a locked journey', () {
      final json = const RailJourneyProgress(
        appliedOperations: <String, RailJourneyOperationBinding>{
          'board-t1': RailJourneyOperationBinding(
            kind: RailJourneyOperationKind.begin,
            journeyId: 'T1',
            direction: RailJourneyDirection.outbound,
            stationMapId: 'map_hanazuki_station',
            doorSide: RailJourneyDoorSide.west,
          ),
        },
      ).toJson();

      expect(
        () => RailJourneyProgress.fromJson(json),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects a JSON operation binding for a locked station', () {
      final json = const RailJourneyProgress(
        unlockedJourneyIds: <String>{'T1'},
        appliedOperations: <String, RailJourneyOperationBinding>{
          'board-t1': RailJourneyOperationBinding(
            kind: RailJourneyOperationKind.begin,
            journeyId: 'T1',
            direction: RailJourneyDirection.outbound,
            stationMapId: 'map_hanazuki_station',
            doorSide: RailJourneyDoorSide.west,
          ),
        },
      ).toJson();

      expect(
        () => RailJourneyProgress.fromJson(json),
        throwsA(isA<StateError>()),
      );
    });
  });
}
