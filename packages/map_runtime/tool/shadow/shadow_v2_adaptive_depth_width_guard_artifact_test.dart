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
const _artifactHeight = 928;
const _columnWidth = 200;
const _headerHeight = 32;
const _rowHeight = 224;
const _row0Top = _headerHeight;
const _row1Top = 256;
const _row2Top = 480;
const _row3Top = 704;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png';

const _backgroundColor = ui.Color(0xFFD8E0C8);
const _gridColor = ui.Color(0xFFE6ECD8);
const _dividerColor = ui.Color(0xFFB5BEA7);
const _labelColor = ui.Color(0xFF343A3D);
const _bodyColor = ui.Color(0xFFE9D7B9);
const _roofColor = ui.Color(0xFFB7655A);
const _outlineColor = ui.Color(0xFF343A3D);
const _doorColor = ui.Color(0xFF7E5547);
const _windowColor = ui.Color(0xFF8EC6D8);
const _signColor = ui.Color(0xFFD5C185);
const _metalColor = ui.Color(0xFF6B7480);

const _standardMode = _ShadowMode.fixed(
  id: 'standard-v2-fixed',
  label: 'Standard',
  attachYRatio: 0.82,
  frontWidthRatio: 1.30,
  rearWidthRatio: 1.42,
  depthRatio: 0.26,
  skewXRatio: 0.08,
  opacity: 0.24,
);

const _adaptiveCPlusMode = _ShadowMode.adaptive(
  id: 'adaptive-c-plus',
  label: 'Adaptive C+',
  attachYRatio: 0.82,
  targetAttachYRatio: 0.80,
  frontWidthRatio: 1.30,
  rearWidthRatio: 1.42,
  targetRearWidthRatio: 1.47,
  depthRatio: 0.26,
  targetDepthRatio: 0.42,
  skewXRatio: 0.08,
  opacity: 0.24,
  targetOpacity: 0.22,
);

const _shadowModes = [_standardMode, _adaptiveCPlusMode];

const _guardCases = [
  _GuardCase(
    id: 'wide_house_6x5',
    label: 'A',
    left: 52,
    top: 80,
    width: 96,
    height: 80,
    expectedHeightGate: 0,
    expectedRatioGate: 0,
    expectedAdaptiveT: 0,
    objectKind: _GuardObjectKind.wideHouse,
    standardExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 37.60, y: 145.60),
        _ExpectedPoint(x: 162.40, y: 145.60),
        _ExpectedPoint(x: 175.84, y: 166.40),
        _ExpectedPoint(x: 39.52, y: 166.40),
      ],
      left: 37.60,
      top: 145.60,
      width: 138.24,
      height: 20.80,
    ),
    adaptiveExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 37.60, y: 145.60),
        _ExpectedPoint(x: 162.40, y: 145.60),
        _ExpectedPoint(x: 175.84, y: 166.40),
        _ExpectedPoint(x: 39.52, y: 166.40),
      ],
      left: 37.60,
      top: 145.60,
      width: 138.24,
      height: 20.80,
    ),
  ),
  _GuardCase(
    id: 'medium_shop_5x6',
    label: 'B',
    left: 60,
    top: 64,
    width: 80,
    height: 96,
    expectedHeightGate: 0.5,
    expectedRatioGate: 0,
    expectedAdaptiveT: 0,
    objectKind: _GuardObjectKind.mediumShop,
    standardExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 48.00, y: 142.72),
        _ExpectedPoint(x: 152.00, y: 142.72),
        _ExpectedPoint(x: 163.20, y: 167.68),
        _ExpectedPoint(x: 49.60, y: 167.68),
      ],
      left: 48.00,
      top: 142.72,
      width: 115.20,
      height: 24.96,
    ),
    adaptiveExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 48.00, y: 142.72),
        _ExpectedPoint(x: 152.00, y: 142.72),
        _ExpectedPoint(x: 163.20, y: 167.68),
        _ExpectedPoint(x: 49.60, y: 167.68),
      ],
      left: 48.00,
      top: 142.72,
      width: 115.20,
      height: 24.96,
    ),
  ),
  _GuardCase(
    id: 'tall_shop_4x7',
    label: 'C',
    left: 68,
    top: 48,
    width: 64,
    height: 112,
    expectedHeightGate: 1,
    expectedRatioGate: 1,
    expectedAdaptiveT: 1,
    objectKind: _GuardObjectKind.tallShop,
    standardExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 58.40, y: 139.84),
        _ExpectedPoint(x: 141.60, y: 139.84),
        _ExpectedPoint(x: 150.56, y: 168.96),
        _ExpectedPoint(x: 59.68, y: 168.96),
      ],
      left: 58.40,
      top: 139.84,
      width: 92.16,
      height: 29.12,
    ),
    adaptiveExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 58.40, y: 137.60),
        _ExpectedPoint(x: 141.60, y: 137.60),
        _ExpectedPoint(x: 152.16, y: 184.64),
        _ExpectedPoint(x: 58.08, y: 184.64),
      ],
      left: 58.08,
      top: 137.60,
      width: 94.08,
      height: 47.04,
    ),
  ),
  _GuardCase(
    id: 'thin_prop_like_2x6',
    label: 'D',
    left: 84,
    top: 64,
    width: 32,
    height: 96,
    expectedHeightGate: 0.5,
    expectedRatioGate: 1,
    expectedAdaptiveT: 0.5,
    objectKind: _GuardObjectKind.thinPropLike,
    standardExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 79.20, y: 142.72),
        _ExpectedPoint(x: 120.80, y: 142.72),
        _ExpectedPoint(x: 125.28, y: 167.68),
        _ExpectedPoint(x: 79.84, y: 167.68),
      ],
      left: 79.20,
      top: 142.72,
      width: 46.08,
      height: 24.96,
    ),
    adaptiveExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 79.20, y: 141.76),
        _ExpectedPoint(x: 120.80, y: 141.76),
        _ExpectedPoint(x: 125.68, y: 174.40),
        _ExpectedPoint(x: 79.44, y: 174.40),
      ],
      left: 79.20,
      top: 141.76,
      width: 46.48,
      height: 32.64,
    ),
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow v2 adaptive depth width guard artifact',
      () async {
    final image = await _renderArtifact();
    expect(image.width, _artifactWidth);
    expect(image.height, _artifactHeight);

    final backgroundPixel = await _pixelAt(image, 12, 44);
    expect(backgroundPixel, _rgba(_backgroundColor));

    for (var guardIndex = 0; guardIndex < _guardCases.length; guardIndex += 1) {
      final guard = _guardCases[guardIndex];
      final columnLeft = guardIndex * _columnWidth;
      final gates = _gatesFor(guard);
      _expectGateClose(gates.heightGate, guard.expectedHeightGate);
      _expectGateClose(gates.ratioGate, guard.expectedRatioGate);
      _expectGateClose(gates.adaptiveT, guard.expectedAdaptiveT);

      for (final mode in _shadowModes) {
        final expected = mode.isAdaptive ? guard.adaptiveExpected : guard.standardExpected;
        final geometry = _geometryFor(mode, guard);
        final instruction = _instructionFor(mode, guard);
        final tuning = _effectiveTuningFor(mode, guard);

        expect(geometry.opacity, closeTo(tuning.opacity, 0.000001));
        expect(geometry.colorHexRgb, '606060');
        _expectGeometryClose(geometry, expected);
        _expectBoundsClose(instruction, expected);

        final shadowOnlyRowTop = mode.isAdaptive ? _row1Top : _row0Top;
        final centroid = _centroid(geometry);
        final shadowOnlyPixel = await _pixelAt(
          image,
          columnLeft + centroid.x.round(),
          shadowOnlyRowTop + centroid.y.round(),
        );
        expect(
          shadowOnlyPixel,
          isNot(backgroundPixel),
          reason: '${guard.id}/${mode.id} shadow-only should render',
        );

        final objectRowTop = mode.isAdaptive ? _row3Top : _row2Top;
        final objectPixel = await _objectPixel(
          image,
          columnLeft: columnLeft,
          rowTop: objectRowTop,
          guard: guard,
        );
        expect(
          objectPixel,
          isNot(backgroundPixel),
          reason: '${guard.id}/${mode.id} object should render',
        );

        final visibleShadowPoint = _visibleShadowPoint(geometry);
        final visibleShadowPixel = await _pixelAt(
          image,
          columnLeft + visibleShadowPoint.x.round(),
          objectRowTop + visibleShadowPoint.y.round(),
        );
        expect(
          visibleShadowPixel,
          isNot(backgroundPixel),
          reason: '${guard.id}/${mode.id} visible shadow should render',
        );
      }
    }

    final wideStandard = _geometryFor(_standardMode, _guardCases[0]);
    final wideAdaptive = _geometryFor(_adaptiveCPlusMode, _guardCases[0]);
    _expectGeometryClose(wideAdaptive, _guardCases[0].standardExpected);
    _expectGeometryClose(wideStandard, _guardCases[0].standardExpected);

    final mediumStandard = _geometryFor(_standardMode, _guardCases[1]);
    final mediumAdaptive = _geometryFor(_adaptiveCPlusMode, _guardCases[1]);
    _expectGeometryClose(mediumAdaptive, _guardCases[1].standardExpected);
    _expectGeometryClose(mediumStandard, _guardCases[1].standardExpected);

    final tallAdaptive = _geometryFor(_adaptiveCPlusMode, _guardCases[2]);
    _expectGeometryClose(tallAdaptive, _guardCases[2].adaptiveExpected);

    final thinTuning = _effectiveTuningFor(_adaptiveCPlusMode, _guardCases[3]);
    expect(thinTuning.attachYRatio, closeTo(0.81, 0.000001));
    expect(thinTuning.frontWidthRatio, closeTo(1.30, 0.000001));
    expect(thinTuning.rearWidthRatio, closeTo(1.445, 0.000001));
    expect(thinTuning.depthRatio, closeTo(0.34, 0.000001));
    expect(thinTuning.skewXRatio, closeTo(0.08, 0.000001));
    expect(thinTuning.opacity, closeTo(0.23, 0.000001));

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

  for (var index = 0; index < _guardCases.length; index += 1) {
    final guard = _guardCases[index];
    final columnLeft = (index * _columnWidth).toDouble();
    _drawLabel(canvas, guard.label, columnLeft: columnLeft);
    _drawCell(canvas, _standardMode, guard, columnLeft, _row0Top.toDouble(), false);
    _drawCell(canvas, _adaptiveCPlusMode, guard, columnLeft, _row1Top.toDouble(), false);
    _drawCell(canvas, _standardMode, guard, columnLeft, _row2Top.toDouble(), true);
    _drawCell(canvas, _adaptiveCPlusMode, guard, columnLeft, _row3Top.toDouble(), true);
  }

  _drawDividers(canvas);

  return recorder.endRecording().toImage(_artifactWidth, _artifactHeight);
}

void _drawCell(
  ui.Canvas canvas,
  _ShadowMode mode,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
  bool drawObject,
) {
  _drawCellBackground(canvas, columnLeft, rowTop);
  _drawShadow(canvas, mode, guard, columnLeft, rowTop);
  if (drawObject) {
    _drawGuardObject(canvas, guard, columnLeft, rowTop);
  }
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
  for (final y in [_headerHeight, _row1Top, _row2Top, _row3Top]) {
    canvas.drawLine(
      ui.Offset(0, y - 0.5),
      ui.Offset(_artifactWidth + 0.0, y - 0.5),
      paint,
    );
  }
}

void _drawShadow(
  ui.Canvas canvas,
  _ShadowMode mode,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
) {
  canvas.save();
  canvas.translate(columnLeft, rowTop);
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    _collectionFor(mode, guard),
    ShadowRenderPass.groundStatic,
  );
  canvas.restore();
}

ShadowRuntimeInstructionCollection _collectionFor(
  _ShadowMode mode,
  _GuardCase guard,
) {
  return ShadowRuntimeInstructionCollection(
    instructions: [_instructionFor(mode, guard)],
  );
}

ShadowRuntimeRenderInstruction _instructionFor(
  _ShadowMode mode,
  _GuardCase guard,
) {
  return createProjectedBuildingShadowRuntimeInstruction(
    _geometryFor(mode, guard),
  );
}

ProjectedBuildingShadowGeometry _geometryFor(
  _ShadowMode mode,
  _GuardCase guard,
) {
  final geometry = resolveProjectedBuildingShadowGeometry(
    config: _shadowConfigFor(mode),
    preset: _shadowPresetFor(mode, guard),
    metrics: _metricsForGuard(guard),
  );
  if (geometry == null) {
    throw StateError('${mode.id}/${guard.id} did not produce geometry');
  }
  return geometry;
}

StaticShadowVisualMetrics _metricsForGuard(_GuardCase guard) {
  return StaticShadowVisualMetrics(
    left: guard.left,
    top: guard.top,
    visualWidth: guard.width,
    visualHeight: guard.height,
  );
}

ProjectBuildingShadowPreset _shadowPresetFor(
  _ShadowMode mode,
  _GuardCase guard,
) {
  final tuning = _effectiveTuningFor(mode, guard);
  return ProjectBuildingShadowPreset(
    id: mode.id,
    name: mode.label,
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.32,
      nearWidthRatio: 0.90,
      farWidthRatio: 0.72,
    ),
    footprint: ProjectedShadowFootprintTuning(
      attachYRatio: tuning.attachYRatio,
      frontWidthRatio: tuning.frontWidthRatio,
      rearWidthRatio: tuning.rearWidthRatio,
      depthRatio: tuning.depthRatio,
      skewXRatio: tuning.skewXRatio,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: tuning.opacity,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _shadowConfigFor(_ShadowMode mode) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: mode.id,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

_EffectiveTuning _effectiveTuningFor(_ShadowMode mode, _GuardCase guard) {
  if (!mode.isAdaptive) {
    return _EffectiveTuning(
      attachYRatio: mode.attachYRatio,
      frontWidthRatio: mode.frontWidthRatio,
      rearWidthRatio: mode.rearWidthRatio,
      depthRatio: mode.depthRatio,
      skewXRatio: mode.skewXRatio,
      opacity: mode.opacity,
    );
  }

  final gates = _gatesFor(guard);
  return _EffectiveTuning(
    attachYRatio: _lerp(mode.attachYRatio, mode.targetAttachYRatio, gates.adaptiveT),
    frontWidthRatio: mode.frontWidthRatio,
    rearWidthRatio: _lerp(mode.rearWidthRatio, mode.targetRearWidthRatio, gates.adaptiveT),
    depthRatio: _lerp(mode.depthRatio, mode.targetDepthRatio, gates.adaptiveT),
    skewXRatio: mode.skewXRatio,
    opacity: _lerp(mode.opacity, mode.targetOpacity, gates.adaptiveT),
  );
}

_AdaptiveGates _gatesFor(_GuardCase guard) {
  final heightGate = _clamp01((guard.height - 80) / 32);
  final ratioGate = _clamp01((guard.height / guard.width - 1.25) / 0.50);
  return _AdaptiveGates(
    heightGate: heightGate,
    ratioGate: ratioGate,
    adaptiveT: heightGate * ratioGate,
  );
}

void _drawGuardObject(
  ui.Canvas canvas,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
) {
  switch (guard.objectKind) {
    case _GuardObjectKind.wideHouse:
      _drawWideHouse(canvas, guard, columnLeft, rowTop);
    case _GuardObjectKind.mediumShop:
      _drawMediumShop(canvas, guard, columnLeft, rowTop);
    case _GuardObjectKind.tallShop:
      _drawTallShop(canvas, guard, columnLeft, rowTop);
    case _GuardObjectKind.thinPropLike:
      _drawThinPropLike(canvas, guard, columnLeft, rowTop);
  }
}

void _drawWideHouse(
  ui.Canvas canvas,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + guard.left;
  final top = rowTop + guard.top;
  final width = guard.width;
  final height = guard.height;
  final outline = _outlinePaint();
  final fill = _fillPaint(_bodyColor);
  final roof = _fillPaint(_roofColor);

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

void _drawMediumShop(
  ui.Canvas canvas,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + guard.left;
  final top = rowTop + guard.top;
  final width = guard.width;
  final height = guard.height;
  final outline = _outlinePaint();
  final fill = _fillPaint(_bodyColor);
  final roof = _fillPaint(_roofColor);
  final sign = _fillPaint(_signColor);

  canvas.drawRect(ui.Rect.fromLTWH(left, top + 18, width, height - 18), fill);
  canvas.drawRect(ui.Rect.fromLTWH(left, top + 18, width, height - 18), outline);
  canvas.drawRect(ui.Rect.fromLTWH(left - 4, top, width + 8, 20), roof);
  canvas.drawRect(ui.Rect.fromLTWH(left - 4, top, width + 8, 20), outline);
  canvas.drawRect(ui.Rect.fromLTWH(left + 10, top + 26, width - 20, 12), sign);
  canvas.drawRect(ui.Rect.fromLTWH(left + 10, top + 26, width - 20, 12), outline);
  _drawDoor(canvas, left + width / 2 - 8, top + height - 30, 16, 30);
  _drawWindow(canvas, left + 14, top + 54, 14, 18);
  _drawWindow(canvas, left + width - 28, top + 54, 14, 18);
}

void _drawTallShop(
  ui.Canvas canvas,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + guard.left;
  final top = rowTop + guard.top;
  final width = guard.width;
  final height = guard.height;
  final outline = _outlinePaint();
  final fill = _fillPaint(_bodyColor);
  final roof = _fillPaint(_roofColor);
  final sign = _fillPaint(_signColor);

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

void _drawThinPropLike(
  ui.Canvas canvas,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
) {
  final centerX = columnLeft + guard.left + guard.width / 2;
  final top = rowTop + guard.top;
  final bottom = top + guard.height;
  final outline = _outlinePaint();
  final metal = _fillPaint(_metalColor);
  final lamp = _fillPaint(_signColor);

  canvas.drawRect(ui.Rect.fromLTWH(centerX - 5, top + 26, 10, guard.height - 26), metal);
  canvas.drawRect(ui.Rect.fromLTWH(centerX - 5, top + 26, 10, guard.height - 26), outline);
  canvas.drawRect(ui.Rect.fromLTWH(centerX - 14, top + 10, 28, 18), lamp);
  canvas.drawRect(ui.Rect.fromLTWH(centerX - 14, top + 10, 28, 18), outline);
  canvas.drawLine(
    ui.Offset(centerX - 12, bottom),
    ui.Offset(centerX + 12, bottom),
    outline,
  );
}

void _drawDoor(ui.Canvas canvas, double left, double top, double width, double height) {
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _fillPaint(_doorColor),
  );
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _outlinePaint(),
  );
}

void _drawWindow(ui.Canvas canvas, double left, double top, double width, double height) {
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _fillPaint(_windowColor),
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
    ..color = _outlineColor
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
    throw StateError('Could not encode ShadowV2 adaptive depth width guard artifact as PNG');
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

Future<_Rgba> _objectPixel(
  ui.Image image, {
  required int columnLeft,
  required int rowTop,
  required _GuardCase guard,
}) {
  return _pixelAt(
    image,
    columnLeft + (guard.left + guard.width / 2).round(),
    rowTop + (guard.top + math.min(40, guard.height / 2)).round(),
  );
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

double _clamp01(double value) => value.clamp(0, 1).toDouble();

double _lerp(double start, double end, double t) => start + (end - start) * t;

void _expectGeometryClose(
  ProjectedBuildingShadowGeometry geometry,
  _ExpectedGeometry expected,
) {
  expect(geometry.points, hasLength(4));
  for (var pointIndex = 0; pointIndex < expected.points.length; pointIndex += 1) {
    _expectPointClose(
      geometry.points[pointIndex],
      x: expected.points[pointIndex].x,
      y: expected.points[pointIndex].y,
    );
  }
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
  _ExpectedGeometry expected,
) {
  expect(instruction.worldLeft, closeTo(expected.left, 0.02));
  expect(instruction.worldTop, closeTo(expected.top, 0.02));
  expect(instruction.width, closeTo(expected.width, 0.02));
  expect(instruction.height, closeTo(expected.height, 0.02));
}

void _expectGateClose(double actual, double expected) {
  expect(actual, closeTo(expected, 0.000001));
}

final class _ShadowMode {
  const _ShadowMode.fixed({
    required this.id,
    required this.label,
    required this.attachYRatio,
    required this.frontWidthRatio,
    required this.rearWidthRatio,
    required this.depthRatio,
    required this.skewXRatio,
    required this.opacity,
  })  : isAdaptive = false,
        targetAttachYRatio = attachYRatio,
        targetRearWidthRatio = rearWidthRatio,
        targetDepthRatio = depthRatio,
        targetOpacity = opacity;

  const _ShadowMode.adaptive({
    required this.id,
    required this.label,
    required this.attachYRatio,
    required this.targetAttachYRatio,
    required this.frontWidthRatio,
    required this.rearWidthRatio,
    required this.targetRearWidthRatio,
    required this.depthRatio,
    required this.targetDepthRatio,
    required this.skewXRatio,
    required this.opacity,
    required this.targetOpacity,
  }) : isAdaptive = true;

  final String id;
  final String label;
  final bool isAdaptive;
  final double attachYRatio;
  final double targetAttachYRatio;
  final double frontWidthRatio;
  final double rearWidthRatio;
  final double targetRearWidthRatio;
  final double depthRatio;
  final double targetDepthRatio;
  final double skewXRatio;
  final double opacity;
  final double targetOpacity;
}

final class _GuardCase {
  const _GuardCase({
    required this.id,
    required this.label,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.expectedHeightGate,
    required this.expectedRatioGate,
    required this.expectedAdaptiveT,
    required this.objectKind,
    required this.standardExpected,
    required this.adaptiveExpected,
  });

  final String id;
  final String label;
  final double left;
  final double top;
  final double width;
  final double height;
  final double expectedHeightGate;
  final double expectedRatioGate;
  final double expectedAdaptiveT;
  final _GuardObjectKind objectKind;
  final _ExpectedGeometry standardExpected;
  final _ExpectedGeometry adaptiveExpected;
}

enum _GuardObjectKind {
  wideHouse,
  mediumShop,
  tallShop,
  thinPropLike,
}

final class _EffectiveTuning {
  const _EffectiveTuning({
    required this.attachYRatio,
    required this.frontWidthRatio,
    required this.rearWidthRatio,
    required this.depthRatio,
    required this.skewXRatio,
    required this.opacity,
  });

  final double attachYRatio;
  final double frontWidthRatio;
  final double rearWidthRatio;
  final double depthRatio;
  final double skewXRatio;
  final double opacity;
}

final class _AdaptiveGates {
  const _AdaptiveGates({
    required this.heightGate,
    required this.ratioGate,
    required this.adaptiveT,
  });

  final double heightGate;
  final double ratioGate;
  final double adaptiveT;
}

final class _ExpectedGeometry {
  const _ExpectedGeometry({
    required this.points,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final List<_ExpectedPoint> points;
  final double left;
  final double top;
  final double width;
  final double height;
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
    return other is _Rgba && r == other.r && g == other.g && b == other.b && a == other.a;
  }

  @override
  int get hashCode => Object.hash(r, g, b, a);

  @override
  String toString() => 'rgba($r, $g, $b, $a)';
}
