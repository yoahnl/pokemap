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
      expect(instruction.opacity, 0.18);
      expect(instruction.colorHexRgb, '123ABC');
      expect(instruction.left, 64);
      expect(instruction.top, 128);
      expect(instruction.width, 48);
      expect(instruction.height, 64);
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 64, y: 128);
      _expectPointClose(instruction.polygonPoints[1], x: 64, y: 192);
      _expectPointClose(instruction.polygonPoints[2], x: 112, y: 176);
      _expectPointClose(instruction.polygonPoints[3], x: 112, y: 144);
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
  String id = 'shadow-a',
  double opacity = 0.18,
  String colorHexRgb = '123ABC',
}) {
  return ProjectBuildingShadowPreset(
    id: id,
    name: 'Shadow A',
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: opacity,
      colorHexRgb: colorHexRgb,
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  String presetId = 'shadow-a',
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

void _expectPointClose(
  EditorStaticShadowPreviewPoint point, {
  required double x,
  required double y,
}) {
  expect(point.x, closeTo(x, 0.000001));
  expect(point.y, closeTo(y, 0.000001));
}
