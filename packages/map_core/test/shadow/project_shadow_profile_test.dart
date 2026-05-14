import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectShadowProfile _profile({
  String id = 'shadow',
  String name = 'Shadow',
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double offsetX = 0,
  double offsetY = 0,
  double scaleX = 1,
  double scaleY = 1,
  double opacity = 0.35,
  String colorHexRgb = '000000',
  ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
}) {
  return ProjectShadowProfile(
    id: id,
    name: name,
    mode: mode,
    renderPass: renderPass,
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
    softnessMode: softnessMode,
  );
}

void main() {
  group('ProjectShadowProfile', () {
    test('creates a valid profile with explicit values', () {
      final profile = _profile(
        id: 'tree_large',
        name: 'Large tree shadow',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        offsetX: 4,
        offsetY: 12,
        scaleX: 1.2,
        scaleY: 0.45,
        opacity: 0.35,
        colorHexRgb: '0A0B0C',
        softnessMode: ShadowSoftnessMode.hardEdge,
      );

      expect(profile.id, 'tree_large');
      expect(profile.name, 'Large tree shadow');
      expect(profile.mode, ShadowCasterMode.ellipse);
      expect(profile.renderPass, ShadowRenderPass.groundStatic);
      expect(profile.offsetX, 4);
      expect(profile.offsetY, 12);
      expect(profile.scaleX, 1.2);
      expect(profile.scaleY, 0.45);
      expect(profile.opacity, 0.35);
      expect(profile.colorHexRgb, '0A0B0C');
      expect(profile.softnessMode, ShadowSoftnessMode.hardEdge);
    });

    test('applies V0 defaults', () {
      final profile = ProjectShadowProfile(
        id: 'actor_contact',
        name: 'Actor contact shadow',
        mode: ShadowCasterMode.contactBlob,
        renderPass: ShadowRenderPass.actorContact,
      );

      expect(profile.offsetX, 0);
      expect(profile.offsetY, 0);
      expect(profile.scaleX, 1);
      expect(profile.scaleY, 1);
      expect(profile.opacity, 0.35);
      expect(profile.colorHexRgb, '000000');
      expect(profile.softnessMode, ShadowSoftnessMode.hardEdge);
    });

    test('rejects blank id values', () {
      expect(
        () => _profile(id: ''),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(id: '   '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects blank name values', () {
      expect(
        () => _profile(name: ''),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(name: '   '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive scale values', () {
      expect(
        () => _profile(scaleX: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(scaleX: -0.1),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(scaleY: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(scaleY: -0.1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('validates opacity bounds', () {
      expect(
        () => _profile(opacity: -0.01),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(opacity: 1.01),
        throwsA(isA<ValidationException>()),
      );
      expect(_profile(opacity: 0).opacity, 0);
      expect(_profile(opacity: 1).opacity, 1);
    });

    test('rejects non-finite double values', () {
      expect(
        () => _profile(offsetX: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(offsetX: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(offsetX: double.negativeInfinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(offsetY: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(offsetY: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(offsetY: double.negativeInfinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(scaleX: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(scaleX: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(scaleX: double.negativeInfinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(scaleY: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(scaleY: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(scaleY: double.negativeInfinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(opacity: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(opacity: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(opacity: double.negativeInfinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('validates colorHexRgb', () {
      expect(
        () => _profile(colorHexRgb: '#000000'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(colorHexRgb: '00000'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(colorHexRgb: '0000000'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(colorHexRgb: 'GGGGGG'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _profile(colorHexRgb: ''),
        throwsA(isA<ValidationException>()),
      );
    });

    test('normalizes lowercase colorHexRgb to uppercase', () {
      final profile = _profile(colorHexRgb: '0a0b0c');

      expect(profile.colorHexRgb, '0A0B0C');
    });

    test('uses value equality and matching hashCode', () {
      final a = _profile(colorHexRgb: '0a0b0c');
      final b = _profile(colorHexRgb: '0A0B0C');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('does not expose runtimeBlur in ShadowSoftnessMode V0', () {
      final names = ShadowSoftnessMode.values.map((value) => value.name);

      expect(names, contains('hardEdge'));
      expect(names, isNot(contains('runtimeBlur')));
    });
  });
}
