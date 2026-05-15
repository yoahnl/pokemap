import 'package:map_core/map_core.dart';

import 'shadow_runtime_render_instruction.dart';

/// Runtime-provided geometry used to place a resolved V0 shadow.
///
/// The caller owns the conversion from sprites, actors, or placed elements to
/// this anchor. This resolver only applies resolved shadow offsets and scales.
final class ShadowRuntimeAnchor {
  ShadowRuntimeAnchor({
    required this.worldX,
    required this.worldY,
    required this.baseWidth,
    required this.baseHeight,
  }) {
    _validateFinite(worldX, 'worldX');
    _validateFinite(worldY, 'worldY');
    _validatePositiveFinite(baseWidth, 'baseWidth');
    _validatePositiveFinite(baseHeight, 'baseHeight');
  }

  final double worldX;
  final double worldY;
  final double baseWidth;
  final double baseHeight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowRuntimeAnchor &&
          other.worldX == worldX &&
          other.worldY == worldY &&
          other.baseWidth == baseWidth &&
          other.baseHeight == baseHeight;

  @override
  int get hashCode => Object.hash(
        worldX,
        worldY,
        baseWidth,
        baseHeight,
      );
}

/// Single runtime shadow resolution request.
final class ShadowRuntimeResolutionInput {
  const ShadowRuntimeResolutionInput({
    required this.resolvedConfig,
    required this.anchor,
  });

  final ResolvedShadowConfig resolvedConfig;
  final ShadowRuntimeAnchor anchor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowRuntimeResolutionInput &&
          other.resolvedConfig == resolvedConfig &&
          other.anchor == anchor;

  @override
  int get hashCode => Object.hash(
        resolvedConfig,
        anchor,
      );
}

ShadowRuntimeRenderInstruction? resolveShadowRuntimeInstruction(
  ShadowRuntimeResolutionInput input,
) {
  final resolved = input.resolvedConfig;
  if (resolved.mode == ShadowCasterMode.none) {
    return null;
  }

  final anchor = input.anchor;
  final resolvedWidth = anchor.baseWidth * resolved.scaleX;
  final resolvedHeight = anchor.baseHeight * resolved.scaleY;
  final centerX = anchor.worldX + resolved.offsetX;
  final centerY = anchor.worldY + resolved.offsetY;

  return ShadowRuntimeRenderInstruction(
    shape: shadowRuntimeShapeFromCasterMode(resolved.mode),
    renderPass: resolved.renderPass,
    worldLeft: centerX - resolvedWidth / 2,
    worldTop: centerY - resolvedHeight / 2,
    width: resolvedWidth,
    height: resolvedHeight,
    opacity: resolved.opacity,
    colorHexRgb: resolved.colorHexRgb,
    softnessMode: resolved.softnessMode,
  );
}

List<ShadowRuntimeRenderInstruction> resolveShadowRuntimeInstructions(
  Iterable<ShadowRuntimeResolutionInput> inputs,
) {
  final instructions = <ShadowRuntimeRenderInstruction>[];
  for (final input in inputs) {
    final instruction = resolveShadowRuntimeInstruction(input);
    if (instruction != null) {
      instructions.add(instruction);
    }
  }
  return List<ShadowRuntimeRenderInstruction>.unmodifiable(instructions);
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'ShadowRuntimeAnchor.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'ShadowRuntimeAnchor.$name must be greater than 0',
    );
  }
}
