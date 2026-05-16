import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectElementShadowConfig', () {
    test('defaults to not casting a shadow', () {
      final config = ProjectElementShadowConfig();

      expect(config.castsShadow, isFalse);
      expect(config.shadowProfileId, isNull);
      expect(config.offsetX, isNull);
      expect(config.offsetY, isNull);
      expect(config.scaleX, isNull);
      expect(config.scaleY, isNull);
      expect(config.opacity, isNull);
    });

    test('keeps a profile id when castsShadow is false', () {
      final config = ProjectElementShadowConfig(
        shadowProfileId: 'tree_large',
      );

      expect(config.castsShadow, isFalse);
      expect(config.shadowProfileId, 'tree_large');
    });

    test('accepts castsShadow true with a profile id', () {
      final config = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
      );

      expect(config.castsShadow, isTrue);
      expect(config.shadowProfileId, 'tree_large');
    });

    test('accepts valid numeric overrides', () {
      final config = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        offsetX: 4,
        offsetY: 12,
        scaleX: 1.2,
        scaleY: 0.45,
        opacity: 0.35,
      );

      expect(config.offsetX, 4);
      expect(config.offsetY, 12);
      expect(config.scaleX, 1.2);
      expect(config.scaleY, 0.45);
      expect(config.opacity, 0.35);
    });

    test('castsShadow false can carry family', () {
      final config = ProjectElementShadowConfig(
        family: StaticShadowFamily.compactProp,
      );

      expect(config.castsShadow, isFalse);
      expect(config.family, StaticShadowFamily.compactProp);
    });

    test('accepts opacity bounds', () {
      expect(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'hidden',
          opacity: 0,
        ).opacity,
        0,
      );
      expect(
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'opaque',
          opacity: 1,
        ).opacity,
        1,
      );
    });

    test('rejects blank profile ids when provided', () {
      expect(
        () => ProjectElementShadowConfig(shadowProfileId: ''),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectElementShadowConfig(shadowProfileId: '   '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects castsShadow true without a profile id', () {
      expect(
        () => ProjectElementShadowConfig(castsShadow: true),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: '',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-finite offsets', () {
      expect(
        () => ProjectElementShadowConfig(offsetX: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectElementShadowConfig(offsetX: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectElementShadowConfig(offsetY: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectElementShadowConfig(offsetY: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid scale overrides', () {
      for (final value in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => ProjectElementShadowConfig(scaleX: value),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => ProjectElementShadowConfig(scaleY: value),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects invalid opacity overrides', () {
      for (final value in <double>[
        -0.1,
        1.1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => ProjectElementShadowConfig(opacity: value),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('uses value equality', () {
      final a = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        offsetX: 4,
        offsetY: 12,
        scaleX: 1.2,
        scaleY: 0.45,
        opacity: 0.35,
      );
      final b = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        offsetX: 4,
        offsetY: 12,
        scaleX: 1.2,
        scaleY: 0.45,
        opacity: 0.35,
      );
      final c = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'rock_small',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('value equality includes family', () {
      final base = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        family: StaticShadowFamily.building,
      );
      final same = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        family: StaticShadowFamily.building,
      );
      final different = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        family: StaticShadowFamily.tallProp,
      );

      expect(base, same);
      expect(base.hashCode, same.hashCode);
      expect(base, isNot(different));
    });
  });
}
