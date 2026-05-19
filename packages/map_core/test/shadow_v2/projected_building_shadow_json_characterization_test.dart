import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ShadowV2 projected building shadow JSON characterization', () {
    test(
      'ProjectManifest JSON without projected building shadow fields '
      'round-trips unchanged for known Shadow V1 data',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(
            shadowCatalog: _shadowCatalogJson(),
            elements: <Object?>[
              _elementJson(id: 'house_01', shadow: _buildingShadowJson()),
              _elementJson(id: 'crate_01'),
            ],
          ),
        );

        final json = _wireJson(manifest.toJson());
        final house =
            (json['elements'] as List<Object?>).cast<Map<String, Object?>>()[0];
        final crate =
            (json['elements'] as List<Object?>).cast<Map<String, Object?>>()[1];

        expect(json['shadowCatalog'], _shadowCatalogJson());
        expect(house['shadow'], _buildingShadowJson());
        expect(crate, containsPair('shadow', null));
        _expectNoV2Keys(json);
        _expectNoV2Keys(house);
        _expectNoV2Keys(crate);
      },
    );

    test(
      'ProjectElementEntry JSON without projected building shadow keeps no V2 '
      'keys after round-trip',
      () {
        final element = ProjectElementEntry.fromJson(
          _elementJson(shadow: _buildingShadowJson()),
        );

        final json = _wireJson(element.toJson());

        expect(json['shadow'], _buildingShadowJson());
        _expectNoV2Keys(json);
      },
    );

    test(
      'ProjectShadowCatalog JSON remains V1-only and does not emit V2 '
      'projected building presets',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(shadowCatalog: _shadowCatalogJson()),
        );

        final catalogJson = _wireJson(manifest.toJson())['shadowCatalog']
            as Map<String, Object?>;

        expect(catalogJson, _shadowCatalogJson());
        _expectNoV2Keys(catalogJson);
      },
    );

    test(
      'unknown root future catalog keys are accepted by ProjectManifest.fromJson '
      'and dropped by toJson',
      () {
        final raw = _manifestJson(
          shadowCatalog: _shadowCatalogJson(),
          extraRoot: <String, Object?>{
            'buildingShadowPresets': <Object?>[],
            'projectedBuildingShadowPresets': <Object?>[],
          },
        );

        final manifest = ProjectManifest.fromJson(raw);
        final json = _wireJson(manifest.toJson());

        expect(raw, contains('buildingShadowPresets'));
        expect(raw, contains('projectedBuildingShadowPresets'));
        expect(json, isNot(contains('buildingShadowPresets')));
        expect(json, isNot(contains('projectedBuildingShadowPresets')));
        expect(json['shadowCatalog'], _shadowCatalogJson());
      },
    );

    test(
      'unknown element future projected shadow key is accepted and dropped by '
      'ProjectElementEntry.toJson',
      () {
        final raw = _elementJson(
          shadow: _buildingShadowJson(),
          extra: <String, Object?>{
            'projectedShadow': <String, Object?>{
              'enabled': true,
              'presetId': 'short-west-building-shadow',
            },
          },
        );

        final element = ProjectElementEntry.fromJson(raw);
        final json = _wireJson(element.toJson());

        expect(raw, contains('projectedShadow'));
        expect(json, isNot(contains('projectedShadow')));
        expect(json['shadow'], _buildingShadowJson());
      },
    );

    test(
      'migrateProjectManifestJson currently preserves V2-like unknown keys by '
      'identity',
      () {
        final raw = _manifestJson(
          elements: <Object?>[
            _elementJson(
              extra: <String, Object?>{
                'projectedBuildingShadow': <String, Object?>{
                  'enabled': true,
                  'presetId': 'short-west-building-shadow',
                },
              },
            ),
          ],
          extraRoot: <String, Object?>{
            'buildingShadowPresets': <Object?>[],
            'projectedBuildingShadowCatalog': <String, Object?>{
              'presets': <Object?>[],
            },
          },
        );

        final migrated = migrateProjectManifestJson(raw);
        final elements = migrated['elements'] as List<Object?>;
        final element = elements.single! as Map<String, Object?>;

        expect(identical(migrated, raw), isTrue);
        expect(migrated, contains('buildingShadowPresets'));
        expect(migrated, contains('projectedBuildingShadowCatalog'));
        expect(element, contains('projectedBuildingShadow'));
      },
    );

    test(
      'Selbrume-like synthetic V1 shadow sample round-trips without V2 keys',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(
            shadowCatalog: _shadowCatalogJson(),
            elements: <Object?>[
              _elementJson(
                  id: 'selbrum_maison_test', shadow: _buildingShadowJson()),
              _elementJson(id: 'decor_without_shadow'),
              _elementJson(id: 'decor_shadow_null', shadow: null),
            ],
          ),
        );

        final json = _wireJson(manifest.toJson());
        final elements =
            (json['elements'] as List<Object?>).cast<Map<String, Object?>>();

        expect(elements[0]['shadow'], _buildingShadowJson());
        expect(elements[1], containsPair('shadow', null));
        expect(elements[2], containsPair('shadow', null));
        _expectNoV2Keys(json);
        for (final element in elements) {
          _expectNoV2Keys(element);
        }
      },
    );
  });
}

Map<String, Object?> _manifestJson({
  Object? shadowCatalog = _absent,
  List<Object?>? elements,
  Map<String, Object?> extraRoot = const <String, Object?>{},
}) {
  return <String, Object?>{
    'name': 'Project',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    if (!identical(shadowCatalog, _absent)) 'shadowCatalog': shadowCatalog,
    if (elements != null) 'elements': elements,
    ...extraRoot,
  };
}

Map<String, Object?> _elementJson({
  String id = 'house_01',
  Object? shadow = _absent,
  Map<String, Object?> extra = const <String, Object?>{},
}) {
  return <String, Object?>{
    'id': id,
    'name': id,
    'tilesetId': 'tileset',
    'categoryId': 'building',
    'frames': <Object?>[
      <String, Object?>{
        'source': <String, Object?>{'x': 0, 'y': 0},
      },
    ],
    if (!identical(shadow, _absent)) 'shadow': shadow,
    ...extra,
  };
}

Map<String, Object?> _shadowCatalogJson() {
  return <String, Object?>{
    'profiles': <Object?>[
      <String, Object?>{
        'id': 'default-ground-wide-ellipse',
        'name': 'Default ground wide ellipse',
        'mode': 'ellipse',
        'renderPass': 'groundStatic',
        'offsetX': 0.0,
        'offsetY': 0.0,
        'scaleX': 1.0,
        'scaleY': 1.0,
        'opacity': 0.18,
        'colorHexRgb': '000000',
        'softnessMode': 'hardEdge',
      },
    ],
  };
}

Map<String, Object?> _buildingShadowJson() {
  return <String, Object?>{
    'castsShadow': true,
    'shadowProfileId': 'default-ground-wide-ellipse',
    'family': 'building',
    'footprint': <String, Object?>{
      'anchorXRatio': 0.5,
      'anchorYRatio': 1.0,
      'footprintWidthRatio': 0.75,
      'footprintHeightRatio': 0.25,
    },
  };
}

Map<String, Object?> _wireJson(Map<String, dynamic> json) {
  return (jsonDecode(jsonEncode(json)) as Map<String, dynamic>)
      .cast<String, Object?>();
}

void _expectNoV2Keys(Map<String, Object?> json) {
  for (final key in _v2Keys) {
    expect(json, isNot(contains(key)), reason: 'unexpected V2 key: $key');
  }
}

const _absent = Object();

const _v2Keys = <String>{
  'buildingShadowPresets',
  'projectedBuildingShadow',
  'projectedShadow',
  'buildingProjectedShadow',
  'projectedBuildingShadowCatalog',
  'projectedBuildingShadowPresets',
};
