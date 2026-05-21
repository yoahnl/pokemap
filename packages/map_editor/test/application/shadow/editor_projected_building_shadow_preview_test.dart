import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/editor_projected_building_shadow_preview.dart';
import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';

void main() {
  group('buildEditorProjectedBuildingShadowPreviewInstructions', () {
    test('builds a projected polygon preview', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, hasLength(1));
      final instruction = instructions.single;
      expect(
        instruction.shape,
        EditorStaticShadowPreviewShapeKind.projectedPolygon,
      );
      expect(instruction.opacity, 0.30);
      expect(instruction.colorHexRgb, '606060');
      expect(instruction.left, closeTo(52.46, 0.02));
      expect(instruction.top, closeTo(129.77, 0.02));
      expect(instruction.width, closeTo(48.92, 0.02));
      expect(instruction.height, closeTo(59.81, 0.02));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 75.54, y: 129.77);
      _expectPointClose(instruction.polygonPoints[1], x: 52.46, y: 182.55);
      _expectPointClose(instruction.polygonPoints[2], x: 82.91, y: 189.58);
      _expectPointClose(instruction.polygonPoints[3], x: 101.38, y: 147.36);
    });

    test(
        'buildEditorProjectedBuildingShadowPreviewInstructions builds a footprint projected polygon preview',
        () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_footprintPreset()]),
          elements: [
            _element(
              projectedBuildingShadow: _config(
                presetId: 'pokemon-building-shadow-footprint-v0',
              ),
            ),
          ],
        ),
        map: _map(placedElements: [_placed(pos: const GridPos(x: 1, y: 2))]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, hasLength(1));
      final instruction = instructions.single;
      expect(
        instruction.shape,
        EditorStaticShadowPreviewShapeKind.projectedPolygon,
      );
      expect(instruction.opacity, 0.28);
      expect(instruction.colorHexRgb, '606060');
      expect(instruction.left, closeTo(28.80, 0.02));
      expect(instruction.top, closeTo(146.56, 0.02));
      expect(instruction.width, closeTo(80.00, 0.02));
      expect(instruction.height, closeTo(26.88, 0.02));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 28.80, y: 146.56);
      _expectPointClose(instruction.polygonPoints[1], x: 99.20, y: 146.56);
      _expectPointClose(instruction.polygonPoints[2], x: 108.80, y: 173.44);
      _expectPointClose(instruction.polygonPoints[3], x: 32.00, y: 173.44);
    });

    test('returns empty when element has no projectedBuildingShadow config',
        () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element()],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('returns empty when projectedBuildingShadow is disabled', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [
            _element(projectedBuildingShadow: _config(enabled: false)),
          ],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('skips missing projected building shadow preset without throwing', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          elements: [
            _element(projectedBuildingShadow: _config(presetId: 'missing')),
          ],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('skips hidden or transparent tile layers', () {
      final manifest = _manifest(
        catalog: _catalog([_preset()]),
        elements: [_element(projectedBuildingShadow: _config())],
      );

      expect(
        buildEditorProjectedBuildingShadowPreviewInstructions(
          manifest: manifest,
          map: _map(
            layers: [_layer(isVisible: false)],
            placedElements: [_placed()],
          ),
          tileWidth: 32,
          tileHeight: 32,
        ),
        isEmpty,
      );
      expect(
        buildEditorProjectedBuildingShadowPreviewInstructions(
          manifest: manifest,
          map: _map(
            layers: [_layer(opacity: 0)],
            placedElements: [_placed()],
          ),
          tileWidth: 32,
          tileHeight: 32,
        ),
        isEmpty,
      );
    });

    test('skips zero opacity placements', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        map: _map(placedElements: [_placed(opacity: 0)]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('skips invalid visual source dimensions', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [
            _element(
              projectedBuildingShadow: _config(),
              sourceWidth: 0,
            ),
          ],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('preserves placed element source order', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        map: _map(
          placedElements: [
            _placed(id: 'first', pos: const GridPos(x: 1, y: 2)),
            _placed(id: 'second', pos: const GridPos(x: 3, y: 2)),
          ],
        ),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(
        instructions.map((instruction) => instruction.instanceId),
        ['first', 'second'],
      );
    });

    test('does not depend on runtime or auto projection', () {
      final source = File(
        'lib/src/application/shadow/editor_projected_building_shadow_preview.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
        'map_' 'runtime',
        'Shadow' 'Runtime',
        'buildRuntimeProjected' 'BuildingShadowCollection',
        'Shadow' 'Runtime' 'Renderer',
        'generic' 'Projection',
        'applyElementAutoShadowPolicy' 'ToProject',
        'diagnoseProjectedBuilding' 'Shadows',
        'resolveProjectedStatic' 'ShadowGeometry',
        'resolveStaticShadowFamily' 'ProjectionSpec',
        'static_shadow_family' '_projection',
        'element_auto_shadow' '_policy',
      ];

      for (final snippet in forbiddenSnippets) {
        expect(source, isNot(contains(snippet)));
      }
    });
  });
}

ProjectManifest _manifest({
  ProjectBuildingShadowPresetCatalog? catalog,
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: elements,
    settings: const ProjectSettings(
      tileWidth: 16,
      tileHeight: 16,
      displayScale: 2,
    ),
    surfaceCatalog: ProjectSurfaceCatalog(),
    projectedBuildingShadowCatalog:
        catalog ?? const ProjectBuildingShadowPresetCatalog.empty(),
  );
}

MapData _map({
  List<MapLayer>? layers,
  List<MapPlacedElement> placedElements = const [],
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 10, height: 10),
    layers: layers ?? [_layer()],
    placedElements: placedElements,
  );
}

MapLayer _layer({
  String id = 'objects',
  bool isVisible = true,
  double opacity = 1,
}) {
  return MapLayer.tile(
    id: id,
    name: 'Objects',
    tilesetId: 'tileset',
    isVisible: isVisible,
    opacity: opacity,
  );
}

MapPlacedElement _placed({
  String id = 'building-placed',
  String layerId = 'objects',
  String elementId = 'building',
  GridPos pos = const GridPos(x: 1, y: 2),
  double opacity = 1,
}) {
  return MapPlacedElement(
    id: id,
    layerId: layerId,
    elementId: elementId,
    pos: pos,
    opacity: opacity,
  );
}

ProjectElementEntry _element({
  String id = 'building',
  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
  int sourceWidth = 2,
  int sourceHeight = 3,
}) {
  return ProjectElementEntry(
    id: id,
    name: 'Building',
    tilesetId: 'tileset',
    categoryId: 'building',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(
          x: 0,
          y: 0,
          width: sourceWidth,
          height: sourceHeight,
        ),
      ),
    ],
    projectedBuildingShadow: projectedBuildingShadow,
  );
}

ProjectBuildingShadowPresetCatalog _catalog(
  List<ProjectBuildingShadowPreset> presets,
) {
  return ProjectBuildingShadowPresetCatalog(presets: presets);
}

ProjectBuildingShadowPreset _preset({
  String id = 'pokemon-building-shadow-v0',
  double opacity = 0.30,
  String colorHexRgb = '606060',
}) {
  return ProjectBuildingShadowPreset(
    id: id,
    name: 'Pokemon-like building shadow V0',
    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.32,
      nearWidthRatio: 0.90,
      farWidthRatio: 0.72,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: opacity,
      colorHexRgb: colorHexRgb,
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
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

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  String presetId = 'pokemon-building-shadow-v0',
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

void _expectPointClose(
  EditorStaticShadowPreviewPoint point, {
  required double x,
  required double y,
}) {
  expect(point.x, closeTo(x, 0.02));
  expect(point.y, closeTo(y, 0.02));
}
