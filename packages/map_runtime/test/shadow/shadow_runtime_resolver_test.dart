import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_resolver.dart';

void main() {
  group('ShadowRuntimeAnchor', () {
    test('creates a valid anchor', () {
      final anchor = ShadowRuntimeAnchor(
        worldX: 100,
        worldY: 200,
        baseWidth: 20,
        baseHeight: 10,
      );

      expect(anchor.worldX, 100);
      expect(anchor.worldY, 200);
      expect(anchor.baseWidth, 20);
      expect(anchor.baseHeight, 10);
    });

    test('rejects non-finite coordinates', () {
      expect(
        () => _anchor(worldX: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _anchor(worldX: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _anchor(worldY: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _anchor(worldY: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid base dimensions', () {
      for (final width in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _anchor(baseWidth: width),
          throwsA(isA<ValidationException>()),
          reason: 'baseWidth $width should be rejected',
        );
      }

      for (final height in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _anchor(baseHeight: height),
          throwsA(isA<ValidationException>()),
          reason: 'baseHeight $height should be rejected',
        );
      }
    });

    test('uses value equality and matching hashCode', () {
      final a = _anchor();
      final b = _anchor();
      final c = _anchor(worldX: 101);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('ShadowRuntimeResolutionInput', () {
    test('uses value equality and matching hashCode', () {
      final a = _input();
      final b = _input();
      final c = _input(anchor: _anchor(worldX: 101));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('resolveShadowRuntimeInstruction', () {
    test('resolves an ellipse groundStatic config into an instruction', () {
      final instruction = resolveShadowRuntimeInstruction(_input());

      expect(instruction, isNotNull);
      expect(instruction!.shape, ShadowRuntimeShapeKind.ellipse);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
    });

    test('resolves a contactBlob actorContact config into an instruction', () {
      final instruction = resolveShadowRuntimeInstruction(
        _input(
          resolvedConfig: _resolvedConfig(
            mode: ShadowCasterMode.contactBlob,
            renderPass: ShadowRenderPass.actorContact,
          ),
        ),
      );

      expect(instruction, isNotNull);
      expect(instruction!.shape, ShadowRuntimeShapeKind.contactBlob);
      expect(instruction.renderPass, ShadowRenderPass.actorContact);
    });

    test('applies offset and scale to compute the world rectangle', () {
      final instruction = resolveShadowRuntimeInstruction(_input());

      expect(instruction, isNotNull);
      expect(instruction!.width, closeTo(24, 0.000001));
      expect(instruction.height, closeTo(5, 0.000001));
      expect(instruction.worldLeft, closeTo(92, 0.000001));
      expect(instruction.worldTop, closeTo(209.5, 0.000001));
    });

    test('passes opacity color softness and renderPass through', () {
      final instruction = resolveShadowRuntimeInstruction(
        _input(
          resolvedConfig: _resolvedConfig(
            renderPass: ShadowRenderPass.actorContact,
            opacity: 0.7,
            colorHexRgb: '0a0b0c',
            softnessMode: ShadowSoftnessMode.hardEdge,
          ),
        ),
      );

      expect(instruction, isNotNull);
      expect(instruction!.renderPass, ShadowRenderPass.actorContact);
      expect(instruction.opacity, 0.7);
      expect(instruction.colorHexRgb, '0A0B0C');
      expect(instruction.softnessMode, ShadowSoftnessMode.hardEdge);
    });

    test('keeps opacity zero as a valid instruction', () {
      final instruction = resolveShadowRuntimeInstruction(
        _input(resolvedConfig: _resolvedConfig(opacity: 0)),
      );

      expect(instruction, isNotNull);
      expect(instruction!.opacity, 0);
    });

    test('returns null for ShadowCasterMode.none before shape conversion', () {
      final instruction = resolveShadowRuntimeInstruction(
        _input(resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.none)),
      );

      expect(instruction, isNull);
    });

    test('does not silently clamp invalid computed dimensions', () {
      expect(
        () => resolveShadowRuntimeInstruction(
          _input(anchor: _anchor(baseWidth: 0)),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('resolveShadowRuntimeInstructions', () {
    test('returns an empty list for no inputs', () {
      expect(resolveShadowRuntimeInstructions(const []), isEmpty);
    });

    test('resolves one input into one instruction', () {
      final instructions = resolveShadowRuntimeInstructions([_input()]);

      expect(instructions, hasLength(1));
      expect(instructions.single.shape, ShadowRuntimeShapeKind.ellipse);
    });

    test('preserves input order and does not sort by renderPass', () {
      final actorContact = _input(
        resolvedConfig: _resolvedConfig(
          shadowProfileId: 'actor',
          mode: ShadowCasterMode.contactBlob,
          renderPass: ShadowRenderPass.actorContact,
          offsetX: 0,
        ),
      );
      final groundStatic = _input(
        resolvedConfig: _resolvedConfig(
          shadowProfileId: 'static',
          mode: ShadowCasterMode.ellipse,
          renderPass: ShadowRenderPass.groundStatic,
          offsetX: 10,
        ),
      );

      final instructions = resolveShadowRuntimeInstructions([
        actorContact,
        groundStatic,
      ]);

      expect(instructions, hasLength(2));
      expect(instructions[0].renderPass, ShadowRenderPass.actorContact);
      expect(instructions[1].renderPass, ShadowRenderPass.groundStatic);
    });

    test('ignores inputs that resolve to null', () {
      final instructions = resolveShadowRuntimeInstructions([
        _input(resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.none)),
        _input(),
      ]);

      expect(instructions, hasLength(1));
      expect(instructions.single.shape, ShadowRuntimeShapeKind.ellipse);
    });

    test('does not cull opacity zero instructions', () {
      final instructions = resolveShadowRuntimeInstructions([
        _input(resolvedConfig: _resolvedConfig(opacity: 0)),
      ]);

      expect(instructions, hasLength(1));
      expect(instructions.single.opacity, 0);
    });

    test('exposes an unmodifiable output list', () {
      final instructions = resolveShadowRuntimeInstructions([_input()]);

      expect(
        () => instructions.add(resolveShadowRuntimeInstruction(_input())!),
        throwsUnsupportedError,
      );
    });
  });
}

ShadowRuntimeAnchor _anchor({
  double worldX = 100,
  double worldY = 200,
  double baseWidth = 20,
  double baseHeight = 10,
}) {
  return ShadowRuntimeAnchor(
    worldX: worldX,
    worldY: worldY,
    baseWidth: baseWidth,
    baseHeight: baseHeight,
  );
}

ShadowRuntimeResolutionInput _input({
  ResolvedShadowConfig? resolvedConfig,
  ShadowRuntimeAnchor? anchor,
}) {
  return ShadowRuntimeResolutionInput(
    resolvedConfig: resolvedConfig ?? _resolvedConfig(),
    anchor: anchor ?? _anchor(),
  );
}

ResolvedShadowConfig _resolvedConfig({
  String shadowProfileId = 'tree_large',
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double offsetX = 4,
  double offsetY = 12,
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
