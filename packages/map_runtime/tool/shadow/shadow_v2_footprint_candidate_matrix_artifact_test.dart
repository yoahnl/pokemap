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

const _artifactWidth = 1120;
const _artifactHeight = 480;
const _columnWidth = 160;
const _headerHeight = 32;
const _rowHeight = 224;
const _shadowOnlyRowTop = _headerHeight;
const _buildingRowTop = 256;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png';

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

final _candidates = [
  _referenceDirectionalCandidate(),
  ..._footprintCandidates(),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow footprint candidate matrix artifact',
      () async {
    final image = await _renderArtifact();
    expect(image.width, _artifactWidth);
    expect(image.height, _artifactHeight);

    final backgroundPixel = await _pixelAt(image, 12, 44);
    expect(backgroundPixel, _rgba(_backgroundColor));

    for (var index = 0; index < _candidates.length; index += 1) {
      final candidate = _candidates[index];
      final columnLeft = index * _columnWidth;
      final geometry = _geometryForCandidate(candidate);
      final centroid = _centroid(geometry);
      final shadowOnlyPixel = await _pixelAt(
        image,
        columnLeft + centroid.x.round(),
        _shadowOnlyRowTop + centroid.y.round(),
      );
      expect(
        shadowOnlyPixel,
        isNot(backgroundPixel),
        reason: '${candidate.label} shadow-only should render',
      );

      final buildingBodyPixel = await _pixelAt(
        image,
        columnLeft + 80,
        _buildingRowTop + 120,
      );
      expect(
        buildingBodyPixel,
        _rgba(_buildingBodyColor),
        reason: '${candidate.label} building body should render above shadow',
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
        reason: '${candidate.label} shadow should remain visible below building',
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

  for (var index = 0; index < _candidates.length; index += 1) {
    final candidate = _candidates[index];
    final columnLeft = (index * _columnWidth).toDouble();
    _drawLabel(canvas, candidate.letter, columnLeft: columnLeft);
    _drawCellBackground(canvas, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawCellBackground(canvas, columnLeft, _buildingRowTop.toDouble());
    _drawShadow(canvas, candidate, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawShadow(canvas, candidate, columnLeft, _buildingRowTop.toDouble());
    _drawSimpleBuilding(canvas, columnLeft, _buildingRowTop.toDouble());
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

  for (var x = 32.0; x < _columnWidth; x += 32) {
    canvas.drawLine(
      ui.Offset(left + x, top),
      ui.Offset(left + x, top + _rowHeight),
      paint,
    );
  }
  for (var y = 32.0; y < _rowHeight; y += 32) {
    canvas.drawLine(
      ui.Offset(left, top + y),
      ui.Offset(left + _columnWidth, top + y),
      paint,
    );
  }
}

void _drawDividers(ui.Canvas canvas) {
  final paint = ui.Paint()
    ..color = _dividerColor
    ..strokeWidth = 1;

  for (var x = _columnWidth.toDouble(); x < _artifactWidth; x += _columnWidth) {
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
    instructions: [_instructionForCandidate(candidate)],
  );
}

ShadowRuntimeRenderInstruction _instructionForCandidate(
  _ShadowCandidate candidate,
) {
  return createProjectedBuildingShadowRuntimeInstruction(
    _geometryForCandidate(candidate),
  );
}

ProjectedBuildingShadowGeometry _geometryForCandidate(
  _ShadowCandidate candidate,
) {
  final geometry = resolveProjectedBuildingShadowGeometry(
    config: _configForCandidate(candidate),
    preset: _presetForCandidate(candidate),
    metrics: _metrics,
  );
  if (geometry == null) {
    throw StateError('${candidate.label} did not produce geometry');
  }
  return geometry;
}

ProjectBuildingShadowPreset _presetForCandidate(_ShadowCandidate candidate) {
  switch (candidate.geometryMode) {
    case ProjectedBuildingShadowGeometryMode.directional:
      return ProjectBuildingShadowPreset(
        id: candidate.id,
        name: candidate.label,
        geometryMode: ProjectedBuildingShadowGeometryMode.directional,
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
    case ProjectedBuildingShadowGeometryMode.footprint:
      return ProjectBuildingShadowPreset(
        id: candidate.id,
        name: candidate.label,
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
        shape: ProjectedShadowShapeTuning(
          lengthRatio: 0.32,
          nearWidthRatio: 0.90,
          farWidthRatio: 0.72,
        ),
        footprint: ProjectedShadowFootprintTuning(
          attachYRatio: candidate.attachYRatio,
          frontWidthRatio: candidate.frontWidthRatio,
          rearWidthRatio: candidate.rearWidthRatio,
          depthRatio: candidate.depthRatio,
          skewXRatio: candidate.skewXRatio,
        ),
        appearance: ProjectedShadowAppearance(
          opacity: candidate.opacity,
          colorHexRgb: candidate.colorHexRgb,
        ),
        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
      );
  }
}

ProjectElementProjectedBuildingShadowConfig _configForCandidate(
  _ShadowCandidate candidate,
) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: candidate.id,
    anchor: ProjectedShadowAnchor(
      xRatio: candidate.anchorXRatio,
      yRatio: candidate.anchorYRatio,
    ),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

_ShadowCandidate _referenceDirectionalCandidate() {
  return const _ShadowCandidate(
    id: 'reference-directional-v0',
    label: 'R — Directional V0',
    letter: 'R',
    geometryMode: ProjectedBuildingShadowGeometryMode.directional,
    directionX: 0.8,
    directionY: 0.35,
    lengthRatio: 0.32,
    nearWidthRatio: 0.90,
    farWidthRatio: 0.72,
    anchorXRatio: 0.5,
    anchorYRatio: 0.96,
    opacity: 0.30,
    colorHexRgb: '606060',
  );
}

List<_ShadowCandidate> _footprintCandidates() {
  return const [
    _ShadowCandidate(
      id: 'candidate-a-current-footprint-v0',
      label: 'A — Current',
      letter: 'A',
      geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
      attachYRatio: 0.86,
      frontWidthRatio: 1.10,
      rearWidthRatio: 1.20,
      depthRatio: 0.28,
      skewXRatio: 0.10,
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      opacity: 0.28,
      colorHexRgb: '606060',
    ),
    _ShadowCandidate(
      id: 'candidate-b-deeper-footprint',
      label: 'B — Deeper',
      letter: 'B',
      geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
      attachYRatio: 0.84,
      frontWidthRatio: 1.10,
      rearWidthRatio: 1.22,
      depthRatio: 0.36,
      skewXRatio: 0.10,
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      opacity: 0.28,
      colorHexRgb: '606060',
    ),
    _ShadowCandidate(
      id: 'candidate-c-wider-footprint',
      label: 'C — Wider',
      letter: 'C',
      geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
      attachYRatio: 0.86,
      frontWidthRatio: 1.22,
      rearWidthRatio: 1.35,
      depthRatio: 0.30,
      skewXRatio: 0.10,
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      opacity: 0.26,
      colorHexRgb: '606060',
    ),
    _ShadowCandidate(
      id: 'candidate-d-higher-attached-footprint',
      label: 'D — Higher',
      letter: 'D',
      geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
      attachYRatio: 0.80,
      frontWidthRatio: 1.12,
      rearWidthRatio: 1.25,
      depthRatio: 0.32,
      skewXRatio: 0.10,
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      opacity: 0.27,
      colorHexRgb: '606060',
    ),
    _ShadowCandidate(
      id: 'candidate-e-stronger-skew-footprint',
      label: 'E — Skew',
      letter: 'E',
      geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
      attachYRatio: 0.84,
      frontWidthRatio: 1.12,
      rearWidthRatio: 1.25,
      depthRatio: 0.32,
      skewXRatio: 0.18,
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      opacity: 0.27,
      colorHexRgb: '606060',
    ),
    _ShadowCandidate(
      id: 'candidate-f-broad-shallow-footprint',
      label: 'F — Broad shallow',
      letter: 'F',
      geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
      attachYRatio: 0.82,
      frontWidthRatio: 1.30,
      rearWidthRatio: 1.42,
      depthRatio: 0.26,
      skewXRatio: 0.08,
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      opacity: 0.24,
      colorHexRgb: '606060',
    ),
  ];
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

  final door = ui.Rect.fromLTWH(left + 26, top + 62, 12, 30);
  canvas.drawRect(door, ui.Paint()..color = _buildingDoorColor);

  final windowPaint = ui.Paint()..color = _buildingWindowColor;
  canvas.drawRect(ui.Rect.fromLTWH(left + 10, top + 36, 14, 10), windowPaint);
  canvas.drawRect(ui.Rect.fromLTWH(left + 40, top + 36, 14, 10), windowPaint);

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

void _drawLabel(
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
    case 'R':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right - 3, top), paint);
      canvas.drawLine(
          ui.Offset(right, top + 3), ui.Offset(right, middle - 1), paint);
      canvas.drawLine(ui.Offset(left, middle), ui.Offset(right, middle), paint);
      canvas.drawLine(ui.Offset(left + 6, middle), ui.Offset(right, bottom), paint);
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
    case 'F':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right, top), paint);
      canvas.drawLine(
          ui.Offset(left, middle), ui.Offset(right - 3, middle), paint);
  }
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

_Point _visibleShadowPoint(ProjectedBuildingShadowGeometry geometry) {
  final rearRight = geometry.points[2];
  final rearLeft = geometry.points[3];
  return _Point(
    x: (rearRight.x + rearLeft.x) / 2,
    y: (rearRight.y + rearLeft.y) / 2 - 3,
  );
}

Future<Uint8List> _pngBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode ShadowV2 footprint matrix as PNG');
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
    throw StateError('Could not read raw pixels from footprint matrix image');
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
    required this.geometryMode,
    this.directionX = 0,
    this.directionY = 1,
    this.lengthRatio = 0,
    this.nearWidthRatio = 1,
    this.farWidthRatio = 1,
    this.attachYRatio = 0.86,
    this.frontWidthRatio = 1.10,
    this.rearWidthRatio = 1.20,
    this.depthRatio = 0.28,
    this.skewXRatio = 0.10,
    required this.anchorXRatio,
    required this.anchorYRatio,
    required this.opacity,
    required this.colorHexRgb,
  });

  final String id;
  final String label;
  final String letter;
  final ProjectedBuildingShadowGeometryMode geometryMode;
  final double directionX;
  final double directionY;
  final double lengthRatio;
  final double nearWidthRatio;
  final double farWidthRatio;
  final double attachYRatio;
  final double frontWidthRatio;
  final double rearWidthRatio;
  final double depthRatio;
  final double skewXRatio;
  final double anchorXRatio;
  final double anchorYRatio;
  final double opacity;
  final String colorHexRgb;
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
