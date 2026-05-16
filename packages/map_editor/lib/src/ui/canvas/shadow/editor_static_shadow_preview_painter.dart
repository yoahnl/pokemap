import 'dart:ui' as ui;

import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';
import 'package:map_core/map_core.dart';

void paintEditorStaticShadowPreviewInstructions(
  ui.Canvas canvas,
  Iterable<EditorStaticShadowPreviewInstruction> instructions,
) {
  for (final instruction in instructions) {
    if (instruction.opacity <= 0 ||
        instruction.width <= 0 ||
        instruction.height <= 0) {
      continue;
    }
    final color = _editorShadowPreviewColor(
      instruction.colorHexRgb,
      instruction.opacity,
    );
    if (color == null) {
      continue;
    }
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill
      ..isAntiAlias = false;
    switch (instruction.shape) {
      case EditorStaticShadowPreviewShapeKind.oval:
        canvas.drawOval(
          ui.Rect.fromLTWH(
            instruction.left,
            instruction.top,
            instruction.width,
            instruction.height,
          ),
          paint,
        );
      case EditorStaticShadowPreviewShapeKind.projectedPolygon:
        if (instruction.polygonPoints.length != 4) {
          final path = _pathFromEditorStaticShadowPreviewPoints(
            instruction.polygonPoints,
          );
          if (path != null) {
            canvas.drawPath(path, paint);
          }
          continue;
        }
        for (final band in createProjectedStaticShadowOpacityBands()) {
          final bandColor = _editorShadowPreviewColor(
            instruction.colorHexRgb,
            instruction.opacity * band.opacityScale,
          );
          if (bandColor == null) {
            continue;
          }
          final bandPaint = ui.Paint()
            ..color = bandColor
            ..style = ui.PaintingStyle.fill
            ..isAntiAlias = false;
          canvas.drawPath(
            _projectedEditorBandPath(instruction.polygonPoints, band),
            bandPaint,
          );
        }
    }
  }
}

ui.Path? _pathFromEditorStaticShadowPreviewPoints(
  List<EditorStaticShadowPreviewPoint> points,
) {
  if (points.length < 3) {
    return null;
  }
  final first = points.first;
  final path = ui.Path()..moveTo(first.x, first.y);
  for (final point in points.skip(1)) {
    path.lineTo(point.x, point.y);
  }
  path.close();
  return path;
}

ui.Path _projectedEditorBandPath(
  List<EditorStaticShadowPreviewPoint> points,
  ProjectedStaticShadowOpacityBand band,
) {
  final nearLeft = points[0];
  final nearRight = points[1];
  final farRight = points[2];
  final farLeft = points[3];
  final leftStart = _lerpEditorPoint(nearLeft, farLeft, band.startT);
  final rightStart = _lerpEditorPoint(nearRight, farRight, band.startT);
  final rightEnd = _lerpEditorPoint(nearRight, farRight, band.endT);
  final leftEnd = _lerpEditorPoint(nearLeft, farLeft, band.endT);
  return ui.Path()
    ..moveTo(leftStart.x, leftStart.y)
    ..lineTo(rightStart.x, rightStart.y)
    ..lineTo(rightEnd.x, rightEnd.y)
    ..lineTo(leftEnd.x, leftEnd.y)
    ..close();
}

EditorStaticShadowPreviewPoint _lerpEditorPoint(
  EditorStaticShadowPreviewPoint first,
  EditorStaticShadowPreviewPoint second,
  double t,
) {
  return EditorStaticShadowPreviewPoint(
    x: first.x + (second.x - first.x) * t,
    y: first.y + (second.y - first.y) * t,
  );
}

ui.Color? _editorShadowPreviewColor(String colorHexRgb, double opacity) {
  final normalized = colorHexRgb.trim();
  if (normalized.length != 6) {
    return null;
  }
  final rgb = int.tryParse(normalized, radix: 16);
  if (rgb == null) {
    return null;
  }
  final clampedOpacity = opacity.clamp(0.0, 1.0).toDouble();
  final alpha = (clampedOpacity * 255).round().clamp(0, 255);
  return ui.Color((alpha << 24) | rgb);
}
