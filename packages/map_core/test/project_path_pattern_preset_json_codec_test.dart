import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPathPatternPreset JSON codec', () {
    test('encodes a minimal preset', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-1x1',
        name: 'Water 1x1',
        basePathPresetId: 'legacy-water',
        centerPattern: _singleCellPattern(),
      );

      final json = encodeProjectPathPatternPreset(preset);

      expect(json['id'], 'water-1x1');
      expect(json['name'], 'Water 1x1');
      expect(json['basePathPresetId'], 'legacy-water');
      expect(json['sortOrder'], 0);
      expect(json, isNot(contains('transparentColor')));
      expect(json, isNot(contains('categoryId')));
      expect(json['centerPattern'], {
        'size': {'width': 1, 'height': 1},
        'cells': [
          {
            'localX': 0,
            'localY': 0,
            'frames': [
              _frame(1, 2).toJson(),
            ],
          },
        ],
      });
    });

    test('decodes a minimal preset', () {
      final preset = decodeProjectPathPatternPreset({
        'id': 'water-1x1',
        'name': 'Water 1x1',
        'basePathPresetId': 'legacy-water',
        'sortOrder': 0,
        'centerPattern': {
          'size': {'width': 1, 'height': 1},
          'cells': [
            {
              'localX': 0,
              'localY': 0,
              'frames': [
                _frame(1, 2).toJson(),
              ],
            },
          ],
        },
      });

      expect(preset.id, 'water-1x1');
      expect(preset.name, 'Water 1x1');
      expect(preset.basePathPresetId, 'legacy-water');
      expect(preset.transparentColor, isNull);
      expect(preset.categoryId, isNull);
      expect(preset.sortOrder, 0);
      expect(preset.centerPattern, _singleCellPattern());
    });

    test('roundtrips a minimal preset', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-1x1',
        name: 'Water 1x1',
        basePathPresetId: 'legacy-water',
        centerPattern: _singleCellPattern(),
      );

      expect(
        decodeProjectPathPatternPreset(encodeProjectPathPatternPreset(preset)),
        preset,
      );
    });

    test('encodes a complete 2x2 preset in row-major cell order', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-sea-2x2',
        name: 'Mer 2x2',
        basePathPresetId: 'legacy-water',
        centerPattern: _twoByTwoPattern(),
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
        categoryId: 'water',
        sortOrder: 12,
      );

      final json = encodeProjectPathPatternPreset(preset);
      final centerPattern = json['centerPattern'] as Map<String, dynamic>;
      final cells = centerPattern['cells'] as List<dynamic>;

      expect(json['transparentColor'], 'f05ba1');
      expect(json['categoryId'], 'water');
      expect(json['sortOrder'], 12);
      expect(
        cells
            .map(
              (dynamic cell) => [
                (cell as Map<String, dynamic>)['localX'],
                cell['localY'],
              ],
            )
            .toList(),
        [
          [0, 0],
          [1, 0],
          [0, 1],
          [1, 1],
        ],
      );
      expect(
        ((cells[0] as Map<String, dynamic>)['frames'] as List<dynamic>)
            .map((dynamic frame) => (frame as Map<String, dynamic>)['source'])
            .toList(),
        [
          {'x': 0, 'y': 0, 'width': 1, 'height': 1},
          {'x': 1, 'y': 0, 'width': 1, 'height': 1},
        ],
      );
    });

    test('roundtrips a complete 2x2 preset', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-sea-2x2',
        name: 'Mer 2x2',
        basePathPresetId: 'legacy-water',
        centerPattern: _twoByTwoPattern(),
        transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
        categoryId: 'water',
        sortOrder: 12,
      );

      expect(
        decodeProjectPathPatternPreset(encodeProjectPathPatternPreset(preset)),
        preset,
      );
    });

    test('canonicalizes transparentColor after decode and encode', () {
      final preset = decodeProjectPathPatternPreset({
        'id': 'water-sea-2x2',
        'name': 'Mer 2x2',
        'basePathPresetId': 'legacy-water',
        'sortOrder': 12,
        'transparentColor': '#F05BA1',
        'centerPattern': _encodedSingleCellPattern(),
      });

      expect(
        encodeProjectPathPatternPreset(preset)['transparentColor'],
        'f05ba1',
      );
    });

    test('roundtrips frame tileset overrides', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-animated',
        name: 'Water animated',
        basePathPresetId: 'legacy-water',
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 1, height: 1),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: [
                _frame(0, 0),
                _frame(1, 0, tilesetId: 'override_tileset'),
              ],
            ),
          ],
        ),
      );

      final roundtripped = decodeProjectPathPatternPreset(
        encodeProjectPathPatternPreset(preset),
      );
      final frames = roundtripped.centerPattern.cellAt(0, 0).frames;

      expect(frames[0].tilesetId, '');
      expect(frames[1].tilesetId, 'override_tileset');
    });

    test('roundtrips null and non-null frame durations', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-duration',
        name: 'Water duration',
        basePathPresetId: 'legacy-water',
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 1, height: 1),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: [
                _frame(0, 0),
                _frame(1, 0, durationMs: 100),
              ],
            ),
          ],
        ),
      );

      final json = encodeProjectPathPatternPreset(preset);
      final frames = ((((json['centerPattern'] as Map<String, dynamic>)['cells']
              as List<dynamic>)
          .single as Map<String, dynamic>)['frames']) as List<dynamic>;
      final roundtripped = decodeProjectPathPatternPreset(json);
      final decodedFrames = roundtripped.centerPattern.cellAt(0, 0).frames;

      expect(frames[0], containsPair('durationMs', null));
      expect(frames[1], containsPair('durationMs', 100));
      expect(decodedFrames[0].durationMs, isNull);
      expect(decodedFrames[1].durationMs, 100);
    });

    test('rejects invalid JSON', () {
      for (final json in [
        _validJson()..remove('id'),
        _validJson()..remove('name'),
        _validJson()..remove('basePathPresetId'),
        _validJson()..remove('centerPattern'),
        _validJson()..remove('sortOrder'),
        _validJson()
          ..['centerPattern'] = {
            'cells': [],
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'width': 1, 'height': 1},
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'height': 1},
            'cells': [],
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'width': 1},
            'cells': [],
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'width': 1, 'height': 1},
            'cells': [
              {
                'localY': 0,
                'frames': [_frame(0, 0).toJson()],
              },
            ],
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'width': 1, 'height': 1},
            'cells': [
              {
                'localX': 0,
                'frames': [_frame(0, 0).toJson()],
              },
            ],
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'width': 1, 'height': 1},
            'cells': [
              {'localX': 0, 'localY': 0},
            ],
          },
        _validJson()
          ..['centerPattern'] = {
            'size': {'width': 1, 'height': 1},
            'cells': [
              {'localX': 0, 'localY': 0, 'frames': 'not-list'},
            ],
          },
        _validJson()..['transparentColor'] = 'not-hex',
      ]) {
        expect(
          () => decodeProjectPathPatternPreset(json),
          throwsA(anyOf(isA<ValidationException>(), isA<ArgumentError>())),
          reason: json.toString(),
        );
      }
    });
  });
}

PathCenterPattern _singleCellPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [_frame(1, 2)],
      ),
    ],
  );
}

PathCenterPattern _twoByTwoPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(
        localX: 1,
        localY: 1,
        frames: [_frame(3, 0, durationMs: 130)],
      ),
      PathCenterPatternCell(
        localX: 0,
        localY: 1,
        frames: [_frame(2, 0, durationMs: 120)],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 0,
        frames: [_frame(1, 0, durationMs: 110)],
      ),
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [
          _frame(0, 0, durationMs: 100),
          _frame(1, 0, durationMs: 110),
        ],
      ),
    ],
  );
}

Map<String, dynamic> _encodedSingleCellPattern() {
  return {
    'size': {'width': 1, 'height': 1},
    'cells': [
      {
        'localX': 0,
        'localY': 0,
        'frames': [_frame(1, 2).toJson()],
      },
    ],
  };
}

Map<String, dynamic> _validJson() {
  return {
    'id': 'water-1x1',
    'name': 'Water 1x1',
    'basePathPresetId': 'legacy-water',
    'sortOrder': 0,
    'centerPattern': _encodedSingleCellPattern(),
  };
}

TilesetVisualFrame _frame(
  int x,
  int y, {
  String tilesetId = '',
  int? durationMs,
}) {
  return TilesetVisualFrame(
    tilesetId: tilesetId,
    source: TilesetSourceRect(x: x, y: y),
    durationMs: durationMs,
  );
}
