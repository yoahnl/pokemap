import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_resolver.dart';
import 'package:map_runtime/src/shadow/static_placed_element_shadow_runtime_resolver.dart';

void main() {
  group('StaticPlacedElementShadowRuntimeMetrics', () {
    test('creates valid metrics with default ratios and multipliers', () {
      final metrics = _metrics();

      expect(metrics.worldLeft, 80);
      expect(metrics.worldTop, 120);
      expect(metrics.visualWidth, 40);
      expect(metrics.visualHeight, 60);
      expect(metrics.anchorXRatio, 0.5);
      expect(metrics.anchorYRatio, 1.0);
      expect(metrics.baseWidthMultiplier, 0.75);
      expect(metrics.baseHeightMultiplier, 0.25);
    });

    test('accepts custom valid ratios and multipliers', () {
      final metrics = _metrics(
        anchorXRatio: 0.25,
        anchorYRatio: 0.75,
        baseWidthMultiplier: 0.5,
        baseHeightMultiplier: 0.125,
      );

      expect(metrics.anchorXRatio, 0.25);
      expect(metrics.anchorYRatio, 0.75);
      expect(metrics.baseWidthMultiplier, 0.5);
      expect(metrics.baseHeightMultiplier, 0.125);
    });

    test('rejects non-finite world coordinates', () {
      expect(
        () => _metrics(worldLeft: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(worldLeft: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(worldTop: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(worldTop: double.infinity),
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

    test('rejects invalid anchor ratios', () {
      for (final ratio in <double>[
        -0.1,
        1.1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(anchorXRatio: ratio),
          throwsA(isA<ValidationException>()),
          reason: 'anchorXRatio $ratio should be rejected',
        );
      }

      for (final ratio in <double>[
        -0.1,
        1.1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(anchorYRatio: ratio),
          throwsA(isA<ValidationException>()),
          reason: 'anchorYRatio $ratio should be rejected',
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
      final c = _metrics(worldLeft: 81);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('StaticPlacedElementShadowRuntimeInput', () {
    test('uses value equality and matching hashCode', () {
      final a = _input();
      final b = _input();
      final c = _input(metrics: _metrics(worldLeft: 81));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('equality includes element and override footprints', () {
      final a = _input(
        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
        overrideFootprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
      );
      final b = _input(
        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
        overrideFootprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
      );
      final c = _input(
        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
        overrideFootprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('staticPlacedElementShadowAnchorFromMetrics', () {
    test('converts static metrics into a runtime anchor', () {
      final anchor = staticPlacedElementShadowAnchorFromMetrics(_metrics());

      expect(anchor, isA<ShadowRuntimeAnchor>());
      expect(anchor.worldX, closeTo(100, 0.000001));
      expect(anchor.worldY, closeTo(180, 0.000001));
      expect(anchor.baseWidth, closeTo(30, 0.000001));
      expect(anchor.baseHeight, closeTo(15, 0.000001));
    });

    test('preserves custom legacy metrics ratios and multipliers', () {
      final anchor = staticPlacedElementShadowAnchorFromMetrics(
        _metrics(
          anchorXRatio: 0.25,
          anchorYRatio: 0.75,
          baseWidthMultiplier: 0.5,
          baseHeightMultiplier: 0.125,
        ),
      );

      expect(anchor.worldX, closeTo(90, 0.000001));
      expect(anchor.worldY, closeTo(165, 0.000001));
      expect(anchor.baseWidth, closeTo(20, 0.000001));
      expect(anchor.baseHeight, closeTo(7.5, 0.000001));
    });

    test('element footprint overrides legacy metrics field by field', () {
      final anchor = staticPlacedElementShadowAnchorFromMetrics(
        _metrics(
          anchorXRatio: 0.25,
          anchorYRatio: 0.75,
          baseWidthMultiplier: 0.5,
          baseHeightMultiplier: 0.125,
        ),
        elementFootprint: StaticShadowFootprintConfig(
          anchorYRatio: 0.5,
          footprintWidthRatio: 0.25,
        ),
      );

      expect(anchor.worldX, closeTo(90, 0.000001));
      expect(anchor.worldY, closeTo(150, 0.000001));
      expect(anchor.baseWidth, closeTo(10, 0.000001));
      expect(anchor.baseHeight, closeTo(7.5, 0.000001));
    });

    test('override footprint wins over element footprint field by field', () {
      final anchor = staticPlacedElementShadowAnchorFromMetrics(
        _metrics(),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.25,
          anchorYRatio: 0.75,
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.125,
        ),
        overrideFootprint: StaticShadowFootprintConfig(
          anchorYRatio: 0.5,
          footprintWidthRatio: 0.25,
        ),
      );

      expect(anchor.worldX, closeTo(90, 0.000001));
      expect(anchor.worldY, closeTo(150, 0.000001));
      expect(anchor.baseWidth, closeTo(10, 0.000001));
      expect(anchor.baseHeight, closeTo(7.5, 0.000001));
    });
  });

  group('resolveStaticPlacedElementShadowRuntimeInstruction', () {
    test('resolves ellipse groundStatic into an instruction', () {
      final instruction =
          resolveStaticPlacedElementShadowRuntimeInstruction(_input());

      expect(instruction, isNotNull);
      expect(instruction!.shape, ShadowRuntimeShapeKind.ellipse);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
    });

    test('resolves contactBlob groundStatic into an instruction', () {
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.contactBlob),
        ),
      );

      expect(instruction, isNotNull);
      expect(instruction!.shape, ShadowRuntimeShapeKind.contactBlob);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
    });

    test('applies static metrics and Shadow-12 offset/scale geometry', () {
      final instruction =
          resolveStaticPlacedElementShadowRuntimeInstruction(_input());

      expect(instruction, isNotNull);
      expect(instruction!.width, closeTo(36, 0.000001));
      expect(instruction.height, closeTo(7.5, 0.000001));
      expect(instruction.worldLeft, closeTo(88, 0.000001));
      expect(instruction.worldTop, closeTo(186.25, 0.000001));
    });

    test('applies offset and scale once after core footprint geometry', () {
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          elementFootprint: StaticShadowFootprintConfig(
            anchorXRatio: 0.25,
            anchorYRatio: 0.5,
            footprintWidthRatio: 0.5,
            footprintHeightRatio: 0.25,
          ),
        ),
      );

      expect(instruction, isNotNull);
      expect(instruction!.width, closeTo(24, 0.000001));
      expect(instruction.height, closeTo(7.5, 0.000001));
      expect(instruction.worldLeft, closeTo(84, 0.000001));
      expect(instruction.worldTop, closeTo(156.25, 0.000001));
    });

    test('custom override without footprint keeps element footprint', () {
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          resolvedConfig: _resolvedConfig(offsetX: 4),
          elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
        ),
      );

      expect(instruction, isNotNull);
      expect(instruction!.worldLeft, closeTo(76, 0.000001));
      expect(instruction.worldTop, closeTo(186.25, 0.000001));
    });

    test('passes opacity color softness and renderPass through', () {
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
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
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
    });

    test('keeps opacity zero as a valid instruction', () {
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(resolvedConfig: _resolvedConfig(opacity: 0)),
      );

      expect(instruction, isNotNull);
      expect(instruction!.opacity, 0);
    });

    test('returns null for ShadowCasterMode.none before render pass checks',
        () {
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          resolvedConfig: _resolvedConfig(
            mode: ShadowCasterMode.none,
            renderPass: ShadowRenderPass.actorContact,
          ),
        ),
      );

      expect(instruction, isNull);
    });

    test('rejects actorContact render pass', () {
      expect(
        () => resolveStaticPlacedElementShadowRuntimeInstruction(
          _input(
            resolvedConfig: _resolvedConfig(
              renderPass: ShadowRenderPass.actorContact,
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('does not silently clamp invalid computed dimensions', () {
      expect(
        () => resolveStaticPlacedElementShadowRuntimeInstruction(
          _input(resolvedConfig: _resolvedConfig(scaleX: -1)),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('resolveStaticPlacedElementShadowRuntimeInstructions', () {
    test('returns an empty list for no inputs', () {
      expect(resolveStaticPlacedElementShadowRuntimeInstructions(const []),
          isEmpty);
    });

    test('resolves one input into one instruction', () {
      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        _input(),
      ]);

      expect(instructions, hasLength(1));
      expect(instructions.single.shape, ShadowRuntimeShapeKind.ellipse);
    });

    test('preserves input order without sorting', () {
      final first = _input(
        metrics: _metrics(worldLeft: 80),
        resolvedConfig: _resolvedConfig(offsetX: 0),
      );
      final second = _input(
        metrics: _metrics(worldLeft: 200),
        resolvedConfig: _resolvedConfig(offsetX: 0),
      );

      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        first,
        second,
      ]);

      expect(instructions, hasLength(2));
      expect(instructions[0].worldLeft, lessThan(instructions[1].worldLeft));
    });

    test('ignores mode none inputs', () {
      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        _input(resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.none)),
        _input(),
      ]);

      expect(instructions, hasLength(1));
      expect(instructions.single.shape, ShadowRuntimeShapeKind.ellipse);
    });

    test('does not cull opacity zero instructions', () {
      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        _input(resolvedConfig: _resolvedConfig(opacity: 0)),
      ]);

      expect(instructions, hasLength(1));
      expect(instructions.single.opacity, 0);
    });

    test('does not deduplicate equal inputs', () {
      final input = _input();

      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        input,
        input,
      ]);

      expect(instructions, hasLength(2));
      expect(instructions[0], instructions[1]);
    });

    test('does not modify inputs and exposes an unmodifiable list', () {
      final input = _input();
      final before = _input();

      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        input,
      ]);

      expect(input, before);
      expect(
        () => instructions.add(
          resolveStaticPlacedElementShadowRuntimeInstruction(_input())!,
        ),
        throwsUnsupportedError,
      );
    });
  });
}

StaticPlacedElementShadowRuntimeMetrics _metrics({
  double worldLeft = 80,
  double worldTop = 120,
  double visualWidth = 40,
  double visualHeight = 60,
  double anchorXRatio = 0.5,
  double anchorYRatio = 1.0,
  double baseWidthMultiplier = 0.75,
  double baseHeightMultiplier = 0.25,
}) {
  return StaticPlacedElementShadowRuntimeMetrics(
    worldLeft: worldLeft,
    worldTop: worldTop,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
    anchorXRatio: anchorXRatio,
    anchorYRatio: anchorYRatio,
    baseWidthMultiplier: baseWidthMultiplier,
    baseHeightMultiplier: baseHeightMultiplier,
  );
}

StaticPlacedElementShadowRuntimeInput _input({
  ResolvedShadowConfig? resolvedConfig,
  StaticPlacedElementShadowRuntimeMetrics? metrics,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
}) {
  return StaticPlacedElementShadowRuntimeInput(
    resolvedConfig: resolvedConfig ?? _resolvedConfig(),
    metrics: metrics ?? _metrics(),
    elementFootprint: elementFootprint,
    overrideFootprint: overrideFootprint,
  );
}

ResolvedShadowConfig _resolvedConfig({
  String shadowProfileId = 'tree_large',
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double offsetX = 6,
  double offsetY = 10,
  double scaleX = 1.2,
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
