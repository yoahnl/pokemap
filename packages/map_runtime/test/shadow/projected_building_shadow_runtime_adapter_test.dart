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
