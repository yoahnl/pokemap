import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectBuildingShadowPresetCatalog JSON codec', () {
    test('encodes an empty catalog canonically', () {
      expect(
        encodeProjectBuildingShadowPresetCatalog(
          ProjectBuildingShadowPresetCatalog(),
        ),
        <String, Object?>{'presets': <Object?>[]},
      );
    });

    test('decodes an empty catalog', () {
      final catalog = decodeProjectBuildingShadowPresetCatalog(
        <String, Object?>{'presets': <Object?>[]},
      );

      expect(catalog.isEmpty, isTrue);
      expect(catalog.length, 0);
      expect(catalog.presetById('missing'), isNull);
    });

    test('encodes multiple presets preserving order', () {
      final catalog = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[
          _shortWestPreset(),
          _longEastPreset(),
        ],
      );

      expect(encodeProjectBuildingShadowPresetCatalog(catalog), _catalogJson());
    });

    test('decodes multiple presets preserving order and lookup behavior', () {
      final catalog = decodeProjectBuildingShadowPresetCatalog(_catalogJson());

      expect(
        catalog.presets.map((preset) => preset.id),
        <String>[
          'short-west-building-shadow',
          'long-east-building-shadow',
        ],
      );
      expect(
        catalog.presetById('short-west-building-shadow')?.timeOfDayMode,
        ProjectedShadowTimeOfDayMode.fixed,
      );
      expect(
        catalog.presetById('long-east-building-shadow')?.timeOfDayMode,
        ProjectedShadowTimeOfDayMode.followsSun,
      );
      expect(catalog.containsPresetId('missing'), isFalse);
    });

    test('round-trips catalog instances through canonical JSON', () {
      final catalog = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[
          _shortWestPreset(),
          _longEastPreset(),
        ],
      );

      expect(
        decodeProjectBuildingShadowPresetCatalog(
          encodeProjectBuildingShadowPresetCatalog(catalog),
        ),
        catalog,
      );
    });

    test('round-trips JSON without re-emitting unknown keys', () {
      final json = _catalogJson()
        ..['futureCatalogField'] = true
        ..['presets'] = <Object?>[
          _shortWestPresetJson()
            ..['futurePresetField'] = 'ignored'
            ..['direction'] = <String, Object?>{
              'x': -0.55,
              'y': 0.35,
              'futureDirectionField': 'ignored',
            },
          _longEastPresetJson()
            ..['appearance'] = <String, Object?>{
              'opacity': 0.16,
              'colorHexRgb': 'abcdef',
              'futureAppearanceField': 'ignored',
            },
        ];

      expect(
        encodeProjectBuildingShadowPresetCatalog(
          decodeProjectBuildingShadowPresetCatalog(json),
        ),
        _catalogJson(secondColorHexRgb: 'ABCDEF'),
      );
    });

    test('rejects invalid catalog shape', () {
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(null),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPresetCatalog('catalog'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{
          'presets': null,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{
          'presets': 'short-west',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid preset items', () {
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{
          'presets': <Object?>['preset'],
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{
          'presets': <Object?>[
            _shortWestPresetJson()..remove('id'),
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{
          'presets': <Object?>[
            _shortWestPresetJson()
              ..['direction'] = <String, Object?>{'x': 0, 'y': 0},
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duplicate preset ids through the catalog model', () {
      expect(
        () => decodeProjectBuildingShadowPresetCatalog(<String, Object?>{
          'presets': <Object?>[
            _shortWestPresetJson(),
            _shortWestPresetJson()..['name'] = 'Short west copy',
          ],
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

ProjectBuildingShadowPreset _shortWestPreset() {
  return ProjectBuildingShadowPreset(
    id: 'short-west-building-shadow',
    name: 'Short west building shadow',
    direction: ProjectedShadowDirection(x: -0.55, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.28,
      nearWidthRatio: 0.85,
      farWidthRatio: 0.75,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.18,
      colorHexRgb: '000000',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectBuildingShadowPreset _longEastPreset() {
  return ProjectBuildingShadowPreset(
    id: 'long-east-building-shadow',
    name: 'Long east building shadow',
    direction: ProjectedShadowDirection(x: 0.65, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.42,
      nearWidthRatio: 0.9,
      farWidthRatio: 0.7,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.16,
      colorHexRgb: '000000',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun,
    categoryId: 'buildings',
    sortOrder: 10,
  );
}

Map<String, Object?> _catalogJson({
  String secondColorHexRgb = '000000',
}) {
  return <String, Object?>{
    'presets': <Object?>[
      _shortWestPresetJson(),
      _longEastPresetJson(colorHexRgb: secondColorHexRgb),
    ],
  };
}

Map<String, Object?> _shortWestPresetJson() {
  return <String, Object?>{
    'id': 'short-west-building-shadow',
    'name': 'Short west building shadow',
    'direction': <String, Object?>{'x': -0.55, 'y': 0.35},
    'shape': <String, Object?>{
      'lengthRatio': 0.28,
      'nearWidthRatio': 0.85,
      'farWidthRatio': 0.75,
    },
    'appearance': <String, Object?>{
      'opacity': 0.18,
      'colorHexRgb': '000000',
    },
    'timeOfDayMode': 'fixed',
    'sortOrder': 0,
  };
}

Map<String, Object?> _longEastPresetJson({
  String colorHexRgb = '000000',
}) {
  return <String, Object?>{
    'id': 'long-east-building-shadow',
    'name': 'Long east building shadow',
    'direction': <String, Object?>{'x': 0.65, 'y': 0.35},
    'shape': <String, Object?>{
      'lengthRatio': 0.42,
      'nearWidthRatio': 0.9,
      'farWidthRatio': 0.7,
    },
    'appearance': <String, Object?>{
      'opacity': 0.16,
      'colorHexRgb': colorHexRgb,
    },
    'timeOfDayMode': 'followsSun',
    'categoryId': 'buildings',
    'sortOrder': 10,
  };
}
