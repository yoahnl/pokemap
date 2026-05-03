import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

EnvironmentAreaMask _mask2x2() => EnvironmentAreaMask(
      width: 2,
      height: 2,
      cells: List<bool>.filled(4, false),
    );

EnvironmentArea _area(
  String id, {
  List<String>? generatedPlacementIds,
}) =>
    EnvironmentArea(
      id: id,
      name: 'n$id',
      presetId: 'p',
      mask: _mask2x2(),
      seed: 0,
      generatedPlacementIds: generatedPlacementIds,
    );

void main() {
  group('EnvironmentLayerContent construction', () {
    test('accepts empty content', () {
      final c = EnvironmentLayerContent();
      expect(c.areas, isEmpty);
      expect(c.targetTileLayerId, isNull);
    });

    test('accepts targetTileLayerId null', () {
      final c = EnvironmentLayerContent(targetTileLayerId: null);
      expect(c.targetTileLayerId, isNull);
    });

    test('trims targetTileLayerId when non-null', () {
      final c = EnvironmentLayerContent(targetTileLayerId: '  layer_a  ');
      expect(c.targetTileLayerId, 'layer_a');
    });

    test('rejects targetTileLayerId whitespace only', () {
      expect(
        () => EnvironmentLayerContent(targetTileLayerId: '   '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EnvironmentLayerContent(targetTileLayerId: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts valid areas and preserves order', () {
      final a = _area('z1');
      final b = _area('z2');
      final c = EnvironmentLayerContent(areas: [a, b]);
      expect(c.areas.length, 2);
      expect(c.areas[0].id, 'z1');
      expect(c.areas[1].id, 'z2');
    });

    test('empty factory', () {
      final c = EnvironmentLayerContent.empty(targetTileLayerId: 'L');
      expect(c.areas, isEmpty);
      expect(c.targetTileLayerId, 'L');
    });
  });

  group('EnvironmentLayerContent defensive copy and immutability', () {
    test('copies areas list defensively', () {
      final list = [_area('a')];
      final c = EnvironmentLayerContent(areas: list);
      list.add(_area('b'));
      expect(c.areas.length, 1);
    });

    test('areas is unmodifiable', () {
      final c = EnvironmentLayerContent(areas: [_area('x')]);
      expect(
        () => c.areas.add(_area('y')),
        throwsUnsupportedError,
      );
    });
  });

  group('EnvironmentLayerContent duplicate area ids', () {
    test('rejects duplicate area id', () {
      final dup = _area('same');
      expect(
        () => EnvironmentLayerContent(areas: [dup, _area('same')]),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('EnvironmentLayerContent helpers', () {
    test('hasAreas false when empty', () {
      expect(EnvironmentLayerContent().hasAreas, isFalse);
    });

    test('hasAreas true when non-empty', () {
      expect(
        EnvironmentLayerContent(areas: [_area('a')]).hasAreas,
        isTrue,
      );
    });

    test('areaCount', () {
      expect(EnvironmentLayerContent().areaCount, 0);
      expect(
        EnvironmentLayerContent(
          areas: [_area('a'), _area('b')],
        ).areaCount,
        2,
      );
    });

    test('containsArea known id', () {
      final c = EnvironmentLayerContent(areas: [_area('north')]);
      expect(c.containsArea('north'), isTrue);
    });

    test('containsArea trims argument', () {
      final c = EnvironmentLayerContent(areas: [_area('north')]);
      expect(c.containsArea('  north  '), isTrue);
    });

    test('containsArea false for unknown', () {
      expect(
        EnvironmentLayerContent(areas: [_area('a')]).containsArea('z'),
        isFalse,
      );
    });

    test('containsArea false for empty or whitespace id', () {
      final c = EnvironmentLayerContent(areas: [_area('a')]);
      expect(c.containsArea(''), isFalse);
      expect(c.containsArea('   '), isFalse);
    });

    test('areaById returns area', () {
      final area = _area('x');
      final c = EnvironmentLayerContent(areas: [area]);
      expect(c.areaById('x'), same(area));
    });

    test('areaById trims argument', () {
      final area = _area('x');
      final c = EnvironmentLayerContent(areas: [area]);
      expect(c.areaById('  x  '), same(area));
    });

    test('areaById null for unknown', () {
      expect(
        EnvironmentLayerContent(areas: [_area('a')]).areaById('z'),
        isNull,
      );
    });

    test('areaById null for empty or whitespace', () {
      final c = EnvironmentLayerContent(areas: [_area('a')]);
      expect(c.areaById(''), isNull);
      expect(c.areaById('  '), isNull);
    });
  });

  group('EnvironmentLayerContent generated placements aggregate', () {
    test('hasGeneratedPlacements false when none', () {
      final c = EnvironmentLayerContent(
        areas: [_area('a'), _area('b')],
      );
      expect(c.hasGeneratedPlacements, isFalse);
    });

    test('hasGeneratedPlacements true when any area has ids', () {
      final c = EnvironmentLayerContent(
        areas: [
          _area('a'),
          _area('b', generatedPlacementIds: ['g1']),
        ],
      );
      expect(c.hasGeneratedPlacements, isTrue);
    });

    test('generatedPlacementIds order: areas then inner order', () {
      final c = EnvironmentLayerContent(
        areas: [
          _area('a', generatedPlacementIds: ['p1', 'p2']),
          _area('b', generatedPlacementIds: ['q1']),
        ],
      );
      expect(c.generatedPlacementIds, ['p1', 'p2', 'q1']);
    });

    test('generatedPlacementIds returns unmodifiable list', () {
      final c = EnvironmentLayerContent(
        areas: [
          _area('a', generatedPlacementIds: ['g'])
        ],
      );
      final g = c.generatedPlacementIds;
      expect(() => g.add('x'), throwsUnsupportedError);
    });
  });

  group('EnvironmentLayerContent equality', () {
    test('two identical contents are equal', () {
      final a = EnvironmentLayerContent(
        targetTileLayerId: 'L1',
        areas: [_area('z')],
      );
      final b = EnvironmentLayerContent(
        targetTileLayerId: 'L1',
        areas: [_area('z')],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different targetTileLayerId not equal', () {
      final base = [_area('z')];
      expect(
        EnvironmentLayerContent(targetTileLayerId: 'A', areas: base),
        isNot(
          equals(EnvironmentLayerContent(targetTileLayerId: 'B', areas: base)),
        ),
      );
    });

    test('different areas order not equal', () {
      final x = _area('x');
      final y = _area('y');
      expect(
        EnvironmentLayerContent(areas: [x, y]),
        isNot(equals(EnvironmentLayerContent(areas: [y, x]))),
      );
    });
  });
}
