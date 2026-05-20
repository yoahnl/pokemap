import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart' show ShadowRenderPass;
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

const _artifactWidth = 320;
const _artifactHeight = 224;
const _panelWidth = 160;
const _panelHeight = 224;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png';

const _backgroundColor = ui.Color(0xFFD8E0C8);
const _gridColor = ui.Color(0xFFE6ECD8);
const _dividerColor = ui.Color(0xFFB5BEA7);
const _buildingBodyColor = ui.Color(0xFFE9D7B9);
const _buildingRoofColor = ui.Color(0xFFB7655A);
const _buildingOutlineColor = ui.Color(0xFF343A3D);
const _buildingDoorColor = ui.Color(0xFF7E5547);
const _buildingWindowColor = ui.Color(0xFF8EC6D8);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow V2 micro visual artifact',
      () async {
    final image = await _renderArtifact();
    expect(image.width, _artifactWidth);
    expect(image.height, _artifactHeight);

    final backgroundPixel = await _pixelAt(image, 12, 12);
    final shadowPixel = await _pixelAt(image, 80, 150);
    final buildingOverShadowPixel = await _pixelAt(image, _panelWidth + 80, 150);

    expect(backgroundPixel, _rgba(_backgroundColor));
    expect(shadowPixel, isNot(backgroundPixel));
    expect(shadowPixel.a, 255);
    expect(buildingOverShadowPixel, _rgba(_buildingBodyColor));
    expect(buildingOverShadowPixel, isNot(shadowPixel));

    final pngBytes = await _pngBytes(image);
    await _writePng(pngBytes);

    final file = File(_artifactPath);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
  });
}

// Manual artifact harness: this intentionally writes one PNG for human review
// of the calibrated V2 hard-edge banding. It is not a golden comparison.
Future<ui.Image> _renderArtifact() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  _drawPanelBackground(canvas, 0);
  _drawPanelBackground(canvas, _panelWidth.toDouble());

  canvas.drawRect(
    ui.Rect.fromLTWH(_panelWidth.toDouble() - 0.5, 0, 1, _artifactHeight + 0.0),
    ui.Paint()..color = _dividerColor,
  );

  _drawShadow(canvas, panelLeft: 0);
  _drawShadow(canvas, panelLeft: _panelWidth.toDouble());
  _drawSimpleBuilding(canvas, panelLeft: _panelWidth.toDouble());

  return recorder.endRecording().toImage(_artifactWidth, _artifactHeight);
}

void _drawPanelBackground(ui.Canvas canvas, double panelLeft) {
  canvas.drawRect(
    ui.Rect.fromLTWH(panelLeft, 0, _panelWidth.toDouble(), _panelHeight + 0.0),
    ui.Paint()..color = _backgroundColor,
  );
  _drawGrid(canvas, panelLeft: panelLeft);
}

void _drawGrid(ui.Canvas canvas, {required double panelLeft}) {
  final paint = ui.Paint()
    ..color = _gridColor
    ..strokeWidth = 1;

  for (var x = 32.0; x < _panelWidth; x += 32) {
    canvas.drawLine(
      ui.Offset(panelLeft + x, 0),
      ui.Offset(panelLeft + x, _panelHeight.toDouble()),
      paint,
    );
  }
  for (var y = 32.0; y < _panelHeight; y += 32) {
    canvas.drawLine(
      ui.Offset(panelLeft, y),
      ui.Offset(panelLeft + _panelWidth, y),
      paint,
    );
  }
}

void _drawShadow(ui.Canvas canvas, {required double panelLeft}) {
  canvas.save();
  canvas.translate(panelLeft, 0);
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    _calibratedShadowCollection(),
    ShadowRenderPass.groundStatic,
  );
  canvas.restore();
}

ShadowRuntimeInstructionCollection _calibratedShadowCollection() {
  return ShadowRuntimeInstructionCollection(
    instructions: [_calibratedShadowInstruction()],
  );
}

ShadowRuntimeRenderInstruction _calibratedShadowInstruction() {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.projectedPolygon,
    renderPass: ShadowRenderPass.groundStatic,
    worldLeft: 52.46,
    worldTop: 129.77,
    width: 48.92,
    height: 59.81,
    opacity: 0.30,
    colorHexRgb: '606060',
    polygonPoints: [
      ShadowRuntimePoint(worldX: 75.54, worldY: 129.77),
      ShadowRuntimePoint(worldX: 52.46, worldY: 182.55),
      ShadowRuntimePoint(worldX: 82.91, worldY: 189.58),
      ShadowRuntimePoint(worldX: 101.38, worldY: 147.36),
    ],
  );
}

void _drawSimpleBuilding(ui.Canvas canvas, {required double panelLeft}) {
  final left = panelLeft + 32;
  const top = 64.0;
  const width = 64.0;
  const height = 96.0;

  final body = ui.Rect.fromLTWH(left, top, width, height);
  canvas.drawRect(body, ui.Paint()..color = _buildingBodyColor);

  final roof = ui.Rect.fromLTWH(left, top, width, 22);
  canvas.drawRect(roof, ui.Paint()..color = _buildingRoofColor);

  final door = ui.Rect.fromLTWH(left + 26, top + 62, 12, 32);
  canvas.drawRect(door, ui.Paint()..color = _buildingDoorColor);

  final windowPaint = ui.Paint()..color = _buildingWindowColor;
  canvas.drawRect(ui.Rect.fromLTWH(left + 10, top + 36, 14, 12), windowPaint);
  canvas.drawRect(ui.Rect.fromLTWH(left + 40, top + 36, 14, 12), windowPaint);

  final outline = ui.Paint()
    ..color = _buildingOutlineColor
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..isAntiAlias = false;
  canvas.drawRect(body, outline);
  canvas.drawLine(
    ui.Offset(left, top + 22),
    ui.Offset(left + width, top + 22),
    outline,
  );
}

Future<Uint8List> _pngBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode ShadowV2 micro visual artifact as PNG');
  }
  return byteData.buffer.asUint8List(
    byteData.offsetInBytes,
    byteData.lengthInBytes,
  );
}

Future<void> _writePng(Uint8List bytes) async {
  final file = File(_artifactPath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
}

Future<_Rgba> _pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) {
    throw StateError('Could not read raw pixels from artifact image');
  }
  final offset = (y * image.width + x) * 4;
  return _Rgba(
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  );
}

_Rgba _rgba(ui.Color color) {
  return _Rgba(
    _colorChannelByte(color.r),
    _colorChannelByte(color.g),
    _colorChannelByte(color.b),
    _colorChannelByte(color.a),
  );
}

int _colorChannelByte(double channel) {
  return (channel * 255.0).round().clamp(0, 255).toInt();
}

final class _Rgba {
  const _Rgba(this.r, this.g, this.b, this.a);

  final int r;
  final int g;
  final int b;
  final int a;

  @override
  bool operator ==(Object other) {
    return other is _Rgba &&
        other.r == r &&
        other.g == g &&
        other.b == b &&
        other.a == a;
  }

  @override
  int get hashCode => Object.hash(r, g, b, a);

  @override
  String toString() => 'rgba($r, $g, $b, $a)';
}
