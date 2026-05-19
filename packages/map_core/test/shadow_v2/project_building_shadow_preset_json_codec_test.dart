import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectBuildingShadowPreset JSON codec', () {
    test('encodes canonical preset JSON without categoryId', () {
      final preset = _preset(colorHexRgb: 'abcdef');

      expect(
        encodeProjectBuildingShadowPreset(preset),
        <String, Object?>{
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
            'colorHexRgb': 'ABCDEF',
          },
          'timeOfDayMode': 'fixed',
          'sortOrder': 0,
        },
      );
    });

    test('encodes categoryId when non-null and always emits sortOrder', () {
      final preset = _preset(categoryId: 'buildings', sortOrder: 10);

      expect(
        encodeProjectBuildingShadowPreset(preset),
        <String, Object?>{
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
          'categoryId': 'buildings',
          'sortOrder': 10,
        },
      );
    });

    test('decodes canonical preset JSON with defaults for omitted optionals',
        () {
      final preset = decodeProjectBuildingShadowPreset(
        _canonicalJson(includeSortOrder: false),
      );

      expect(preset.id, 'short-west-building-shadow');
      expect(preset.name, 'Short west building shadow');
      expect(preset.direction, ProjectedShadowDirection(x: -0.55, y: 0.35));
      expect(
        preset.shape,
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
      );
      expect(
        preset.appearance,
        ProjectedShadowAppearance(opacity: 0.18, colorHexRgb: '000000'),
      );
      expect(preset.timeOfDayMode, ProjectedShadowTimeOfDayMode.fixed);
      expect(preset.categoryId, isNull);
      expect(preset.sortOrder, 0);
    });

    test('decodes categoryId null as null', () {
      final json = _canonicalJson(categoryId: null)..['categoryId'] = null;

      final preset = decodeProjectBuildingShadowPreset(json);

      expect(preset.categoryId, isNull);
    });

    test('round-trips preset instances through canonical JSON', () {
      final preset = _preset(categoryId: 'buildings', sortOrder: 10);

      expect(
        decodeProjectBuildingShadowPreset(
          encodeProjectBuildingShadowPreset(preset),
        ),
        preset,
      );
    });

    test('round-trips JSON without re-emitting unknown keys', () {
      final json = _canonicalJson(
        categoryId: 'buildings',
        sortOrder: 10,
      )
        ..['futureField'] = 'ignored'
        ..['direction'] = <String, Object?>{
          'x': -0.55,
          'y': 0.35,
          'futureDirectionField': 'ignored',
        }
        ..['shape'] = <String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
          'futureShapeField': 'ignored',
        }
        ..['appearance'] = <String, Object?>{
          'opacity': 0.18,
          'colorHexRgb': 'abcdef',
          'futureAppearanceField': 'ignored',
        };

      final encoded = encodeProjectBuildingShadowPreset(
        decodeProjectBuildingShadowPreset(json),
      );

      expect(
        encoded,
        _canonicalJson(
          categoryId: 'buildings',
          sortOrder: 10,
          colorHexRgb: 'ABCDEF',
        ),
      );
    });

    test('rejects null and non-map preset JSON', () {
      expect(
        () => decodeProjectBuildingShadowPreset(null),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset('preset'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects missing required fields', () {
      for (final field in <String>{
        'id',
        'name',
        'direction',
        'shape',
        'appearance',
        'timeOfDayMode',
      }) {
        final json = _canonicalJson()..remove(field);

        expect(
          () => decodeProjectBuildingShadowPreset(json),
          throwsA(isA<ValidationException>()),
          reason: 'missing $field should be rejected',
        );
      }
    });

    test('rejects invalid field types', () {
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['id'] = 123,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['name'] = 123,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['direction'] = 'west',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['shape'] = 'wide',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['appearance'] = 'soft',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['timeOfDayMode'] = 0,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['categoryId'] = 123,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['sortOrder'] = 1.5,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid values delegated to model and atomic codecs', () {
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['id'] = '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['name'] = '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['direction'] = <String, Object?>{'x': 0, 'y': 0},
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()
            ..['shape'] = <String, Object?>{
              'lengthRatio': -0.01,
              'nearWidthRatio': 0.85,
              'farWidthRatio': 0.75,
            },
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()
            ..['appearance'] = <String, Object?>{
              'opacity': 1.01,
              'colorHexRgb': '000000',
            },
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectBuildingShadowPreset(
          _canonicalJson()..['timeOfDayMode'] = 'moonlight',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

ProjectBuildingShadowPreset _preset({
  String? categoryId,
  int sortOrder = 0,
  String colorHexRgb = '000000',
}) {
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
      colorHexRgb: colorHexRgb,
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

Map<String, Object?> _canonicalJson({
  Object? categoryId = _absent,
  int sortOrder = 0,
  bool includeSortOrder = true,
  String colorHexRgb = '000000',
}) {
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
      'colorHexRgb': colorHexRgb,
    },
    'timeOfDayMode': 'fixed',
    if (categoryId != _absent) 'categoryId': categoryId,
    if (includeSortOrder) 'sortOrder': sortOrder,
  };
}

const Object _absent = Object();
