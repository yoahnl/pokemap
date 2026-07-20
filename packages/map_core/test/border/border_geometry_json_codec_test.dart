import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderFeatureGeometry JSON codec', () {
    test('encodes a region exactly and round-trips its row-major mask', () {
      final geometry = BorderRegionGeometry(
        width: 3,
        height: 2,
        cells: const <bool>[true, true, false, false, true, false],
      );

      final encoded = encodeBorderFeatureGeometryJson(geometry);

      expect(encoded, <String, Object?>{
        'kind': 'region',
        'width': 3,
        'height': 2,
        'cellsRle': 'border-rle-v1:6:1:2,2,1,1',
      });
      expect(encoded.keys, <String>['kind', 'width', 'height', 'cellsRle']);
      expect(decodeBorderFeatureGeometryJson(encoded), geometry);
      expect(encoded.toString(), isNot(contains('collision')));
    });

    test('accepts an all-false region as an empty feature draft', () {
      final decoded = decodeBorderFeatureGeometryJson(<String, Object?>{
        'kind': 'region',
        'width': 3,
        'height': 2,
        'cellsRle': 'border-rle-v1:6:0:6',
      });

      expect(
        decoded,
        BorderRegionGeometry(
          width: 3,
          height: 2,
          cells: const <bool>[false, false, false, false, false, false],
        ),
      );
    });

    test('encodes strokes exactly and preserves stroke and point order', () {
      final geometry = BorderStrokeGeometry(
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'west',
            points: const <GridPos>[
              GridPos(x: -2, y: 4),
              GridPos(x: -1, y: 4),
              GridPos(x: -1, y: 5),
            ],
            closed: false,
          ),
          BorderStroke(
            id: 'island',
            points: const <GridPos>[
              GridPos(x: 10, y: 10),
              GridPos(x: 10, y: 11),
              GridPos(x: 11, y: 11),
              GridPos(x: 11, y: 10),
            ],
            closed: true,
          ),
        ],
      );

      final encoded = encodeBorderFeatureGeometryJson(geometry);

      expect(encoded, <String, Object?>{
        'kind': 'stroke',
        'strokes': <Object?>[
          <String, Object?>{
            'id': 'west',
            'points': <Object?>[
              <String, Object?>{'x': -2, 'y': 4},
              <String, Object?>{'x': -1, 'y': 4},
              <String, Object?>{'x': -1, 'y': 5},
            ],
            'closed': false,
          },
          <String, Object?>{
            'id': 'island',
            'points': <Object?>[
              <String, Object?>{'x': 10, 'y': 10},
              <String, Object?>{'x': 10, 'y': 11},
              <String, Object?>{'x': 11, 'y': 11},
              <String, Object?>{'x': 11, 'y': 10},
            ],
            'closed': true,
          },
        ],
      });
      expect(decodeBorderFeatureGeometryJson(encoded), geometry);
    });

    test('round-trips an empty stroke collection as a valid draft', () {
      final geometry = BorderStrokeGeometry(strokes: const <BorderStroke>[]);

      expect(
        decodeBorderFeatureGeometryJson(
          encodeBorderFeatureGeometryJson(geometry),
        ),
        geometry,
      );
    });

    test('rejects unknown kinds and fields at their exact paths', () {
      expect(
        () => decodeBorderFeatureGeometryJson(<String, Object?>{
          'kind': 'organicLine',
          'strokes': const <Object?>[],
        }),
        _formatAt(r'$.kind'),
      );

      expect(
        () => decodeBorderFeatureGeometryJson(<String, Object?>{
          'kind': 'region',
          'width': 1,
          'height': 1,
          'cellsRle': 'border-rle-v1:1:0:1',
          'collision': true,
        }),
        _formatAt(r'$.collision'),
      );

      expect(
        () => decodeBorderFeatureGeometryJson(<String, Object?>{
          'kind': 'stroke',
          'strokes': <Object?>[
            <String, Object?>{
              'id': 'a',
              'points': <Object?>[
                <String, Object?>{'x': 0, 'y': 0, 'z': 0},
                <String, Object?>{'x': 1, 'y': 0},
              ],
              'closed': false,
            },
          ],
        }),
        _formatAt(r'$.strokes[0].points[0].z'),
      );
    });

    test('requires strict fields and scalar types for a region', () {
      final missingHeight = _regionJson()..remove('height');
      expect(
        () => decodeBorderFeatureGeometryJson(missingHeight),
        _formatAt(r'$.height'),
      );

      for (final badWidth in <Object?>[null, 2.0, '2', true]) {
        final invalid = _regionJson()..['width'] = badWidth;
        expect(
          () => decodeBorderFeatureGeometryJson(invalid),
          _formatAt(r'$.width'),
          reason: '$badWidth',
        );
      }

      final invalidRleType = _regionJson()..['cellsRle'] = <Object?>[];
      expect(
        () => decodeBorderFeatureGeometryJson(invalidRleType),
        _formatAt(r'$.cellsRle'),
      );
    });

    test('rejects malformed and wrong-length region RLE', () {
      for (final rle in <String>[
        'not-rle',
        'border-rle-v1:3:1:3',
        'border-rle-v1:4:1:2,0,2',
        'border-rle-v1:4:1:4,',
      ]) {
        final invalid = _regionJson()..['cellsRle'] = rle;
        expect(
          () => decodeBorderFeatureGeometryJson(invalid),
          _formatAt(r'$.cellsRle'),
          reason: rle,
        );
      }
    });

    test('rejects region dimensions outside the bounded V1 range', () {
      for (final width in <int>[0, 8193]) {
        final invalid = _regionJson()..['width'] = width;
        expect(
          () => decodeBorderFeatureGeometryJson(invalid),
          _formatAt(r'$.width'),
          reason: 'width: $width',
        );
      }
      for (final height in <int>[0, 8193]) {
        final invalid = _regionJson()..['height'] = height;
        expect(
          () => decodeBorderFeatureGeometryJson(invalid),
          _formatAt(r'$.height'),
          reason: 'height: $height',
        );
      }
    });

    test('encoder rejects a model that exceeds V1 wire bounds', () {
      final oversized = BorderRegionGeometry(
        width: 8193,
        height: 1,
        cells: List<bool>.filled(8193, false),
      );

      expect(
        () => encodeBorderFeatureGeometryJson(oversized),
        _formatAt(r'$.width'),
      );
    });

    test('requires strict stroke, point, and boolean fields', () {
      final wrongX = _strokeJson();
      (((wrongX['strokes']! as List<Object?>).first!
              as Map<String, Object?>)['points']! as List<Object?>)
          .first = <String, Object?>{'x': 0.0, 'y': 0};
      expect(
        () => decodeBorderFeatureGeometryJson(wrongX),
        _formatAt(r'$.strokes[0].points[0].x'),
      );

      final wrongClosed = _strokeJson();
      ((wrongClosed['strokes']! as List<Object?>).first!
          as Map<String, Object?>)['closed'] = 0;
      expect(
        () => decodeBorderFeatureGeometryJson(wrongClosed),
        _formatAt(r'$.strokes[0].closed'),
      );

      final missingId = _strokeJson();
      ((missingId['strokes']! as List<Object?>).first! as Map<String, Object?>)
          .remove('id');
      expect(
        () => decodeBorderFeatureGeometryJson(missingId),
        _formatAt(r'$.strokes[0].id'),
      );
    });

    test('reports invalid open and closed topology at the authored stroke', () {
      final diagonal = _strokeJson(
        points: <Object?>[
          <String, Object?>{'x': 0, 'y': 0},
          <String, Object?>{'x': 1, 'y': 1},
        ],
      );
      expect(
        () => decodeBorderFeatureGeometryJson(diagonal),
        _formatAt(r'$.strokes[0]'),
      );

      final hairpin = _strokeJson(
        points: <Object?>[
          <String, Object?>{'x': 0, 'y': 0},
          <String, Object?>{'x': 1, 'y': 0},
          <String, Object?>{'x': 0, 'y': 0},
        ],
      );
      expect(
        () => decodeBorderFeatureGeometryJson(hairpin),
        _formatAt(r'$.strokes[0]'),
      );

      final invalidClosure = _strokeJson(
        points: <Object?>[
          <String, Object?>{'x': 0, 'y': 0},
          <String, Object?>{'x': 1, 'y': 0},
          <String, Object?>{'x': 2, 'y': 0},
          <String, Object?>{'x': 2, 'y': 1},
        ],
        closed: true,
      );
      expect(
        () => decodeBorderFeatureGeometryJson(invalidClosure),
        _formatAt(r'$.strokes[0]'),
      );
    });

    test('reports duplicate ids at the second authored id path', () {
      final duplicate = <String, Object?>{
        'kind': 'stroke',
        'strokes': <Object?>[
          _strokeEntryJson(id: 'same', startX: 0),
          _strokeEntryJson(id: 'same', startX: 10),
        ],
      };

      expect(
        () => decodeBorderFeatureGeometryJson(duplicate),
        _formatAt(r'$.strokes[1].id'),
      );
    });

    test('rejects shared cells between otherwise valid strokes', () {
      final shared = <String, Object?>{
        'kind': 'stroke',
        'strokes': <Object?>[
          _strokeEntryJson(id: 'horizontal', startX: 0),
          <String, Object?>{
            'id': 'vertical',
            'points': <Object?>[
              <String, Object?>{'x': 1, 'y': 0},
              <String, Object?>{'x': 1, 'y': 1},
            ],
            'closed': false,
          },
        ],
      };

      expect(
        () => decodeBorderFeatureGeometryJson(shared),
        _formatAt(r'$.strokes'),
      );
    });

    test('honors a custom JSONPath and never mutates input', () {
      final input = _strokeJson();
      final before = _deepCopy(input);

      final decoded = decodeBorderFeatureGeometryJson(
        input,
        path: r'$.layers[2].features[1].geometry',
      );

      expect(decoded, isA<BorderStrokeGeometry>());
      expect(input, before);

      final invalid = _regionJson()..['width'] = 0;
      expect(
        () => decodeBorderFeatureGeometryJson(
          invalid,
          path: r'$.layers[2].features[1].geometry',
        ),
        _formatAt(r'$.layers[2].features[1].geometry.width'),
      );
    });
  });

  group('BorderKeepOutRegion JSON codec', () {
    test('encodes only the id and a discriminated nested region', () {
      final keepOut = BorderKeepOutRegion(
        id: 'harbor-mouth',
        region: BorderRegionGeometry(
          width: 2,
          height: 2,
          cells: const <bool>[false, true, true, false],
        ),
      );

      final encoded = encodeBorderKeepOutRegionJson(keepOut);

      expect(encoded, <String, Object?>{
        'id': 'harbor-mouth',
        'region': <String, Object?>{
          'kind': 'region',
          'width': 2,
          'height': 2,
          'cellsRle': 'border-rle-v1:4:0:1,2,1',
        },
      });
      expect(decodeBorderKeepOutRegionJson(encoded), keepOut);
    });

    test('rejects a stroke in the nested region at region.kind', () {
      expect(
        () => decodeBorderKeepOutRegionJson(<String, Object?>{
          'id': 'opening',
          'region': <String, Object?>{
            'kind': 'stroke',
            'strokes': const <Object?>[],
          },
        }),
        _formatAt(r'$.region.kind'),
      );
    });

    test('requires exact fields and a stable id', () {
      final unknown = _keepOutJson()..['name'] = 'Opening';
      expect(
        () => decodeBorderKeepOutRegionJson(unknown),
        _formatAt(r'$.name'),
      );

      final invalidId = _keepOutJson()..['id'] = ' opening ';
      expect(
        () => decodeBorderKeepOutRegionJson(invalidId),
        _formatAt(r'$.id'),
      );

      final missingRegion = _keepOutJson()..remove('region');
      expect(
        () => decodeBorderKeepOutRegionJson(missingRegion),
        _formatAt(r'$.region'),
      );
    });

    test('honors custom paths and validates nested RLE there', () {
      final invalid = _keepOutJson();
      (invalid['region']! as Map<String, Object?>)['cellsRle'] =
          'border-rle-v1:3:0:3';

      expect(
        () => decodeBorderKeepOutRegionJson(
          invalid,
          path: r'$.features[0].keepOutRegions[4]',
        ),
        _formatAt(r'$.features[0].keepOutRegions[4].region.cellsRle'),
      );
    });
  });
}

Map<String, Object?> _regionJson() => <String, Object?>{
      'kind': 'region',
      'width': 2,
      'height': 2,
      'cellsRle': 'border-rle-v1:4:1:1,2,1',
    };

Map<String, Object?> _strokeJson({
  List<Object?>? points,
  bool closed = false,
}) =>
    <String, Object?>{
      'kind': 'stroke',
      'strokes': <Object?>[
        <String, Object?>{
          'id': 'stroke-a',
          'points': points ??
              <Object?>[
                <String, Object?>{'x': 0, 'y': 0},
                <String, Object?>{'x': 1, 'y': 0},
              ],
          'closed': closed,
        },
      ],
    };

Map<String, Object?> _strokeEntryJson({
  required String id,
  required int startX,
}) =>
    <String, Object?>{
      'id': id,
      'points': <Object?>[
        <String, Object?>{'x': startX, 'y': 0},
        <String, Object?>{'x': startX + 1, 'y': 0},
      ],
      'closed': false,
    };

Map<String, Object?> _keepOutJson() => <String, Object?>{
      'id': 'opening',
      'region': _regionJson(),
    };

Matcher _formatAt(String path) => throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        'message',
        startsWith('$path:'),
      ),
    );

Object? _deepCopy(Object? value) {
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key as String: _deepCopy(entry.value),
    };
  }
  if (value is List) {
    return <Object?>[for (final item in value) _deepCopy(item)];
  }
  return value;
}
