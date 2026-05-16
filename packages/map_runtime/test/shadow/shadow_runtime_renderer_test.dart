import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shadowRuntimeColorForInstruction', () {
    test('converts RGB hex and opacity to runtime color', () {
      final color = shadowRuntimeColorForInstruction(
        _instruction(colorHexRgb: '336699', opacity: 1),
      );

      expect(color, const ui.Color(0xFF336699));
    });

    test('converts opacity zero to transparent color', () {
      final color = shadowRuntimeColorForInstruction(
        _instruction(colorHexRgb: '336699', opacity: 0),
      );

      expect(color, const ui.Color(0x00336699));
    });

    test('uses stable rounded alpha for fractional opacity', () {
      final color = shadowRuntimeColorForInstruction(
        _instruction(colorHexRgb: '000000', opacity: 0.35),
      );

      expect(color, const ui.Color(0x59000000));
    });
  });

  group('shadowRuntimePaintForInstruction', () {
    test('creates a hard-edge fill paint', () {
      final paint = shadowRuntimePaintForInstruction(_instruction());

      expect(paint.style, ui.PaintingStyle.fill);
      expect(paint.isAntiAlias, isFalse);
      expect(paint.color.toARGB32(), 0x59000000);
    });

    test('accepts hardEdge softness', () {
      expect(
        () => shadowRuntimePaintForInstruction(
          _instruction(softnessMode: ShadowSoftnessMode.hardEdge),
        ),
        returnsNormally,
      );
    });
  });

  group('ShadowRuntimeRenderer.renderInstruction', () {
    test('draws an ellipse with visible center and transparent outside pixels',
        () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.ellipse,
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 1,
        ),
      );

      expect(await _alphaAt(image, 10, 8), greaterThan(0));
      expect(await _alphaAt(image, 1, 1), 0);
    });

    test('draws contactBlob through the same V0 oval path', () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.contactBlob,
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 1,
        ),
      );

      expect(await _alphaAt(image, 10, 8), greaterThan(0));
      expect(await _alphaAt(image, 1, 1), 0);
    });

    test('keeps opacity zero transparent at the center', () async {
      final image = await _renderInstruction(
        _instruction(
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 0,
        ),
      );

      expect(await _alphaAt(image, 10, 8), 0);
    });

    test('draws projectedPolygon with visible interior and transparent outside',
        () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          worldLeft: 2,
          worldTop: 4,
          width: 18,
          height: 8,
          opacity: 1,
          polygonPoints: _polygonPoints(),
        ),
      );

      expect(await _alphaAt(image, 10, 8), greaterThan(0));
      expect(await _alphaAt(image, 1, 1), 0);
    });

    test('keeps projectedPolygon opacity zero transparent inside', () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          worldLeft: 2,
          worldTop: 4,
          width: 18,
          height: 8,
          opacity: 0,
          polygonPoints: _polygonPoints(),
        ),
      );

      expect(await _alphaAt(image, 10, 8), 0);
    });

    test('draws projectedPolygon with stronger near alpha than far alpha',
        () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          worldLeft: 6,
          worldTop: 6,
          width: 28,
          height: 30,
          opacity: 1,
          polygonPoints: [
            ShadowRuntimePoint(worldX: 10, worldY: 10),
            ShadowRuntimePoint(worldX: 26, worldY: 10),
            ShadowRuntimePoint(worldX: 34, worldY: 34),
            ShadowRuntimePoint(worldX: 6, worldY: 34),
          ],
        ),
        width: 48,
        height: 48,
      );

      final nearAlpha = await _alphaAt(image, 18, 12);
      final farAlpha = await _alphaAt(image, 20, 32);

      expect(nearAlpha, greaterThan(farAlpha));
      expect(farAlpha, greaterThan(0));
    });

    test('projectedPolygon fallback still draws non four point polygons',
        () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          worldLeft: 6,
          worldTop: 6,
          width: 28,
          height: 30,
          opacity: 1,
          polygonPoints: [
            ShadowRuntimePoint(worldX: 10, worldY: 10),
            ShadowRuntimePoint(worldX: 26, worldY: 10),
            ShadowRuntimePoint(worldX: 34, worldY: 22),
            ShadowRuntimePoint(worldX: 26, worldY: 34),
            ShadowRuntimePoint(worldX: 6, worldY: 34),
          ],
        ),
        width: 48,
        height: 48,
      );

      expect(await _alphaAt(image, 20, 20), greaterThan(0));
    });
  });

  group('ShadowRuntimeRenderer.renderInstructions', () {
    test('draws multiple instructions in input order', () async {
      final image = await _renderInstructions([
        _instruction(
          worldLeft: 2,
          worldTop: 2,
          width: 8,
          height: 8,
          opacity: 1,
          colorHexRgb: 'FF0000',
        ),
        _instruction(
          worldLeft: 2,
          worldTop: 2,
          width: 8,
          height: 8,
          opacity: 1,
          colorHexRgb: '0000FF',
        ),
      ]);

      expect(await _rgbaAt(image, 6, 6), _rgba(0, 0, 255, 255));
    });

    test('draws projectedPolygon and ellipse in input order', () async {
      final image = await _renderInstructions([
        _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          worldLeft: 2,
          worldTop: 4,
          width: 18,
          height: 8,
          opacity: 1,
          colorHexRgb: 'FF0000',
          polygonPoints: _polygonPoints(),
        ),
        _instruction(
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 1,
          colorHexRgb: '0000FF',
        ),
      ]);

      expect(await _rgbaAt(image, 10, 8), _rgba(0, 0, 255, 255));
    });
  });

  group('ShadowRuntimeRenderer.renderCollectionPass', () {
    test('draws only groundStatic instructions for the groundStatic pass',
        () async {
      final ground = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );
      final actor = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 14,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );

      final image = await _renderCollectionPass(
        ShadowRuntimeInstructionCollection(instructions: [ground, actor]),
        ShadowRenderPass.groundStatic,
      );

      expect(await _alphaAt(image, 6, 6), greaterThan(0));
      expect(await _alphaAt(image, 18, 6), 0);
    });

    test('draws only actorContact instructions for the actorContact pass',
        () async {
      final ground = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );
      final actor = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 14,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );

      final image = await _renderCollectionPass(
        ShadowRuntimeInstructionCollection(instructions: [ground, actor]),
        ShadowRenderPass.actorContact,
      );

      expect(await _alphaAt(image, 6, 6), 0);
      expect(await _alphaAt(image, 18, 6), greaterThan(0));
    });

    test('filters projectedPolygon instructions by render pass', () async {
      final ground = _instruction(
        shape: ShadowRuntimeShapeKind.projectedPolygon,
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
        worldTop: 4,
        width: 18,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
        polygonPoints: _polygonPoints(),
      );
      final actor = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 14,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );

      final image = await _renderCollectionPass(
        ShadowRuntimeInstructionCollection(instructions: [ground, actor]),
        ShadowRenderPass.actorContact,
      );

      expect(await _alphaAt(image, 10, 8), 0);
      expect(await _alphaAt(image, 18, 6), greaterThan(0));
    });
  });
}

ShadowRuntimeRenderInstruction _instruction({
  ShadowRuntimeShapeKind shape = ShadowRuntimeShapeKind.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double worldLeft = 0,
  double worldTop = 0,
  double width = 8,
  double height = 4,
  double opacity = 0.35,
  String colorHexRgb = '000000',
  ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
  List<ShadowRuntimePoint> polygonPoints = const [],
}) {
  return ShadowRuntimeRenderInstruction(
    shape: shape,
    renderPass: renderPass,
    worldLeft: worldLeft,
    worldTop: worldTop,
    width: width,
    height: height,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
    softnessMode: softnessMode,
    polygonPoints: polygonPoints,
  );
}

List<ShadowRuntimePoint> _polygonPoints() {
  return [
    ShadowRuntimePoint(worldX: 4, worldY: 4),
    ShadowRuntimePoint(worldX: 16, worldY: 4),
    ShadowRuntimePoint(worldX: 20, worldY: 12),
    ShadowRuntimePoint(worldX: 2, worldY: 12),
  ];
}

Future<ui.Image> _renderInstruction(
  ShadowRuntimeRenderInstruction instruction, {
  int width = 24,
  int height = 16,
}) {
  return _renderInstructions([instruction], width: width, height: height);
}

Future<ui.Image> _renderInstructions(
  Iterable<ShadowRuntimeRenderInstruction> instructions, {
  int width = 24,
  int height = 16,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const ShadowRuntimeRenderer().renderInstructions(canvas, instructions);
  return recorder.endRecording().toImage(width, height);
}

Future<ui.Image> _renderCollectionPass(
  ShadowRuntimeInstructionCollection collection,
  ShadowRenderPass pass,
) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const ShadowRuntimeRenderer().renderCollectionPass(canvas, collection, pass);
  return recorder.endRecording().toImage(24, 16);
}

Future<int> _alphaAt(ui.Image image, int x, int y) async {
  return (await _rgbaAt(image, x, y))[3];
}

Future<List<int>> _rgbaAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return [
    data!.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}

List<int> _rgba(int red, int green, int blue, int alpha) {
  return [red, green, blue, alpha];
}
