import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/projected_building_shadow_runtime_adapter.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('createProjectedBuildingShadowRuntimeInstruction', () {
    test('converts geometry to a ground projected polygon instruction', () {
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
        _geometry(
          [
            ProjectedBuildingShadowPoint(x: 0, y: 0),
            ProjectedBuildingShadowPoint(x: 10, y: 0),
            ProjectedBuildingShadowPoint(x: 10, y: 5),
            ProjectedBuildingShadowPoint(x: 0, y: 5),
          ],
          opacity: 0.18,
          colorHexRgb: '000000',
        ),
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.opacity, 0.18);
      expect(instruction.colorHexRgb, '000000');
      expect(instruction.worldLeft, 0);
      expect(instruction.worldTop, 0);
      expect(instruction.width, 10);
      expect(instruction.height, 5);
      expect(
        instruction.polygonPoints,
        [
          ShadowRuntimePoint(worldX: 0, worldY: 0),
          ShadowRuntimePoint(worldX: 10, worldY: 0),
          ShadowRuntimePoint(worldX: 10, worldY: 5),
          ShadowRuntimePoint(worldX: 0, worldY: 5),
        ],
      );
    });

    test('converts footprint geometry to runtime projected polygon instruction',
        () {
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
        _geometry(
          [
            ProjectedBuildingShadowPoint(x: 28.80, y: 146.56),
            ProjectedBuildingShadowPoint(x: 99.20, y: 146.56),
            ProjectedBuildingShadowPoint(x: 108.80, y: 173.44),
            ProjectedBuildingShadowPoint(x: 32.00, y: 173.44),
          ],
          opacity: 0.28,
          colorHexRgb: '606060',
        ),
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.opacity, 0.28);
      expect(instruction.colorHexRgb, '606060');
      expect(instruction.worldLeft, closeTo(28.80, 0.02));
      expect(instruction.worldTop, closeTo(146.56, 0.02));
      expect(instruction.width, closeTo(80.00, 0.02));
      expect(instruction.height, closeTo(26.88, 0.02));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 28.80, y: 146.56);
      _expectPointClose(instruction.polygonPoints[1], x: 99.20, y: 146.56);
      _expectPointClose(instruction.polygonPoints[2], x: 108.80, y: 173.44);
      _expectPointClose(instruction.polygonPoints[3], x: 32.00, y: 173.44);
    });

    test(
        'converts footprint v1 geometry to runtime projected polygon instruction',
        () {
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
        _geometry(
          [
            ProjectedBuildingShadowPoint(x: 22.40, y: 142.72),
            ProjectedBuildingShadowPoint(x: 105.60, y: 142.72),
            ProjectedBuildingShadowPoint(x: 114.56, y: 167.68),
            ProjectedBuildingShadowPoint(x: 23.68, y: 167.68),
          ],
          opacity: 0.24,
          colorHexRgb: '606060',
        ),
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.opacity, 0.24);
      expect(instruction.colorHexRgb, '606060');
      expect(instruction.worldLeft, closeTo(22.40, 0.02));
      expect(instruction.worldTop, closeTo(142.72, 0.02));
      expect(instruction.width, closeTo(92.16, 0.02));
      expect(instruction.height, closeTo(24.96, 0.02));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 22.40, y: 142.72);
      _expectPointClose(instruction.polygonPoints[1], x: 105.60, y: 142.72);
      _expectPointClose(instruction.polygonPoints[2], x: 114.56, y: 167.68);
      _expectPointClose(instruction.polygonPoints[3], x: 23.68, y: 167.68);
    });

    test('preserves point order exactly', () {
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
        _geometry(
          [
            ProjectedBuildingShadowPoint(x: 1, y: 2),
            ProjectedBuildingShadowPoint(x: 3, y: 5),
            ProjectedBuildingShadowPoint(x: 8, y: 13),
            ProjectedBuildingShadowPoint(x: 21, y: 34),
          ],
        ),
      );

      expect(
        instruction.polygonPoints,
        [
          ShadowRuntimePoint(worldX: 1, worldY: 2),
          ShadowRuntimePoint(worldX: 3, worldY: 5),
          ShadowRuntimePoint(worldX: 8, worldY: 13),
          ShadowRuntimePoint(worldX: 21, worldY: 34),
        ],
      );
    });

    test('preserves appearance values', () {
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
        _geometry(
          [
            ProjectedBuildingShadowPoint(x: -5, y: 2),
            ProjectedBuildingShadowPoint(x: 6, y: 3),
            ProjectedBuildingShadowPoint(x: 8, y: 14),
            ProjectedBuildingShadowPoint(x: -3, y: 12),
          ],
          opacity: 0.42,
          colorHexRgb: '123ABC',
        ),
      );

      expect(instruction.opacity, 0.42);
      expect(instruction.colorHexRgb, '123ABC');
    });

    test('keeps runtime validation for degenerate polygons', () {
      expect(
        () => createProjectedBuildingShadowRuntimeInstruction(
          _geometry(
            [
              ProjectedBuildingShadowPoint(x: 0, y: 0),
              ProjectedBuildingShadowPoint(x: 1, y: 1),
              ProjectedBuildingShadowPoint(x: 2, y: 2),
              ProjectedBuildingShadowPoint(x: 3, y: 3),
            ],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('adapter source stays independent from render and traversal layers',
        () {
      final source = File(
        'lib/src/shadow/projected_building_shadow_runtime_adapter.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
        'dart:' 'ui',
        'package:' 'flutter',
        'package:' 'flame',
        'Can' 'vas',
        'Pa' 'th',
        'Pa' 'int',
        'generic' 'Projection',
        'resolveProjected' 'StaticShadowGeometry',
        'resolveStaticShadowFamily' 'ProjectionSpec',
        'Project' 'Manifest',
        'ProjectElement' 'Entry',
        'Map' 'Data',
        'MapPlaced' 'Element',
        'static_shadow_family' '_projection',
        'static_shadow_projection' '_geometry',
        'static_shadow_contact_ledge' '_geometry',
        'element_auto_shadow' '_policy',
        'projected_building_shadow' '_diagnostics',
      ];

      for (final snippet in forbiddenSnippets) {
        expect(source, isNot(contains(snippet)));
      }
    });
  });
}

ProjectedBuildingShadowGeometry _geometry(
  List<ProjectedBuildingShadowPoint> points, {
  double opacity = 0.18,
  String colorHexRgb = '000000',
}) {
  return ProjectedBuildingShadowGeometry(
    points: points,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
  );
}

void _expectPointClose(
  ShadowRuntimePoint point, {
  required double x,
  required double y,
}) {
  expect(point.worldX, closeTo(x, 0.02));
  expect(point.worldY, closeTo(y, 0.02));
}
