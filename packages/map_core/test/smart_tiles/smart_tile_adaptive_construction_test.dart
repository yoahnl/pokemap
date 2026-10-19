import 'package:map_core/map_core.dart';
import 'package:map_core/src/operations/resource_pack_native_json.dart';
import 'package:test/test.dart';

void main() {
  group('Native adaptive Smart Tile construction', () {
    test(
      'portable native pattern codec accepts typed construction and rejects extensions',
      () {
        final raw = _bridge().toJson();
        expect(
          () => validateResourcePackNativeJson(raw, 'ProjectSmartTilePattern'),
          returnsNormally,
        );
        final malformed = _bridge().toJson();
        (malformed['construction'] as Map)['unsupported'] = true;
        expect(
          () => validateResourcePackNativeJson(
            malformed,
            'ProjectSmartTilePattern',
          ),
          throwsA(isA<FormatException>()),
        );
        final fractional = _bridge().toJson();
        ((fractional['construction'] as Map)['y'] as Map)['repeatLength'] = 1.5;
        expect(
          () => validateResourcePackNativeJson(
            fractional,
            'ProjectSmartTilePattern',
          ),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'repeat intervals preserve both ends at zero, minimum and maximum counts',
      () {
        final axis = SmartTilePatternRepeatAxis(
          repeatStart: 1,
          repeatLength: 2,
          minimumRepeats: 0,
          maximumRepeats: 2,
        );
        List<int> indices(int length) => [
          for (var i = 0; i < length; i++)
            axis.sourceIndex(
              position: i,
              sourceLength: 4,
              outputLength: length,
            ),
        ];

        expect(indices(2), [0, 3]);
        expect(indices(4), [0, 1, 2, 3]);
        expect(indices(6), [0, 1, 2, 1, 2, 3]);
        expect(() => indices(8), throwsA(isA<ValidationException>()));
        expect(() => indices(5), throwsA(isA<ValidationException>()));
      },
    );

    test('retains the typed repeat interval through the native codec', () {
      final pattern = _bridge();

      expect(pattern.toJson()['construction'], _construction);
      expect(ProjectSmartTilePattern.fromJson(pattern.toJson()), pattern);
    });

    test('a vertical gesture expands the entire fixed five-cell bridge', () {
      final applied = _paint(
        const SmartTilePatternSelection.line(
          start: GridPos(x: 2, y: 2),
          end: GridPos(x: 2, y: 9),
        ),
      );

      expect(applied.affectedCells.length, 40);
      expect(applied.affectedCells.toSet(), {
        for (var y = 2; y <= 9; y++)
          for (var x = 2; x <= 6; x++) GridPos(x: x, y: y),
      });
      expect(
        applied.layer.patternStrokes.single.toJson()['constructionBounds'],
        {
          'pos': {'x': 2, 'y': 2},
          'size': {'width': 5, 'height': 8},
        },
      );
    });

    test(
      'samples north, whole body periods and south without repeating caps',
      () {
        final pattern = _bridge();
        final applied = _paint(
          const SmartTilePatternSelection.rectangle(
            start: GridPos(x: 2, y: 2),
            end: GridPos(x: 6, y: 7),
          ),
        );
        final stroke = applied.layer.patternStrokes.single;

        expect(
          [
            for (var y = 2; y <= 7; y++)
              [
                for (var x = 2; x <= 6; x++)
                  _moduleAt(pattern, stroke, GridPos(x: x, y: y)),
              ],
          ],
          [_north, _bodyA, _bodyB, _bodyA, _bodyB, _south],
        );
      },
    );

    test('rejects wrong bridge widths before changing the layer', () {
      expect(
        () => _paint(
          const SmartTilePatternSelection.rectangle(
            start: GridPos(x: 2, y: 2),
            end: GridPos(x: 5, y: 7),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects a partial two-row period before changing the layer', () {
      expect(
        () => _paint(
          const SmartTilePatternSelection.rectangle(
            start: GridPos(x: 2, y: 2),
            end: GridPos(x: 6, y: 6),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects map clipping of an expanded cross-section', () {
      expect(
        () => _paint(
          const SmartTilePatternSelection.line(
            start: GridPos(x: 18, y: 2),
            end: GridPos(x: 18, y: 7),
          ),
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.code,
            'code',
            'smart_tile.pattern.construction_out_of_bounds',
          ),
        ),
      );
    });

    test('rejects a map-phase shift that would displace the native caps', () {
      expect(
        () => _paint(
          const SmartTilePatternSelection.rectangle(
            start: GridPos(x: 2, y: 2),
            end: GridPos(x: 6, y: 7),
          ),
          phaseY: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('keeps original bounds after erasing the first complete row', () {
      final pattern = _bridge();
      final applied = _paint(
        const SmartTilePatternSelection.rectangle(
          start: GridPos(x: 2, y: 2),
          end: GridPos(x: 6, y: 7),
        ),
      );
      final erased = eraseSmartTilePatternCells(
        applied.layer,
        mapSize: _size,
        cells: [for (var x = 2; x <= 6; x++) GridPos(x: x, y: 2)],
      );
      final stroke = erased.patternStrokes.single;

      expect(stroke.toJson()['constructionBounds'], {
        'pos': {'x': 2, 'y': 2},
        'size': {'width': 5, 'height': 6},
      });
      expect(_moduleAt(pattern, stroke, const GridPos(x: 2, y: 3)), 750);
      expect(_moduleAt(pattern, stroke, const GridPos(x: 2, y: 7)), 725);
    });

    test(
      'resize crop preserves original cap phase instead of creating a new end',
      () {
        final applied = _paint(
          const SmartTilePatternSelection.line(
            start: GridPos(x: 2, y: 2),
            end: GridPos(x: 2, y: 9),
          ),
        );
        final source = MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v8,
          size: _size,
          layers: [applied.layer],
        );
        final resized = resizeMapData(source, width: 20, height: 8);
        final stroke = resized.layers
            .whereType<SmartTileLayer>()
            .single
            .patternStrokes
            .single;

        expect(
          stroke.constructionBounds,
          applied.layer.patternStrokes.single.constructionBounds,
        );
        expect(stroke.cells, hasLength(30));
        expect(_moduleAt(_bridge(), stroke, const GridPos(x: 2, y: 7)), 750);
        expect(
          () => validateSmartTilePatternConstructionStroke(
            pattern: _bridge(),
            stroke: stroke,
          ),
          returnsNormally,
        );
      },
    );

    test(
      'rejects construction semantics under the previous catalog version',
      () {
        final raw = ProjectSmartTileCatalog(patterns: [_bridge()]).toJson();
        raw['formatVersion'] = 7;

        expect(
          () => ProjectSmartTileCatalog.fromJson(raw),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('rejects fractional repeat intervals instead of truncating them', () {
      final raw = _bridge().toJson();
      raw['construction'] = {
        'y': {'repeatStart': 1.5, 'repeatLength': 2},
      };

      expect(
        () => ProjectSmartTilePattern.fromJson(raw),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a repeat interval outside its authored source axis', () {
      final raw = _bridge().toJson();
      raw['construction'] = {
        'y': {'repeatStart': 3, 'repeatLength': 2},
      };

      expect(
        () => ProjectSmartTilePattern.fromJson(raw),
        throwsA(anyOf(isA<FormatException>(), isA<ValidationException>())),
      );
    });

    test(
      'a stamp rejects partial placement instead of clipping native ends',
      () {
        expect(
          () => _paint(
            const SmartTilePatternSelection.stamp(anchor: GridPos(x: 18, y: 2)),
          ),
          throwsA(
            isA<ValidationException>().having(
              (error) => error.code,
              'code',
              'smart_tile.pattern.construction_out_of_bounds',
            ),
          ),
        );
      },
    );

    test('rejects a horizontal gesture for a north-south construction', () {
      expect(
        () => _paint(
          const SmartTilePatternSelection.line(
            start: GridPos(x: 2, y: 2),
            end: GridPos(x: 9, y: 2),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      'reversed vertical input preserves the authored north-south direction',
      () {
        final applied = _paint(
          const SmartTilePatternSelection.line(
            start: GridPos(x: 2, y: 9),
            end: GridPos(x: 2, y: 2),
          ),
        );
        final stroke = applied.layer.patternStrokes.single;

        expect(applied.affectedCells.length, 40);
        expect(_moduleAt(_bridge(), stroke, const GridPos(x: 2, y: 2)), 709);
        expect(_moduleAt(_bridge(), stroke, const GridPos(x: 6, y: 9)), 727);
      },
    );
  });
}

const _size = GridSize(width: 20, height: 20);
const _north = [709, 710, 733, 734, 711];
const _bodyA = [750, 718, 741, 742, 751];
const _bodyB = [717, 718, 741, 742, 719];
const _south = [725, 726, 749, 749, 727];
const _construction = {
  'y': {'repeatStart': 1, 'repeatLength': 2, 'minimumRepeats': 1},
};

ProjectSmartTilePattern _bridge() {
  const matrix = [_north, _bodyA, _bodyB, _south];
  final raw = ProjectSmartTilePattern(
    id: 'native-bridge',
    name: 'Native bridge',
    usage: SmartTileUsage.path,
    width: 5,
    height: 4,
    cells: [
      for (var y = 0; y < matrix.length; y++)
        for (var x = 0; x < matrix[y].length; x++)
          SmartTilePatternCell(
            x: x,
            y: y,
            parts: [
              SmartTileVisualPart(
                source: SmartTileVisualSource.frame(
                  frame: SmartTileFrameRef(
                    atlasId: 'native-atlas',
                    column: matrix[y][x],
                    row: 0,
                  ),
                ),
              ),
            ],
          ),
    ],
  ).toJson();
  raw['construction'] = _construction;
  return ProjectSmartTilePattern.fromJson(raw);
}

SmartTilePatternApplication _paint(
  SmartTilePatternSelection selection, {
  int phaseY = 0,
}) => applySmartTilePatternGesture(
  SmartTileLayer(
    id: 'bridge-layer',
    name: 'Bridge',
    presetId: 'bridge-preset',
    usage: SmartTileUsage.path,
    materialPalette: const [''],
    field: SmartTileField.cell(semanticCells: List.filled(400, 0)),
  ),
  pattern: _bridge(),
  mapSize: _size,
  selection: selection,
  strokeId: 'bridge-stroke',
  phaseY: phaseY,
);

int _moduleAt(
  ProjectSmartTilePattern pattern,
  SmartTilePatternStroke stroke,
  GridPos cell,
) =>
    (smartTilePatternCellAt(
              pattern: pattern,
              stroke: stroke,
              cell: cell,
            )!.parts.single.source
            as SmartTileFrameSource)
        .frame
        .column;
