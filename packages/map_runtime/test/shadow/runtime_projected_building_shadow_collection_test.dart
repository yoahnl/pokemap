import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/runtime_projected_building_shadow_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('buildRuntimeProjectedBuildingShadowCollection', () {
    test('returns an empty collection when no element has a projected shadow',
        () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(elements: [_element()]),
        mapData: _map(placedElements: [_placed()]),
      );

      expect(collection, ShadowRuntimeInstructionCollection());
      expect(collection.groundStatic, isEmpty);
      expect(collection.actorContact, isEmpty);
    });

    test('builds one ground projected polygon for a valid projected shadow',
        () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        mapData:
            _map(placedElements: [_placed(pos: const GridPos(x: 1, y: 2))]),
      );

      expect(collection.length, 1);
      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, isEmpty);

      final instruction = collection.groundStatic.single;
      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.opacity, 0.18);
      expect(instruction.colorHexRgb, '123ABC');
      expect(instruction.worldLeft, closeTo(64, 0.000001));
      expect(instruction.worldTop, closeTo(128, 0.000001));
      expect(instruction.width, closeTo(48, 0.000001));
      expect(instruction.height, closeTo(64, 0.000001));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 64, y: 128);
      _expectPointClose(instruction.polygonPoints[1], x: 64, y: 192);
      _expectPointClose(instruction.polygonPoints[2], x: 112, y: 176);
      _expectPointClose(instruction.polygonPoints[3], x: 112, y: 144);
    });

    test(
        'buildRuntimeProjectedBuildingShadowCollection resolves footprint preset through map_core geometry',
        () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_footprintPreset()]),
          elements: [
            _element(
              projectedBuildingShadow:
                  _config(presetId: 'pokemon-building-shadow-footprint-v0'),
            ),
          ],
        ),
        mapData:
            _map(placedElements: [_placed(pos: const GridPos(x: 1, y: 2))]),
      );

      expect(collection.length, 1);
      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, isEmpty);

      final instruction = collection.groundStatic.single;
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

    test('skips disabled projected shadow config', () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [
            _element(projectedBuildingShadow: _config(enabled: false)),
          ],
        ),
        mapData: _map(placedElements: [_placed()]),
      );

      expect(collection.isEmpty, isTrue);
    });

    test('skips missing preset without throwing', () {
      late ShadowRuntimeInstructionCollection collection;

      expect(
        () {
          collection = buildRuntimeProjectedBuildingShadowCollection(
            manifest: _manifest(
              catalog: _catalog([]),
              elements: [
                _element(projectedBuildingShadow: _config(presetId: 'missing')),
              ],
            ),
            mapData: _map(placedElements: [_placed()]),
          );
        },
        returnsNormally,
      );
      expect(collection.isEmpty, isTrue);
    });

    test('skips missing element without throwing', () {
      late ShadowRuntimeInstructionCollection collection;

      expect(
        () {
          collection = buildRuntimeProjectedBuildingShadowCollection(
            manifest: _manifest(
              catalog: _catalog([_preset()]),
              elements: const [],
            ),
            mapData: _map(
              placedElements: [_placed(elementId: 'missing-element')],
            ),
          );
        },
        returnsNormally,
      );
      expect(collection.isEmpty, isTrue);
    });

    test(
        'skips hidden or transparent placement layers and zero opacity placement',
        () {
      final manifest = _manifest(
        catalog: _catalog([_preset()]),
        elements: [_element(projectedBuildingShadow: _config())],
      );

      expect(
        buildRuntimeProjectedBuildingShadowCollection(
          manifest: manifest,
          mapData: _map(
            layers: [_layer(isVisible: false)],
            placedElements: [_placed()],
          ),
        ).isEmpty,
        isTrue,
      );
      expect(
        buildRuntimeProjectedBuildingShadowCollection(
          manifest: manifest,
          mapData: _map(
            layers: [_layer(opacity: 0)],
            placedElements: [_placed()],
          ),
        ).isEmpty,
        isTrue,
      );
      expect(
        buildRuntimeProjectedBuildingShadowCollection(
          manifest: manifest,
          mapData: _map(placedElements: [_placed(opacity: 0)]),
        ).isEmpty,
        isTrue,
      );
    });

    test('does not multiply preset opacity by placement opacity', () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        mapData: _map(placedElements: [_placed(opacity: 0.5)]),
      );

      expect(collection.groundStatic.single.opacity, 0.18);
    });

    test('preserves source placement order', () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        mapData: _map(
          placedElements: [
            _placed(id: 'late-left', pos: const GridPos(x: 5, y: 2)),
            _placed(id: 'early-left', pos: const GridPos(x: 1, y: 2)),
          ],
        ),
      );

      expect(collection.groundStatic, hasLength(2));
      expect(collection.groundStatic[0].worldLeft, greaterThan(100));
      expect(collection.groundStatic[1].worldLeft, lessThan(100));
    });

    test('does not block V2 when the element also has a V1 shadow', () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [
            _element(
              shadow: ProjectElementShadowConfig(
                castsShadow: true,
                shadowProfileId: 'legacy-shadow',
              ),
              projectedBuildingShadow: _config(),
            ),
          ],
        ),
        mapData: _map(placedElements: [_placed()]),
      );

      expect(collection.groundStatic, hasLength(1));
    });

    test(
        'builder source stays independent from renderer and diagnostics layers',
        () {
      final source = File(
        'lib/src/shadow/runtime_projected_building_shadow_collection.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
        'generic' 'Projection',
        'applyElementAutoShadow' 'PolicyToProject',
        'diagnoseProjectedBuilding' 'Shadows',
        'Project' 'Validator',
        'Map' 'Validator',
        'resolveProjected' 'StaticShadowGeometry',
        'resolveStaticShadowFamily' 'ProjectionSpec',
        'Can' 'vas',
        'Pa' 'th',
        'Pa' 'int',
        'dart:' 'ui',
        'package:' 'flutter',
        'package:' 'flame',
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

ProjectElementEntry _element({
  String id = 'building',
  ProjectElementShadowConfig? shadow,
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
    shadow: shadow,
    projectedBuildingShadow: projectedBuildingShadow,
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

ProjectBuildingShadowPreset _footprintPreset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-footprint-v0',
    name: 'Pokemon-like footprint building shadow V0',
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
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
  ShadowRuntimePoint point, {
  required double x,
  required double y,
}) {
  expect(point.worldX, closeTo(x, 0.000001));
  expect(point.worldY, closeTo(y, 0.000001));
}
