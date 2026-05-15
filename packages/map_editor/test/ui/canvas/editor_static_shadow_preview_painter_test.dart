import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';
import 'package:map_editor/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart';

void main() {
  group('paintEditorStaticShadowPreviewInstructions', () {
    test('draws a non-transparent center pixel', () async {
      final pixel = await _paintAndReadPixel(
        const EditorStaticShadowPreviewInstruction(
          instanceId: 'stand_1',
          elementId: 'stand',
          shape: ShadowCasterMode.ellipse,
          left: 8,
          top: 8,
          width: 24,
          height: 16,
          opacity: 0.5,
          colorHexRgb: '000000',
        ),
        x: 20,
        y: 16,
      );

      expect(pixel.alpha, greaterThan(0));
    });

    test('opacity zero does not color the pixel', () async {
      final pixel = await _paintAndReadPixel(
        const EditorStaticShadowPreviewInstruction(
          instanceId: 'stand_1',
          elementId: 'stand',
          shape: ShadowCasterMode.ellipse,
          left: 8,
          top: 8,
          width: 24,
          height: 16,
          opacity: 0,
          colorHexRgb: '000000',
        ),
        x: 20,
        y: 16,
      );

      expect(pixel.alpha, 0);
    });

    test('empty instructions do not throw', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      paintEditorStaticShadowPreviewInstructions(canvas, const []);

      final picture = recorder.endRecording();
      picture.dispose();
    });
  });
}

Future<_Pixel> _paintAndReadPixel(
  EditorStaticShadowPreviewInstruction instruction, {
  required int x,
  required int y,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  paintEditorStaticShadowPreviewInstructions(canvas, [instruction]);
  final picture = recorder.endRecording();
  final image = await picture.toImage(48, 48);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  picture.dispose();
  image.dispose();
  final data = bytes!;
  final index = ((y * 48) + x) * 4;
  return _Pixel(
    red: data.getUint8(index),
    green: data.getUint8(index + 1),
    blue: data.getUint8(index + 2),
    alpha: data.getUint8(index + 3),
  );
}

final class _Pixel {
  const _Pixel({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  final int red;
  final int green;
  final int blue;
  final int alpha;
}
