import 'package:map_core/map_core.dart';

import 'shadow_runtime_render_instruction.dart';
import 'shadow_runtime_resolver.dart';

/// Runtime actor metrics used to derive a contact shadow anchor.
///
/// The default multipliers are V0 heuristics for a compact contact blob. They
/// are intentionally adjustable once real rendered shadows can be evaluated.
final class ActorContactShadowRuntimeMetrics {
  ActorContactShadowRuntimeMetrics({
    required this.footWorldX,
    required this.footWorldY,
    required this.visualWidth,
    required this.visualHeight,
    this.baseWidthMultiplier = 0.6,
    this.baseHeightMultiplier = 0.18,
  }) {
    _validateFinite(footWorldX, 'footWorldX');
    _validateFinite(footWorldY, 'footWorldY');
    _validatePositiveFinite(visualWidth, 'visualWidth');
    _validatePositiveFinite(visualHeight, 'visualHeight');
    _validatePositiveFinite(baseWidthMultiplier, 'baseWidthMultiplier');
    _validatePositiveFinite(baseHeightMultiplier, 'baseHeightMultiplier');
  }

  final double footWorldX;
  final double footWorldY;
  final double visualWidth;
  final double visualHeight;
  final double baseWidthMultiplier;
  final double baseHeightMultiplier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActorContactShadowRuntimeMetrics &&
          other.footWorldX == footWorldX &&
          other.footWorldY == footWorldY &&
          other.visualWidth == visualWidth &&
          other.visualHeight == visualHeight &&
          other.baseWidthMultiplier == baseWidthMultiplier &&
          other.baseHeightMultiplier == baseHeightMultiplier;

  @override
  int get hashCode => Object.hash(
        footWorldX,
        footWorldY,
        visualWidth,
        visualHeight,
        baseWidthMultiplier,
        baseHeightMultiplier,
      );
}

/// Single actor contact shadow resolution request.
final class ActorContactShadowRuntimeInput {
  const ActorContactShadowRuntimeInput({
    required this.resolvedConfig,
    required this.metrics,
  });

  final ResolvedShadowConfig resolvedConfig;
  final ActorContactShadowRuntimeMetrics metrics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActorContactShadowRuntimeInput &&
          other.resolvedConfig == resolvedConfig &&
          other.metrics == metrics;

  @override
  int get hashCode => Object.hash(
        resolvedConfig,
        metrics,
      );
}

ShadowRuntimeAnchor actorContactShadowAnchorFromMetrics(
  ActorContactShadowRuntimeMetrics metrics,
) {
  return ShadowRuntimeAnchor(
    worldX: metrics.footWorldX,
    worldY: metrics.footWorldY,
    baseWidth: metrics.visualWidth * metrics.baseWidthMultiplier,
    baseHeight: metrics.visualHeight * metrics.baseHeightMultiplier,
  );
}

ShadowRuntimeRenderInstruction? resolveActorContactShadowRuntimeInstruction(
  ActorContactShadowRuntimeInput input,
) {
  final resolved = input.resolvedConfig;
  if (resolved.mode == ShadowCasterMode.none) {
    return null;
  }
  if (resolved.mode != ShadowCasterMode.contactBlob) {
    throw const ValidationException(
      'Actor contact shadow resolver requires contactBlob mode',
    );
  }
  if (resolved.renderPass != ShadowRenderPass.actorContact) {
    throw const ValidationException(
      'Actor contact shadow resolver requires actorContact render pass',
    );
  }

  return resolveShadowRuntimeInstruction(
    ShadowRuntimeResolutionInput(
      resolvedConfig: resolved,
      anchor: actorContactShadowAnchorFromMetrics(input.metrics),
    ),
  );
}

List<ShadowRuntimeRenderInstruction>
    resolveActorContactShadowRuntimeInstructions(
  Iterable<ActorContactShadowRuntimeInput> inputs,
) {
  final instructions = <ShadowRuntimeRenderInstruction>[];
  for (final input in inputs) {
    final instruction = resolveActorContactShadowRuntimeInstruction(input);
    if (instruction != null) {
      instructions.add(instruction);
    }
  }
  return List<ShadowRuntimeRenderInstruction>.unmodifiable(instructions);
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'ActorContactShadowRuntimeMetrics.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'ActorContactShadowRuntimeMetrics.$name must be greater than 0',
    );
  }
}
