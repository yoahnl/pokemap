import 'package:map_core/map_core.dart';

import 'shadow_runtime_render_instruction.dart';

/// World-space rectangle used to cull runtime shadow instructions.
final class ShadowRuntimeCullingBounds {
  ShadowRuntimeCullingBounds({
    required this.worldLeft,
    required this.worldTop,
    required this.width,
    required this.height,
  }) {
    _validateFinite(worldLeft, 'worldLeft');
    _validateFinite(worldTop, 'worldTop');
    _validatePositiveFinite(width, 'width');
    _validatePositiveFinite(height, 'height');
  }

  final double worldLeft;
  final double worldTop;
  final double width;
  final double height;

  double get worldRight => worldLeft + width;

  double get worldBottom => worldTop + height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowRuntimeCullingBounds &&
          other.worldLeft == worldLeft &&
          other.worldTop == worldTop &&
          other.width == width &&
          other.height == height;

  @override
  int get hashCode => Object.hash(
        worldLeft,
        worldTop,
        width,
        height,
      );
}

/// Immutable runtime shadow instruction grouping after optional culling.
final class ShadowRuntimeInstructionCollection {
  factory ShadowRuntimeInstructionCollection({
    Iterable<ShadowRuntimeRenderInstruction> instructions = const [],
  }) {
    final source = List<ShadowRuntimeRenderInstruction>.of(instructions);
    final groundStatic = <ShadowRuntimeRenderInstruction>[];
    final actorContact = <ShadowRuntimeRenderInstruction>[];
    for (final instruction in source) {
      switch (instruction.renderPass) {
        case ShadowRenderPass.groundStatic:
          groundStatic.add(instruction);
        case ShadowRenderPass.actorContact:
          actorContact.add(instruction);
      }
    }
    return ShadowRuntimeInstructionCollection._(
      instructions:
          List<ShadowRuntimeRenderInstruction>.unmodifiable(source),
      groundStatic:
          List<ShadowRuntimeRenderInstruction>.unmodifiable(groundStatic),
      actorContact:
          List<ShadowRuntimeRenderInstruction>.unmodifiable(actorContact),
    );
  }

  const ShadowRuntimeInstructionCollection._({
    required this.instructions,
    required this.groundStatic,
    required this.actorContact,
  });

  final List<ShadowRuntimeRenderInstruction> instructions;
  final List<ShadowRuntimeRenderInstruction> groundStatic;
  final List<ShadowRuntimeRenderInstruction> actorContact;

  bool get isEmpty => instructions.isEmpty;

  bool get isNotEmpty => instructions.isNotEmpty;

  int get length => instructions.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowRuntimeInstructionCollection &&
          _listEquals(other.instructions, instructions);

  @override
  int get hashCode => Object.hashAll(instructions);
}

bool shadowRuntimeInstructionIntersectsBounds(
  ShadowRuntimeRenderInstruction instruction,
  ShadowRuntimeCullingBounds bounds, {
  double padding = 0,
}) {
  _validatePadding(padding);

  final instructionRight = instruction.worldLeft + instruction.width;
  final instructionBottom = instruction.worldTop + instruction.height;
  final paddedLeft = bounds.worldLeft - padding;
  final paddedTop = bounds.worldTop - padding;
  final paddedRight = bounds.worldRight + padding;
  final paddedBottom = bounds.worldBottom + padding;

  return instructionRight >= paddedLeft &&
      instruction.worldLeft <= paddedRight &&
      instructionBottom >= paddedTop &&
      instruction.worldTop <= paddedBottom;
}

ShadowRuntimeInstructionCollection collectShadowRuntimeInstructions(
  Iterable<ShadowRuntimeRenderInstruction> instructions, {
  ShadowRuntimeCullingBounds? cullingBounds,
  double cullingPadding = 0,
}) {
  _validatePadding(cullingPadding);

  final retained = <ShadowRuntimeRenderInstruction>[];
  for (final instruction in instructions) {
    if (cullingBounds == null ||
        shadowRuntimeInstructionIntersectsBounds(
          instruction,
          cullingBounds,
          padding: cullingPadding,
        )) {
      retained.add(instruction);
    }
  }
  return ShadowRuntimeInstructionCollection(instructions: retained);
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'ShadowRuntimeCullingBounds.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'ShadowRuntimeCullingBounds.$name must be greater than 0',
    );
  }
}

void _validatePadding(double value) {
  if (!value.isFinite || value < 0) {
    throw const ValidationException(
      'Shadow runtime culling padding must be finite and greater than or equal to 0',
    );
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
