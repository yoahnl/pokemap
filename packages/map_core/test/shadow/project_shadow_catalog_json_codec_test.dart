import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectShadowProfile _profile(String id) {
  return ProjectShadowProfile(
    id: id,
    name: 'Shadow $id',
    mode: ShadowCasterMode.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    offsetX: id == 'tree' ? 4 : 0,
    offsetY: id == 'tree' ? 12 : 0,
    scaleX: id == 'tree' ? 1.2 : 1,
    scaleY: id == 'tree' ? 0.45 : 1,
    opacity: id == 'tree' ? 0.35 : 0.5,
    colorHexRgb: id == 'tree' ? '000000' : '0A0B0C',
  );
}

Map<String, Object?> _profileJson(String id) {
  if (id == 'tree') {
    return <String, Object?>{
      'id': 'tree',
      'name': 'Shadow tree',
      'mode': 'ellipse',
      'renderPass': 'groundStatic',
      'offsetX': 4.0,
      'offsetY': 12.0,
      'scaleX': 1.2,
      'scaleY': 0.45,
      'opacity': 0.35,
      'colorHexRgb': '000000',
      'softnessMode': 'hardEdge',
    };
  }
  return <String, Object?>{
    'id': id,
    'name': 'Shadow $id',
    'mode': 'ellipse',
    'renderPass': 'groundStatic',
    'offsetX': 0.0,
    'offsetY': 0.0,
    'scaleX': 1.0,
    'scaleY': 1.0,
    'opacity': 0.5,
    'colorHexRgb': '0A0B0C',
    'softnessMode': 'hardEdge',
  };
}

Map<String, Object?> _catalogJson() {
  return <String, Object?>{
    'profiles': <Object?>[
      _profileJson('tree'),
      _profileJson('rock'),
    ],
  };
}

void main() {
  group('ProjectShadowCatalog JSON codec', () {
    test('encodes an empty catalog canonically', () {
      expect(
        encodeProjectShadowCatalog(ProjectShadowCatalog()),
        <String, Object?>{'profiles': <Object?>[]},
      );
    });

    test('decodes null, empty object, and empty profiles as empty catalog', () {
      expect(decodeProjectShadowCatalog(null).isEmpty, isTrue);
      expect(decodeProjectShadowCatalog(<String, Object?>{}).isEmpty, isTrue);
      expect(
        decodeProjectShadowCatalog(<String, Object?>{
          'profiles': <Object?>[],
        }).isEmpty,
        isTrue,
      );
    });

    test('encodes a complete catalog preserving order', () {
      final catalog = ProjectShadowCatalog(
        profiles: [_profile('tree'), _profile('rock')],
      );

      final encoded = encodeProjectShadowCatalog(catalog);
      final profiles = encoded['profiles']! as List<Object?>;

      expect(encoded, _catalogJson());
      expect(
        profiles.map((item) => (item! as Map<String, Object?>)['id']),
        ['tree', 'rock'],
      );
    });

    test('decodes a complete catalog preserving order', () {
      final catalog = decodeProjectShadowCatalog(_catalogJson());

      expect(catalog.profiles.map((profile) => profile.id), ['tree', 'rock']);
      expect(catalog,
          ProjectShadowCatalog(profiles: [_profile('tree'), _profile('rock')]));
    });

    test('roundtrips encode then decode without changing value', () {
      final catalog = ProjectShadowCatalog(
        profiles: [_profile('tree'), _profile('rock')],
      );

      expect(
        decodeProjectShadowCatalog(encodeProjectShadowCatalog(catalog)),
        catalog,
      );
    });

    test('roundtrips decode then encode into canonical JSON', () {
      final json = <String, Object?>{
        'profiles': <Object?>[
          <String, Object?>{
            'id': 'actor_contact',
            'name': 'Actor contact shadow',
            'mode': 'contactBlob',
            'renderPass': 'actorContact',
            'unknownFutureField': true,
          },
        ],
        'ignoredTopLevel': true,
      };

      expect(
        encodeProjectShadowCatalog(decodeProjectShadowCatalog(json)),
        <String, Object?>{
          'profiles': <Object?>[
            <String, Object?>{
              'id': 'actor_contact',
              'name': 'Actor contact shadow',
              'mode': 'contactBlob',
              'renderPass': 'actorContact',
              'offsetX': 0.0,
              'offsetY': 0.0,
              'scaleX': 1.0,
              'scaleY': 1.0,
              'opacity': 0.35,
              'colorHexRgb': '000000',
              'softnessMode': 'hardEdge',
            },
          ],
        },
      );
    });

    test('profileById works after decode', () {
      final catalog = decodeProjectShadowCatalog(<String, Object?>{
        'profiles': <Object?>[
          <String, Object?>{
            'id': 'actor_contact',
            'name': 'Actor contact shadow',
            'mode': 'contactBlob',
            'renderPass': 'actorContact',
          },
        ],
      });

      expect(catalog.profileById('actor_contact'), isNotNull);
      expect(catalog.profileById('ACTOR_CONTACT'), isNull);
    });

    test('keeps lookup case-sensitive after decode', () {
      final catalog = decodeProjectShadowCatalog(<String, Object?>{
        'profiles': <Object?>[
          <String, Object?>{
            'id': 'tree',
            'name': 'Tree',
            'mode': 'ellipse',
            'renderPass': 'groundStatic',
          },
          <String, Object?>{
            'id': 'TREE',
            'name': 'Upper Tree',
            'mode': 'ellipse',
            'renderPass': 'groundStatic',
          },
        ],
      });

      expect(catalog.profileById('tree')?.name, 'Tree');
      expect(catalog.profileById('TREE')?.name, 'Upper Tree');
      expect(
        decodeProjectShadowCatalog(<String, Object?>{
          'profiles': <Object?>[
            <String, Object?>{
              'id': 'tree',
              'name': 'Tree',
              'mode': 'ellipse',
              'renderPass': 'groundStatic',
            },
          ],
        }).profileById('TREE'),
        isNull,
      );
    });

    test('rejects invalid profiles collection shapes', () {
      expect(
        () => decodeProjectShadowCatalog(<String, Object?>{'profiles': 'nope'}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectShadowCatalog(<String, Object?>{
          'profiles': <Object?>['nope'],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duplicate ids', () {
      expect(
        () => decodeProjectShadowCatalog(<String, Object?>{
          'profiles': <Object?>[
            <String, Object?>{
              'id': 'tree',
              'name': 'Tree',
              'mode': 'ellipse',
              'renderPass': 'groundStatic',
            },
            <String, Object?>{
              'id': 'tree',
              'name': 'Tree again',
              'mode': 'ellipse',
              'renderPass': 'groundStatic',
            },
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid profile items', () {
      expect(
        () => decodeProjectShadowCatalog(<String, Object?>{
          'profiles': <Object?>[
            <String, Object?>{
              'id': 'tree',
              'name': 'Tree',
              'mode': 'projectedQuad',
              'renderPass': 'groundStatic',
            },
          ],
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
