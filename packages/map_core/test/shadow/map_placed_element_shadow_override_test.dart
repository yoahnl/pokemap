import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapPlacedElementShadowOverride', () {
    test('defaults to inherit', () {
      final override = MapPlacedElementShadowOverride();

      expect(override.mode, ShadowOverrideMode.inherit);
      expect(override.shadowProfileId, isNull);
      expect(override.offsetX, isNull);
      expect(override.offsetY, isNull);
      expect(override.scaleX, isNull);
      expect(override.scaleY, isNull);
      expect(override.opacity, isNull);
    });

    test('accepts disabled override', () {
      final override = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.disabled,
      );

      expect(override.mode, ShadowOverrideMode.disabled);
    });

    test('accepts custom override with profile id', () {
      final override = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        shadowProfileId: 'tree_short',
      );

      expect(override.mode, ShadowOverrideMode.custom);
      expect(override.shadowProfileId, 'tree_short');
    });

    test('accepts custom numeric overrides without profile id', () {
      final override = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        offsetX: 2,
        offsetY: 8,
        scaleX: 0.8,
        scaleY: 0.35,
        opacity: 0.25,
      );

      expect(override.shadowProfileId, isNull);
      expect(override.offsetX, 2);
      expect(override.offsetY, 8);
      expect(override.scaleX, 0.8);
      expect(override.scaleY, 0.35);
      expect(override.opacity, 0.25);
    });

    test('accepts custom override with family', () {
      final override = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        family: StaticShadowFamily.tallProp,
      );

      expect(override.family, StaticShadowFamily.tallProp);
    });

    test('accepts opacity bounds on custom override', () {
      expect(
        MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          opacity: 0,
        ).opacity,
        0,
      );
      expect(
        MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          opacity: 1,
        ).opacity,
        1,
      );
    });

    test('rejects blank profile ids when provided', () {
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          shadowProfileId: '',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          shadowProfileId: '   ',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects inherit with any override fields', () {
      expect(
        () => MapPlacedElementShadowOverride(shadowProfileId: 'tree_short'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(offsetX: 2),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(opacity: 0.25),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(
          family: StaticShadowFamily.building,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects disabled with any override fields', () {
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
          shadowProfileId: 'tree_short',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
          offsetX: 2,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
          opacity: 0.25,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
          family: StaticShadowFamily.building,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-finite offsets', () {
      for (final value in <double>[double.nan, double.infinity]) {
        expect(
          () => MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetX: value,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetY: value,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects invalid scale overrides', () {
      for (final value in <double>[0, -1, double.nan, double.infinity]) {
        expect(
          () => MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            scaleX: value,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            scaleY: value,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects invalid opacity overrides', () {
      for (final value in <double>[-0.1, 1.1, double.nan, double.infinity]) {
        expect(
          () => MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            opacity: value,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('uses value equality', () {
      final a = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        shadowProfileId: 'tree_short',
        offsetX: 2,
        offsetY: 8,
        scaleX: 0.8,
        scaleY: 0.35,
        opacity: 0.25,
      );
      final b = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        shadowProfileId: 'tree_short',
        offsetX: 2,
        offsetY: 8,
        scaleX: 0.8,
        scaleY: 0.35,
        opacity: 0.25,
      );
      final c = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.disabled,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('value equality includes family', () {
      final base = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        family: StaticShadowFamily.building,
      );
      final same = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        family: StaticShadowFamily.building,
      );
      final different = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        family: StaticShadowFamily.compactProp,
      );

      expect(base, same);
      expect(base.hashCode, same.hashCode);
      expect(base, isNot(different));
    });
  });
}
