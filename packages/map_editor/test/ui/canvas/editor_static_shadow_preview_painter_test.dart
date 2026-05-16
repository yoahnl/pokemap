import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';
import 'package:map_editor/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart';

void main() {
  group('paintEditorStaticShadowPreviewInstructions', () {
    test('draws a projected polygon interior pixel', () async {
      final pixel = await _paintAndReadPixel(
        _projectedInstruction(),
        x: 20,
        y: 18,
      );

      expect(pixel.alpha, greaterThan(0));
    });

    test('projected polygon leaves outside pixel transparent', () async {
      final pixel = await _paintAndReadPixel(
        _projectedInstruction(),
        x: 4,
        y: 4,
      );

      expect(pixel.alpha, 0);
    });

    test('opacity zero does not color projected polygon pixel', () async {
      final pixel = await _paintAndReadPixel(
        _projectedInstruction(opacity: 0),
        x: 20,
        y: 18,
      );

      expect(pixel.alpha, 0);
    });

    test('projected polygon preview has stronger near alpha than far alpha',
        () async {
      final instruction = _projectedInstruction(
        polygonPoints: [
          EditorStaticShadowPreviewPoint(x: 10, y: 10),
          EditorStaticShadowPreviewPoint(x: 26, y: 10),
          EditorStaticShadowPreviewPoint(x: 34, y: 34),
          EditorStaticShadowPreviewPoint(x: 6, y: 34),
        ],
        opacity: 1,
      );
      final near = await _paintAndReadPixel(instruction, x: 18, y: 12);
      final far = await _paintAndReadPixel(instruction, x: 20, y: 32);

      expect(near.alpha, greaterThan(far.alpha));
      expect(far.alpha, greaterThan(0));
    });

    test('projected polygon preview fallback draws non four point polygons',
        () async {
      final pixel = await _paintAndReadPixel(
        _projectedInstruction(
          polygonPoints: [
            EditorStaticShadowPreviewPoint(x: 10, y: 10),
            EditorStaticShadowPreviewPoint(x: 26, y: 10),
            EditorStaticShadowPreviewPoint(x: 34, y: 22),
            EditorStaticShadowPreviewPoint(x: 26, y: 34),
            EditorStaticShadowPreviewPoint(x: 6, y: 34),
          ],
          opacity: 1,
        ),
        x: 20,
        y: 20,
      );

      expect(pixel.alpha, greaterThan(0));
    });

    test('draws an oval fallback instruction', () async {
      final pixel = await _paintAndReadPixel(
        EditorStaticShadowPreviewInstruction(
          instanceId: 'stand_1',
          elementId: 'stand',
          shape: EditorStaticShadowPreviewShapeKind.oval,
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

    test('empty instructions do not throw', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      paintEditorStaticShadowPreviewInstructions(canvas, const []);

      final picture = recorder.endRecording();
      picture.dispose();
    });
  });
}

EditorStaticShadowPreviewInstruction _projectedInstruction({
  double opacity = 0.5,
  List<EditorStaticShadowPreviewPoint>? polygonPoints,
}) {
  return EditorStaticShadowPreviewInstruction(
    instanceId: 'stand_1',
    elementId: 'stand',
    shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
    left: 8,
    top: 8,
    width: 28,
    height: 20,
    opacity: opacity,
    colorHexRgb: '000000',
    polygonPoints: polygonPoints ??
        [
          EditorStaticShadowPreviewPoint(x: 10, y: 12),
          EditorStaticShadowPreviewPoint(x: 24, y: 10),
          EditorStaticShadowPreviewPoint(x: 34, y: 28),
          EditorStaticShadowPreviewPoint(x: 12, y: 26),
        ],
  );
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
