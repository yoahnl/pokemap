import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/actor_contact_shadow_runtime_resolver.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_resolver.dart';

void main() {
  group('ActorContactShadowRuntimeMetrics', () {
    test('creates valid metrics with default multipliers', () {
      final metrics = _metrics();

      expect(metrics.footWorldX, 100);
      expect(metrics.footWorldY, 200);
      expect(metrics.visualWidth, 32);
      expect(metrics.visualHeight, 48);
      expect(metrics.baseWidthMultiplier, 0.6);
      expect(metrics.baseHeightMultiplier, 0.18);
    });

    test('accepts custom valid multipliers', () {
      final metrics = _metrics(
        baseWidthMultiplier: 0.5,
        baseHeightMultiplier: 0.125,
      );

      expect(metrics.baseWidthMultiplier, 0.5);
      expect(metrics.baseHeightMultiplier, 0.125);
    });

    test('rejects non-finite foot coordinates', () {
      expect(
        () => _metrics(footWorldX: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(footWorldX: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(footWorldY: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(footWorldY: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid visual dimensions', () {
      for (final width in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(visualWidth: width),
          throwsA(isA<ValidationException>()),
          reason: 'visualWidth $width should be rejected',
        );
      }

      for (final height in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(visualHeight: height),
          throwsA(isA<ValidationException>()),
          reason: 'visualHeight $height should be rejected',
        );
      }
    });

    test('rejects invalid base multipliers', () {
      for (final multiplier in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(baseWidthMultiplier: multiplier),
          throwsA(isA<ValidationException>()),
          reason: 'baseWidthMultiplier $multiplier should be rejected',
        );
      }

      for (final multiplier in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(baseHeightMultiplier: multiplier),
          throwsA(isA<ValidationException>()),
          reason: 'baseHeightMultiplier $multiplier should be rejected',
        );
      }
    });

    test('uses value equality and matching hashCode', () {
      final a = _metrics();
      final b = _metrics();
      final c = _metrics(footWorldX: 101);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('ActorContactShadowRuntimeInput', () {
    test('uses value equality and matching hashCode', () {
      final a = _input();
      final b = _input();
      final c = _input(metrics: _metrics(footWorldX: 101));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('actorContactShadowAnchorFromMetrics', () {
    test('converts actor metrics into a runtime anchor', () {
      final anchor = actorContactShadowAnchorFromMetrics(
        _metrics(
          baseWidthMultiplier: 0.5,
          baseHeightMultiplier: 0.125,
        ),
      );

      expect(anchor, isA<ShadowRuntimeAnchor>());
      expect(anchor.worldX, 100);
      expect(anchor.worldY, 200);
      expect(anchor.baseWidth, closeTo(16, 0.000001));
      expect(anchor.baseHeight, closeTo(6, 0.000001));
    });
  });

  group('resolveActorContactShadowRuntimeInstruction', () {
    test('resolves contactBlob actorContact into an instruction', () {
      final instruction = resolveActorContactShadowRuntimeInstruction(_input());

      expect(instruction, isNotNull);
      expect(instruction!.shape, ShadowRuntimeShapeKind.contactBlob);
      expect(instruction.renderPass, ShadowRenderPass.actorContact);
    });

    test('applies actor metrics and Shadow-12 offset/scale geometry', () {
      final instruction = resolveActorContactShadowRuntimeInstruction(_input());

      expect(instruction, isNotNull);
      expect(instruction!.width, closeTo(24, 0.000001));
      expect(instruction.height, closeTo(3, 0.000001));
      expect(instruction.worldLeft, closeTo(92, 0.000001));
      expect(instruction.worldTop, closeTo(201.5, 0.000001));
    });

    test('passes opacity color softness and renderPass through', () {
      final instruction = resolveActorContactShadowRuntimeInstruction(
        _input(
          resolvedConfig: _resolvedConfig(
            opacity: 0.7,
            colorHexRgb: '0a0b0c',
            softnessMode: ShadowSoftnessMode.hardEdge,
          ),
        ),
      );

      expect(instruction, isNotNull);
      expect(instruction!.opacity, 0.7);
      expect(instruction.colorHexRgb, '0A0B0C');
      expect(instruction.softnessMode, ShadowSoftnessMode.hardEdge);
      expect(instruction.renderPass, ShadowRenderPass.actorContact);
    });

    test('keeps opacity zero as a valid instruction', () {
      final instruction = resolveActorContactShadowRuntimeInstruction(
        _input(resolvedConfig: _resolvedConfig(opacity: 0)),
      );

      expect(instruction, isNotNull);
      expect(instruction!.opacity, 0);
    });

    test('returns null for ShadowCasterMode.none', () {
      final instruction = resolveActorContactShadowRuntimeInstruction(
        _input(resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.none)),
      );

      expect(instruction, isNull);
    });

    test('rejects non contactBlob modes', () {
      expect(
        () => resolveActorContactShadowRuntimeInstruction(
          _input(
              resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.ellipse)),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non actorContact render passes', () {
      expect(
        () => resolveActorContactShadowRuntimeInstruction(
          _input(
            resolvedConfig: _resolvedConfig(
              renderPass: ShadowRenderPass.groundStatic,
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('does not silently clamp invalid computed dimensions', () {
      expect(
        () => resolveActorContactShadowRuntimeInstruction(
          _input(resolvedConfig: _resolvedConfig(scaleX: -1)),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('resolveActorContactShadowRuntimeInstructions', () {
    test('returns an empty list for no inputs', () {
      expect(resolveActorContactShadowRuntimeInstructions(const []), isEmpty);
    });

    test('resolves one input into one instruction', () {
      final instructions = resolveActorContactShadowRuntimeInstructions([
        _input(),
      ]);

      expect(instructions, hasLength(1));
      expect(instructions.single.shape, ShadowRuntimeShapeKind.contactBlob);
    });

    test('preserves input order without sorting', () {
      final first = _input(
        metrics: _metrics(footWorldX: 100),
        resolvedConfig: _resolvedConfig(offsetX: 0),
      );
      final second = _input(
        metrics: _metrics(footWorldX: 200),
        resolvedConfig: _resolvedConfig(offsetX: 0),
      );

      final instructions = resolveActorContactShadowRuntimeInstructions([
        first,
        second,
      ]);

      expect(instructions, hasLength(2));
      expect(instructions[0].worldLeft, lessThan(instructions[1].worldLeft));
    });

    test('ignores mode none inputs', () {
      final instructions = resolveActorContactShadowRuntimeInstructions([
        _input(resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.none)),
        _input(),
      ]);

      expect(instructions, hasLength(1));
      expect(instructions.single.shape, ShadowRuntimeShapeKind.contactBlob);
    });

    test('does not cull opacity zero instructions', () {
      final instructions = resolveActorContactShadowRuntimeInstructions([
        _input(resolvedConfig: _resolvedConfig(opacity: 0)),
      ]);

      expect(instructions, hasLength(1));
      expect(instructions.single.opacity, 0);
    });

    test('does not deduplicate equal inputs', () {
      final input = _input();

      final instructions = resolveActorContactShadowRuntimeInstructions([
        input,
        input,
      ]);

      expect(instructions, hasLength(2));
      expect(instructions[0], instructions[1]);
    });

    test('does not modify inputs and exposes an unmodifiable list', () {
      final input = _input();
      final before = _input();

      final instructions = resolveActorContactShadowRuntimeInstructions([
        input,
      ]);

      expect(input, before);
      expect(
        () => instructions.add(
          resolveActorContactShadowRuntimeInstruction(_input())!,
        ),
        throwsUnsupportedError,
      );
    });
  });
}

ActorContactShadowRuntimeMetrics _metrics({
  double footWorldX = 100,
  double footWorldY = 200,
  double visualWidth = 32,
  double visualHeight = 48,
  double baseWidthMultiplier = 0.6,
  double baseHeightMultiplier = 0.18,
}) {
  return ActorContactShadowRuntimeMetrics(
    footWorldX: footWorldX,
    footWorldY: footWorldY,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
    baseWidthMultiplier: baseWidthMultiplier,
    baseHeightMultiplier: baseHeightMultiplier,
  );
}

ActorContactShadowRuntimeInput _input({
  ResolvedShadowConfig? resolvedConfig,
  ActorContactShadowRuntimeMetrics? metrics,
}) {
  return ActorContactShadowRuntimeInput(
    resolvedConfig: resolvedConfig ?? _resolvedConfig(),
    metrics: metrics ??
        _metrics(
          baseWidthMultiplier: 0.5,
          baseHeightMultiplier: 0.125,
        ),
  );
}

ResolvedShadowConfig _resolvedConfig({
  String shadowProfileId = 'actor_contact',
  ShadowCasterMode mode = ShadowCasterMode.contactBlob,
  ShadowRenderPass renderPass = ShadowRenderPass.actorContact,
  double offsetX = 4,
  double offsetY = 3,
  double scaleX = 1.5,
  double scaleY = 0.5,
  double opacity = 0.35,
  String colorHexRgb = '000000',
  ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
}) {
  return ResolvedShadowConfig(
    shadowProfileId: shadowProfileId,
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
