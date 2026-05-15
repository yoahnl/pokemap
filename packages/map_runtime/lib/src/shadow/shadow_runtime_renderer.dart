import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'shadow_runtime_instruction_collection.dart';
import 'shadow_runtime_render_instruction.dart';

final class ShadowRuntimeRenderer {
  const ShadowRuntimeRenderer();

  void renderInstruction(
    ui.Canvas canvas,
    ShadowRuntimeRenderInstruction instruction,
  ) {
    _validateHardEdge(instruction);
    final rect = ui.Rect.fromLTWH(
      instruction.worldLeft,
      instruction.worldTop,
      instruction.width,
      instruction.height,
    );
    canvas.drawOval(rect, shadowRuntimePaintForInstruction(instruction));
  }

  void renderInstructions(
    ui.Canvas canvas,
    Iterable<ShadowRuntimeRenderInstruction> instructions,
  ) {
    for (final instruction in instructions) {
      renderInstruction(canvas, instruction);
    }
  }

  void renderCollectionPass(
    ui.Canvas canvas,
    ShadowRuntimeInstructionCollection collection,
    ShadowRenderPass pass,
  ) {
    final instructions = switch (pass) {
      ShadowRenderPass.groundStatic => collection.groundStatic,
      ShadowRenderPass.actorContact => collection.actorContact,
    };
    renderInstructions(canvas, instructions);
  }
}

ui.Color shadowRuntimeColorForInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  final rgb = int.parse(instruction.colorHexRgb, radix: 16);
  final alpha = (instruction.opacity * 255).round().clamp(0, 255).toInt();
  return ui.Color((alpha << 24) | rgb);
}

ui.Paint shadowRuntimePaintForInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  _validateHardEdge(instruction);
  return ui.Paint()
    ..style = ui.PaintingStyle.fill
    ..isAntiAlias = false
    ..color = shadowRuntimeColorForInstruction(instruction);
}

void _validateHardEdge(ShadowRuntimeRenderInstruction instruction) {
  if (instruction.softnessMode != ShadowSoftnessMode.hardEdge) {
    throw const ValidationException(
      'ShadowRuntimeRenderer only supports hardEdge shadows in V0',
    );
  }
}
