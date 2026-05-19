import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ShadowV2 manifest and element persistence integration', () {
    test(
      'ProjectManifest without projectedBuildingShadowCatalog decodes an empty '
      'catalog and omits the root on toJson',
      () {
        final manifest = ProjectManifest.fromJson(_manifestJson());

        expect(manifest.projectedBuildingShadowCatalog.isEmpty, isTrue);

        final json = _wireJson(manifest.toJson());
        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
        expect(_elementJsonAt(json, 0),
            isNot(contains('projectedBuildingShadow')));
      },
    );

    test(
      'ProjectManifest with projectedBuildingShadowCatalog null decodes empty '
      'and omits the root on toJson',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(projectedBuildingShadowCatalog: null),
        );

        expect(manifest.projectedBuildingShadowCatalog.isEmpty, isTrue);

        final json = _wireJson(manifest.toJson());
        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
      },
    );

    test(
      'ProjectManifest rejects an object projectedBuildingShadowCatalog without '
      'presets',
      () {
        expect(
          () => ProjectManifest.fromJson(
            _manifestJson(
              projectedBuildingShadowCatalog: <String, Object?>{},
            ),
          ),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test(
      'ProjectManifest with empty projectedBuildingShadowCatalog presets decodes '
      'empty and omits the root on toJson',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(
            projectedBuildingShadowCatalog: <String, Object?>{
              'presets': <Object?>[],
            },
          ),
        );

        expect(manifest.projectedBuildingShadowCatalog.isEmpty, isTrue);

        final json = _wireJson(manifest.toJson());
        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
      },
    );

    test(
      'ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips '
      'and emits the root',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(projectedBuildingShadowCatalog: _catalogJson()),
        );

        expect(manifest.projectedBuildingShadowCatalog.length, 2);
        expect(
          manifest.projectedBuildingShadowCatalog
              .presetById('short-west-building-shadow')
              ?.appearance
              .colorHexRgb,
          '000000',
        );

        final json = _wireJson(manifest.toJson());
        expect(json['projectedBuildingShadowCatalog'], _catalogJson());

        final roundTripped = ProjectManifest.fromJson(json);
        expect(
          roundTripped.projectedBuildingShadowCatalog,
          manifest.projectedBuildingShadowCatalog,
        );
      },
    );

    test(
      'ProjectElementEntry without projectedBuildingShadow decodes null and '
      'omits the field on toJson',
      () {
        final element = ProjectElementEntry.fromJson(_elementJson());

        expect(element.projectedBuildingShadow, isNull);
        expect(element.toJson(), isNot(contains('projectedBuildingShadow')));
      },
    );

    test(
      'ProjectElementEntry with projectedBuildingShadow null decodes null and '
      'omits the field on toJson',
      () {
        final element = ProjectElementEntry.fromJson(
          _elementJson(projectedBuildingShadow: null),
        );

        expect(element.projectedBuildingShadow, isNull);
        expect(element.toJson(), isNot(contains('projectedBuildingShadow')));
      },
    );

    test(
      'ProjectElementEntry with projectedBuildingShadow round-trips and emits '
      'the field',
      () {
        final element = ProjectElementEntry.fromJson(
          _elementJson(projectedBuildingShadow: _projectedShadowConfigJson()),
        );

        expect(element.projectedBuildingShadow, _projectedShadowConfig());

        final json = _wireJson(element.toJson());
        expect(json['projectedBuildingShadow'], _projectedShadowConfigJson());

        final roundTripped = ProjectElementEntry.fromJson(json);
        expect(roundTripped.projectedBuildingShadow,
            element.projectedBuildingShadow);
      },
    );

    test(
      'ProjectElementEntry preserves V1 shadow and V2 projectedBuildingShadow '
      'together',
      () {
        final element = ProjectElementEntry.fromJson(
          _elementJson(
            shadow: _v1ShadowJson(),
            projectedBuildingShadow: _projectedShadowConfigJson(enabled: false),
          ),
        );

        expect(element.shadow?.castsShadow, isTrue);
        expect(element.shadow?.shadowProfileId, 'default-ground-wide-ellipse');
        expect(
          element.projectedBuildingShadow,
          _projectedShadowConfig(enabled: false),
        );

        final json = _wireJson(element.toJson());
        expect(json['shadow'], _v1ShadowJson());
        expect(
          json['projectedBuildingShadow'],
          _projectedShadowConfigJson(enabled: false),
        );
      },
    );

    test(
      'existing V1-only manifest round-trip stays free of projected building '
      'shadow output',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(
            shadowCatalog: _v1ShadowCatalogJson(),
            elements: <Object?>[
              _elementJson(id: 'house', shadow: _v1ShadowJson()),
              _elementJson(id: 'crate'),
            ],
          ),
        );

        final json = _wireJson(manifest.toJson());
        final elements =
            (json['elements'] as List<Object?>).cast<Map<String, Object?>>();

        expect(json['shadowCatalog'], _v1ShadowCatalogJson());
        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
        expect(elements[0], isNot(contains('projectedBuildingShadow')));
        expect(elements[1], isNot(contains('projectedBuildingShadow')));
      },
    );

    test('copyWith can replace manifest catalog and element config', () {
      final manifest = ProjectManifest.fromJson(_manifestJson());
      final catalog = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[_shortWestPreset()],
      );

      final updatedManifest = manifest.copyWith(
        projectedBuildingShadowCatalog: catalog,
      );

      expect(updatedManifest.projectedBuildingShadowCatalog, catalog);
      expect(manifest.projectedBuildingShadowCatalog.isEmpty, isTrue);

      final element = ProjectElementEntry.fromJson(_elementJson());
      final config = _projectedShadowConfig();
      final updatedElement = element.copyWith(projectedBuildingShadow: config);

      expect(updatedElement.projectedBuildingShadow, config);
      expect(element.projectedBuildingShadow, isNull);
    });
  });
}

Map<String, Object?> _manifestJson({
  Object? projectedBuildingShadowCatalog = _absent,
  Object? shadowCatalog = _absent,
  List<Object?>? elements,
}) {
  return <String, Object?>{
    'name': 'Project',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    if (!identical(shadowCatalog, _absent)) 'shadowCatalog': shadowCatalog,
    if (!identical(projectedBuildingShadowCatalog, _absent))
      'projectedBuildingShadowCatalog': projectedBuildingShadowCatalog,
    'elements': elements ?? <Object?>[_elementJson()],
  };
}

Map<String, Object?> _elementJson({
  String id = 'house',
  Object? shadow = _absent,
  Object? projectedBuildingShadow = _absent,
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
    if (!identical(projectedBuildingShadow, _absent))
      'projectedBuildingShadow': projectedBuildingShadow,
  };
}

Map<String, Object?> _catalogJson() {
  return <String, Object?>{
    'presets': <Object?>[
      _shortWestPresetJson(),
      _longEastPresetJson(),
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

Map<String, Object?> _longEastPresetJson() {
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
      'colorHexRgb': '000000',
    },
    'timeOfDayMode': 'followsSun',
    'categoryId': 'buildings',
    'sortOrder': 10,
  };
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

Map<String, Object?> _projectedShadowConfigJson({
  bool enabled = true,
}) {
  return <String, Object?>{
    'enabled': enabled,
    'presetId': 'short-west-building-shadow',
    'anchor': <String, Object?>{
      'xRatio': 0.5,
      'yRatio': 0.98,
    },
    'localOffset': <String, Object?>{
      'x': 0,
      'y': 0,
    },
  };
}

ProjectElementProjectedBuildingShadowConfig _projectedShadowConfig({
  bool enabled = true,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: 'short-west-building-shadow',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

Map<String, Object?> _v1ShadowJson() {
  return <String, Object?>{
    'castsShadow': true,
    'shadowProfileId': 'default-ground-wide-ellipse',
  };
}

Map<String, Object?> _v1ShadowCatalogJson() {
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

Map<String, Object?> _wireJson(Map<String, dynamic> json) {
  return (jsonDecode(jsonEncode(json)) as Map<String, dynamic>)
      .cast<String, Object?>();
}

Map<String, Object?> _elementJsonAt(Map<String, Object?> json, int index) {
  return (json['elements'] as List<Object?>)
      .cast<Map<String, Object?>>()[index];
}

const _absent = Object();
