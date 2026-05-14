import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapPlacedElementShadowOverride JSON codec', () {
    test('encodes inherit, disabled, and custom canonically', () {
      expect(
        encodeMapPlacedElementShadowOverride(MapPlacedElementShadowOverride()),
        <String, Object?>{'mode': 'inherit'},
      );
      expect(
        encodeMapPlacedElementShadowOverride(
          MapPlacedElementShadowOverride(mode: ShadowOverrideMode.disabled),
        ),
        <String, Object?>{'mode': 'disabled'},
      );
      expect(
        encodeMapPlacedElementShadowOverride(_customOverride()),
        <String, Object?>{
          'mode': 'custom',
          'shadowProfileId': 'tree_short',
          'offsetX': 2.0,
          'offsetY': 8.0,
          'scaleX': 0.8,
          'scaleY': 0.35,
          'opacity': 0.25,
        },
      );
    });

    test('decodes inherit, disabled, and custom', () {
      expect(
        decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'inherit',
        }),
        MapPlacedElementShadowOverride(),
      );
      expect(
        decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'disabled',
        }),
        MapPlacedElementShadowOverride(mode: ShadowOverrideMode.disabled),
      );
      expect(
        decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'shadowProfileId': 'tree_short',
          'offsetX': 2,
          'offsetY': 8,
          'scaleX': 0.8,
          'scaleY': 0.35,
          'opacity': 0.25,
        }),
        _customOverride(),
      );
    });

    test('roundtrips encode/decode and canonicalizes unknown fields', () {
      final custom = _customOverride();
      expect(
        decodeMapPlacedElementShadowOverride(
          encodeMapPlacedElementShadowOverride(custom),
        ),
        custom,
      );

      final decoded = decodeMapPlacedElementShadowOverride(
        <String, Object?>{
          'mode': 'custom',
          'shadowProfileId': 'tree_short',
          'offsetX': 2,
          'unknown': true,
        },
      );

      expect(
        encodeMapPlacedElementShadowOverride(decoded!),
        <String, Object?>{
          'mode': 'custom',
          'shadowProfileId': 'tree_short',
          'offsetX': 2.0,
        },
      );
    });

    test('decodes null and empty objects as inherit/null contract', () {
      expect(decodeMapPlacedElementShadowOverride(null), isNull);
      expect(
        decodeMapPlacedElementShadowOverride(<String, Object?>{}),
        MapPlacedElementShadowOverride(),
      );
      expect(
        decodeMapPlacedElementShadowOverride(<String, Object?>{
          'shadowProfileId': null,
        }),
        MapPlacedElementShadowOverride(),
      );
    });

    test('rejects invalid root, mode, and field types', () {
      expect(
        () => decodeMapPlacedElementShadowOverride('override'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 1,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'deleteTheSun',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'shadowProfileId': 123,
        }),
        throwsA(isA<ValidationException>()),
      );
      for (final key in <String>[
        'offsetX',
        'offsetY',
        'scaleX',
        'scaleY',
        'opacity',
      ]) {
        expect(
          () => decodeMapPlacedElementShadowOverride(<String, Object?>{
            'mode': 'custom',
            key: '1',
          }),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects invalid decoded values', () {
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'inherit',
          'offsetX': 2,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'disabled',
          'shadowProfileId': 'tree_short',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'shadowProfileId': '',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'scaleX': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'scaleY': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeMapPlacedElementShadowOverride(<String, Object?>{
          'mode': 'custom',
          'opacity': 2,
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

MapPlacedElementShadowOverride _customOverride() {
  return MapPlacedElementShadowOverride(
    mode: ShadowOverrideMode.custom,
    shadowProfileId: 'tree_short',
    offsetX: 2,
    offsetY: 8,
    scaleX: 0.8,
    scaleY: 0.35,
    opacity: 0.25,
  );
}
