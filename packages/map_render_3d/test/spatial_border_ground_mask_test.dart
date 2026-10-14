import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';

import 'spatial_cliff_ground_replacement_test.dart' show cliffFixture;

const maskedCells = {(1, 1), (2, 1), (3, 1), (3, 2), (3, 3)};

void main() {
  test('a narrow wall masks its cells across native ground layers', () {
    final fixture = maskFixture();
    final plan = SpatialGroundPlan(fixture.map, fixture.project);
    expect(plan.groundReplacementCells, maskedCells);
    expect(plan.paintedCells!.intersection(maskedCells), isEmpty);
    for (final part in plan.resolve(0)) {
      expect(plan.excludedCellsFor(part.visual), maskedCells);
    }
    expect(plan.borderGroundReplacements, isEmpty);
    expect(fixture.map.spatialScene!.heightAt(1, 1), 1);
  });

  test('masked frames produce no vertices while neighboring frames remain', () {
    final fixture = maskFixture();
    final plan = SpatialGroundPlan(fixture.map, fixture.project);
    final vertices = [
      for (final part in plan.resolve(0))
        ...spatialGroundVertices(
          part.visual.geometry,
          height: part.height,
          scene: fixture.map.spatialScene,
          excludedCells: plan.excludedCellsFor(part.visual),
        ),
    ];
    expect(vertices, hasLength(2 * (36 - maskedCells.length) * 4));
    expect(fixture.map.spatialScene!.heightLevels, List.filled(36, 1));
  });

  test('hiding or removing a masking border restores the native ground', () {
    final fixture = maskFixture();
    final layer = fixture.map.layers.whereType<BorderLayer>().single;
    for (final layers in [
      fixture.map.layers.where((l) => l != layer).toList(),
      [
        for (final l in fixture.map.layers)
          l == layer ? layer.copyWith(isVisible: false) : l,
      ],
      [
        for (final l in fixture.map.layers)
          l == layer ? layer.copyWith(opacity: 0) : l,
      ],
    ]) {
      final plan = SpatialGroundPlan(
        fixture.map.copyWith(layers: layers),
        fixture.project,
      );
      expect(plan.groundReplacementCells, isEmpty);
      expect(plan.paintedCells!.intersection(maskedCells), maskedCells);
    }
  });
}

({ProjectManifest project, MapData map}) maskFixture() {
  final base = cliffFixture();
  final raw = base.project.toJson();
  final record = (raw['borderCatalog']['records'] as List).single as Map;
  for (final key in ['draft', 'latestPublished']) {
    (record[key] as Map)['definition']['masksGroundCells'] = true;
    (record[key] as Map)['definition']['replacesGround'] = false;
    for (final primitive
        in (record[key] as Map)['definition']['primitives'] as List) {
      primitive['anchorWorld'] = {'x': 0, 'y': 0, 'z': 0};
    }
  }
  (raw['models3d'] as List).single['inspection']['bounds'] = {
    'min': {'x': -.2, 'y': 0, 'z': -.2},
    'max': {'x': .2, 'y': 1, 'z': .2},
  };
  final catalog = ProjectSmartTileCatalog(
    materials: const [
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'grass',
      ),
    ],
    atlases: const [
      ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Atlas',
        tilesetId: 'tiles',
        columns: 1,
        rows: 1,
      ),
    ],
    presets: [
      ProjectSmartTilePreset(
        id: 'ground',
        name: 'Ground',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
        templateHint: SmartTileTemplateHint.simple,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: const SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: const ['grass'],
        rules: [
          SmartTileRule(
            id: 'grass',
            centerMatch: const SmartTileSlotMatch.material('grass'),
            candidates: const [
              SmartTileCandidate(
                id: 'frame',
                parts: [
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'atlas',
                        column: 0,
                        row: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  final project = ProjectManifest.fromJson(raw)
      .copyWith(smartTileCatalog: catalog);
  final expanded = base.map.copyWith(
    size: const GridSize(width: 6, height: 6),
    spatialScene: MapSpatialScene(
      width: 6,
      depth: 6,
      levelHeight: 1,
      heightLevels: List.filled(36, 1),
      generateCliffs: false,
      instances: base.map.spatialScene!.instances,
    ),
  );
  final map = updateBorderFeatureGeometry(
    expanded,
    layerId: 'border',
    featureId: 'cliff',
    geometry: BorderStrokeGeometry(
      alignment: BorderStrokeAlignment.cellCenters,
      strokes: [
        BorderStroke(
          id: 'line',
          points: [
            for (final cell in maskedCells) GridPos(x: cell.$1, y: cell.$2),
          ],
          closed: false,
        ),
      ],
    ),
  );
  final resolved = resolveSpatialBorderFeature(
    manifest: project,
    map: map,
    layerId: 'border',
    featureId: 'cliff',
  );
  expect(resolved.result.canApply, isTrue);
  final applied = applySpatialBorderFeaturePreview(
    map,
    manifest: project,
    proposedResult: resolved,
  );
  return (
    project: project,
    map: applied.copyWith(
      layers: [
        for (final id in ['grass-base', 'grass-details'])
          SmartTileLayer(
            id: id,
            name: id,
            presetId: 'ground',
            usage: SmartTileUsage.terrain,
            materialPalette: const ['', 'grass'],
            field: SmartTileField.cell(semanticCells: List.filled(36, 1)),
          ),
        ...applied.layers,
      ],
    ),
  );
}
