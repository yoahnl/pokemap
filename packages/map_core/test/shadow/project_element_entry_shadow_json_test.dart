import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _shadowAbsent = Object();

void main() {
  group('ProjectElementEntry shadow JSON', () {
    test('decodes legacy element JSON without shadow as null', () {
      final element = ProjectElementEntry.fromJson(_elementJson());

      expect(element.shadow, isNull);
    });

    test('decodes element JSON with null shadow as null', () {
      final element = ProjectElementEntry.fromJson(
        _elementJson(shadow: null),
      );

      expect(element.shadow, isNull);
    });

    test('decodes castsShadow false config', () {
      final element = ProjectElementEntry.fromJson(
        _elementJson(
          shadow: <String, Object?>{'castsShadow': false},
        ),
      );

      expect(element.shadow, ProjectElementShadowConfig());
    });

    test('decodes castsShadow true config with profile id', () {
      final element = ProjectElementEntry.fromJson(
        _elementJson(
          shadow: <String, Object?>{
            'castsShadow': true,
            'shadowProfileId': 'tree_large',
          },
        ),
      );

      expect(element.shadow, isNotNull);
      expect(element.shadow!.castsShadow, isTrue);
      expect(element.shadow!.shadowProfileId, 'tree_large');
    });

    test('encodes non-null shadow', () {
      final element = _element(
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          offsetX: 4,
          offsetY: 12,
          scaleX: 1.2,
          scaleY: 0.45,
          opacity: 0.35,
        ),
      );

      expect(element.toJson()['shadow'], <String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
        'offsetX': 4.0,
        'offsetY': 12.0,
        'scaleX': 1.2,
        'scaleY': 0.45,
        'opacity': 0.35,
      });
    });

    test('encodes null shadow using the existing nullable field style', () {
      final json = _element().toJson();

      expect(json, containsPair('shadow', null));
    });

    test('copyWith modifies and preserves shadow', () {
      final shadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
      );
      final updated = _element().copyWith(shadow: shadow);

      expect(updated.shadow, shadow);
      expect(updated.copyWith(name: 'Oak').shadow, shadow);
    });

    test('legacy ProjectManifest JSON decodes element shadow as null', () {
      final manifest = ProjectManifest.fromJson(<String, Object?>{
        'name': 'Project',
        'maps': <Object?>[],
        'tilesets': <Object?>[],
        'elements': <Object?>[_elementJson()],
      });

      expect(manifest.elements.single.shadow, isNull);
    });

    test('ProjectManifest JSON preserves element shadow', () {
      final manifest = ProjectManifest(
        name: 'Project',
        maps: const [],
        tilesets: const [],
        elements: [
          _element(
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'tree_large',
            ),
          ),
        ],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );

      final json = manifest.toJson();
      final elementJson =
          (json['elements'] as List<Object?>).single as Map<String, Object?>;

      expect(elementJson['shadow'], <String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
      });
    });

    test('adding shadow does not modify collision profile', () {
      const collisionProfile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        cells: <GridPos>[GridPos(x: 1, y: 2)],
      );
      final element = _element(collisionProfile: collisionProfile);
      final shadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
      );

      final updated = element.copyWith(shadow: shadow);

      expect(updated.collisionProfile, same(collisionProfile));
      expect(updated.collisionProfile, element.collisionProfile);
    });
  });
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

ProjectElementEntry _element({
  ProjectElementShadowConfig? shadow,
  ElementCollisionProfile? collisionProfile,
}) {
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
    collisionProfile: collisionProfile,
    shadow: shadow,
  );
}
