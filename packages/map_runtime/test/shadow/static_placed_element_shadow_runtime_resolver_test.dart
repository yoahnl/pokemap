import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_resolver.dart';
import 'package:map_runtime/src/shadow/static_placed_element_shadow_runtime_resolver.dart';

void main() {
  group('StaticPlacedElementShadowRuntimeMetrics', () {
    test('creates valid metrics with default ratios and multipliers', () {
      final metrics = _metrics();

      expect(metrics.worldLeft, 80);
      expect(metrics.worldTop, 120);
      expect(metrics.visualWidth, 40);
      expect(metrics.visualHeight, 60);
      expect(metrics.anchorXRatio, 0.5);
      expect(metrics.anchorYRatio, 1.0);
      expect(metrics.baseWidthMultiplier, 0.75);
      expect(metrics.baseHeightMultiplier, 0.25);
    });

    test('accepts custom valid ratios and multipliers', () {
      final metrics = _metrics(
        anchorXRatio: 0.25,
        anchorYRatio: 0.75,
        baseWidthMultiplier: 0.5,
        baseHeightMultiplier: 0.125,
      );

      expect(metrics.anchorXRatio, 0.25);
      expect(metrics.anchorYRatio, 0.75);
      expect(metrics.baseWidthMultiplier, 0.5);
      expect(metrics.baseHeightMultiplier, 0.125);
    });

    test('rejects non-finite world coordinates', () {
      expect(
        () => _metrics(worldLeft: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(worldLeft: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(worldTop: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _metrics(worldTop: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid visual dimensions', () {
      for (final width in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(visualWidth: width),
          throwsA(isA<ValidationException>()),
          reason: 'visualWidth $width should be rejected',
        );
      }

      for (final height in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(visualHeight: height),
          throwsA(isA<ValidationException>()),
          reason: 'visualHeight $height should be rejected',
        );
      }
    });

    test('rejects invalid anchor ratios', () {
      for (final ratio in <double>[
        -0.1,
        1.1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(anchorXRatio: ratio),
          throwsA(isA<ValidationException>()),
          reason: 'anchorXRatio $ratio should be rejected',
        );
      }

      for (final ratio in <double>[
        -0.1,
        1.1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(anchorYRatio: ratio),
          throwsA(isA<ValidationException>()),
          reason: 'anchorYRatio $ratio should be rejected',
        );
      }
    });

    test('rejects invalid base multipliers', () {
      for (final multiplier in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(baseWidthMultiplier: multiplier),
          throwsA(isA<ValidationException>()),
          reason: 'baseWidthMultiplier $multiplier should be rejected',
        );
      }

      for (final multiplier in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _metrics(baseHeightMultiplier: multiplier),
          throwsA(isA<ValidationException>()),
          reason: 'baseHeightMultiplier $multiplier should be rejected',
        );
      }
    });

    test('uses value equality and matching hashCode', () {
      final a = _metrics();
      final b = _metrics();
      final c = _metrics(worldLeft: 81);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('StaticPlacedElementShadowRuntimeInput', () {
    test('uses value equality and matching hashCode', () {
      final a = _input();
      final b = _input();
      final c = _input(metrics: _metrics(worldLeft: 81));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('equality includes element and override footprints', () {
      final a = _input(
        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
        overrideFootprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
      );
      final b = _input(
        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
        overrideFootprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
      );
      final c = _input(
        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.5),
        overrideFootprint: StaticShadowFootprintConfig(anchorYRatio: 0.75),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('equality includes element and override families', () {
      final a = _input(
        elementFamily: StaticShadowFamily.tallProp,
        overrideFamily: StaticShadowFamily.building,
      );
      final b = _input(
        elementFamily: StaticShadowFamily.tallProp,
        overrideFamily: StaticShadowFamily.building,
      );
      final c = _input(
        elementFamily: StaticShadowFamily.compactProp,
        overrideFamily: StaticShadowFamily.building,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('staticPlacedElementShadowAnchorFromMetrics', () {
    test('converts static metrics into a runtime anchor', () {
      final anchor = staticPlacedElementShadowAnchorFromMetrics(_metrics());

      expect(anchor, isA<ShadowRuntimeAnchor>());
      expect(anchor.worldX, closeTo(100, 0.000001));
      expect(anchor.worldY, closeTo(180, 0.000001));
      expect(anchor.baseWidth, closeTo(30, 0.000001));
      expect(anchor.baseHeight, closeTo(15, 0.000001));
    });

    test('preserves custom legacy metrics ratios and multipliers', () {
      final anchor = staticPlacedElementShadowAnchorFromMetrics(
        _metrics(
          anchorXRatio: 0.25,
          anchorYRatio: 0.75,
          baseWidthMultiplier: 0.5,
          baseHeightMultiplier: 0.125,
        ),
      );

      expect(anchor.worldX, closeTo(90, 0.000001));
      expect(anchor.worldY, closeTo(165, 0.000001));
      expect(anchor.baseWidth, closeTo(20, 0.000001));
      expect(anchor.baseHeight, closeTo(7.5, 0.000001));
    });

    test('element footprint overrides legacy metrics field by field', () {
      final anchor = staticPlacedElementShadowAnchorFromMetrics(
        _metrics(
          anchorXRatio: 0.25,
          anchorYRatio: 0.75,
          baseWidthMultiplier: 0.5,
          baseHeightMultiplier: 0.125,
        ),
        elementFootprint: StaticShadowFootprintConfig(
          anchorYRatio: 0.5,
          footprintWidthRatio: 0.25,
        ),
      );

      expect(anchor.worldX, closeTo(90, 0.000001));
      expect(anchor.worldY, closeTo(150, 0.000001));
      expect(anchor.baseWidth, closeTo(10, 0.000001));
      expect(anchor.baseHeight, closeTo(7.5, 0.000001));
    });

    test('override footprint wins over element footprint field by field', () {
      final anchor = staticPlacedElementShadowAnchorFromMetrics(
        _metrics(),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.25,
          anchorYRatio: 0.75,
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.125,
        ),
        overrideFootprint: StaticShadowFootprintConfig(
          anchorYRatio: 0.5,
          footprintWidthRatio: 0.25,
        ),
      );

      expect(anchor.worldX, closeTo(90, 0.000001));
      expect(anchor.worldY, closeTo(150, 0.000001));
      expect(anchor.baseWidth, closeTo(10, 0.000001));
      expect(anchor.baseHeight, closeTo(7.5, 0.000001));
    });
  });

  group('resolveStaticPlacedElementShadowRuntimeInstruction', () {
    test('resolves ellipse groundStatic into a projected polygon instruction',
        () {
      final input = _input();
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      expect(instruction!.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.polygonPoints, hasLength(4));
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      _expectInstructionMatchesProjectedGeometry(instruction, input);
    });

    test(
        'resolves contactBlob groundStatic into a projected polygon instruction',
        () {
      final input = _input(
        resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.contactBlob),
      );
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      expect(instruction!.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.polygonPoints, hasLength(4));
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      _expectInstructionMatchesProjectedGeometry(instruction, input);
    });

    test('applies static metrics and Shadow-12 offset/scale geometry', () {
      final input = _input();
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      _expectInstructionMatchesProjectedGeometry(instruction!, input);
      _expectAllPointsInsideBounds(instruction);
    });

    test('applies offset and scale once after core footprint geometry', () {
      final input = _input(
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.25,
          anchorYRatio: 0.5,
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.25,
        ),
      );
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      _expectInstructionMatchesProjectedGeometry(instruction!, input);
    });

    test('custom override without footprint keeps element footprint', () {
      final input = _input(
        resolvedConfig: _resolvedConfig(offsetX: 4),
        elementFootprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
      );
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      _expectInstructionMatchesProjectedGeometry(instruction!, input);
    });

    test('building family emits a short contact ledge polygon', () {
      final input = _input(
        resolvedConfig: _resolvedConfig(
          offsetX: 0,
          offsetY: 0,
          scaleX: 0.72,
          scaleY: 0.44,
        ),
        metrics: _metrics(
          worldLeft: 160,
          worldTop: 96,
          visualWidth: 192,
          visualHeight: 224,
        ),
        elementFootprint: StaticShadowFootprintConfig(
          anchorXRatio: 0.5,
          anchorYRatio: 0.92,
          footprintWidthRatio: 0.6,
          footprintHeightRatio: 0.08,
        ),
        elementFamily: StaticShadowFamily.building,
      );

      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      _expectInstructionMatchesBuildingContactLedge(instruction!, input);
      expect(instruction.height, greaterThan(13));
      expect(instruction.height, lessThan(15));
      expect(instruction.width, greaterThan(118));
      expect(instruction.width, lessThan(121));
    });

    test('building contact ledge uses resolved footprint width', () {
      final narrow = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          elementFamily: StaticShadowFamily.building,
          elementFootprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.25,
            footprintHeightRatio: 0.08,
          ),
        ),
      )!;
      final wide = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          elementFamily: StaticShadowFamily.building,
          elementFootprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.75,
            footprintHeightRatio: 0.08,
          ),
        ),
      )!;

      _expectBuildingContactLedgeShape(narrow);
      _expectBuildingContactLedgeShape(wide);
      expect(narrow.width, lessThan(wide.width));
    });

    test('building contact ledge applies offset and scale once', () {
      final input = _input(
        resolvedConfig: _resolvedConfig(
          offsetX: 5,
          offsetY: 7,
          scaleX: 2,
          scaleY: 0.5,
        ),
        elementFamily: StaticShadowFamily.building,
        elementFootprint: StaticShadowFootprintConfig(
          footprintWidthRatio: 0.5,
          footprintHeightRatio: 0.2,
        ),
      );

      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      _expectInstructionMatchesBuildingContactLedge(instruction!, input);
    });

    test('non-building family keeps projected shadow geometry', () {
      final input = _input(
        elementFamily: StaticShadowFamily.tallProp,
        elementFootprint: StaticShadowFootprintConfig(
          footprintWidthRatio: 0.25,
          footprintHeightRatio: 0.08,
        ),
      );

      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        input,
      );

      expect(instruction, isNotNull);
      _expectInstructionMatchesProjectedGeometry(instruction!, input);
    });

    test('element family changes the projected shadow silhouette', () {
      final tallProp = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          elementFamily: StaticShadowFamily.tallProp,
          elementFootprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.25,
            footprintHeightRatio: 0.08,
          ),
        ),
      )!;
      final building = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          elementFamily: StaticShadowFamily.building,
          elementFootprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.25,
            footprintHeightRatio: 0.08,
          ),
        ),
      )!;

      expect(tallProp.width, lessThan(building.width));
      expect(tallProp.polygonPoints, isNot(building.polygonPoints));
    });

    test('override family wins over element family', () {
      final overrideBuilding =
          resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          elementFamily: StaticShadowFamily.tallProp,
          overrideFamily: StaticShadowFamily.building,
          elementFootprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.25,
            footprintHeightRatio: 0.08,
          ),
        ),
      )!;
      final building = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          elementFamily: StaticShadowFamily.building,
          elementFootprint: StaticShadowFootprintConfig(
            footprintWidthRatio: 0.25,
            footprintHeightRatio: 0.08,
          ),
        ),
      )!;

      expect(overrideBuilding.width, closeTo(building.width, 0.000001));
      expect(overrideBuilding.height, closeTo(building.height, 0.000001));
    });

    test('passes opacity color softness and renderPass through', () {
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          resolvedConfig: _resolvedConfig(
            opacity: 0.7,
            colorHexRgb: '0a0b0c',
            softnessMode: ShadowSoftnessMode.hardEdge,
          ),
        ),
      );

      expect(instruction, isNotNull);
      expect(instruction!.opacity, 0.7);
      expect(instruction.colorHexRgb, '0A0B0C');
      expect(instruction.softnessMode, ShadowSoftnessMode.hardEdge);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
    });

    test('keeps opacity zero as a valid instruction', () {
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(resolvedConfig: _resolvedConfig(opacity: 0)),
      );

      expect(instruction, isNotNull);
      expect(instruction!.opacity, 0);
    });

    test('returns null for ShadowCasterMode.none before render pass checks',
        () {
      final instruction = resolveStaticPlacedElementShadowRuntimeInstruction(
        _input(
          resolvedConfig: _resolvedConfig(
            mode: ShadowCasterMode.none,
            renderPass: ShadowRenderPass.actorContact,
          ),
        ),
      );

      expect(instruction, isNull);
    });

    test('rejects actorContact render pass', () {
      expect(
        () => resolveStaticPlacedElementShadowRuntimeInstruction(
          _input(
            resolvedConfig: _resolvedConfig(
              renderPass: ShadowRenderPass.actorContact,
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('does not silently clamp invalid computed dimensions', () {
      expect(
        () => resolveStaticPlacedElementShadowRuntimeInstruction(
          _input(resolvedConfig: _resolvedConfig(scaleX: -1)),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('resolveStaticPlacedElementShadowRuntimeInstructions', () {
    test('returns an empty list for no inputs', () {
      expect(resolveStaticPlacedElementShadowRuntimeInstructions(const []),
          isEmpty);
    });

    test('resolves one input into one instruction', () {
      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        _input(),
      ]);

      expect(instructions, hasLength(1));
      expect(
        instructions.single.shape,
        ShadowRuntimeShapeKind.projectedPolygon,
      );
    });

    test('preserves input order without sorting', () {
      final first = _input(
        metrics: _metrics(worldLeft: 80),
        resolvedConfig: _resolvedConfig(offsetX: 0),
      );
      final second = _input(
        metrics: _metrics(worldLeft: 200),
        resolvedConfig: _resolvedConfig(offsetX: 0),
      );

      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        first,
        second,
      ]);

      expect(instructions, hasLength(2));
      expect(instructions[0].worldLeft, lessThan(instructions[1].worldLeft));
    });

    test('ignores mode none inputs', () {
      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        _input(resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.none)),
        _input(),
      ]);

      expect(instructions, hasLength(1));
      expect(
        instructions.single.shape,
        ShadowRuntimeShapeKind.projectedPolygon,
      );
    });

    test('does not cull opacity zero instructions', () {
      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        _input(resolvedConfig: _resolvedConfig(opacity: 0)),
      ]);

      expect(instructions, hasLength(1));
      expect(instructions.single.opacity, 0);
    });

    test('does not deduplicate equal inputs', () {
      final input = _input();

      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        input,
        input,
      ]);

      expect(instructions, hasLength(2));
      expect(instructions[0], instructions[1]);
    });

    test('does not modify inputs and exposes an unmodifiable list', () {
      final input = _input();
      final before = _input();

      final instructions = resolveStaticPlacedElementShadowRuntimeInstructions([
        input,
      ]);

      expect(input, before);
      expect(
        () => instructions.add(
          resolveStaticPlacedElementShadowRuntimeInstruction(_input())!,
        ),
        throwsUnsupportedError,
      );
    });
  });
}

StaticPlacedElementShadowRuntimeMetrics _metrics({
  double worldLeft = 80,
  double worldTop = 120,
  double visualWidth = 40,
  double visualHeight = 60,
  double anchorXRatio = 0.5,
  double anchorYRatio = 1.0,
  double baseWidthMultiplier = 0.75,
  double baseHeightMultiplier = 0.25,
}) {
  return StaticPlacedElementShadowRuntimeMetrics(
    worldLeft: worldLeft,
    worldTop: worldTop,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
    anchorXRatio: anchorXRatio,
    anchorYRatio: anchorYRatio,
    baseWidthMultiplier: baseWidthMultiplier,
    baseHeightMultiplier: baseHeightMultiplier,
  );
}

StaticPlacedElementShadowRuntimeInput _input({
  ResolvedShadowConfig? resolvedConfig,
  StaticPlacedElementShadowRuntimeMetrics? metrics,
  StaticShadowFootprintConfig? elementFootprint,
  StaticShadowFootprintConfig? overrideFootprint,
  StaticShadowFamily? elementFamily,
  StaticShadowFamily? overrideFamily,
}) {
  return StaticPlacedElementShadowRuntimeInput(
    resolvedConfig: resolvedConfig ?? _resolvedConfig(),
    metrics: metrics ?? _metrics(),
    elementFootprint: elementFootprint,
    overrideFootprint: overrideFootprint,
    elementFamily: elementFamily,
    overrideFamily: overrideFamily,
  );
}

ResolvedShadowConfig _resolvedConfig({
  String shadowProfileId = 'tree_large',
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double offsetX = 6,
  double offsetY = 10,
  double scaleX = 1.2,
  double scaleY = 0.5,
  double opacity = 0.35,
  String colorHexRgb = '000000',
  ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
}) {
  return ResolvedShadowConfig(
    shadowProfileId: shadowProfileId,
    mode: mode,
    renderPass: renderPass,
    offsetX: offsetX,
    offsetY: offsetY,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
    softnessMode: softnessMode,
  );
}

void _expectInstructionMatchesProjectedGeometry(
  ShadowRuntimeRenderInstruction instruction,
  StaticPlacedElementShadowRuntimeInput input,
) {
  final expected = _expectedProjectedGeometry(input);
  final expectedPoints = expected.points
      .map(
        (point) => ShadowRuntimePoint(
          worldX: point.x,
          worldY: point.y,
        ),
      )
      .toList();

  expect(instruction.polygonPoints, hasLength(expectedPoints.length));
  for (var i = 0; i < expectedPoints.length; i += 1) {
    expect(
      instruction.polygonPoints[i].worldX,
      closeTo(expectedPoints[i].worldX, 0.000001),
    );
    expect(
      instruction.polygonPoints[i].worldY,
      closeTo(expectedPoints[i].worldY, 0.000001),
    );
  }

  final expectedBounds = _boundsFromPoints(expectedPoints);
  expect(instruction.worldLeft, closeTo(expectedBounds.left, 0.000001));
  expect(instruction.worldTop, closeTo(expectedBounds.top, 0.000001));
  expect(instruction.width, closeTo(expectedBounds.width, 0.000001));
  expect(instruction.height, closeTo(expectedBounds.height, 0.000001));
}

void _expectAllPointsInsideBounds(ShadowRuntimeRenderInstruction instruction) {
  for (final point in instruction.polygonPoints) {
    expect(point.worldX, greaterThanOrEqualTo(instruction.worldLeft));
    expect(
      point.worldX,
      lessThanOrEqualTo(instruction.worldLeft + instruction.width),
    );
    expect(point.worldY, greaterThanOrEqualTo(instruction.worldTop));
    expect(
      point.worldY,
      lessThanOrEqualTo(instruction.worldTop + instruction.height),
    );
  }
}

ProjectedStaticShadowGeometry _expectedProjectedGeometry(
  StaticPlacedElementShadowRuntimeInput input,
) {
  final metrics = input.metrics;
  final legacyAndElementFootprint = resolveStaticShadowFootprint(
    elementFootprint: StaticShadowFootprintConfig(
      anchorXRatio: metrics.anchorXRatio,
      anchorYRatio: metrics.anchorYRatio,
      footprintWidthRatio: metrics.baseWidthMultiplier,
      footprintHeightRatio: metrics.baseHeightMultiplier,
    ),
    overrideFootprint: input.elementFootprint,
  );
  final baseGeometry = resolveStaticShadowGeometry(
    metrics: StaticShadowVisualMetrics(
      left: metrics.worldLeft,
      top: metrics.worldTop,
      visualWidth: metrics.visualWidth,
      visualHeight: metrics.visualHeight,
    ),
    shadowConfig: input.resolvedConfig,
    elementFootprint: StaticShadowFootprintConfig(
      anchorXRatio: legacyAndElementFootprint.anchorXRatio,
      anchorYRatio: legacyAndElementFootprint.anchorYRatio,
      footprintWidthRatio: legacyAndElementFootprint.footprintWidthRatio,
      footprintHeightRatio: legacyAndElementFootprint.footprintHeightRatio,
    ),
    overrideFootprint: input.overrideFootprint,
  );
  return resolveProjectedStaticShadowGeometry(
    baseGeometry: baseGeometry,
    metrics: StaticShadowVisualMetrics(
      left: metrics.worldLeft,
      top: metrics.worldTop,
      visualWidth: metrics.visualWidth,
      visualHeight: metrics.visualHeight,
    ),
    projectionSpec: resolveStaticShadowFamilyProjectionSpec(
      family: resolveStaticShadowFamily(
        elementFamily: input.elementFamily,
        overrideFamily: input.overrideFamily,
      ),
    ),
  );
}

void _expectInstructionMatchesBuildingContactLedge(
  ShadowRuntimeRenderInstruction instruction,
  StaticPlacedElementShadowRuntimeInput input,
) {
  _expectBuildingContactLedgeShape(instruction);
  final expectedPoints = _expectedBuildingContactLedgePoints(input);

  expect(instruction.polygonPoints, hasLength(expectedPoints.length));
  for (var i = 0; i < expectedPoints.length; i += 1) {
    expect(
      instruction.polygonPoints[i].worldX,
      closeTo(expectedPoints[i].worldX, 0.000001),
    );
    expect(
      instruction.polygonPoints[i].worldY,
      closeTo(expectedPoints[i].worldY, 0.000001),
    );
  }

  final expectedBounds = _boundsFromPoints(expectedPoints);
  expect(instruction.worldLeft, closeTo(expectedBounds.left, 0.000001));
  expect(instruction.worldTop, closeTo(expectedBounds.top, 0.000001));
  expect(instruction.width, closeTo(expectedBounds.width, 0.000001));
  expect(instruction.height, closeTo(expectedBounds.height, 0.000001));
}

void _expectBuildingContactLedgeShape(
  ShadowRuntimeRenderInstruction instruction,
) {
  expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
  expect(instruction.polygonPoints, hasLength(4));
  final points = instruction.polygonPoints;
  expect(points[0].worldY, closeTo(points[1].worldY, 0.000001));
  expect(points[2].worldY, closeTo(points[3].worldY, 0.000001));
  expect(points[2].worldY, greaterThan(points[0].worldY));
  expect(points[3].worldY, greaterThan(points[1].worldY));
  _expectAllPointsInsideBounds(instruction);
}

List<ShadowRuntimePoint> _expectedBuildingContactLedgePoints(
  StaticPlacedElementShadowRuntimeInput input,
) {
  final metrics = input.metrics;
  final geometry = resolveBuildingStaticShadowContactLedgeGeometry(
    baseGeometry: _expectedBaseGeometry(input),
    metrics: StaticShadowVisualMetrics(
      left: metrics.worldLeft,
      top: metrics.worldTop,
      visualWidth: metrics.visualWidth,
      visualHeight: metrics.visualHeight,
    ),
  );
  return geometry.points
      .map(
        (point) => ShadowRuntimePoint(
          worldX: point.x,
          worldY: point.y,
        ),
      )
      .toList();
}

ResolvedStaticShadowGeometry _expectedBaseGeometry(
  StaticPlacedElementShadowRuntimeInput input,
) {
  final metrics = input.metrics;
  final legacyAndElementFootprint = resolveStaticShadowFootprint(
    elementFootprint: StaticShadowFootprintConfig(
      anchorXRatio: metrics.anchorXRatio,
      anchorYRatio: metrics.anchorYRatio,
      footprintWidthRatio: metrics.baseWidthMultiplier,
      footprintHeightRatio: metrics.baseHeightMultiplier,
    ),
    overrideFootprint: input.elementFootprint,
  );
  return resolveStaticShadowGeometry(
    metrics: StaticShadowVisualMetrics(
      left: metrics.worldLeft,
      top: metrics.worldTop,
      visualWidth: metrics.visualWidth,
      visualHeight: metrics.visualHeight,
    ),
    shadowConfig: input.resolvedConfig,
    elementFootprint: StaticShadowFootprintConfig(
      anchorXRatio: legacyAndElementFootprint.anchorXRatio,
      anchorYRatio: legacyAndElementFootprint.anchorYRatio,
      footprintWidthRatio: legacyAndElementFootprint.footprintWidthRatio,
      footprintHeightRatio: legacyAndElementFootprint.footprintHeightRatio,
    ),
    overrideFootprint: input.overrideFootprint,
  );
}

_RuntimeTestBounds _boundsFromPoints(List<ShadowRuntimePoint> points) {
  var minX = points.first.worldX;
  var maxX = points.first.worldX;
  var minY = points.first.worldY;
  var maxY = points.first.worldY;
  for (final point in points.skip(1)) {
    if (point.worldX < minX) {
      minX = point.worldX;
    }
    if (point.worldX > maxX) {
      maxX = point.worldX;
    }
    if (point.worldY < minY) {
      minY = point.worldY;
    }
    if (point.worldY > maxY) {
      maxY = point.worldY;
    }
  }
  return _RuntimeTestBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

final class _RuntimeTestBounds {
  const _RuntimeTestBounds({
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
