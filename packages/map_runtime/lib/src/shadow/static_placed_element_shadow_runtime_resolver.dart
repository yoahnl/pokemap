import 'package:map_core/map_core.dart';

import 'shadow_runtime_render_instruction.dart';
import 'shadow_runtime_resolver.dart';

/// Runtime static element metrics used to derive a ground shadow anchor.
///
/// The default ratios and multipliers are V0 heuristics for common static
/// props. They are intentionally adjustable once real rendered shadows can be
/// evaluated.
final class StaticPlacedElementShadowRuntimeMetrics {
  StaticPlacedElementShadowRuntimeMetrics({
    required this.worldLeft,
    required this.worldTop,
    required this.visualWidth,
    required this.visualHeight,
    this.anchorXRatio = 0.5,
    this.anchorYRatio = 1.0,
    this.baseWidthMultiplier = 0.75,
    this.baseHeightMultiplier = 0.25,
  }) {
    _validateFinite(worldLeft, 'worldLeft');
    _validateFinite(worldTop, 'worldTop');
    _validatePositiveFinite(visualWidth, 'visualWidth');
    _validatePositiveFinite(visualHeight, 'visualHeight');
    _validateRatio(anchorXRatio, 'anchorXRatio');
    _validateRatio(anchorYRatio, 'anchorYRatio');
    _validatePositiveFinite(baseWidthMultiplier, 'baseWidthMultiplier');
    _validatePositiveFinite(baseHeightMultiplier, 'baseHeightMultiplier');
  }

  final double worldLeft;
  final double worldTop;
  final double visualWidth;
  final double visualHeight;
  final double anchorXRatio;
  final double anchorYRatio;
  final double baseWidthMultiplier;
  final double baseHeightMultiplier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticPlacedElementShadowRuntimeMetrics &&
          other.worldLeft == worldLeft &&
          other.worldTop == worldTop &&
          other.visualWidth == visualWidth &&
          other.visualHeight == visualHeight &&
          other.anchorXRatio == anchorXRatio &&
          other.anchorYRatio == anchorYRatio &&
          other.baseWidthMultiplier == baseWidthMultiplier &&
          other.baseHeightMultiplier == baseHeightMultiplier;

  @override
  int get hashCode => Object.hash(
        worldLeft,
        worldTop,
        visualWidth,
        visualHeight,
        anchorXRatio,
        anchorYRatio,
        baseWidthMultiplier,
        baseHeightMultiplier,
      );
}

/// Single static placed element shadow resolution request.
final class StaticPlacedElementShadowRuntimeInput {
  const StaticPlacedElementShadowRuntimeInput({
    required this.resolvedConfig,
    required this.metrics,
    this.elementFootprint,
    this.overrideFootprint,
  });

  final ResolvedShadowConfig resolvedConfig;
  final StaticPlacedElementShadowRuntimeMetrics metrics;
  final StaticShadowFootprintConfig? elementFootprint;
  final StaticShadowFootprintConfig? overrideFootprint;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticPlacedElementShadowRuntimeInput &&
          other.resolvedConfig == resolvedConfig &&
          other.metrics == metrics &&
          other.elementFootprint == elementFootprint &&
          other.overrideFootprint == overrideFootprint;

  @override
  int get hashCode => Object.hash(
        resolvedConfig,
        metrics,
        elementFootprint,
        overrideFootprint,
      );
}

ShadowRuntimeAnchor staticPlacedElementShadowAnchorFromMetrics(
  StaticPlacedElementShadowRuntimeMetrics metrics, {
  ResolvedShadowConfig? shadowConfig,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
}) {
  final legacyAndElementFootprint = _mergeLegacyAndElementFootprint(
    metrics: metrics,
    elementFootprint: elementFootprint,
  );
  final geometry = resolveStaticShadowGeometry(
    metrics: StaticShadowVisualMetrics(
      left: metrics.worldLeft,
      top: metrics.worldTop,
      visualWidth: metrics.visualWidth,
      visualHeight: metrics.visualHeight,
    ),
    shadowConfig: shadowConfig ?? _identityShadowConfig,
    elementFootprint: legacyAndElementFootprint,
    overrideFootprint: overrideFootprint,
  );

  return ShadowRuntimeAnchor(
    worldX: geometry.anchorX,
    worldY: geometry.anchorY,
    baseWidth: geometry.baseWidth,
    baseHeight: geometry.baseHeight,
  );
}

ShadowRuntimeRenderInstruction?
    resolveStaticPlacedElementShadowRuntimeInstruction(
  StaticPlacedElementShadowRuntimeInput input,
) {
  final resolved = input.resolvedConfig;
  if (resolved.mode == ShadowCasterMode.none) {
    return null;
  }
  if (resolved.renderPass != ShadowRenderPass.groundStatic) {
    throw const ValidationException(
      'Static placed element shadow resolver requires groundStatic render pass',
    );
  }
  if (resolved.mode != ShadowCasterMode.ellipse &&
      resolved.mode != ShadowCasterMode.contactBlob) {
    throw const ValidationException(
      'Static placed element shadow resolver requires ellipse or contactBlob mode',
    );
  }

  return resolveShadowRuntimeInstruction(
    ShadowRuntimeResolutionInput(
      resolvedConfig: resolved,
      anchor: staticPlacedElementShadowAnchorFromMetrics(
        input.metrics,
        shadowConfig: resolved,
        elementFootprint: input.elementFootprint,
        overrideFootprint: input.overrideFootprint,
      ),
    ),
  );
}

List<ShadowRuntimeRenderInstruction>
    resolveStaticPlacedElementShadowRuntimeInstructions(
  Iterable<StaticPlacedElementShadowRuntimeInput> inputs,
) {
  final instructions = <ShadowRuntimeRenderInstruction>[];
  for (final input in inputs) {
    final instruction =
        resolveStaticPlacedElementShadowRuntimeInstruction(input);
    if (instruction != null) {
      instructions.add(instruction);
    }
  }
  return List<ShadowRuntimeRenderInstruction>.unmodifiable(instructions);
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'StaticPlacedElementShadowRuntimeMetrics.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'StaticPlacedElementShadowRuntimeMetrics.$name must be greater than 0',
    );
  }
}

void _validateRatio(double value, String name) {
  _validateFinite(value, name);
  if (value < 0 || value > 1) {
    throw ValidationException(
      'StaticPlacedElementShadowRuntimeMetrics.$name must be between 0 and 1',
    );
  }
}

StaticShadowFootprintConfig _legacyFootprintFromMetrics(
  StaticPlacedElementShadowRuntimeMetrics metrics,
) {
  return StaticShadowFootprintConfig(
    anchorXRatio: metrics.anchorXRatio,
    anchorYRatio: metrics.anchorYRatio,
    footprintWidthRatio: metrics.baseWidthMultiplier,
    footprintHeightRatio: metrics.baseHeightMultiplier,
  );
}

StaticShadowFootprintConfig _mergeLegacyAndElementFootprint({
  required StaticPlacedElementShadowRuntimeMetrics metrics,
  required StaticShadowFootprintConfig? elementFootprint,
}) {
  final resolved = resolveStaticShadowFootprint(
    elementFootprint: _legacyFootprintFromMetrics(metrics),
    overrideFootprint: elementFootprint,
  );
  return StaticShadowFootprintConfig(
    anchorXRatio: resolved.anchorXRatio,
    anchorYRatio: resolved.anchorYRatio,
    footprintWidthRatio: resolved.footprintWidthRatio,
    footprintHeightRatio: resolved.footprintHeightRatio,
  );
}

const _identityShadowConfig = ResolvedShadowConfig(
  shadowProfileId: 'runtime-static-shadow-anchor',
  mode: ShadowCasterMode.ellipse,
  renderPass: ShadowRenderPass.groundStatic,
  offsetX: 0,
  offsetY: 0,
  scaleX: 1,
  scaleY: 1,
  opacity: 1,
  colorHexRgb: '000000',
  softnessMode: ShadowSoftnessMode.hardEdge,
);
