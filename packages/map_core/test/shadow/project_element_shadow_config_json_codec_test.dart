import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectElementShadowConfig JSON codec', () {
    test('encodes a complete config to canonical JSON', () {
      final config = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        offsetX: 4,
        offsetY: 12,
        scaleX: 1.2,
        scaleY: 0.45,
        opacity: 0.35,
        footprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 1,
          footprintWidthRatio: 0.75,
          footprintHeightRatio: 0.25,
        ),
      );

      expect(encodeProjectElementShadowConfig(config), <String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
        'offsetX': 4.0,
        'offsetY': 12.0,
        'scaleX': 1.2,
        'scaleY': 0.45,
        'opacity': 0.35,
        'footprint': <String, Object?>{
          'anchorXRatio': 0.5,
          'anchorYRatio': 1.0,
          'footprintWidthRatio': 0.75,
          'footprintHeightRatio': 0.25,
        },
      });
    });

    test('decodes a complete config', () {
      final config = decodeProjectElementShadowConfig(<String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
        'offsetX': 4,
        'offsetY': 12,
        'scaleX': 1.2,
        'scaleY': 0.45,
        'opacity': 0.35,
        'footprint': <String, Object?>{
          'anchorXRatio': 0.5,
          'anchorYRatio': 1,
          'footprintWidthRatio': 0.75,
          'footprintHeightRatio': 0.25,
        },
      });

      expect(
        config,
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'tree_large',
          offsetX: 4,
          offsetY: 12,
          scaleX: 1.2,
          scaleY: 0.45,
          opacity: 0.35,
          footprint: StaticShadowFootprintConfig(
            anchorXRatio: 0.5,
            anchorYRatio: 1,
            footprintWidthRatio: 0.75,
            footprintHeightRatio: 0.25,
          ),
        ),
      );
    });

    test('old JSON without footprint decodes footprint null', () {
      final config = decodeProjectElementShadowConfig(<String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
      });

      expect(config!.footprint, isNull);
    });

    test('encodes null and empty footprint by omitting footprint key', () {
      expect(
        encodeProjectElementShadowConfig(
          ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'tree_large',
          ),
        ),
        <String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
        },
      );
      expect(
        encodeProjectElementShadowConfig(
          ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'tree_large',
            footprint: StaticShadowFootprintConfig(),
          ),
        ),
        <String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
        },
      );
    });

    test('equality includes footprint', () {
      final base = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
      );
      final same = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
      );
      final different = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.4),
      );

      expect(base, same);
      expect(base.hashCode, same.hashCode);
      expect(base, isNot(different));
    });

    test('castsShadow false can carry footprint', () {
      final config = ProjectElementShadowConfig(
        footprint: StaticShadowFootprintConfig(footprintWidthRatio: 0.7),
      );

      expect(config.castsShadow, isFalse);
      expect(config.footprint!.footprintWidthRatio, 0.7);
    });

    test('roundtrips encode to decode', () {
      final config = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        offsetX: 4,
        offsetY: 12,
        scaleX: 1.2,
        scaleY: 0.45,
        opacity: 0.35,
      );

      expect(
        decodeProjectElementShadowConfig(
          encodeProjectElementShadowConfig(config),
        ),
        config,
      );
    });

    test('roundtrips decode to canonical encode', () {
      final config = decodeProjectElementShadowConfig(<String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
        'offsetX': 4,
        'offsetY': 12,
        'scaleX': 1.2,
        'scaleY': 0.45,
        'opacity': 0.35,
        'unknown': 'ignored',
      });

      expect(encodeProjectElementShadowConfig(config!), <String, Object?>{
        'castsShadow': true,
        'shadowProfileId': 'tree_large',
        'offsetX': 4.0,
        'offsetY': 12.0,
        'scaleX': 1.2,
        'scaleY': 0.45,
        'opacity': 0.35,
      });
    });

    test('decodes null as null', () {
      expect(decodeProjectElementShadowConfig(null), isNull);
    });

    test('decodes empty and minimal objects with defaults', () {
      expect(
        decodeProjectElementShadowConfig(<String, Object?>{}),
        ProjectElementShadowConfig(),
      );
      expect(
        decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': false,
        }),
        ProjectElementShadowConfig(),
      );

      final absentCastsShadow = decodeProjectElementShadowConfig(
        <String, Object?>{'shadowProfileId': 'tree_large'},
      );

      expect(absentCastsShadow!.castsShadow, isFalse);
      expect(absentCastsShadow.shadowProfileId, 'tree_large');
      expect(absentCastsShadow.offsetX, isNull);
      expect(absentCastsShadow.offsetY, isNull);
      expect(absentCastsShadow.scaleX, isNull);
      expect(absentCastsShadow.scaleY, isNull);
      expect(absentCastsShadow.opacity, isNull);
    });

    test('ignores unknown fields and does not encode them', () {
      final config = decodeProjectElementShadowConfig(<String, Object?>{
        'castsShadow': false,
        'runtimeBlur': true,
        'zOrder': 99,
      });

      expect(config, ProjectElementShadowConfig());
      expect(
        encodeProjectElementShadowConfig(config!),
        <String, Object?>{'castsShadow': false},
      );
    });

    test('rejects invalid root and field types', () {
      expect(
        () => decodeProjectElementShadowConfig('shadow'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': 'true',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'shadowProfileId': 123,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'offsetX': '4',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'offsetY': '12',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'scaleX': '1.2',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'scaleY': '0.45',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'opacity': '0.35',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'footprint': 'wide',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid decoded values', () {
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
          'shadowProfileId': '',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
          'scaleX': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
          'scaleY': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
          'opacity': 2,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementShadowConfig(<String, Object?>{
          'castsShadow': true,
          'shadowProfileId': 'tree_large',
          'footprint': <String, Object?>{
            'footprintWidthRatio': 0,
          },
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
