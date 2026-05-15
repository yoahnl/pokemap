import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('ShadowRuntimeRenderInstruction', () {
    test('creates a valid contact blob instruction', () {
      final instruction = _instruction(
        shape: ShadowRuntimeShapeKind.contactBlob,
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.contactBlob);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.worldLeft, 12);
      expect(instruction.worldTop, 24);
      expect(instruction.width, 32);
      expect(instruction.height, 16);
      expect(instruction.opacity, 0.4);
    });

    test('creates a valid ellipse instruction', () {
      final instruction = _instruction(
        shape: ShadowRuntimeShapeKind.ellipse,
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.ellipse);
    });

    test('applies default color and softness', () {
      final instruction = _instruction();

      expect(instruction.colorHexRgb, '000000');
      expect(instruction.softnessMode, ShadowSoftnessMode.hardEdge);
    });

    test('accepts opacity bounds', () {
      expect(_instruction(opacity: 0).opacity, 0);
      expect(_instruction(opacity: 1).opacity, 1);
    });

    test('normalizes lowercase color to uppercase', () {
      final instruction = _instruction(colorHexRgb: '0a0b0c');

      expect(instruction.colorHexRgb, '0A0B0C');
    });

    test('rejects invalid colors', () {
      for (final color in <String>[
        '',
        '#000000',
        '00000',
        '0000000',
        'GGGGGG',
      ]) {
        expect(
          () => _instruction(colorHexRgb: color),
          throwsA(isA<ValidationException>()),
          reason: 'color $color should be rejected',
        );
      }
    });

    test('rejects non-finite world coordinates', () {
      expect(
        () => _instruction(worldLeft: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _instruction(worldLeft: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _instruction(worldTop: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _instruction(worldTop: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid width', () {
      for (final width in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _instruction(width: width),
          throwsA(isA<ValidationException>()),
          reason: 'width $width should be rejected',
        );
      }
    });

    test('rejects invalid height', () {
      for (final height in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _instruction(height: height),
          throwsA(isA<ValidationException>()),
          reason: 'height $height should be rejected',
        );
      }
    });

    test('rejects invalid opacity', () {
      for (final opacity in <double>[
        -0.1,
        1.1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _instruction(opacity: opacity),
          throwsA(isA<ValidationException>()),
          reason: 'opacity $opacity should be rejected',
        );
      }
    });

    test('rejects non hard-edge softness in V0 if one appears later', () {
      for (final softnessMode in ShadowSoftnessMode.values) {
        if (softnessMode == ShadowSoftnessMode.hardEdge) {
          expect(_instruction(softnessMode: softnessMode).softnessMode,
              ShadowSoftnessMode.hardEdge);
        } else {
          expect(
            () => _instruction(softnessMode: softnessMode),
            throwsA(isA<ValidationException>()),
          );
        }
      }
    });

    test('has value equality and stable hashCode', () {
      final a = _instruction(colorHexRgb: '0a0b0c');
      final b = _instruction(colorHexRgb: '0A0B0C');
      final c = _instruction(opacity: 0.5);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('shadowRuntimeShapeFromCasterMode', () {
    test('maps contactBlob and ellipse', () {
      expect(
        shadowRuntimeShapeFromCasterMode(ShadowCasterMode.contactBlob),
        ShadowRuntimeShapeKind.contactBlob,
      );
      expect(
        shadowRuntimeShapeFromCasterMode(ShadowCasterMode.ellipse),
        ShadowRuntimeShapeKind.ellipse,
      );
    });

    test('rejects none because render instructions must be drawable', () {
      expect(
        () => shadowRuntimeShapeFromCasterMode(ShadowCasterMode.none),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

ShadowRuntimeRenderInstruction _instruction({
  ShadowRuntimeShapeKind shape = ShadowRuntimeShapeKind.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double worldLeft = 12,
  double worldTop = 24,
  double width = 32,
  double height = 16,
  double opacity = 0.4,
  String colorHexRgb = '000000',
  ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
}) {
  return ShadowRuntimeRenderInstruction(
    shape: shape,
    renderPass: renderPass,
    worldLeft: worldLeft,
    worldTop: worldTop,
    width: width,
    height: height,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
    softnessMode: softnessMode,
  );
}
