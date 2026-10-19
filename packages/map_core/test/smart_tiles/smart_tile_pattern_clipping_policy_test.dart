import 'package:map_core/map_core.dart';
import 'package:map_core/src/operations/resource_pack_native_json.dart';
import 'package:test/test.dart';

void main() {
  test('explicit rejection survives native and portable pattern codecs', () {
    final pattern = _pattern();
    expect(pattern.toJson()['clippingPolicy'], 'reject');
    expect(ProjectSmartTilePattern.fromJson(pattern.toJson()), pattern);
    expect(
      () => validateResourcePackNativeJson(
        pattern.toJson(),
        'ProjectSmartTilePattern',
      ),
      returnsNormally,
    );
  });

  test(
    'ordinary default clipping remains omitted and clips the anchored envelope',
    () {
      final pattern = _pattern(reject: false);
      expect(pattern.toJson().containsKey('clippingPolicy'), isFalse);
      expect(_paint(pattern, const GridPos(x: 0, y: 0)).affectedCells.toSet(), {
        const GridPos(x: 0, y: 0),
        const GridPos(x: 1, y: 0),
      });
    },
  );

  for (final point in [
    const GridPos(x: 0, y: 1),
    const GridPos(x: 3, y: 1),
    const GridPos(x: 1, y: 0),
    const GridPos(x: 1, y: 4),
  ]) {
    test('whole sparse envelope refuses boundary $point before mutation', () {
      final layer = _layer();
      expect(
        () => _paint(_pattern(), point, layer: layer),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'smart_tile.pattern.stamp_out_of_bounds',
          ),
        ),
      );
      expect(layer.patternStrokes, isEmpty);
    });
  }

  test('anchored envelope fits exactly despite sparse visual holes', () {
    final application = _paint(_pattern(), const GridPos(x: 2, y: 3));
    expect(application.affectedCells.toSet(), {
      for (var y = 2; y < 4; y++)
        for (var x = 1; x < 4; x++) GridPos(x: x, y: y),
    });
  });

  test(
    'erasure preserves existing phase and never revalidates full ownership',
    () {
      final application = applySmartTilePatternGesture(
        _layer(),
        pattern: _pattern(),
        mapSize: _size,
        selection: const SmartTilePatternSelection.stamp(
          anchor: GridPos(x: 2, y: 3),
        ),
        strokeId: 'shape',
        phaseX: 2,
        phaseY: 1,
      );
      final before = application.layer.patternStrokes.single;
      final erased = eraseSmartTilePatternCells(
        application.layer,
        mapSize: _size,
        cells: [before.cells.first],
      );
      expect(erased.patternStrokes.single.phaseX, before.phaseX);
      expect(erased.patternStrokes.single.phaseY, before.phaseY);
      expect(erased.patternStrokes.single.cells, hasLength(5));
    },
  );

  for (final selection in [
    const SmartTilePatternSelection.line(
      start: GridPos(x: 3, y: 3),
      end: GridPos(x: 0, y: 0),
    ),
    const SmartTilePatternSelection.rectangle(
      start: GridPos(x: 3, y: 3),
      end: GridPos(x: 0, y: 0),
    ),
  ]) {
    test('fixed stamp refuses unsupported reversed ${selection.kind.name}', () {
      expect(
        () => applySmartTilePatternGesture(
          _layer(),
          pattern: _pattern(),
          mapSize: _size,
          selection: selection,
          strokeId: 'shape',
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'smart_tile.pattern.stamp_only',
          ),
        ),
      );
    });
  }

  test('rejects unknown policy and a rejection policy under catalog7', () {
    final raw = _pattern().toJson()..['clippingPolicy'] = 'unknown';
    expect(() => ProjectSmartTilePattern.fromJson(raw), throwsA(anything));
    final catalog = ProjectSmartTileCatalog(patterns: [_pattern()]).toJson()
      ..['formatVersion'] = 7;
    expect(
      () => ProjectSmartTileCatalog.fromJson(catalog),
      throwsA(isA<FormatException>()),
    );
  });
}

const _size = GridSize(width: 4, height: 4);

SmartTileLayer _layer() => SmartTileLayer(
  id: 'layer',
  name: 'Layer',
  presetId: 'preset',
  usage: SmartTileUsage.path,
  materialPalette: const [''],
  field: SmartTileField.cell(semanticCells: List.filled(16, 0)),
);

ProjectSmartTilePattern _pattern({bool reject = true}) {
  final raw = const ProjectSmartTilePattern(
    id: 'sparse',
    name: 'Sparse native stamp',
    usage: SmartTileUsage.path,
    width: 3,
    height: 2,
    anchorX: 1,
    anchorY: 1,
    repeatMode: SmartTilePatternRepeatMode.stamp,
    cells: [
      SmartTilePatternCell(
        x: 1,
        y: 0,
        parts: [
          SmartTileVisualPart(
            source: SmartTileVisualSource.frame(
              frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
            ),
          ),
        ],
      ),
    ],
  ).toJson();
  if (reject) raw['clippingPolicy'] = 'reject';
  return ProjectSmartTilePattern.fromJson(raw);
}

SmartTilePatternApplication _paint(
  ProjectSmartTilePattern pattern,
  GridPos anchor, {
  SmartTileLayer? layer,
}) => applySmartTilePatternGesture(
  layer ?? _layer(),
  pattern: pattern,
  mapSize: _size,
  selection: SmartTilePatternSelection.stamp(anchor: anchor),
  strokeId: 'shape',
);
