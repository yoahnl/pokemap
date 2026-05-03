import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('EnvironmentPaletteItem', () {
    test('accepts valid item', () {
      final item = EnvironmentPaletteItem(
        elementId: 'tree_oak',
        weight: 3,
        collisionMode: EnvironmentCollisionMode.forceEnabled,
        tags: {'canopy'},
      );
      expect(item.elementId, 'tree_oak');
      expect(item.weight, 3);
      expect(item.collisionMode, EnvironmentCollisionMode.forceEnabled);
      expect(item.tags, {'canopy'});
    });

    test('trims elementId', () {
      final item = EnvironmentPaletteItem(
        elementId: '  elm  ',
        weight: 1,
      );
      expect(item.elementId, 'elm');
    });

    test('rejects empty elementId', () {
      expect(
        () => EnvironmentPaletteItem(elementId: '', weight: 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects whitespace elementId', () {
      expect(
        () => EnvironmentPaletteItem(elementId: '   ', weight: 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects weight <= 0', () {
      expect(
        () => EnvironmentPaletteItem(elementId: 'a', weight: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EnvironmentPaletteItem(elementId: 'a', weight: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('defaults collisionMode to useElementDefault', () {
      final item = EnvironmentPaletteItem(elementId: 'x', weight: 2);
      expect(item.collisionMode, EnvironmentCollisionMode.useElementDefault);
    });

    test('copies tags defensively', () {
      final backing = <String>{'a'};
      final item = EnvironmentPaletteItem(
        elementId: 'x',
        weight: 1,
        tags: backing,
      );
      backing.add('b');
      expect(item.tags, {'a'});
    });

    test('tags are immutable', () {
      final item = EnvironmentPaletteItem(
        elementId: 'x',
        weight: 1,
        tags: {'t'},
      );
      expect(
        () => item.tags.add('nope'),
        throwsUnsupportedError,
      );
    });

    test('rejects empty tag', () {
      expect(
        () => EnvironmentPaletteItem(
          elementId: 'x',
          weight: 1,
          tags: {'ok', ''},
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EnvironmentPaletteItem(
          elementId: 'x',
          weight: 1,
          tags: {'  '},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('value equality', () {
      final a = EnvironmentPaletteItem(
        elementId: 'x',
        weight: 2,
        tags: {'a', 'b'},
      );
      final b = EnvironmentPaletteItem(
        elementId: 'x',
        weight: 2,
        tags: {'b', 'a'},
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('EnvironmentGenerationParams', () {
    test('accepts valid params', () {
      final p = EnvironmentGenerationParams(
        density: 0.0,
        variation: 1.0,
        edgeDensity: 0.75,
        minSpacingCells: 3,
      );
      expect(p.density, 0.0);
      expect(p.variation, 1.0);
      expect(p.edgeDensity, 0.75);
      expect(p.minSpacingCells, 3);
    });

    test('rejects density out of range', () {
      expect(
        () => EnvironmentGenerationParams(
          density: -0.01,
          variation: 0.5,
          edgeDensity: 0.5,
          minSpacingCells: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EnvironmentGenerationParams(
          density: 1.01,
          variation: 0.5,
          edgeDensity: 0.5,
          minSpacingCells: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects variation out of range', () {
      expect(
        () => EnvironmentGenerationParams(
          density: 0.5,
          variation: -1,
          edgeDensity: 0.5,
          minSpacingCells: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects edgeDensity out of range', () {
      expect(
        () => EnvironmentGenerationParams(
          density: 0.5,
          variation: 0.5,
          edgeDensity: 2,
          minSpacingCells: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative minSpacingCells', () {
      expect(
        () => EnvironmentGenerationParams(
          density: 0.5,
          variation: 0.5,
          edgeDensity: 0.5,
          minSpacingCells: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('standard factory', () {
      final s = EnvironmentGenerationParams.standard();
      expect(s.density, 0.5);
      expect(s.variation, 0.5);
      expect(s.edgeDensity, 0.5);
      expect(s.minSpacingCells, 0);
    });

    test('value equality', () {
      final a = EnvironmentGenerationParams.standard();
      final b = EnvironmentGenerationParams(
        density: 0.5,
        variation: 0.5,
        edgeDensity: 0.5,
        minSpacingCells: 0,
      );
      expect(a, equals(b));
    });
  });

  group('EnvironmentAreaMask', () {
    EnvironmentAreaMask makeMask() => EnvironmentAreaMask(
          width: 2,
          height: 2,
          cells: const [true, false, false, true],
        );

    test('accepts valid mask', () {
      final m = makeMask();
      expect(m.width, 2);
      expect(m.height, 2);
      expect(m.cells, [true, false, false, true]);
    });

    test('rejects width <= 0', () {
      expect(
        () => EnvironmentAreaMask(width: 0, height: 1, cells: const [false]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects height <= 0', () {
      expect(
        () => EnvironmentAreaMask(width: 1, height: 0, cells: const [false]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects wrong cells length', () {
      expect(
        () => EnvironmentAreaMask(
          width: 2,
          height: 2,
          cells: const [true],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('cells copied defensively', () {
      final raw = [true, false, false, false];
      final m = EnvironmentAreaMask(width: 2, height: 2, cells: raw);
      raw[0] = false;
      expect(m.cells[0], isTrue);
    });

    test('cells list is unmodifiable', () {
      final m = EnvironmentAreaMask(
        width: 1,
        height: 1,
        cells: const [false],
      );
      expect(
        () => m.cells.add(true),
        throwsUnsupportedError,
      );
    });

    test('hasAnyActiveCell', () {
      expect(
        EnvironmentAreaMask(
          width: 2,
          height: 1,
          cells: const [false, false],
        ).hasAnyActiveCell,
        isFalse,
      );
      expect(
        EnvironmentAreaMask(
          width: 2,
          height: 1,
          cells: const [true, false],
        ).hasAnyActiveCell,
        isTrue,
      );
    });

    test('activeCellCount', () {
      final m = EnvironmentAreaMask(
        width: 2,
        height: 2,
        cells: const [true, true, false, false],
      );
      expect(m.activeCellCount, 2);
    });

    test('contains', () {
      final m = EnvironmentAreaMask(
        width: 3,
        height: 2,
        cells: List<bool>.filled(6, false),
      );
      expect(m.contains(0, 0), isTrue);
      expect(m.contains(2, 1), isTrue);
      expect(m.contains(-1, 0), isFalse);
      expect(m.contains(0, 2), isFalse);
      expect(m.contains(3, 0), isFalse);
    });

    test('isActiveAt returns false out of bounds without throwing', () {
      final m = EnvironmentAreaMask(
        width: 2,
        height: 2,
        cells: const [true, false, false, false],
      );
      expect(m.isActiveAt(-1, 0), isFalse);
      expect(m.isActiveAt(0, 5), isFalse);
      expect(m.isActiveAt(0, 0), isTrue);
      expect(m.isActiveAt(1, 0), isFalse);
      expect(m.isActiveAt(1, 1), isFalse);
    });

    test('equality order-sensitive on cells', () {
      final a = EnvironmentAreaMask(
        width: 2,
        height: 1,
        cells: const [true, false],
      );
      final b = EnvironmentAreaMask(
        width: 2,
        height: 1,
        cells: const [false, true],
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('EnvironmentArea', () {
    EnvironmentAreaMask empty4() => EnvironmentAreaMask(
          width: 2,
          height: 2,
          cells: List<bool>.filled(4, false),
        );

    test('accepts valid area', () {
      final area = EnvironmentArea(
        id: 'a1',
        name: 'Zone nord',
        presetId: 'preset_forest',
        mask: empty4(),
        seed: 42,
      );
      expect(area.id, 'a1');
      expect(area.name, 'Zone nord');
      expect(area.presetId, 'preset_forest');
      expect(area.seed, 42);
      expect(area.generatedPlacementIds, isEmpty);
    });

    test('rejects empty id', () {
      expect(
        () => EnvironmentArea(
          id: '',
          name: 'n',
          presetId: 'p',
          mask: empty4(),
          seed: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty name', () {
      expect(
        () => EnvironmentArea(
          id: 'i',
          name: '  ',
          presetId: 'p',
          mask: empty4(),
          seed: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty presetId', () {
      expect(
        () => EnvironmentArea(
          id: 'i',
          name: 'n',
          presetId: '',
          mask: empty4(),
          seed: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts negative seed', () {
      final area = EnvironmentArea(
        id: 'x',
        name: 'n',
        presetId: 'p',
        mask: empty4(),
        seed: -999,
      );
      expect(area.seed, -999);
    });

    test('paramsOverride null and non-null', () {
      final nullParams = EnvironmentArea(
        id: 'x',
        name: 'n',
        presetId: 'p',
        mask: empty4(),
        seed: 0,
        paramsOverride: null,
      );
      expect(nullParams.paramsOverride, isNull);

      final params = EnvironmentGenerationParams.standard();
      final withParams = EnvironmentArea(
        id: 'x',
        name: 'n',
        presetId: 'p',
        mask: empty4(),
        seed: 0,
        paramsOverride: params,
      );
      expect(withParams.paramsOverride, params);
    });

    test('generatedPlacementIds defensive copy and immutable', () {
      final list = <String>['p1'];
      final area = EnvironmentArea(
        id: 'x',
        name: 'n',
        presetId: 'p',
        mask: empty4(),
        seed: 0,
        generatedPlacementIds: list,
      );
      list.add('p2');
      expect(area.generatedPlacementIds, ['p1']);
      expect(
        () => area.generatedPlacementIds.add('x'),
        throwsUnsupportedError,
      );
    });

    test('rejects empty placement id', () {
      expect(
        () => EnvironmentArea(
          id: 'x',
          name: 'n',
          presetId: 'p',
          mask: empty4(),
          seed: 0,
          generatedPlacementIds: ['ok', ''],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects duplicate placement ids', () {
      expect(
        () => EnvironmentArea(
          id: 'x',
          name: 'n',
          presetId: 'p',
          mask: empty4(),
          seed: 0,
          generatedPlacementIds: ['a', 'a'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('hasGeneratedPlacements', () {
      final empty = EnvironmentArea(
        id: 'x',
        name: 'n',
        presetId: 'p',
        mask: empty4(),
        seed: 0,
      );
      expect(empty.hasGeneratedPlacements, isFalse);

      final filled = EnvironmentArea(
        id: 'x',
        name: 'n',
        presetId: 'p',
        mask: empty4(),
        seed: 0,
        generatedPlacementIds: ['id1'],
      );
      expect(filled.hasGeneratedPlacements, isTrue);
    });

    test('value equality', () {
      final m = empty4();
      final p = EnvironmentGenerationParams.standard();
      final a = EnvironmentArea(
        id: 'a',
        name: 'n',
        presetId: 'pr',
        mask: m,
        seed: 7,
        paramsOverride: p,
        generatedPlacementIds: ['g1'],
      );
      final b = EnvironmentArea(
        id: 'a',
        name: 'n',
        presetId: 'pr',
        mask: EnvironmentAreaMask(
          width: 2,
          height: 2,
          cells: List<bool>.filled(4, false),
        ),
        seed: 7,
        paramsOverride: EnvironmentGenerationParams.standard(),
        generatedPlacementIds: ['g1'],
      );
      expect(a, equals(b));
    });
  });

  group('EnvironmentPreset', () {
    EnvironmentPaletteItem item(String id) => EnvironmentPaletteItem(
          elementId: id,
          weight: 1,
        );

    EnvironmentGenerationParams params() =>
        EnvironmentGenerationParams.standard();

    test('accepts valid preset', () {
      final preset = EnvironmentPreset(
        id: 'pre1',
        name: 'Ma forêt',
        templateId: 'forest_dense',
        palette: [item('t1'), item('t2')],
        defaultParams: params(),
        sortOrder: 10,
      );
      expect(preset.id, 'pre1');
      expect(preset.templateId, 'forest_dense');
      expect(preset.palette.length, 2);
      expect(preset.categoryId, isNull);
    });

    test('rejects empty id name templateId', () {
      expect(
        () => EnvironmentPreset(
          id: '',
          name: 'n',
          templateId: 't',
          palette: [item('a')],
          defaultParams: params(),
          sortOrder: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EnvironmentPreset(
          id: 'i',
          name: '',
          templateId: 't',
          palette: [item('a')],
          defaultParams: params(),
          sortOrder: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EnvironmentPreset(
          id: 'i',
          name: 'n',
          templateId: ' ',
          palette: [item('a')],
          defaultParams: params(),
          sortOrder: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty palette', () {
      expect(
        () => EnvironmentPreset(
          id: 'i',
          name: 'n',
          templateId: 't',
          palette: [],
          defaultParams: params(),
          sortOrder: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('palette defensive copy and immutable', () {
      final list = [item('a')];
      final preset = EnvironmentPreset(
        id: 'p',
        name: 'n',
        templateId: 'forest_dense',
        palette: list,
        defaultParams: params(),
        sortOrder: 0,
      );
      list.add(item('b'));
      expect(preset.palette.length, 1);
      expect(
        () => preset.palette.add(item('c')),
        throwsUnsupportedError,
      );
    });

    test('rejects duplicate elementId in palette', () {
      final dup = item('same');
      expect(
        () => EnvironmentPreset(
          id: 'p',
          name: 'n',
          templateId: 't',
          palette: [dup, EnvironmentPaletteItem(elementId: 'same', weight: 2)],
          defaultParams: params(),
          sortOrder: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('categoryId null ok', () {
      final preset = EnvironmentPreset(
        id: 'p',
        name: 'n',
        templateId: 't',
        palette: [item('e')],
        defaultParams: params(),
        sortOrder: -5,
      );
      expect(preset.categoryId, isNull);
      expect(preset.sortOrder, -5);
    });

    test('categoryId whitespace rejected', () {
      expect(
        () => EnvironmentPreset(
          id: 'p',
          name: 'n',
          templateId: 't',
          palette: [item('e')],
          defaultParams: params(),
          categoryId: '   ',
          sortOrder: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('value equality', () {
      final pr = EnvironmentPreset(
        id: 'p',
        name: 'n',
        templateId: 'forest_dense',
        palette: [item('e')],
        defaultParams: params(),
        categoryId: 'cat',
        sortOrder: 3,
      );
      final pr2 = EnvironmentPreset(
        id: 'p',
        name: 'n',
        templateId: 'forest_dense',
        palette: [EnvironmentPaletteItem(elementId: 'e', weight: 1)],
        defaultParams: EnvironmentGenerationParams.standard(),
        categoryId: 'cat',
        sortOrder: 3,
      );
      expect(pr, equals(pr2));
    });
  });

  group('public export map_core', () {
    test('types reachable from package:map_core/map_core.dart', () {
      expect(EnvironmentCollisionMode.forceDisabled, isNotNull);
      expect(EnvironmentPaletteItem(elementId: 'x', weight: 1), isNotNull);
      expect(EnvironmentGenerationParams.standard(), isNotNull);
      expect(
        EnvironmentAreaMask(width: 1, height: 1, cells: const [false]),
        isNotNull,
      );
      expect(
        EnvironmentArea(
          id: 'i',
          name: 'n',
          presetId: 'p',
          mask: EnvironmentAreaMask(
            width: 1,
            height: 1,
            cells: const [false],
          ),
          seed: 0,
        ),
        isNotNull,
      );
      expect(
        EnvironmentPreset(
          id: 'p',
          name: 'n',
          templateId: 't',
          palette: [
            EnvironmentPaletteItem(elementId: 'e', weight: 1),
          ],
          defaultParams: EnvironmentGenerationParams.standard(),
          sortOrder: 0,
        ),
        isNotNull,
      );
    });
  });
}
