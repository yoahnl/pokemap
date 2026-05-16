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
    switch (instruction.shape) {
      case ShadowRuntimeShapeKind.contactBlob:
      case ShadowRuntimeShapeKind.ellipse:
        _renderOval(canvas, instruction);
      case ShadowRuntimeShapeKind.projectedPolygon:
        _renderProjectedPolygon(canvas, instruction);
    }
  }

  void _renderOval(
    ui.Canvas canvas,
    ShadowRuntimeRenderInstruction instruction,
  ) {
    final rect = ui.Rect.fromLTWH(
      instruction.worldLeft,
      instruction.worldTop,
      instruction.width,
      instruction.height,
    );
    canvas.drawOval(rect, shadowRuntimePaintForInstruction(instruction));
  }

  void _renderProjectedPolygon(
    ui.Canvas canvas,
    ShadowRuntimeRenderInstruction instruction,
  ) {
    final points = instruction.polygonPoints;
    if (points.length != 4) {
      canvas.drawPath(
        _pathFromRuntimePoints(points),
        shadowRuntimePaintForInstruction(instruction),
      );
      return;
    }
    for (final band in createProjectedStaticShadowOpacityBands()) {
      canvas.drawPath(
        _projectedRuntimeBandPath(points, band),
        shadowRuntimePaintForInstruction(
          _instructionWithOpacityScale(instruction, band.opacityScale),
        ),
      );
    }
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

ui.Path _pathFromRuntimePoints(List<ShadowRuntimePoint> points) {
  final path = ui.Path()..moveTo(points.first.worldX, points.first.worldY);
  for (final point in points.skip(1)) {
    path.lineTo(point.worldX, point.worldY);
  }
  return path..close();
}

ui.Path _projectedRuntimeBandPath(
  List<ShadowRuntimePoint> points,
  ProjectedStaticShadowOpacityBand band,
) {
  final nearLeft = points[0];
  final nearRight = points[1];
  final farRight = points[2];
  final farLeft = points[3];
  final leftStart = _lerpRuntimePoint(nearLeft, farLeft, band.startT);
  final rightStart = _lerpRuntimePoint(nearRight, farRight, band.startT);
  final rightEnd = _lerpRuntimePoint(nearRight, farRight, band.endT);
  final leftEnd = _lerpRuntimePoint(nearLeft, farLeft, band.endT);
  return ui.Path()
    ..moveTo(leftStart.worldX, leftStart.worldY)
    ..lineTo(rightStart.worldX, rightStart.worldY)
    ..lineTo(rightEnd.worldX, rightEnd.worldY)
    ..lineTo(leftEnd.worldX, leftEnd.worldY)
    ..close();
}

ShadowRuntimePoint _lerpRuntimePoint(
  ShadowRuntimePoint first,
  ShadowRuntimePoint second,
  double t,
) {
  return ShadowRuntimePoint(
    worldX: first.worldX + (second.worldX - first.worldX) * t,
    worldY: first.worldY + (second.worldY - first.worldY) * t,
  );
}

ShadowRuntimeRenderInstruction _instructionWithOpacityScale(
  ShadowRuntimeRenderInstruction instruction,
  double opacityScale,
) {
  return ShadowRuntimeRenderInstruction(
    shape: instruction.shape,
    renderPass: instruction.renderPass,
    worldLeft: instruction.worldLeft,
    worldTop: instruction.worldTop,
    width: instruction.width,
    height: instruction.height,
    opacity: instruction.opacity * opacityScale,
    colorHexRgb: instruction.colorHexRgb,
    softnessMode: instruction.softnessMode,
    polygonPoints: instruction.polygonPoints,
  );
}
