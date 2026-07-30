import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapPlacedElement quarter-turn persistence', () {
    test('direct constructor defaults omitted quarterTurns to zero', () {
      const instance = MapPlacedElement(
        id: 'placed',
        layerId: 'ground',
        elementId: 'sign',
        pos: GridPos(x: 1, y: 1),
      );

      expect(instance.quarterTurns, 0);
    });

    test('historical JSON without quarterTurns defaults to zero', () {
      final decoded = MapPlacedElement.fromJson(_legacyPlacedElementJson());

      expect(decoded.quarterTurns, 0);
      expect(decoded.toJson()['quarterTurns'], 0);
    });

    test('all normalized quarter-turn values round-trip exactly', () {
      for (var quarterTurns = 0; quarterTurns < 4; quarterTurns++) {
        final instance = _placedElement(quarterTurns: quarterTurns);

        final json = instance.toJson();
        final decoded = MapPlacedElement.fromJson(json);

        expect(json['quarterTurns'], quarterTurns);
        expect(decoded.quarterTurns, quarterTurns);
      }
    });

    test('accepts null and integer-valued JSON numbers', () {
      for (final entry in <(Object?, int)>[
        (null, 0),
        (0, 0),
        (1.0, 1),
        (2, 2),
        (3.0, 3),
      ]) {
        final json = _legacyPlacedElementJson()..['quarterTurns'] = entry.$1;

        expect(
          MapPlacedElement.fromJson(json).quarterTurns,
          entry.$2,
          reason: 'quarterTurns=${entry.$1}',
        );
      }
    });

    for (final value in <double>[1.9, -0.9]) {
      test('rejects fractional JSON quarterTurns $value', () {
        final json = _legacyPlacedElementJson()..['quarterTurns'] = value;

        expect(
          () => MapPlacedElement.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    }

    for (final entry in <(Object, String)>[
      (double.nan, 'NaN'),
      (double.infinity, 'positive infinity'),
      (double.negativeInfinity, 'negative infinity'),
      ('1', 'string'),
      (true, 'boolean'),
    ]) {
      test('rejects non-integer JSON quarterTurns ${entry.$2}', () {
        final json = _legacyPlacedElementJson()..['quarterTurns'] = entry.$1;

        expect(
          () => MapPlacedElement.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('decodes four before semantic range validation rejects it', () {
      final json = _legacyPlacedElementJson()..['quarterTurns'] = 4;
      final decoded = MapPlacedElement.fromJson(json);

      expect(decoded.quarterTurns, 4);
      expect(
        () => MapValidator.validate(
          _validationMap(quarterTurns: decoded.quarterTurns),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('copy and value equality include quarterTurns', () {
      const original = MapPlacedElement(
        id: 'placed',
        layerId: 'ground',
        elementId: 'sign',
        pos: GridPos(x: 1, y: 1),
      );

      final rotated = original.copyWith(quarterTurns: 1);

      expect(rotated, isNot(original));
      expect(rotated, original.copyWith(quarterTurns: 1));
      expect(rotated.quarterTurns, 1);
    });

    test('migration adds the default before the behavior-list early return',
        () {
      final migrated = migrateMapPlacedElementJson(
        _legacyPlacedElementJson(
          behaviors: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'placed::behavior::0',
              'trigger': 'on_action',
              'effect': <String, dynamic>{
                'type': 'show_message',
                'message': 'Hello',
              },
            },
          ],
        ),
      );

      expect(migrated['quarterTurns'], 0);
      expect(migrated['behaviors'], isNotEmpty);
    });
  });

  group('MapPlacedElement quarter-turn operations', () {
    test('absolute setter accepts every normalized value immutably', () {
      for (var quarterTurns = 0; quarterTurns < 4; quarterTurns++) {
        final source = _map();
        final sourceSnapshot = source.toJson();
        final targetBefore = source.placedElements.first;
        final otherBefore = source.placedElements.last;

        final updated = setMapPlacedElementQuarterTurns(
          source,
          instanceId: 'placed',
          quarterTurns: quarterTurns,
        );

        _expectOnlyTargetRotationChanged(
          source: source,
          sourceSnapshot: sourceSnapshot,
          targetBefore: targetBefore,
          otherBefore: otherBefore,
          result: updated,
          expectedQuarterTurns: quarterTurns,
        );
        expect(
          () => updated.placedElements.add(_placedElement()),
          throwsUnsupportedError,
        );
      }
    });

    test('absolute setter rejects values outside zero through three', () {
      for (final quarterTurns in <int>[-1, 4]) {
        final source = _map();
        final sourceSnapshot = source.toJson();
        final targetBefore = source.placedElements.first;
        final otherBefore = source.placedElements.last;

        expect(
          () => setMapPlacedElementQuarterTurns(
            source,
            instanceId: 'placed',
            quarterTurns: quarterTurns,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(source, MapData.fromJson(sourceSnapshot));
        expect(source.toJson(), sourceSnapshot);
        expect(source.placedElements, hasLength(2));
        expect(source.placedElements.first, same(targetBefore));
        expect(source.placedElements.last, same(otherBefore));
      }
    });

    test('delta rotation wraps positive and negative values', () {
      final positiveSource = _map(quarterTurns: 3);
      final positiveSnapshot = positiveSource.toJson();
      final positiveTargetBefore = positiveSource.placedElements.first;
      final positiveOtherBefore = positiveSource.placedElements.last;
      final positive = rotateMapPlacedElement(
        positiveSource,
        instanceId: 'placed',
        deltaQuarterTurns: 5,
      );
      final negativeSource = _map(quarterTurns: 0);
      final negativeSnapshot = negativeSource.toJson();
      final negativeTargetBefore = negativeSource.placedElements.first;
      final negativeOtherBefore = negativeSource.placedElements.last;
      final negative = rotateMapPlacedElement(
        negativeSource,
        instanceId: 'placed',
        deltaQuarterTurns: -2,
      );

      _expectOnlyTargetRotationChanged(
        source: positiveSource,
        sourceSnapshot: positiveSnapshot,
        targetBefore: positiveTargetBefore,
        otherBefore: positiveOtherBefore,
        result: positive,
        expectedQuarterTurns: 0,
      );
      _expectOnlyTargetRotationChanged(
        source: negativeSource,
        sourceSnapshot: negativeSnapshot,
        targetBefore: negativeTargetBefore,
        otherBefore: negativeOtherBefore,
        result: negative,
        expectedQuarterTurns: 2,
      );
    });

    test('delta rotation reduces web-safe integer limits before addition', () {
      final source = _map(quarterTurns: 2);

      final result = rotateMapPlacedElement(
        source,
        instanceId: 'placed',
        deltaQuarterTurns: 9007199254740991,
      );

      expect(result.placedElements.first.quarterTurns, 1);
    });

    test('absolute and delta no-ops return the identical MapData instance', () {
      final source = _map(quarterTurns: 2);

      final absolute = setMapPlacedElementQuarterTurns(
        source,
        instanceId: 'placed',
        quarterTurns: 2,
      );
      final delta = rotateMapPlacedElement(
        source,
        instanceId: 'placed',
        deltaQuarterTurns: -4,
      );

      expect(absolute, same(source));
      expect(delta, same(source));
    });

    test('unknown instance fails without modifying the source map', () {
      final source = _map();
      final snapshot = source.toJson();

      expect(
        () => setMapPlacedElementQuarterTurns(
          source,
          instanceId: 'missing',
          quarterTurns: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => rotateMapPlacedElement(
          source,
          instanceId: 'missing',
          deltaQuarterTurns: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(source.toJson(), snapshot);
      expect(source.placedElements.first.quarterTurns, 0);
    });
  });

  group('QuarterTurnGridTransform', () {
    test('normalizes negative and overflowing quarter turns', () {
      expect(normalizeQuarterTurns(-1), 3);
      expect(normalizeQuarterTurns(-5), 3);
      expect(normalizeQuarterTurns(4), 0);
      expect(normalizeQuarterTurns(9), 1);
    });

    test('maps and inverse-maps every cell of a three-by-two source', () {
      const sourceSize = GridSize(width: 3, height: 2);
      const sourceCells = <GridPos>[
        GridPos(x: 0, y: 0),
        GridPos(x: 1, y: 0),
        GridPos(x: 2, y: 0),
        GridPos(x: 0, y: 1),
        GridPos(x: 1, y: 1),
        GridPos(x: 2, y: 1),
      ];
      const expectedSizes = <GridSize>[
        GridSize(width: 3, height: 2),
        GridSize(width: 2, height: 3),
        GridSize(width: 3, height: 2),
        GridSize(width: 2, height: 3),
      ];
      const expectedDestinations = <List<GridPos>>[
        <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
        ],
        <GridPos>[
          GridPos(x: 1, y: 0),
          GridPos(x: 1, y: 1),
          GridPos(x: 1, y: 2),
          GridPos(x: 0, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 0, y: 2),
        ],
        <GridPos>[
          GridPos(x: 2, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 0, y: 1),
          GridPos(x: 2, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 0, y: 0),
        ],
        <GridPos>[
          GridPos(x: 0, y: 2),
          GridPos(x: 0, y: 1),
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 2),
          GridPos(x: 1, y: 1),
          GridPos(x: 1, y: 0),
        ],
      ];

      for (var quarterTurns = 0; quarterTurns < 4; quarterTurns++) {
        final transform = QuarterTurnGridTransform(
          sourceSize: sourceSize,
          quarterTurns: quarterTurns,
        );

        expect(transform.destinationSize, expectedSizes[quarterTurns]);
        for (var index = 0; index < sourceCells.length; index++) {
          final source = sourceCells[index];
          final destination = expectedDestinations[quarterTurns][index];
          expect(transform.sourceToDestination(source), destination);
          expect(transform.destinationToSource(destination), source);
        }
      }
    });

    test('resolves a placed element source and rotated destination size', () {
      final transform = resolveMapPlacedElementFootprint(
        instance: _placedElement(quarterTurns: 3),
        element: _element(),
      );

      expect(transform.sourceSize, const GridSize(width: 3, height: 2));
      expect(transform.destinationSize, const GridSize(width: 2, height: 3));
      expect(transform.quarterTurns, 3);
    });

    test('preserves the legacy one-cell fallback for invalid frame sizes', () {
      final transform = resolveMapPlacedElementFootprint(
        instance: _placedElement(),
        element: const ProjectElementEntry(
          id: 'legacy-invalid',
          name: 'Legacy invalid',
          tilesetId: 'tiles',
          categoryId: 'props',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(
                x: 0,
                y: 0,
                width: 0,
                height: -2,
              ),
            ),
          ],
        ),
      );

      expect(transform.sourceSize, const GridSize(width: 1, height: 1));
      expect(transform.destinationSize, const GridSize(width: 1, height: 1));
    });

    test('rejects invalid dimensions, turns, and coordinates in release mode',
        () {
      expect(
        () => QuarterTurnGridTransform(
          sourceSize: const GridSize(width: 0, height: 2),
          quarterTurns: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => QuarterTurnGridTransform(
          sourceSize: const GridSize(width: 3, height: -1),
          quarterTurns: 0,
        ),
        throwsArgumentError,
      );
      for (final quarterTurns in <int>[-1, 4]) {
        expect(
          () => QuarterTurnGridTransform(
            sourceSize: const GridSize(width: 3, height: 2),
            quarterTurns: quarterTurns,
          ),
          throwsArgumentError,
        );
      }

      final transform = QuarterTurnGridTransform(
        sourceSize: const GridSize(width: 3, height: 2),
        quarterTurns: 1,
      );
      for (final source in const <GridPos>[
        GridPos(x: -1, y: 0),
        GridPos(x: 3, y: 0),
        GridPos(x: 0, y: 2),
      ]) {
        expect(
          () => transform.sourceToDestination(source),
          throwsRangeError,
        );
      }
      for (final destination in const <GridPos>[
        GridPos(x: -1, y: 0),
        GridPos(x: 2, y: 0),
        GridPos(x: 0, y: 3),
      ]) {
        expect(
          () => transform.destinationToSource(destination),
          throwsRangeError,
        );
      }
    });
  });

  group('QuarterTurnPixelTransform', () {
    test('samples forward pixel centers at exact rational boundaries', () {
      final transform = QuarterTurnPixelTransform(
        sourcePixelSize: const GridSize(width: 22, height: 1),
        destinationPixelSize: const GridSize(width: 11, height: 1),
        quarterTurns: 0,
      );

      expect(
        transform.destinationPixelToSourcePixel(
          const GridPos(x: 7, y: 0),
        ),
        const GridPos(x: 15, y: 0),
      );
    });

    test('samples inverted pixel centers at exact rational boundaries', () {
      final transform = QuarterTurnPixelTransform(
        sourcePixelSize: const GridSize(width: 6, height: 1),
        destinationPixelSize: const GridSize(width: 3, height: 1),
        quarterTurns: 2,
      );

      expect(
        transform.destinationPixelToSourcePixel(
          const GridPos(x: 2, y: 0),
        ),
        const GridPos(x: 1, y: 0),
      );
    });

    test('uses exact fallback when center products exceed web-safe integers',
        () {
      final transform = QuarterTurnPixelTransform(
        sourcePixelSize: const GridSize(width: 9007199254740991, height: 1),
        destinationPixelSize: const GridSize(width: 3, height: 1),
        quarterTurns: 0,
      );

      expect(
        transform.destinationPixelToSourcePixel(
          const GridPos(x: 2, y: 0),
        ),
        const GridPos(x: 7505999378950825, y: 0),
      );
    });

    test('inverse-samples every pixel with unequal world tile dimensions', () {
      const sourcePixelSize = GridSize(width: 6, height: 2);
      const destinationSizes = <GridSize>[
        GridSize(width: 6, height: 2),
        GridSize(width: 3, height: 4),
        GridSize(width: 6, height: 2),
        GridSize(width: 3, height: 4),
      ];
      const expectedSamples = <List<GridPos>>[
        <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 3, y: 0),
          GridPos(x: 4, y: 0),
          GridPos(x: 5, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
          GridPos(x: 4, y: 1),
          GridPos(x: 5, y: 1),
        ],
        <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 0, y: 1),
          GridPos(x: 0, y: 0),
          GridPos(x: 2, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 2, y: 0),
          GridPos(x: 3, y: 1),
          GridPos(x: 3, y: 1),
          GridPos(x: 3, y: 0),
          GridPos(x: 5, y: 1),
          GridPos(x: 5, y: 1),
          GridPos(x: 5, y: 0),
        ],
        <GridPos>[
          GridPos(x: 5, y: 1),
          GridPos(x: 4, y: 1),
          GridPos(x: 3, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 0, y: 1),
          GridPos(x: 5, y: 0),
          GridPos(x: 4, y: 0),
          GridPos(x: 3, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 0, y: 0),
        ],
        <GridPos>[
          GridPos(x: 5, y: 0),
          GridPos(x: 5, y: 1),
          GridPos(x: 5, y: 1),
          GridPos(x: 3, y: 0),
          GridPos(x: 3, y: 1),
          GridPos(x: 3, y: 1),
          GridPos(x: 2, y: 0),
          GridPos(x: 2, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 0, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 0, y: 1),
        ],
      ];

      for (var quarterTurns = 0; quarterTurns < 4; quarterTurns++) {
        final destinationSize = destinationSizes[quarterTurns];
        final transform = QuarterTurnPixelTransform(
          sourcePixelSize: sourcePixelSize,
          destinationPixelSize: destinationSize,
          quarterTurns: quarterTurns,
        );
        var index = 0;
        for (var y = 0; y < destinationSize.height; y++) {
          for (var x = 0; x < destinationSize.width; x++) {
            expect(
              transform.destinationPixelToSourcePixel(
                GridPos(x: x, y: y),
              ),
              expectedSamples[quarterTurns][index],
              reason: 'q$quarterTurns destination ($x, $y)',
            );
            index += 1;
          }
        }
      }
    });

    test('rejects invalid dimensions, turns, and destination coordinates', () {
      expect(
        () => QuarterTurnPixelTransform(
          sourcePixelSize: const GridSize(width: 0, height: 2),
          destinationPixelSize: const GridSize(width: 3, height: 4),
          quarterTurns: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => QuarterTurnPixelTransform(
          sourcePixelSize: const GridSize(width: 6, height: 2),
          destinationPixelSize: const GridSize(width: 3, height: 0),
          quarterTurns: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => QuarterTurnPixelTransform(
          sourcePixelSize: const GridSize(width: 6, height: 2),
          destinationPixelSize: const GridSize(width: 3, height: 4),
          quarterTurns: 4,
        ),
        throwsArgumentError,
      );

      final transform = QuarterTurnPixelTransform(
        sourcePixelSize: const GridSize(width: 6, height: 2),
        destinationPixelSize: const GridSize(width: 3, height: 4),
        quarterTurns: 1,
      );
      for (final destination in const <GridPos>[
        GridPos(x: -1, y: 0),
        GridPos(x: 3, y: 0),
        GridPos(x: 0, y: 4),
      ]) {
        expect(
          () => transform.destinationPixelToSourcePixel(destination),
          throwsRangeError,
        );
      }
    });
  });

  group('MapPlacedElement quarter-turn validation', () {
    test('rejects stored values outside zero through three without context',
        () {
      for (final quarterTurns in <int>[-1, 4]) {
        expect(
          () => MapValidator.validate(
            _validationMap(quarterTurns: quarterTurns),
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('does not invent an element footprint without project context', () {
      expect(
        () => MapValidator.validate(
          _validationMap(
            quarterTurns: 1,
            pos: const GridPos(x: 3, y: 2),
          ),
        ),
        returnsNormally,
      );
    });

    test('uses the rotated bounding box when project context resolves size',
        () {
      for (final quarterTurns in <int>[1, 3]) {
        expect(
          () => MapValidator.validate(
            _validationMap(
              quarterTurns: quarterTurns,
              pos: const GridPos(x: 2, y: 0),
            ),
            projectDialogueContext: _project(),
          ),
          returnsNormally,
        );
        expect(
          () => MapValidator.validate(
            _validationMap(
              quarterTurns: quarterTurns,
              pos: const GridPos(x: 2, y: 1),
            ),
            projectDialogueContext: _project(),
          ),
          throwsA(isA<ValidationException>()),
        );
      }

      for (final quarterTurns in <int>[0, 2]) {
        expect(
          () => MapValidator.validate(
            _validationMap(
              quarterTurns: quarterTurns,
              pos: const GridPos(x: 2, y: 0),
            ),
            projectDialogueContext: _project(),
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });
  });
}

Map<String, dynamic> _legacyPlacedElementJson({
  List<Map<String, dynamic>>? behaviors,
}) =>
    <String, dynamic>{
      'id': 'placed',
      'layerId': 'ground',
      'elementId': 'sign',
      'pos': <String, dynamic>{'x': 1, 'y': 1},
      if (behaviors != null) 'behaviors': behaviors,
    };

MapPlacedElement _placedElement({int quarterTurns = 0}) => MapPlacedElement(
      id: 'placed',
      layerId: 'ground',
      elementId: 'sign',
      pos: const GridPos(x: 1, y: 1),
      quarterTurns: quarterTurns,
    );

MapData _map({int quarterTurns = 0}) => MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 4, height: 4),
      placedElements: <MapPlacedElement>[
        _placedElement(quarterTurns: quarterTurns),
        const MapPlacedElement(
          id: 'other',
          layerId: 'ground',
          elementId: 'sign',
          pos: GridPos(x: 2, y: 2),
        ),
      ],
    );

void _expectOnlyTargetRotationChanged({
  required MapData source,
  required Map<String, dynamic> sourceSnapshot,
  required MapPlacedElement targetBefore,
  required MapPlacedElement otherBefore,
  required MapData result,
  required int expectedQuarterTurns,
}) {
  expect(source, MapData.fromJson(sourceSnapshot));
  expect(source.toJson(), sourceSnapshot);
  expect(source.placedElements, hasLength(2));
  expect(source.placedElements.first, same(targetBefore));
  expect(source.placedElements.last, same(otherBefore));

  expect(result.placedElements, hasLength(2));
  expect(
    result.placedElements.map((instance) => instance.id),
    orderedEquals(const <String>['placed', 'other']),
  );
  expect(result.placedElements.first.quarterTurns, expectedQuarterTurns);
  expect(result.placedElements.last, same(otherBefore));
  expect(result.placedElements.last, otherBefore);
}

MapData _validationMap({
  required int quarterTurns,
  GridPos pos = const GridPos(x: 0, y: 0),
}) =>
    MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 4, height: 3),
      layers: <MapLayer>[
        MapLayer.tile(
          id: 'ground',
          name: 'Ground',
          tilesetId: 'tiles',
          tiles: List<int>.filled(12, 0),
        ),
      ],
      placedElements: <MapPlacedElement>[
        MapPlacedElement(
          id: 'placed',
          layerId: 'ground',
          elementId: 'sign',
          pos: pos,
          quarterTurns: quarterTurns,
        ),
      ],
    );

ProjectElementEntry _element() => const ProjectElementEntry(
      id: 'sign',
      name: 'Sign',
      tilesetId: 'tiles',
      categoryId: 'props',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 3, height: 2),
        ),
      ],
    );

ProjectManifest _project() => ProjectManifest(
      name: 'Project',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'tiles',
          name: 'Tiles',
          relativePath: 'tiles.png',
        ),
      ],
      elementCategories: const <ProjectElementCategory>[
        ProjectElementCategory(id: 'props', name: 'Props'),
      ],
      elements: <ProjectElementEntry>[_element()],
      surfaceCatalog: ProjectSurfaceCatalog(),
    );
