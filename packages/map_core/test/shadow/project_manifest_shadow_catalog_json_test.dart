import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest.shadowCatalog JSON', () {
    test('decodes legacy manifest JSON without shadowCatalog as empty', () {
      final manifest = ProjectManifest.fromJson(_manifestJson());

      expect(manifest.shadowCatalog, ProjectShadowCatalog());
      expect(manifest.shadowCatalog.isEmpty, isTrue);
    });

    test('decodes null, empty object, and empty profiles as empty', () {
      for (final shadowCatalog in <Object?>[
        null,
        <String, Object?>{},
        <String, Object?>{'profiles': <Object?>[]},
      ]) {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(shadowCatalog: shadowCatalog),
        );

        expect(manifest.shadowCatalog, ProjectShadowCatalog());
        expect(manifest.shadowCatalog.isEmpty, isTrue);
      }
    });

    test('decodes a complete shadow catalog', () {
      final manifest = ProjectManifest.fromJson(
        _manifestJson(shadowCatalog: _catalogJson()),
      );

      final profile = manifest.shadowCatalog.profileById('tree_large');
      expect(profile, isNotNull);
      expect(profile!.mode, ShadowCasterMode.ellipse);
      expect(profile.renderPass, ShadowRenderPass.groundStatic);
      expect(profile.offsetX, 4);
      expect(profile.offsetY, 12);
      expect(profile.scaleX, 1.2);
      expect(profile.scaleY, 0.45);
      expect(profile.opacity, 0.35);
      expect(profile.colorHexRgb, '000000');
      expect(profile.softnessMode, ShadowSoftnessMode.hardEdge);
    });

    test('toJson preserves a complete shadow catalog', () {
      final manifest = _manifest(shadowCatalog: _catalog());

      expect(manifest.toJson()['shadowCatalog'], _catalogJson());
    });

    test('toJson encodes an empty shadow catalog canonically', () {
      final json = _manifest().toJson();

      expect(json['shadowCatalog'], <String, Object?>{
        'profiles': <Object?>[],
      });
    });

    test('copyWith replaces shadowCatalog', () {
      final catalog = _catalog();
      final manifest = _manifest().copyWith(shadowCatalog: catalog);

      expect(manifest.shadowCatalog, catalog);
      expect(manifest.shadowCatalog.profileById('tree_large'), isNotNull);
    });

    test('rejects invalid shadow catalogs', () {
      expect(
        () => ProjectManifest.fromJson(
          _manifestJson(shadowCatalog: 'invalid'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectManifest.fromJson(
          _manifestJson(
            shadowCatalog: <String, Object?>{'profiles': 'invalid'},
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectManifest.fromJson(
          _manifestJson(
            shadowCatalog: <String, Object?>{
              'profiles': <Object?>['invalid'],
            },
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duplicate and invalid profiles', () {
      expect(
        () => ProjectManifest.fromJson(
          _manifestJson(
            shadowCatalog: <String, Object?>{
              'profiles': <Object?>[
                _profileJson(id: 'tree_large'),
                _profileJson(id: 'tree_large'),
              ],
            },
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectManifest.fromJson(
          _manifestJson(
            shadowCatalog: <String, Object?>{
              'profiles': <Object?>[
                <String, Object?>{
                  'name': 'Missing id',
                  'mode': 'ellipse',
                  'renderPass': 'groundStatic',
                },
              ],
            },
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects unknown enums and runtimeBlur softnessMode', () {
      expect(
        () => ProjectManifest.fromJson(
          _manifestJson(
            shadowCatalog: <String, Object?>{
              'profiles': <Object?>[
                _profileJson(mode: 'projectedQuad'),
              ],
            },
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectManifest.fromJson(
          _manifestJson(
            shadowCatalog: <String, Object?>{
              'profiles': <Object?>[
                _profileJson(softnessMode: 'runtimeBlur'),
              ],
            },
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('preserves ProjectElementEntry.shadow alongside shadowCatalog', () {
      final manifest = ProjectManifest.fromJson(
        _manifestJson(
          shadowCatalog: _catalogJson(),
          elements: <Object?>[
            _elementJson(
              shadow: <String, Object?>{
                'castsShadow': true,
                'shadowProfileId': 'tree_large',
              },
            ),
          ],
        ),
      );

      expect(manifest.shadowCatalog.profileById('tree_large'), isNotNull);
      expect(manifest.elements.single.shadow!.shadowProfileId, 'tree_large');
    });

    test('roundtrips element shadow and catalog through JSON', () {
      final manifest = _manifest(
        shadowCatalog: _catalog(),
        elements: [
          _element(
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'tree_large',
            ),
          ),
        ],
      );

      final decoded = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>,
      );

      expect(decoded, manifest);
      expect(decoded.elements.single.shadow!.shadowProfileId, 'tree_large');
      expect(decoded.shadowCatalog.profileById('tree_large'), isNotNull);
    });
  });
}

Map<String, Object?> _manifestJson({
  Object? shadowCatalog = _shadowCatalogAbsent,
  List<Object?>? elements,
}) {
  return <String, Object?>{
    'name': 'Project',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    if (!identical(shadowCatalog, _shadowCatalogAbsent))
      'shadowCatalog': shadowCatalog,
    if (elements != null) 'elements': elements,
  };
}

const _shadowCatalogAbsent = Object();
const _shadowAbsent = Object();

Map<String, Object?> _catalogJson() {
  return <String, Object?>{
    'profiles': <Object?>[_profileJson()],
  };
}

Map<String, Object?> _profileJson({
  String id = 'tree_large',
  String mode = 'ellipse',
  String softnessMode = 'hardEdge',
}) {
  return <String, Object?>{
    'id': id,
    'name': 'Large tree shadow',
    'mode': mode,
    'renderPass': 'groundStatic',
    'offsetX': 4.0,
    'offsetY': 12.0,
    'scaleX': 1.2,
    'scaleY': 0.45,
    'opacity': 0.35,
    'colorHexRgb': '000000',
    'softnessMode': softnessMode,
  };
}

ProjectShadowCatalog _catalog() {
  return ProjectShadowCatalog(
    profiles: [
      ProjectShadowProfile(
        id: 'tree_large',
        name: 'Large tree shadow',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        offsetX: 4,
        offsetY: 12,
        scaleX: 1.2,
        scaleY: 0.45,
        opacity: 0.35,
      ),
    ],
  );
}

ProjectManifest _manifest({
  ProjectShadowCatalog? shadowCatalog,
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
    shadowCatalog: shadowCatalog ?? ProjectShadowCatalog(),
  );
}

ProjectElementEntry _element({ProjectElementShadowConfig? shadow}) {
  return ProjectElementEntry(
    id: 'tree',
    name: 'Tree',
    tilesetId: 'tileset',
    categoryId: 'nature',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
    shadow: shadow,
  );
}

Map<String, Object?> _elementJson({Object? shadow = _shadowAbsent}) {
  return <String, Object?>{
    'id': 'tree',
    'name': 'Tree',
    'tilesetId': 'tileset',
    'categoryId': 'nature',
    'frames': <Object?>[
      <String, Object?>{
        'source': <String, Object?>{'x': 0, 'y': 0},
      },
    ],
    if (!identical(shadow, _shadowAbsent)) 'shadow': shadow,
  };
}
