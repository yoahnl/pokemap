import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

EnvironmentPaletteItem _paletteItem(String id, {int weight = 1}) {
  return EnvironmentPaletteItem(elementId: id, weight: weight);
}

EnvironmentGenerationParams _params({
  double density = 0.5,
  double variation = 0.5,
  double edgeDensity = 0.5,
  int minSpacingCells = 1,
}) {
  return EnvironmentGenerationParams(
    density: density,
    variation: variation,
    edgeDensity: edgeDensity,
    minSpacingCells: minSpacingCells,
  );
}

EnvironmentPreset _preset({
  String id = 'selbrume_dense_forest',
  String name = 'Forêt dense',
  String templateId = 'forest_dense',
  List<EnvironmentPaletteItem>? palette,
  EnvironmentGenerationParams? defaultParams,
  String? categoryId,
  int sortOrder = 0,
}) {
  return EnvironmentPreset(
    id: id,
    name: name,
    templateId: templateId,
    palette: palette ?? [_paletteItem('oak_tree_large', weight: 5)],
    defaultParams: defaultParams ?? _params(),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

Map<String, dynamic> _presetJson({
  Object? categoryId,
  String collisionMode = 'forceEnabled',
  List<String>? tags,
}) {
  return <String, dynamic>{
    'id': 'selbrume_dense_forest',
    'name': 'Forêt dense de Selbrume',
    'templateId': 'forest_dense',
    'palette': <Map<String, dynamic>>[
      <String, dynamic>{
        'elementId': 'oak_tree_large',
        'weight': 5,
        'collisionMode': collisionMode,
        'tags': tags ?? <String>['tree', 'canopy'],
      },
    ],
    'defaultParams': <String, dynamic>{
      'density': 0.75,
      'variation': 0.45,
      'edgeDensity': 0.8,
      'minSpacingCells': 1,
    },
    'sortOrder': 0,
    if (categoryId != null) 'categoryId': categoryId,
  };
}

void main() {
  group('EnvironmentPreset JSON codec', () {
    test('decode preset complet', () {
      final j = _presetJson();
      final p = decodeEnvironmentPreset(j);
      expect(p.id, 'selbrume_dense_forest');
      expect(p.name, 'Forêt dense de Selbrume');
      expect(p.templateId, 'forest_dense');
      expect(p.palette.length, 1);
      expect(p.palette.single.elementId, 'oak_tree_large');
      expect(p.palette.single.weight, 5);
      expect(p.palette.single.collisionMode,
          EnvironmentCollisionMode.forceEnabled);
      expect(p.palette.single.tags, containsAll(<String>['tree', 'canopy']));
      expect(p.defaultParams.density, 0.75);
      expect(p.sortOrder, 0);
      expect(p.categoryId, isNull);
    });

    test('encode preset complet', () {
      final p = _preset();
      final m = encodeEnvironmentPreset(p);
      expect(m['id'], 'selbrume_dense_forest');
      expect(m['templateId'], 'forest_dense');
      expect(m['palette'], isA<List>());
      expect(m['defaultParams'], isA<Map>());
      expect(m['sortOrder'], 0);
      expect(m.containsKey('categoryId'), isFalse);
    });

    test('roundtrip preset complet', () {
      final original = _preset(
        categoryId: 'biomes',
        sortOrder: 42,
      );
      final back = decodeEnvironmentPreset(encodeEnvironmentPreset(original));
      expect(back, equals(original));
    });

    test('decode categoryId absent/null => null', () {
      final j = _presetJson(categoryId: null);
      j.remove('categoryId');
      expect(decodeEnvironmentPreset(j).categoryId, isNull);

      final j2 = _presetJson();
      j2['categoryId'] = null;
      expect(decodeEnvironmentPreset(j2).categoryId, isNull);
    });

    test('decode collisionMode absent/null => useElementDefault', () {
      final j = _presetJson();
      final pal = (j['palette'] as List).single as Map<String, dynamic>;
      pal.remove('collisionMode');
      expect(
        decodeEnvironmentPreset(j).palette.single.collisionMode,
        EnvironmentCollisionMode.useElementDefault,
      );

      final j2 = _presetJson();
      final pal2 = (j2['palette'] as List).single as Map<String, dynamic>;
      pal2['collisionMode'] = null;
      expect(
        decodeEnvironmentPreset(j2).palette.single.collisionMode,
        EnvironmentCollisionMode.useElementDefault,
      );
    });

    test('decode collisionMode inconnu => FormatException', () {
      final j = _presetJson(collisionMode: 'nope');
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode tags absent/null => set vide', () {
      final j = _presetJson();
      final pal = (j['palette'] as List).single as Map<String, dynamic>;
      pal.remove('tags');
      expect(decodeEnvironmentPreset(j).palette.single.tags, isEmpty);

      final j2 = _presetJson();
      final pal2 = (j2['palette'] as List).single as Map<String, dynamic>;
      pal2['tags'] = null;
      expect(decodeEnvironmentPreset(j2).palette.single.tags, isEmpty);
    });

    test('decode tag non-string => FormatException', () {
      final j = _presetJson();
      final pal = (j['palette'] as List).single as Map<String, dynamic>;
      pal['tags'] = <Object?>[1];
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode tag vide/whitespace => FormatException', () {
      final j = _presetJson(tags: <String>['  ']);
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode weight double => FormatException', () {
      final j = _presetJson();
      final pal = (j['palette'] as List).single as Map<String, dynamic>;
      pal['weight'] = 1.5;
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode sortOrder double => FormatException', () {
      final j = _presetJson();
      j['sortOrder'] = 0.0;
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode minSpacingCells double => FormatException', () {
      final j = _presetJson();
      final dp = j['defaultParams'] as Map<String, dynamic>;
      dp['minSpacingCells'] = 1.0;
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode density hors [0,1] => FormatException', () {
      final j = _presetJson();
      final dp = j['defaultParams'] as Map<String, dynamic>;
      dp['density'] = 1.5;
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode palette vide => FormatException via modèle', () {
      final j = _presetJson();
      j['palette'] = <Map<String, dynamic>>[];
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode duplicate palette elementId => FormatException via modèle',
        () {
      final j = _presetJson();
      j['palette'] = <Map<String, dynamic>>[
        <String, dynamic>{
          'elementId': 'same',
          'weight': 1,
        },
        <String, dynamic>{
          'elementId': 'same',
          'weight': 2,
        },
      ];
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('json non-map preset => FormatException', () {
      expect(() => decodeEnvironmentPreset(1), throwsFormatException);
    });

    test('decodeEnvironmentPresets duplicate preset ids => FormatException',
        () {
      final list = <Map<String, dynamic>>[
        encodeEnvironmentPreset(_preset(id: 'dup')),
        encodeEnvironmentPreset(_preset(id: 'dup', name: 'Autre')),
      ];
      expect(() => decodeEnvironmentPresets(list), throwsFormatException);
    });
  });

  group('decodeEnvironmentGenerationParamsJson', () {
    test('accepte int pour densités', () {
      final p = decodeEnvironmentGenerationParamsJson(<String, dynamic>{
        'density': 1,
        'variation': 0,
        'edgeDensity': 1,
        'minSpacingCells': 2,
      });
      expect(p.density, 1.0);
      expect(p.minSpacingCells, 2);
    });
  });
}
