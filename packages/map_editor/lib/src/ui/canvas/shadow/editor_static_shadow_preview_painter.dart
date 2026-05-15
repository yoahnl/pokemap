import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';

void paintEditorStaticShadowPreviewInstructions(
  ui.Canvas canvas,
  Iterable<EditorStaticShadowPreviewInstruction> instructions,
) {
  for (final instruction in instructions) {
    if (instruction.shape == ShadowCasterMode.none ||
        instruction.opacity <= 0 ||
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
    canvas.drawOval(
      ui.Rect.fromLTWH(
        instruction.left,
        instruction.top,
        instruction.width,
        instruction.height,
      ),
      ui.Paint()
        ..color = color
        ..style = ui.PaintingStyle.fill
        ..isAntiAlias = false,
    );
  }
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
