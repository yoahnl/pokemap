import 'dart:typed_data';

import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';

void main() {
  test(
    'terrain color keys preserve real alpha and clear only matching pixels',
    () {
      final rgba = Uint8List.fromList([
        255,
        0,
        255,
        255,
        30,
        80,
        40,
        128,
        255,
        0,
        254,
        255,
      ]);
      applySpatialGroundColorKey(
        rgba,
        TilesetTransparentColor(red: 255, green: 0, blue: 255),
      );
      expect(rgba, [0, 0, 0, 0, 30, 80, 40, 128, 255, 0, 254, 255]);
    },
  );
  test('ground quads preserve all eight 2D transforms and texture corners', () {
    for (final transform in smartTileD4Transforms) {
      final geometry = resolveSmartTileSpriteGeometry(
        cellX: 2,
        cellY: 3,
        destinationCellWidth: 1,
        destinationCellHeight: 1,
        sourceCellWidth: 32,
        sourceCellHeight: 32,
        offsetUnit: SmartTileOffsetUnit.pixel,
        offsetX: 0,
        offsetY: 0,
        atlasPixelOffsetX: 0,
        atlasPixelOffsetY: 0,
        footprintWidth: 2,
        footprintHeight: 1,
        anchorX: 0,
        anchorY: 0,
        transform: transform,
      );
      final vertices = spatialGroundVertices(geometry);
      expect(vertices, hasLength(4));
      expect(
        vertices.map((v) => v.position.x).reduce((a, b) => a < b ? a : b),
        geometry.visualBounds.left,
      );
      expect(
        vertices.map((v) => v.position.z).reduce((a, b) => a < b ? a : b),
        geometry.visualBounds.top,
      );
      expect(
        vertices.map((v) => v.position.x).reduce((a, b) => a > b ? a : b),
        geometry.visualBounds.right,
      );
      expect(
        vertices.map((v) => v.position.z).reduce((a, b) => a > b ? a : b),
        geometry.visualBounds.bottom,
      );
      expect(vertices.map((v) => (v.texCoord.x, v.texCoord.y)), [
        (0.0, 0.0),
        (0.0, 1.0),
        (1.0, 1.0),
        (1.0, 0.0),
      ]);
      expect(vertices.every((v) => v.position.y == 0), isTrue);
    }
  });

  test('3D ground uses the same visual resolver and skips hidden layers', () {
    const preset = ProjectSmartTilePreset(
      id: 'grass',
      name: 'Herbe',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: ['grass'],
      rules: [
        SmartTileRule(
          id: 'fill',
          centerMatch: SmartTileSlotMatch.material('grass'),
          candidates: [
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
    );
    final catalog = ProjectSmartTileCatalog(
      presets: const [preset],
      materials: const [
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Herbe',
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
    );
    const layer = SmartTileLayer(
      id: 'ground',
      name: 'Sol',
      presetId: 'grass',
      usage: SmartTileUsage.terrain,
      materialPalette: ['', 'grass'],
      field: SmartTileField.cell(semanticCells: [1, 0, 1, 1]),
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v9,
      size: const GridSize(width: 2, height: 2),
      spatialScene: MapSpatialScene(width: 2, depth: 2),
      layers: [
        layer,
        layer.copyWith(id: 'hidden', isVisible: false),
      ],
    );
    final project = ProjectManifest(
      name: 'Map',
      version: ProjectVersion.v9,
      maps: const [],
      tilesets: const [],
      smartTileCatalog: catalog,
    );
    final plan = SpatialGroundPlan(map, project);
    final expected = resolveSmartTileLayerVisuals(
      map: map,
      layer: layer,
      catalog: catalog,
      pass: SmartTileVisualPass.background,
    );
    final actual = plan.resolve(0);
    expect(actual, hasLength(3));
    expect(
      actual.map(
        (item) =>
            (item.visual.cellX, item.visual.cellY, item.visual.sourceRect),
      ),
      expected.map((item) => (item.cellX, item.cellY, item.sourceRect)),
    );
    expect(plan.imageIds, {'tiles'});
    expect(plan.animated, isFalse);
    expect(plan.resolve(5000), same(actual));
    final translucent = SpatialGroundPlan(
      map.copyWith(layers: [layer.copyWith(opacity: .5)]),
      project,
    ).resolve(0);
    expect(translucent.every((item) => item.opacity == .5), isTrue);
    expect(
      SpatialGroundPlan(
        map.copyWith(layers: [layer.copyWith(opacity: 0)]),
        project,
      ).resolve(0),
      isEmpty,
    );
    final animatedPreset = preset.copyWith(
      rules: [
        const SmartTileRule(
          id: 'animated',
          centerMatch: SmartTileSlotMatch.material('grass'),
          candidates: [
            SmartTileCandidate(
              id: 'animated',
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.animation(animationId: 'sway'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final animatedCatalog = ProjectSmartTileCatalog(
      materials: catalog.materials,
      presets: [animatedPreset],
      atlases: [catalog.atlases.single.copyWith(columns: 2)],
      animations: const [
        ProjectSmartTileAnimation(
          id: 'sway',
          name: 'Sway',
          frames: [
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
              durationMs: 100,
            ),
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(atlasId: 'atlas', column: 1, row: 0),
              durationMs: 100,
            ),
          ],
        ),
      ],
    );
    final animated = SpatialGroundPlan(
      map,
      project.copyWith(smartTileCatalog: animatedCatalog),
    );
    expect(animated.animated, isTrue);
    expect(animated.resolve(0).first.visual.sourceRect.x, 0);
    expect(animated.resolve(100).first.visual.sourceRect.x, 32);
    final patternCatalog = ProjectSmartTileCatalog(
      presets: catalog.presets,
      materials: catalog.materials,
      atlases: [
        ...catalog.atlases,
        const ProjectSmartTileAtlas(
          id: 'pattern-atlas',
          name: 'Pattern',
          tilesetId: 'pattern-tiles',
          columns: 2,
          rows: 1,
        ),
      ],
      animations: const [
        ProjectSmartTileAnimation(
          id: 'pattern-sway',
          name: 'Pattern sway',
          frames: [
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(
                atlasId: 'pattern-atlas',
                column: 0,
                row: 0,
              ),
              durationMs: 100,
            ),
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(
                atlasId: 'pattern-atlas',
                column: 1,
                row: 0,
              ),
              durationMs: 100,
            ),
          ],
        ),
      ],
      patterns: const [
        ProjectSmartTilePattern(
          id: 'stamp',
          name: 'Stamp',
          usage: SmartTileUsage.terrain,
          width: 1,
          height: 1,
          cells: [
            SmartTilePatternCell(
              x: 0,
              y: 0,
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.animation(
                    animationId: 'pattern-sway',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final patternLayer = layer.copyWith(
      patternStrokes: [
        const SmartTilePatternStroke(
          id: 'stroke',
          patternId: 'stamp',
          cells: [GridPos(x: 0, y: 0)],
        ),
      ],
    );
    final patternPlan = SpatialGroundPlan(
      map.copyWith(layers: [patternLayer]),
      project.copyWith(smartTileCatalog: patternCatalog),
    );
    expect(patternPlan.imageIds, {'tiles', 'pattern-tiles'});
    expect(patternPlan.animated, isTrue);
    final patternVisuals = patternPlan.resolve(0);
    final sameCell = patternVisuals
        .where((item) => item.visual.cellX == 0 && item.visual.cellY == 0)
        .toList();
    expect(sameCell, hasLength(2));
    expect(sameCell.last.height, greaterThan(sameCell.first.height));
    expect(actual.map((item) => item.height).toSet(), hasLength(1));
    final texture = Texture(ByteData(32 * 32 * 4), width: 32, height: 32);
    final repeated = [
      translucent.first,
      (
        visual: patternVisuals
            .firstWhere((item) => item.visual.tilesetId == 'pattern-tiles')
            .visual,
        height: .003,
        opacity: .5,
      ),
      (visual: translucent.first.visual, height: .004, opacity: .5),
    ];
    final mesh = spatialGroundMeshes(repeated, {
      'tiles': texture,
      'pattern-tiles': texture,
    }).single;
    expect(mesh.surfaceCount, 3);
    expect(
      mesh.surfaces.map(
        (surface) => (surface.material as SpatialPixelMaterial).albedoColor.a,
      ),
      [.5, .5, .5],
    );
    expect(
      patternPlan
          .resolve(100)
          .where((item) => item.visual.tilesetId == 'pattern-tiles')
          .single
          .visual
          .sourceRect
          .x,
      32,
    );
  });
}
