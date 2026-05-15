import 'package:map_core/map_core.dart';

import '../presentation/flame/shadow_runtime_render_order_contract.dart';

enum ShadowRuntimeShapeKind {
  contactBlob,
  ellipse,
}

final _colorHexRgbPattern = RegExp(r'^[0-9a-fA-F]{6}$');

/// Pure runtime draw instruction for one resolved V0 shadow.
///
/// The rectangle is already expressed in world coordinates. This model does
/// not resolve map data, load images, or draw anything.
final class ShadowRuntimeRenderInstruction {
  ShadowRuntimeRenderInstruction({
    required this.shape,
    required this.renderPass,
    required this.worldLeft,
    required this.worldTop,
    required this.width,
    required this.height,
    required this.opacity,
    String colorHexRgb = '000000',
    this.softnessMode = ShadowSoftnessMode.hardEdge,
  }) : colorHexRgb = _normalizeColorHexRgb(colorHexRgb) {
    _validateFinite(worldLeft, 'worldLeft');
    _validateFinite(worldTop, 'worldTop');
    _validatePositiveFinite(width, 'width');
    _validatePositiveFinite(height, 'height');
    _validateOpacity(opacity);
    _validateSoftnessMode(softnessMode);
  }

  final ShadowRuntimeShapeKind shape;
  final ShadowRenderPass renderPass;
  final double worldLeft;
  final double worldTop;
  final double width;
  final double height;
  final double opacity;
  final String colorHexRgb;
  final ShadowSoftnessMode softnessMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowRuntimeRenderInstruction &&
          other.shape == shape &&
          other.renderPass == renderPass &&
          other.worldLeft == worldLeft &&
          other.worldTop == worldTop &&
          other.width == width &&
          other.height == height &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb &&
          other.softnessMode == softnessMode;

  @override
  int get hashCode => Object.hash(
        shape,
        renderPass,
        worldLeft,
        worldTop,
        width,
        height,
        opacity,
        colorHexRgb,
        softnessMode,
      );
}

ShadowRuntimeShapeKind shadowRuntimeShapeFromCasterMode(
  ShadowCasterMode mode,
) {
  return switch (mode) {
    ShadowCasterMode.contactBlob => ShadowRuntimeShapeKind.contactBlob,
    ShadowCasterMode.ellipse => ShadowRuntimeShapeKind.ellipse,
    ShadowCasterMode.none => throw const ValidationException(
        'ShadowCasterMode.none cannot produce a drawable runtime shadow shape',
      ),
  };
}

RuntimeShadowRenderOrderSlot runtimeShadowRenderSlotForPass(
  ShadowRenderPass pass,
) {
  return switch (pass) {
    ShadowRenderPass.groundStatic =>
      RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
    ShadowRenderPass.actorContact =>
      RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
  };
}

RuntimeShadowRenderOrderSlot runtimeShadowRenderSlotForInstruction(
  ShadowRuntimeRenderInstruction instruction,
) =>
    runtimeShadowRenderSlotForPass(instruction.renderPass);

String _normalizeColorHexRgb(String value) {
  if (!_colorHexRgbPattern.hasMatch(value)) {
    throw const ValidationException(
      'ShadowRuntimeRenderInstruction.colorHexRgb must be a 6-character RGB hex string without #',
    );
  }
  return value.toUpperCase();
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'ShadowRuntimeRenderInstruction.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'ShadowRuntimeRenderInstruction.$name must be greater than 0',
    );
  }
}

void _validateOpacity(double value) {
  _validateFinite(value, 'opacity');
  if (value < 0 || value > 1) {
    throw const ValidationException(
      'ShadowRuntimeRenderInstruction.opacity must be between 0 and 1',
    );
  }
}

void _validateSoftnessMode(ShadowSoftnessMode value) {
  if (value != ShadowSoftnessMode.hardEdge) {
    throw const ValidationException(
      'ShadowRuntimeRenderInstruction.softnessMode only supports hardEdge in V0',
    );
  }
}
