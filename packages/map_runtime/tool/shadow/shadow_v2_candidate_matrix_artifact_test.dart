import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart'
    show
        ProjectBuildingShadowPreset,
        ProjectElementProjectedBuildingShadowConfig,
        ProjectedBuildingShadowGeometry,
        ProjectedShadowAnchor,
        ProjectedShadowAppearance,
        ProjectedShadowDirection,
        ProjectedShadowOffset,
        ProjectedShadowShapeTuning,
        ProjectedShadowTimeOfDayMode,
        ShadowRenderPass,
        StaticShadowVisualMetrics,
        resolveProjectedBuildingShadowGeometry;
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

const _artifactWidth = 800;
const _artifactHeight = 480;
const _columnWidth = 160;
const _headerHeight = 32;
const _cellHeight = 224;
const _shadowOnlyRowTop = _headerHeight;
const _buildingRowTop = _headerHeight + _cellHeight;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png';

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

const _candidates = [
  _ShadowCandidate(
    id: 'candidate-a-current-v0',
    label: 'A — Current V0',
    letter: 'A',
    directionX: 0.8,
    directionY: 0.35,
    lengthRatio: 0.32,
    nearWidthRatio: 0.90,
    farWidthRatio: 0.72,
    anchorXRatio: 0.5,
    anchorYRatio: 0.96,
    opacity: 0.30,
    colorHexRgb: '606060',
  ),
  _ShadowCandidate(
    id: 'candidate-b-downward-attached',
    label: 'B — Downward attached',
    letter: 'B',
    directionX: 0.45,
    directionY: 0.90,
    lengthRatio: 0.34,
    nearWidthRatio: 1.05,
    farWidthRatio: 0.95,
    anchorXRatio: 0.5,
    anchorYRatio: 0.92,
    opacity: 0.30,
    colorHexRgb: '606060',
  ),
  _ShadowCandidate(
    id: 'candidate-c-short-broad',
    label: 'C — Short broad',
    letter: 'C',
    directionX: 0.35,
    directionY: 0.70,
    lengthRatio: 0.24,
    nearWidthRatio: 1.15,
    farWidthRatio: 1.05,
    anchorXRatio: 0.5,
    anchorYRatio: 0.95,
    opacity: 0.28,
    colorHexRgb: '606060',
  ),
  _ShadowCandidate(
    id: 'candidate-d-wide-trapezoid',
    label: 'D — Wide trapezoid',
    letter: 'D',
    directionX: 0.55,
    directionY: 0.65,
    lengthRatio: 0.30,
    nearWidthRatio: 1.20,
    farWidthRatio: 1.10,
    anchorXRatio: 0.5,
    anchorYRatio: 0.94,
    opacity: 0.28,
    colorHexRgb: '606060',
  ),
  _ShadowCandidate(
    id: 'candidate-e-low-side-cast',
    label: 'E — Low side cast',
    letter: 'E',
    directionX: 0.70,
    directionY: 0.45,
    lengthRatio: 0.26,
    nearWidthRatio: 1.10,
    farWidthRatio: 0.95,
    anchorXRatio: 0.5,
    anchorYRatio: 0.98,
    opacity: 0.30,
    colorHexRgb: '606060',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow V2 candidate matrix artifact',
      () async {
    final image = await _renderCandidateMatrix();
    expect(image.width, _artifactWidth);
    expect(image.height, _artifactHeight);

    final backgroundPixel = await _pixelAt(image, 12, _shadowOnlyRowTop + 12);
    expect(backgroundPixel, _rgba(_backgroundColor));

    for (var index = 0; index < _candidates.length; index += 1) {
      final candidate = _candidates[index];
      final columnLeft = index * _columnWidth;
      final geometry = _geometryForCandidate(candidate);
      final centroid = _centroid(geometry);
      final shadowPixel = await _pixelAt(
        image,
        columnLeft + centroid.x.round(),
        _shadowOnlyRowTop + centroid.y.round(),
      );
      expect(
        shadowPixel,
        isNot(backgroundPixel),
        reason: '${candidate.label} should render a visible shadow',
      );

      final buildingPixel = await _pixelAt(
        image,
        columnLeft + 80,
        _buildingRowTop + 150,
      );
      expect(
        buildingPixel,
        _rgba(_buildingBodyColor),
        reason: '${candidate.label} building body should render over shadow',
      );
    }

    final pngBytes = await _pngBytes(image);
    await _writePng(pngBytes);

    final file = File(_artifactPath);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
  });
}

// Manual artifact harness: this writes one controlled PNG for human review of
// candidate ShadowV2 shapes. It is not an image comparison test.
Future<ui.Image> _renderCandidateMatrix() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, _artifactWidth + 0.0, _artifactHeight + 0.0),
    ui.Paint()..color = _backgroundColor,
  );

  for (var index = 0; index < _candidates.length; index += 1) {
    final candidate = _candidates[index];
    final columnLeft = (index * _columnWidth).toDouble();
    _drawCandidateLabel(canvas, candidate.letter, columnLeft: columnLeft);
    _drawCellBackground(canvas, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawCellBackground(canvas, columnLeft, _buildingRowTop.toDouble());
    _drawShadow(canvas, candidate, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawShadow(canvas, candidate, columnLeft, _buildingRowTop.toDouble());
    _drawSimpleBuilding(canvas, columnLeft, _buildingRowTop.toDouble());
  }

  _drawMatrixDividers(canvas);

  return recorder.endRecording().toImage(_artifactWidth, _artifactHeight);
}

void _drawCellBackground(ui.Canvas canvas, double left, double top) {
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, _columnWidth + 0.0, _cellHeight + 0.0),
    ui.Paint()..color = _backgroundColor,
  );
  _drawGrid(canvas, left: left, top: top);
}

void _drawGrid(ui.Canvas canvas, {required double left, required double top}) {
  final paint = ui.Paint()
    ..color = _gridColor
    ..strokeWidth = 1;

  for (var x = 32.0; x < _columnWidth; x += 32) {
    canvas.drawLine(
      ui.Offset(left + x, top),
      ui.Offset(left + x, top + _cellHeight),
      paint,
    );
  }
  for (var y = 32.0; y < _cellHeight; y += 32) {
    canvas.drawLine(
      ui.Offset(left, top + y),
      ui.Offset(left + _columnWidth, top + y),
      paint,
    );
  }
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
    case 'D':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right - 2, top), paint);
      canvas.drawLine(
          ui.Offset(right, top + 3), ui.Offset(right, bottom - 3), paint);
      canvas.drawLine(
          ui.Offset(left, bottom), ui.Offset(right - 2, bottom), paint);
    case 'E':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right, top), paint);
      canvas.drawLine(
          ui.Offset(left, middle), ui.Offset(right - 3, middle), paint);
      canvas.drawLine(ui.Offset(left, bottom), ui.Offset(right, bottom), paint);
  }
}

void _drawMatrixDividers(ui.Canvas canvas) {
  final paint = ui.Paint()
    ..color = _dividerColor
    ..strokeWidth = 1;
  for (var x = _columnWidth.toDouble(); x < _artifactWidth; x += _columnWidth) {
    canvas.drawLine(ui.Offset(x - 0.5, 0),
        ui.Offset(x - 0.5, _artifactHeight + 0.0), paint);
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
  _ShadowCandidate candidate,
  double columnLeft,
  double rowTop,
) {
  canvas.save();
  canvas.translate(columnLeft, rowTop);
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    _collectionForCandidate(candidate),
    ShadowRenderPass.groundStatic,
  );
  canvas.restore();
}

ShadowRuntimeInstructionCollection _collectionForCandidate(
  _ShadowCandidate candidate,
) {
  return ShadowRuntimeInstructionCollection(
    instructions: [_runtimeInstructionForCandidate(candidate)],
  );
}

ShadowRuntimeRenderInstruction _runtimeInstructionForCandidate(
  _ShadowCandidate candidate,
) {
  final geometry = _geometryForCandidate(candidate);
  final bounds = _boundsForGeometry(geometry);

  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.projectedPolygon,
    renderPass: ShadowRenderPass.groundStatic,
    worldLeft: bounds.left,
    worldTop: bounds.top,
    width: bounds.width,
    height: bounds.height,
    opacity: geometry.opacity,
    colorHexRgb: geometry.colorHexRgb,
    polygonPoints: [
      for (final point in geometry.points)
        ShadowRuntimePoint(worldX: point.x, worldY: point.y),
    ],
  );
}

ProjectedBuildingShadowGeometry _geometryForCandidate(
  _ShadowCandidate candidate,
) {
  final preset = ProjectBuildingShadowPreset(
    id: candidate.id,
    name: candidate.label,
    direction: ProjectedShadowDirection(
      x: candidate.directionX,
      y: candidate.directionY,
    ),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: candidate.lengthRatio,
      nearWidthRatio: candidate.nearWidthRatio,
      farWidthRatio: candidate.farWidthRatio,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: candidate.opacity,
      colorHexRgb: candidate.colorHexRgb,
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
  final config = ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: candidate.id,
    anchor: ProjectedShadowAnchor(
      xRatio: candidate.anchorXRatio,
      yRatio: candidate.anchorYRatio,
    ),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
  final geometry = resolveProjectedBuildingShadowGeometry(
    config: config,
    preset: preset,
    metrics: _metrics,
  );
  if (geometry == null) {
    throw StateError('${candidate.label} did not produce geometry');
  }
  return geometry;
}

_Bounds _boundsForGeometry(ProjectedBuildingShadowGeometry geometry) {
  var minX = geometry.points.first.x;
  var maxX = geometry.points.first.x;
  var minY = geometry.points.first.y;
  var maxY = geometry.points.first.y;

  for (final point in geometry.points.skip(1)) {
    if (point.x < minX) {
      minX = point.x;
    }
    if (point.x > maxX) {
      maxX = point.x;
    }
    if (point.y < minY) {
      minY = point.y;
    }
    if (point.y > maxY) {
      maxY = point.y;
    }
  }

  return _Bounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

_Point _centroid(ProjectedBuildingShadowGeometry geometry) {
  var totalX = 0.0;
  var totalY = 0.0;
  for (final point in geometry.points) {
    totalX += point.x;
    totalY += point.y;
  }
  return _Point(
    x: totalX / geometry.points.length,
    y: totalY / geometry.points.length,
  );
}

void _drawSimpleBuilding(ui.Canvas canvas, double columnLeft, double rowTop) {
  final left = columnLeft + 32;
  final top = rowTop + 64;
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
    throw StateError('Could not encode ShadowV2 candidate matrix as PNG');
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
    throw StateError('Could not read raw pixels from matrix image');
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

final class _ShadowCandidate {
  const _ShadowCandidate({
    required this.id,
    required this.label,
    required this.letter,
    required this.directionX,
    required this.directionY,
    required this.lengthRatio,
    required this.nearWidthRatio,
    required this.farWidthRatio,
    required this.anchorXRatio,
    required this.anchorYRatio,
    required this.opacity,
    required this.colorHexRgb,
  });

  final String id;
  final String label;
  final String letter;
  final double directionX;
  final double directionY;
  final double lengthRatio;
  final double nearWidthRatio;
  final double farWidthRatio;
  final double anchorXRatio;
  final double anchorYRatio;
  final double opacity;
  final String colorHexRgb;
}

final class _Bounds {
  const _Bounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

final class _Point {
  const _Point({
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
