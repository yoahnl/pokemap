import 'dart:io';
import 'dart:math' as math;
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

const _artifactWidth = 800;
const _artifactHeight = 480;
const _columnWidth = 200;
const _headerHeight = 32;
const _rowHeight = 224;
const _shadowOnlyRowTop = _headerHeight;
const _buildingRowTop = 256;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png';

const _backgroundColor = ui.Color(0xFFD8E0C8);
const _gridColor = ui.Color(0xFFE6ECD8);
const _dividerColor = ui.Color(0xFFB5BEA7);
const _labelColor = ui.Color(0xFF343A3D);
const _buildingBodyColor = ui.Color(0xFFE9D7B9);
const _buildingRoofColor = ui.Color(0xFFB7655A);
const _buildingOutlineColor = ui.Color(0xFF343A3D);
const _buildingDoorColor = ui.Color(0xFF7E5547);
const _buildingWindowColor = ui.Color(0xFF8EC6D8);
const _buildingSignColor = ui.Color(0xFFD5C185);

const _buildingCases = [
  _BuildingCase(
    id: 'simple_house_4x5',
    label: 'A',
    left: 68,
    top: 80,
    width: 64,
    height: 80,
    expectedPoints: [
      _ExpectedPoint(x: 58.40, y: 145.60),
      _ExpectedPoint(x: 141.60, y: 145.60),
      _ExpectedPoint(x: 150.56, y: 166.40),
      _ExpectedPoint(x: 59.68, y: 166.40),
    ],
    expectedLeft: 58.40,
    expectedTop: 145.60,
    expectedWidth: 92.16,
    expectedHeight: 20.80,
  ),
  _BuildingCase(
    id: 'wide_house_6x5',
    label: 'B',
    left: 52,
    top: 80,
    width: 96,
    height: 80,
    expectedPoints: [
      _ExpectedPoint(x: 37.60, y: 145.60),
      _ExpectedPoint(x: 162.40, y: 145.60),
      _ExpectedPoint(x: 175.84, y: 166.40),
      _ExpectedPoint(x: 39.52, y: 166.40),
    ],
    expectedLeft: 37.60,
    expectedTop: 145.60,
    expectedWidth: 138.24,
    expectedHeight: 20.80,
  ),
  _BuildingCase(
    id: 'tall_shop_4x7',
    label: 'C',
    left: 68,
    top: 48,
    width: 64,
    height: 112,
    expectedPoints: [
      _ExpectedPoint(x: 58.40, y: 139.84),
      _ExpectedPoint(x: 141.60, y: 139.84),
      _ExpectedPoint(x: 150.56, y: 168.96),
      _ExpectedPoint(x: 59.68, y: 168.96),
    ],
    expectedLeft: 58.40,
    expectedTop: 139.84,
    expectedWidth: 92.16,
    expectedHeight: 29.12,
  ),
  _BuildingCase(
    id: 'small_kiosk_3x4',
    label: 'D',
    left: 76,
    top: 96,
    width: 48,
    height: 64,
    expectedPoints: [
      _ExpectedPoint(x: 68.80, y: 148.48),
      _ExpectedPoint(x: 131.20, y: 148.48),
      _ExpectedPoint(x: 137.92, y: 165.12),
      _ExpectedPoint(x: 69.76, y: 165.12),
    ],
    expectedLeft: 68.80,
    expectedTop: 148.48,
    expectedWidth: 69.12,
    expectedHeight: 16.64,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow v2 controlled multi building artifact',
      () async {
    final image = await _renderArtifact();
    expect(image.width, _artifactWidth);
    expect(image.height, _artifactHeight);

    final backgroundPixel = await _pixelAt(image, 12, 44);
    expect(backgroundPixel, _rgba(_backgroundColor));

    for (var index = 0; index < _buildingCases.length; index += 1) {
      final building = _buildingCases[index];
      final columnLeft = index * _columnWidth;
      final geometry = _geometryForCase(building);
      final instruction = _instructionForCase(building);

      expect(geometry.opacity, 0.24);
      expect(geometry.colorHexRgb, '606060');
      expect(geometry.points, hasLength(4));
      for (var pointIndex = 0; pointIndex < building.expectedPoints.length; pointIndex += 1) {
        _expectPointClose(
          geometry.points[pointIndex],
          x: building.expectedPoints[pointIndex].x,
          y: building.expectedPoints[pointIndex].y,
        );
      }
      _expectBoundsClose(instruction, building);

      final centroid = _centroid(geometry);
      final shadowOnlyPixel = await _pixelAt(
        image,
        columnLeft + centroid.x.round(),
        _shadowOnlyRowTop + centroid.y.round(),
      );
      expect(
        shadowOnlyPixel,
        isNot(backgroundPixel),
        reason: '${building.id} shadow-only should render',
      );

      final buildingBodyPixel = await _pixelAt(
        image,
        columnLeft + (building.left + building.width / 2).round(),
        _buildingRowTop +
            (building.top + math.min(40, building.height / 2)).round(),
      );
      expect(
        buildingBodyPixel,
        _rgba(_buildingBodyColor),
        reason: '${building.id} body should render above shadow',
      );

      final visibleShadowPoint = _visibleShadowPoint(geometry);
      final visibleShadowPixel = await _pixelAt(
        image,
        columnLeft + visibleShadowPoint.x.round(),
        _buildingRowTop + visibleShadowPoint.y.round(),
      );
      expect(
        visibleShadowPixel,
        isNot(backgroundPixel),
        reason: '${building.id} visible shadow should render below building',
      );
      expect(
        visibleShadowPixel,
        isNot(_rgba(_buildingBodyColor)),
        reason: '${building.id} visible shadow should not be covered by body',
      );
    }

    final pngBytes = await _pngBytes(image);
    await _writePng(pngBytes);

    final file = File(_artifactPath);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
  });
}

Future<ui.Image> _renderArtifact() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, _artifactWidth + 0.0, _artifactHeight + 0.0),
    ui.Paint()..color = _backgroundColor,
  );

  for (var index = 0; index < _buildingCases.length; index += 1) {
    final building = _buildingCases[index];
    final columnLeft = (index * _columnWidth).toDouble();
    _drawLabel(canvas, building.label, columnLeft: columnLeft);
    _drawCellBackground(canvas, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawCellBackground(canvas, columnLeft, _buildingRowTop.toDouble());
    _drawShadow(canvas, building, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawShadow(canvas, building, columnLeft, _buildingRowTop.toDouble());
    _drawControlledBuilding(canvas, building, columnLeft, _buildingRowTop.toDouble());
  }

  _drawDividers(canvas);

  return recorder.endRecording().toImage(_artifactWidth, _artifactHeight);
}

void _drawCellBackground(ui.Canvas canvas, double left, double top) {
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, _columnWidth + 0.0, _rowHeight + 0.0),
    ui.Paint()..color = _backgroundColor,
  );
  _drawGrid(canvas, left: left, top: top);
}

void _drawGrid(ui.Canvas canvas, {required double left, required double top}) {
  final paint = ui.Paint()
    ..color = _gridColor
    ..strokeWidth = 1;
  for (var x = left; x <= left + _columnWidth; x += 32) {
    canvas.drawLine(ui.Offset(x, top), ui.Offset(x, top + _rowHeight), paint);
  }
  for (var y = top; y <= top + _rowHeight; y += 32) {
    canvas.drawLine(ui.Offset(left, y), ui.Offset(left + _columnWidth, y), paint);
  }
}

void _drawDividers(ui.Canvas canvas) {
  final paint = ui.Paint()
    ..color = _dividerColor
    ..strokeWidth = 1;
  for (var x = _columnWidth; x < _artifactWidth; x += _columnWidth) {
    canvas.drawLine(
      ui.Offset(x - 0.5, 0),
      ui.Offset(x - 0.5, _artifactHeight + 0.0),
      paint,
    );
  }
  canvas.drawLine(
    const ui.Offset(0, _headerHeight - 0.5),
    const ui.Offset(_artifactWidth + 0.0, _headerHeight - 0.5),
    paint,
  );
  canvas.drawLine(
    const ui.Offset(0, _buildingRowTop - 0.5),
    const ui.Offset(_artifactWidth + 0.0, _buildingRowTop - 0.5),
    paint,
  );
}

void _drawShadow(
  ui.Canvas canvas,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  canvas.save();
  canvas.translate(columnLeft, rowTop);
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    _collectionForCase(building),
    ShadowRenderPass.groundStatic,
  );
  canvas.restore();
}

ShadowRuntimeInstructionCollection _collectionForCase(_BuildingCase building) {
  return ShadowRuntimeInstructionCollection(
    instructions: [_instructionForCase(building)],
  );
}

ShadowRuntimeRenderInstruction _instructionForCase(_BuildingCase building) {
  return createProjectedBuildingShadowRuntimeInstruction(
    _geometryForCase(building),
  );
}

ProjectedBuildingShadowGeometry _geometryForCase(_BuildingCase building) {
  final geometry = resolveProjectedBuildingShadowGeometry(
    config: _shadowConfig(),
    preset: _shadowPreset(),
    metrics: _metricsForCase(building),
  );
  if (geometry == null) {
    throw StateError('${building.id} did not produce geometry');
  }
  return geometry;
}

StaticShadowVisualMetrics _metricsForCase(_BuildingCase building) {
  return StaticShadowVisualMetrics(
    left: building.left,
    top: building.top,
    visualWidth: building.width,
    visualHeight: building.height,
  );
}

ProjectBuildingShadowPreset _shadowPreset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-footprint-v2',
    name: 'Pokemon-like footprint building shadow V2',
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.32,
      nearWidthRatio: 0.90,
      farWidthRatio: 0.72,
    ),
    footprint: ProjectedShadowFootprintTuning(
      attachYRatio: 0.82,
      frontWidthRatio: 1.30,
      rearWidthRatio: 1.42,
      depthRatio: 0.26,
      skewXRatio: 0.08,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.24,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _shadowConfig() {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: 'pokemon-building-shadow-footprint-v2',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

void _drawControlledBuilding(
  ui.Canvas canvas,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  switch (building.id) {
    case 'simple_house_4x5':
      _drawSimpleHouse(canvas, building, columnLeft, rowTop);
    case 'wide_house_6x5':
      _drawWideHouse(canvas, building, columnLeft, rowTop);
    case 'tall_shop_4x7':
      _drawTallShop(canvas, building, columnLeft, rowTop);
    case 'small_kiosk_3x4':
      _drawSmallKiosk(canvas, building, columnLeft, rowTop);
  }
}

void _drawSimpleHouse(
  ui.Canvas canvas,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + building.left;
  final top = rowTop + building.top;
  final width = building.width;
  final height = building.height;
  final outline = _outlinePaint();
  final fill = _fillPaint(_buildingBodyColor);
  final roof = _fillPaint(_buildingRoofColor);

  canvas.drawRect(ui.Rect.fromLTWH(left, top + 22, width, height - 22), fill);
  canvas.drawRect(ui.Rect.fromLTWH(left, top + 22, width, height - 22), outline);
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 6, top + 24)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 6, top + 24)
      ..close(),
    roof,
  );
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 6, top + 24)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 6, top + 24)
      ..close(),
    outline,
  );
  _drawDoor(canvas, left + width / 2 - 7, top + height - 28, 14, 28);
  _drawWindow(canvas, left + 10, top + 42, 14, 14);
  _drawWindow(canvas, left + width - 24, top + 42, 14, 14);
}

void _drawWideHouse(
  ui.Canvas canvas,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + building.left;
  final top = rowTop + building.top;
  final width = building.width;
  final height = building.height;
  final outline = _outlinePaint();
  final fill = _fillPaint(_buildingBodyColor);
  final roof = _fillPaint(_buildingRoofColor);

  canvas.drawRect(ui.Rect.fromLTWH(left, top + 20, width, height - 20), fill);
  canvas.drawRect(ui.Rect.fromLTWH(left, top + 20, width, height - 20), outline);
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 8, top + 22)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 8, top + 22)
      ..close(),
    roof,
  );
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 8, top + 22)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 8, top + 22)
      ..close(),
    outline,
  );
  _drawDoor(canvas, left + width / 2 - 8, top + height - 28, 16, 28);
  _drawWindow(canvas, left + 10, top + 40, 14, 14);
  _drawWindow(canvas, left + 30, top + 40, 14, 14);
  _drawWindow(canvas, left + width - 44, top + 40, 14, 14);
  _drawWindow(canvas, left + width - 24, top + 40, 14, 14);
}

void _drawTallShop(
  ui.Canvas canvas,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + building.left;
  final top = rowTop + building.top;
  final width = building.width;
  final height = building.height;
  final outline = _outlinePaint();
  final fill = _fillPaint(_buildingBodyColor);
  final roof = _fillPaint(_buildingRoofColor);
  final sign = _fillPaint(_buildingSignColor);

  canvas.drawRect(ui.Rect.fromLTWH(left, top + 16, width, height - 16), fill);
  canvas.drawRect(ui.Rect.fromLTWH(left, top + 16, width, height - 16), outline);
  canvas.drawRect(ui.Rect.fromLTWH(left - 4, top, width + 8, 18), roof);
  canvas.drawRect(ui.Rect.fromLTWH(left - 4, top, width + 8, 18), outline);
  canvas.drawRect(ui.Rect.fromLTWH(left + 8, top + 22, width - 16, 12), sign);
  canvas.drawRect(ui.Rect.fromLTWH(left + 8, top + 22, width - 16, 12), outline);
  _drawDoor(canvas, left + width / 2 - 8, top + height - 32, 16, 32);
  _drawWindow(canvas, left + 12, top + 58, 14, 22);
  _drawWindow(canvas, left + width - 26, top + 58, 14, 22);
}

void _drawSmallKiosk(
  ui.Canvas canvas,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + building.left;
  final top = rowTop + building.top;
  final width = building.width;
  final height = building.height;
  final outline = _outlinePaint();
  final fill = _fillPaint(_buildingBodyColor);
  final roof = _fillPaint(_buildingRoofColor);
  final sign = _fillPaint(_buildingSignColor);

  canvas.drawRect(ui.Rect.fromLTWH(left, top + 18, width, height - 18), fill);
  canvas.drawRect(ui.Rect.fromLTWH(left, top + 18, width, height - 18), outline);
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 5, top + 20)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 5, top + 20)
      ..close(),
    roof,
  );
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 5, top + 20)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 5, top + 20)
      ..close(),
    outline,
  );
  canvas.drawRect(ui.Rect.fromLTWH(left + 8, top + 20, width - 16, 8), sign);
  canvas.drawRect(ui.Rect.fromLTWH(left + 8, top + 20, width - 16, 8), outline);
  _drawDoor(canvas, left + width - 18, top + height - 24, 12, 24);
  _drawWindow(canvas, left + 8, top + 44, 14, 12);
}

void _drawDoor(ui.Canvas canvas, double left, double top, double width, double height) {
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _fillPaint(_buildingDoorColor),
  );
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _outlinePaint(),
  );
}

void _drawWindow(ui.Canvas canvas, double left, double top, double width, double height) {
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _fillPaint(_buildingWindowColor),
  );
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _outlinePaint(),
  );
}

ui.Paint _fillPaint(ui.Color color) {
  return ui.Paint()
    ..color = color
    ..style = ui.PaintingStyle.fill;
}

ui.Paint _outlinePaint() {
  return ui.Paint()
    ..color = _buildingOutlineColor
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..isAntiAlias = false;
}

void _drawLabel(
  ui.Canvas canvas,
  String label, {
  required double columnLeft,
}) {
  final paint = ui.Paint()
    ..color = _labelColor
    ..strokeWidth = 3
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.square;
  final x = columnLeft + 90;
  const top = 8.0;
  const bottom = 24.0;
  const width = 20.0;
  const middle = 16.0;
  final left = x;
  final right = x + width;
  switch (label) {
    case 'A':
      canvas.drawLine(ui.Offset(left, bottom), ui.Offset(x + width / 2, top), paint);
      canvas.drawLine(ui.Offset(x + width / 2, top), ui.Offset(right, bottom), paint);
      canvas.drawLine(ui.Offset(left + 4, middle), ui.Offset(right - 4, middle), paint);
    case 'B':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right - 3, top + 3), paint);
      canvas.drawLine(ui.Offset(right - 3, top + 3), ui.Offset(right - 3, middle - 2), paint);
      canvas.drawLine(ui.Offset(right - 3, middle - 2), ui.Offset(left, middle), paint);
      canvas.drawLine(ui.Offset(left, middle), ui.Offset(right, middle + 3), paint);
      canvas.drawLine(ui.Offset(right, middle + 3), ui.Offset(right - 2, bottom - 2), paint);
      canvas.drawLine(ui.Offset(right - 2, bottom - 2), ui.Offset(left, bottom), paint);
    case 'C':
      canvas.drawLine(ui.Offset(right, top), ui.Offset(left + 3, top), paint);
      canvas.drawLine(ui.Offset(left + 3, top), ui.Offset(left, middle), paint);
      canvas.drawLine(ui.Offset(left, middle), ui.Offset(left + 3, bottom), paint);
      canvas.drawLine(ui.Offset(left + 3, bottom), ui.Offset(right, bottom), paint);
    case 'D':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right - 2, top + 4), paint);
      canvas.drawLine(ui.Offset(right - 2, top + 4), ui.Offset(right - 2, bottom - 4), paint);
      canvas.drawLine(ui.Offset(right - 2, bottom - 4), ui.Offset(left, bottom), paint);
  }
}

Future<Uint8List> _pngBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode ShadowV2 controlled multi-building artifact as PNG');
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
    _colorByte(color.r),
    _colorByte(color.g),
    _colorByte(color.b),
    _colorByte(color.a),
  );
}

int _colorByte(double value) {
  return (value * 255.0).round().clamp(0, 255).toInt();
}

ProjectedBuildingShadowPoint _centroid(ProjectedBuildingShadowGeometry geometry) {
  var totalX = 0.0;
  var totalY = 0.0;
  for (final point in geometry.points) {
    totalX += point.x;
    totalY += point.y;
  }
  return ProjectedBuildingShadowPoint(
    x: totalX / geometry.points.length,
    y: totalY / geometry.points.length,
  );
}

ProjectedBuildingShadowPoint _visibleShadowPoint(ProjectedBuildingShadowGeometry geometry) {
  final rearCenterX = (geometry.points[2].x + geometry.points[3].x) / 2;
  final rearY = math.max(geometry.points[2].y, geometry.points[3].y);
  return ProjectedBuildingShadowPoint(
    x: rearCenterX,
    y: math.max(161, rearY.round() - 3).toDouble(),
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

void _expectBoundsClose(
  ShadowRuntimeRenderInstruction instruction,
  _BuildingCase building,
) {
  expect(instruction.worldLeft, closeTo(building.expectedLeft, 0.02));
  expect(instruction.worldTop, closeTo(building.expectedTop, 0.02));
  expect(instruction.width, closeTo(building.expectedWidth, 0.02));
  expect(instruction.height, closeTo(building.expectedHeight, 0.02));
}

final class _BuildingCase {
  const _BuildingCase({
    required this.id,
    required this.label,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.expectedPoints,
    required this.expectedLeft,
    required this.expectedTop,
    required this.expectedWidth,
    required this.expectedHeight,
  });

  final String id;
  final String label;
  final double left;
  final double top;
  final double width;
  final double height;
  final List<_ExpectedPoint> expectedPoints;
  final double expectedLeft;
  final double expectedTop;
  final double expectedWidth;
  final double expectedHeight;
}

final class _ExpectedPoint {
  const _ExpectedPoint({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;
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
