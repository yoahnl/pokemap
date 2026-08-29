import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

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
  stationMapId: 'map_origin_station',
  boardingArea: MapRect(
    pos: GridPos(x: 2, y: 3),
    size: GridSize(width: 3, height: 2),
  ),
  trainEntryPos: GridPos(x: 1, y: 4),
  stationArrivalPos: GridPos(x: 3, y: 6),
  doors: <RailJourneyEndpointDoor>[_originDoor],
);

const _destination = RailJourneyEndpoint(
  stationMapId: 'map_destination_station',
  boardingArea: MapRect(
    pos: GridPos(x: 4, y: 2),
    size: GridSize(width: 2, height: 3),
  ),
  trainEntryPos: GridPos(x: 6, y: 4),
  stationArrivalPos: GridPos(x: 7, y: 6),
  doors: <RailJourneyEndpointDoor>[_destinationDoor],
);

const _journey = RailJourneyDefinition(
  id: 'T1',
  label: 'Origin to destination',
  origin: _origin,
  destination: _destination,
  vehicleMapId: 'map_train_car',
  vehicleVariant: RailJourneyVehicleVariant.regular,
  shellState: 'day',
  fare: RailJourneyFare(policy: RailJourneyFarePolicy.storyFree),
  requirements: RailJourneyRequirements(
    completedStoryStepIds: <String>{'step_ready'},
    requiredFactIds: <String>{'fact_required'},
    requiredAnyFactIds: <String>{'fact_any_a', 'fact_any_b'},
  ),
);

const _catalog = RailJourneyCatalog(
  journeys: <RailJourneyDefinition>[_journey],
);

const _itemCatalog = ProjectItemCatalog(
  schemaVersion: 1,
  entries: <ProjectItemDefinition>[
    ProjectItemDefinition(
      id: 'item_ticket',
      displayName: 'Ticket',
      pocketId: 'key_items',
    ),
  ],
);

void main() {
  group('ProjectManifest RailJourney catalog persistence', () {
    test('defaults absent and explicit null catalogs to null', () {
      final absent = ProjectManifest.fromJsonPokeMapBetaV1ForTest(
        _minimalProjectJson(),
      );
      final explicitNull = ProjectManifest.fromJsonPokeMapBetaV1ForTest(
        <String, dynamic>{..._minimalProjectJson(), 'railJourneyCatalog': null},
      );

      expect(absent.railJourneyCatalog, isNull);
      expect(explicitNull.railJourneyCatalog, isNull);
      expect(absent.toJson(), isNot(contains('railJourneyCatalog')));
      expect(explicitNull.toJson(), isNot(contains('railJourneyCatalog')));
    });

    test('round-trips a non-null catalog', () {
      final decoded = ProjectManifest.fromJsonPokeMapBetaV1ForTest(
        jsonDecode(
              jsonEncode(<String, dynamic>{
                ..._minimalProjectJson(),
                'railJourneyCatalog': _catalog.toJson(),
              }),
            )
            as Map<String, dynamic>,
      );

      expect(decoded.railJourneyCatalog, _catalog.validated());
      expect(decoded.toJson()['railJourneyCatalog'], _catalog.toJson());
    });
  });

  group('ProjectManifest RailJourney cross-resource validation', () {
    test('accepts known references and in-bounds journey geometry', () {
      expect(
        () => ProjectValidator.validate(_manifest(), maps: _maps()),
        returnsNormally,
      );
    });

    test('rejects unknown station and vehicle map references', () {
      _expectValidationCode(
        _manifest(
          journey: _journey.copyWith(
            origin: _origin.copyWith(stationMapId: 'map_unknown_station'),
          ),
        ),
        _maps(),
        'rail_journey.map_unknown',
      );
      _expectValidationCode(
        _manifest(
          journey: _journey.copyWith(vehicleMapId: 'map_unknown_vehicle'),
        ),
        _maps(),
        'rail_journey.map_unknown',
      );
    });

    test('rejects unknown required and alternative facts', () {
      for (final requirements in <RailJourneyRequirements>[
        _journey.requirements.copyWith(
          requiredFactIds: <String>{'fact_unknown'},
        ),
        _journey.requirements.copyWith(
          requiredAnyFactIds: <String>{'fact_any_a', 'fact_unknown'},
        ),
      ]) {
        _expectValidationCode(
          _manifest(journey: _journey.copyWith(requirements: requirements)),
          _maps(),
          'rail_journey.fact_unknown',
        );
      }
    });

    test('rejects an unknown required story step', () {
      _expectValidationCode(
        _manifest(
          journey: _journey.copyWith(
            requirements: _journey.requirements.copyWith(
              completedStoryStepIds: <String>{'step_unknown'},
            ),
          ),
        ),
        _maps(),
        'rail_journey.story_step_unknown',
      );
    });

    test('validates required items when the item catalog is available', () {
      final journey = _journey.copyWith(
        requirements: _journey.requirements.copyWith(
          requiredItemIds: const <String>{'item_ticket'},
        ),
      );

      expect(
        () => ProjectValidator.validate(
          _manifest(journey: journey),
          maps: _maps(),
          itemCatalog: _itemCatalog,
        ),
        returnsNormally,
      );
    });

    test('rejects an unknown required item when the catalog is available', () {
      final journey = _journey.copyWith(
        requirements: _journey.requirements.copyWith(
          requiredItemIds: const <String>{'item_missing'},
        ),
      );

      _expectValidationCode(
        _manifest(journey: journey),
        _maps(),
        'rail_journey.item_unknown',
        itemCatalog: _itemCatalog,
      );
    });

    test('rejects a boarding area outside its station map', () {
      _expectValidationCode(
        _manifest(
          journey: _journey.copyWith(
            origin: _origin.copyWith(
              boardingArea: const MapRect(
                pos: GridPos(x: 8, y: 8),
                size: GridSize(width: 3, height: 2),
              ),
            ),
          ),
        ),
        _maps(),
        'rail_journey.boarding_area_out_of_bounds',
      );
    });

    test('rejects an arrival position outside its station map', () {
      _expectValidationCode(
        _manifest(
          journey: _journey.copyWith(
            destination: _destination.copyWith(
              stationArrivalPos: const GridPos(x: 10, y: 3),
            ),
          ),
        ),
        _maps(),
        'rail_journey.station_arrival_out_of_bounds',
      );
    });

    test('rejects a train entry position outside the vehicle map', () {
      _expectValidationCode(
        _manifest(
          journey: _journey.copyWith(
            destination: _destination.copyWith(
              trainEntryPos: const GridPos(x: 10, y: 3),
            ),
          ),
        ),
        _maps(),
        'rail_journey.train_entry_out_of_bounds',
      );
    });

    test('rejects missing loaded map data when bounds are requested', () {
      _expectValidationCode(
        _manifest(),
        _maps().where((map) => map.id != 'map_train_car'),
        'rail_journey.map_data_missing',
      );
    });

    test(
      'rejects an exact station door instance missing from its endpoint',
      () {
        final maps = _maps();
        maps[0] = maps[0].copyWith(placedElements: const <MapPlacedElement>[]);

        _expectValidationCode(
          _manifest(),
          maps,
          'rail_journey.station_door_instance_missing',
        );
      },
    );

    test(
      'rejects an exact vehicle door instance missing from the vehicle map',
      () {
        final maps = _maps();
        maps[2] = maps[2].copyWith(
          placedElements: maps[2].placedElements
              .where((placed) => placed.id != 'door_vehicle_east')
              .toList(growable: false),
        );

        _expectValidationCode(
          _manifest(),
          maps,
          'rail_journey.vehicle_door_instance_missing',
        );
      },
    );

    test(
      'rejects station and vehicle door elements with fewer than two frames',
      () {
        for (final elementId in <String>{
          'element_station_west',
          'element_vehicle_east',
        }) {
          final elements = <ProjectElementEntry>[
            for (final element in _doorElements)
              element.id == elementId
                  ? element.copyWith(
                      frames: <TilesetVisualFrame>[element.frames.first],
                    )
                  : element,
          ];

          _expectValidationCode(
            _manifest(elements: elements),
            _maps(),
            'rail_journey.door_not_animated',
          );
        }
      },
    );
  });
}

Map<String, dynamic> _minimalProjectJson() => <String, dynamic>{
  'name': 'Rail project',
  'version': 'v6',
  'maps': <Object?>[],
  'tilesets': <Object?>[],
};

const _doorFrames = <TilesetVisualFrame>[
  TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0), durationMs: 120),
  TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0), durationMs: 120),
];

const _doorElements = <ProjectElementEntry>[
  ProjectElementEntry(
    id: 'element_station_west',
    name: 'Station west door',
    tilesetId: 'doors',
    categoryId: 'doors',
    frames: _doorFrames,
  ),
  ProjectElementEntry(
    id: 'element_station_east',
    name: 'Station east door',
    tilesetId: 'doors',
    categoryId: 'doors',
    frames: _doorFrames,
  ),
  ProjectElementEntry(
    id: 'element_vehicle_west',
    name: 'Vehicle west door',
    tilesetId: 'doors',
    categoryId: 'doors',
    frames: _doorFrames,
  ),
  ProjectElementEntry(
    id: 'element_vehicle_east',
    name: 'Vehicle east door',
    tilesetId: 'doors',
    categoryId: 'doors',
    frames: _doorFrames,
  ),
];

ProjectManifest _manifest({
  RailJourneyDefinition journey = _journey,
  List<ProjectElementEntry> elements = _doorElements,
}) {
  return ProjectManifest(
    name: 'Rail project',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_origin_station',
        name: 'Origin station',
        relativePath: 'maps/origin.json',
      ),
      ProjectMapEntry(
        id: 'map_destination_station',
        name: 'Destination station',
        relativePath: 'maps/destination.json',
      ),
      ProjectMapEntry(
        id: 'map_train_car',
        name: 'Train car',
        relativePath: 'maps/train.json',
        role: MapRole.interior,
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'doors',
        name: 'Doors',
        relativePath: 'tilesets/doors.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'doors', name: 'Doors'),
    ],
    elements: elements,
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(id: 'fact_required', label: 'Required'),
      NarrativeFactDefinition(id: 'fact_any_a', label: 'Alternative A'),
      NarrativeFactDefinition(id: 'fact_any_b', label: 'Alternative B'),
    ],
    storylines: <StorylineAsset>[
      StorylineAsset(
        id: 'story_main',
        type: StorylineType.main,
        title: 'Main story',
        chapters: <StorylineChapter>[
          StorylineChapter(
            id: 'chapter_one',
            title: 'Chapter one',
            order: 0,
            steps: <StorylineStep>[
              StorylineStep(id: 'step_ready', title: 'Ready', order: 0),
            ],
          ),
        ],
      ),
    ],
    railJourneyCatalog: RailJourneyCatalog(
      journeys: <RailJourneyDefinition>[journey],
    ),
  );
}

List<MapData> _maps() => <MapData>[
  const MapData(
    id: 'map_origin_station',
    name: 'Origin station',
    size: GridSize(width: 10, height: 10),
    layers: <MapLayer>[MapLayer.object(id: 'doors', name: 'Doors')],
    placedElements: <MapPlacedElement>[
      MapPlacedElement(
        id: 'door_origin_west',
        layerId: 'doors',
        elementId: 'element_station_west',
        pos: GridPos(x: 2, y: 3),
      ),
    ],
  ),
  const MapData(
    id: 'map_destination_station',
    name: 'Destination station',
    size: GridSize(width: 10, height: 10),
    layers: <MapLayer>[MapLayer.object(id: 'doors', name: 'Doors')],
    placedElements: <MapPlacedElement>[
      MapPlacedElement(
        id: 'door_destination_east',
        layerId: 'doors',
        elementId: 'element_station_east',
        pos: GridPos(x: 4, y: 2),
      ),
    ],
  ),
  const MapData(
    id: 'map_train_car',
    name: 'Train car',
    size: GridSize(width: 10, height: 10),
    layers: <MapLayer>[MapLayer.object(id: 'doors', name: 'Doors')],
    placedElements: <MapPlacedElement>[
      MapPlacedElement(
        id: 'door_vehicle_west',
        layerId: 'doors',
        elementId: 'element_vehicle_west',
        pos: GridPos(x: 1, y: 4),
      ),
      MapPlacedElement(
        id: 'door_vehicle_east',
        layerId: 'doors',
        elementId: 'element_vehicle_east',
        pos: GridPos(x: 6, y: 4),
      ),
    ],
  ),
];

void _expectValidationCode(
  ProjectManifest manifest,
  Iterable<MapData> maps,
  String code, {
  ProjectItemCatalog? itemCatalog,
}) {
  expect(
    () => ProjectValidator.validate(
      manifest,
      maps: maps,
      itemCatalog: itemCatalog,
    ),
    throwsA(
      isA<ValidationException>().having((error) => error.code, 'code', code),
    ),
  );
}
