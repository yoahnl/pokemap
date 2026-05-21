import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart'
    show
        ProjectBuildingShadowPreset,
        ProjectElementProjectedBuildingShadowConfig,
        ProjectedBuildingShadowGeometry,
        ProjectedBuildingShadowGeometryMode,
        ProjectedBuildingShadowPoint,
        ProjectedShadowAnchor,
        ProjectedShadowAppearance,
        ProjectedShadowDirection,
        ProjectedShadowFootprintTuning,
        ProjectedShadowOffset,
        ProjectedShadowShapeTuning,
        ProjectedShadowTimeOfDayMode,
        ShadowRenderPass,
        StaticShadowVisualMetrics,
        resolveProjectedBuildingShadowGeometry;
import 'package:map_runtime/src/shadow/projected_building_shadow_runtime_adapter.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

const _artifactWidth = 480;
const _artifactHeight = 256;
const _columnWidth = 160;
const _headerHeight = 32;
const _visualHeight = 224;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png';

const _backgroundColor = ui.Color(0xFFD8E0C8);
const _gridColor = ui.Color(0xFFE6ECD8);
const _dividerColor = ui.Color(0xFFB5BEA7);
const _labelColor = ui.Color(0xFF343A3D);
const _buildingBodyColor = ui.Color(0xFFE9D7B9);
const _buildingRoofColor = ui.Color(0xFFB7655A);
const _buildingOutlineColor = ui.Color(0xFF343A3D);
const _buildingDoorColor = ui.Color(0xFF7E5547);
const _buildingWindowColor = ui.Color(0xFF8EC6D8);

final _metrics = StaticShadowVisualMetrics(
  left: 32,
  top: 64,
  visualWidth: 64,
  visualHeight: 96,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow footprint micro visual artifact',
      () async {
    final image = await _renderArtifact();
    expect(image.width, _artifactWidth);
    expect(image.height, _artifactHeight);

    final backgroundPixel = await _pixelAt(image, 12, _headerHeight + 12);
    expect(backgroundPixel, _rgba(_backgroundColor));

    final directionalShadowPixel =
        await _pixelAt(image, 80, _headerHeight + 182);
    expect(directionalShadowPixel, isNot(backgroundPixel));

    final footprintOnlyPixel =
        await _pixelAt(image, _columnWidth + 64, _headerHeight + 160);
    expect(footprintOnlyPixel, isNot(backgroundPixel));

    final footprintBelowBuildingPixel =
        await _pixelAt(image, (_columnWidth * 2) + 90, _headerHeight + 166);
    expect(footprintBelowBuildingPixel, isNot(backgroundPixel));

    final buildingBodyPixel =
        await _pixelAt(image, (_columnWidth * 2) + 80, _headerHeight + 120);
    expect(buildingBodyPixel, _rgba(_buildingBodyColor));

    final footprintGeometry = _geometryFor(
      preset: _footprintPreset(),
      config: _footprintConfig(),
    );
    expect(footprintGeometry.points, hasLength(4));
    _expectPointClose(footprintGeometry.points[0], x: 28.80, y: 146.56);
    _expectPointClose(footprintGeometry.points[1], x: 99.20, y: 146.56);
    _expectPointClose(footprintGeometry.points[2], x: 108.80, y: 173.44);
    _expectPointClose(footprintGeometry.points[3], x: 32.00, y: 173.44);

    final pngBytes = await _pngBytes(image);
    await _writePng(pngBytes);

    final file = File(_artifactPath);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
  });
}

// Manual artifact harness: writes one PNG for human visual review.
// It is not a golden test and does not compare against any image file.
Future<ui.Image> _renderArtifact() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, _artifactWidth + 0.0, _artifactHeight + 0.0),
    ui.Paint()..color = _backgroundColor,
  );

  for (var index = 0; index < 3; index += 1) {
    final columnLeft = (index * _columnWidth).toDouble();
    _drawCandidateLabel(canvas, _labelForIndex(index), columnLeft: columnLeft);
    _drawPanelBackground(canvas, columnLeft);
  }

  _drawShadow(
    canvas,
    collection: _collectionFor(
      preset: _directionalPreset(),
      config: _directionalConfig(),
    ),
    columnLeft: 0,
  );
  _drawSimpleBuilding(canvas, columnLeft: 0);

  _drawShadow(
    canvas,
    collection: _collectionFor(
      preset: _footprintPreset(),
      config: _footprintConfig(),
    ),
    columnLeft: _columnWidth.toDouble(),
  );

  _drawShadow(
    canvas,
    collection: _collectionFor(
      preset: _footprintPreset(),
      config: _footprintConfig(),
    ),
    columnLeft: (_columnWidth * 2).toDouble(),
  );
  _drawSimpleBuilding(canvas, columnLeft: (_columnWidth * 2).toDouble());

  _drawDividers(canvas);

  return recorder.endRecording().toImage(_artifactWidth, _artifactHeight);
}

void _drawPanelBackground(ui.Canvas canvas, double columnLeft) {
  canvas.drawRect(
    ui.Rect.fromLTWH(
      columnLeft,
      _headerHeight.toDouble(),
      _columnWidth.toDouble(),
      _visualHeight.toDouble(),
    ),
    ui.Paint()..color = _backgroundColor,
  );
  _drawGrid(canvas, columnLeft: columnLeft);
}

void _drawGrid(ui.Canvas canvas, {required double columnLeft}) {
  final paint = ui.Paint()
    ..color = _gridColor
    ..strokeWidth = 1;

  for (var x = 32.0; x < _columnWidth; x += 32) {
    canvas.drawLine(
      ui.Offset(columnLeft + x, _headerHeight.toDouble()),
      ui.Offset(columnLeft + x, _artifactHeight.toDouble()),
      paint,
    );
  }
  for (var y = 32.0; y < _visualHeight; y += 32) {
    canvas.drawLine(
      ui.Offset(columnLeft, _headerHeight + y),
      ui.Offset(columnLeft + _columnWidth, _headerHeight + y),
      paint,
    );
  }
}

void _drawDividers(ui.Canvas canvas) {
  final paint = ui.Paint()
    ..color = _dividerColor
    ..strokeWidth = 1;

  canvas.drawLine(
    const ui.Offset(0, _headerHeight - 0.5),
    const ui.Offset(_artifactWidth + 0.0, _headerHeight - 0.5),
    paint,
  );
  for (var x = _columnWidth.toDouble(); x < _artifactWidth; x += _columnWidth) {
    canvas.drawLine(
      ui.Offset(x - 0.5, 0),
      ui.Offset(x - 0.5, _artifactHeight.toDouble()),
      paint,
    );
  }
}

void _drawShadow(
  ui.Canvas canvas, {
  required ShadowRuntimeInstructionCollection collection,
  required double columnLeft,
}) {
  canvas.save();
  canvas.translate(columnLeft, _headerHeight.toDouble());
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    collection,
    ShadowRenderPass.groundStatic,
  );
  canvas.restore();
}

ShadowRuntimeInstructionCollection _collectionFor({
  required ProjectBuildingShadowPreset preset,
  required ProjectElementProjectedBuildingShadowConfig config,
}) {
  return ShadowRuntimeInstructionCollection(
    instructions: [_instructionFor(preset: preset, config: config)],
  );
}

ShadowRuntimeRenderInstruction _instructionFor({
  required ProjectBuildingShadowPreset preset,
  required ProjectElementProjectedBuildingShadowConfig config,
}) {
  return createProjectedBuildingShadowRuntimeInstruction(
    _geometryFor(preset: preset, config: config),
  );
}

ProjectedBuildingShadowGeometry _geometryFor({
  required ProjectBuildingShadowPreset preset,
  required ProjectElementProjectedBuildingShadowConfig config,
}) {
  final geometry = resolveProjectedBuildingShadowGeometry(
    config: config,
    preset: preset,
    metrics: _metrics,
  );
  if (geometry == null) {
    throw StateError('${preset.id} did not produce geometry');
  }
  return geometry;
}

ProjectBuildingShadowPreset _directionalPreset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-v0',
    name: 'Pokemon-like building shadow V0',
    geometryMode: ProjectedBuildingShadowGeometryMode.directional,
    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.32,
      nearWidthRatio: 0.90,
      farWidthRatio: 0.72,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.30,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _directionalConfig() {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: 'pokemon-building-shadow-v0',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

ProjectBuildingShadowPreset _footprintPreset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-footprint-v0',
    name: 'Pokemon-like footprint building shadow V0',
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.32,
      nearWidthRatio: 0.90,
      farWidthRatio: 0.72,
    ),
    footprint: ProjectedShadowFootprintTuning(),
    appearance: ProjectedShadowAppearance(
      opacity: 0.28,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _footprintConfig() {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: 'pokemon-building-shadow-footprint-v0',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

void _drawSimpleBuilding(ui.Canvas canvas, {required double columnLeft}) {
  const left = 32.0;
  const top = _headerHeight + 64.0;
  const width = 64.0;
  const height = 96.0;
  final body = ui.Paint()..color = _buildingBodyColor;
  final roof = ui.Paint()..color = _buildingRoofColor;
  final outline = ui.Paint()
    ..color = _buildingOutlineColor
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..isAntiAlias = false;
  final door = ui.Paint()..color = _buildingDoorColor;
  final window = ui.Paint()..color = _buildingWindowColor;

  final x = columnLeft + left;
  canvas.drawRect(ui.Rect.fromLTWH(x, top, width, height), body);
  canvas.drawRect(ui.Rect.fromLTWH(x, top, width, 22), roof);
  canvas.drawRect(ui.Rect.fromLTWH(x, top, width, height), outline);
  canvas.drawLine(
    ui.Offset(x, top + 22),
    ui.Offset(x + width, top + 22),
    outline,
  );
  canvas.drawRect(ui.Rect.fromLTWH(x + 26, top + 62, 12, 30), door);
  canvas.drawRect(ui.Rect.fromLTWH(x + 10, top + 36, 14, 10), window);
  canvas.drawRect(ui.Rect.fromLTWH(x + 40, top + 36, 14, 10), window);
}

void _drawCandidateLabel(
  ui.Canvas canvas,
  String letter, {
  required double columnLeft,
}) {
  final paint = ui.Paint()
    ..color = _labelColor
    ..strokeWidth = 2
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.square
    ..isAntiAlias = false;
  final x = columnLeft + 72;
  const y = 7.0;
  const width = 16.0;
  const height = 18.0;
  final left = x;
  final right = x + width;
  const top = y;
  const middle = y + height / 2;
  const bottom = y + height;

  switch (letter) {
    case 'A':
      canvas.drawLine(
          ui.Offset(left, bottom), ui.Offset(x + width / 2, top), paint);
      canvas.drawLine(
          ui.Offset(x + width / 2, top), ui.Offset(right, bottom), paint);
      canvas.drawLine(
          ui.Offset(left + 4, middle), ui.Offset(right - 4, middle), paint);
    case 'B':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right - 3, top), paint);
      canvas.drawLine(ui.Offset(left, middle), ui.Offset(right, middle), paint);
      canvas.drawLine(
          ui.Offset(left, bottom), ui.Offset(right - 3, bottom), paint);
      canvas.drawLine(
          ui.Offset(right, top + 3), ui.Offset(right, middle - 1), paint);
      canvas.drawLine(
          ui.Offset(right, middle + 1), ui.Offset(right, bottom - 3), paint);
    case 'C':
      canvas.drawLine(ui.Offset(right, top), ui.Offset(left, top), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, bottom), ui.Offset(right, bottom), paint);
  }
}

String _labelForIndex(int index) {
  return switch (index) {
    0 => 'A',
    1 => 'B',
    2 => 'C',
    _ => throw ArgumentError.value(index, 'index'),
  };
}

Future<Uint8List> _pngBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode ShadowV2 footprint artifact as PNG');
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

void _expectPointClose(
  ProjectedBuildingShadowPoint point, {
  required double x,
  required double y,
}) {
  expect(point.x, closeTo(x, 0.02));
  expect(point.y, closeTo(y, 0.02));
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
