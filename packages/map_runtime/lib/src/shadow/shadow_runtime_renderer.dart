import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'shadow_runtime_instruction_collection.dart';
import 'shadow_runtime_render_instruction.dart';

/// Opacity bands never vary at runtime; building them per polygon per frame
/// was pure waste.
final List<ProjectedStaticShadowOpacityBand> _defaultProjectedOpacityBands =
    createProjectedStaticShadowOpacityBands();

/// Instructions are immutable and identity-stable across frames (collections
/// are built once per map and the merged provider is cached), so paths and
/// paints are baked once per instruction. Expando keys are weak: unloading a
/// map releases the baked data together with its instructions.
final Expando<_BakedShadowInstruction> _bakedShadowInstructionCache =
    Expando<_BakedShadowInstruction>('bakedShadowInstruction');

final class ShadowRuntimeRenderer {
  const ShadowRuntimeRenderer();

  void renderInstruction(
    ui.Canvas canvas,
    ShadowRuntimeRenderInstruction instruction,
  ) {
    _validateHardEdge(instruction);
    final baked = _bakedShadowInstructionCache[instruction] ??=
        _bakeShadowInstruction(instruction);
    baked.draw(canvas);
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
    ShadowRenderPass pass, {
    ShadowRuntimeCullingBounds? cullingBounds,
  }) {
    final instructions = switch (pass) {
      ShadowRenderPass.groundStatic => collection.groundStatic,
      ShadowRenderPass.actorContact => collection.actorContact,
    };
    if (cullingBounds == null) {
      renderInstructions(canvas, instructions);
      return;
    }
    for (final instruction in instructions) {
      if (shadowRuntimeInstructionIntersectsBounds(
        instruction,
        cullingBounds,
      )) {
        renderInstruction(canvas, instruction);
      }
    }
  }
}

ui.Color shadowRuntimeColorForInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  return _shadowColor(instruction.colorRgbValue, instruction.opacity);
}

ui.Paint shadowRuntimePaintForInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  _validateHardEdge(instruction);
  return _shadowPaint(instruction.colorRgbValue, instruction.opacity);
}

ui.Color _shadowColor(int rgb, double opacity) {
  final alpha = (opacity * 255).round().clamp(0, 255).toInt();
  return ui.Color((alpha << 24) | rgb);
}

ui.Paint _shadowPaint(int rgb, double opacity) {
  return ui.Paint()
    ..style = ui.PaintingStyle.fill
    ..isAntiAlias = false
    ..color = _shadowColor(rgb, opacity);
}

void _validateHardEdge(ShadowRuntimeRenderInstruction instruction) {
  if (instruction.softnessMode != ShadowSoftnessMode.hardEdge) {
    throw const ValidationException(
      'ShadowRuntimeRenderer only supports hardEdge shadows in V0',
    );
  }
}

final class _BakedShadowInstruction {
  const _BakedShadowInstruction({
    this.ovalRect,
    this.ovalPaint,
    this.paths = const [],
    this.pathPaints = const [],
  });

  final ui.Rect? ovalRect;
  final ui.Paint? ovalPaint;
  final List<ui.Path> paths;
  final List<ui.Paint> pathPaints;

  void draw(ui.Canvas canvas) {
    final rect = ovalRect;
    if (rect != null) {
      canvas.drawOval(rect, ovalPaint!);
      return;
    }
    for (var index = 0; index < paths.length; index += 1) {
      canvas.drawPath(paths[index], pathPaints[index]);
    }
  }
}

_BakedShadowInstruction _bakeShadowInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  switch (instruction.shape) {
    case ShadowRuntimeShapeKind.contactBlob:
    case ShadowRuntimeShapeKind.ellipse:
      return _BakedShadowInstruction(
        ovalRect: ui.Rect.fromLTWH(
          instruction.worldLeft,
          instruction.worldTop,
          instruction.width,
          instruction.height,
        ),
        ovalPaint: shadowRuntimePaintForInstruction(instruction),
      );
    case ShadowRuntimeShapeKind.projectedPolygon:
      final points = instruction.polygonPoints;
      if (points.length != 4) {
        return _BakedShadowInstruction(
          paths: [_pathFromRuntimePoints(points)],
          pathPaints: [shadowRuntimePaintForInstruction(instruction)],
        );
      }
      final paths = <ui.Path>[];
      final paints = <ui.Paint>[];
      for (final band in _defaultProjectedOpacityBands) {
        paths.add(_projectedRuntimeBandPath(points, band));
        paints.add(
          _shadowPaint(
            instruction.colorRgbValue,
            instruction.opacity * band.opacityScale,
          ),
        );
      }
      return _BakedShadowInstruction(paths: paths, pathPaints: paints);
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
