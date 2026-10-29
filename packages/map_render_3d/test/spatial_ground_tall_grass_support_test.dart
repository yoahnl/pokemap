import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';

void main() {
  for (final kind in [PathSurfaceKind.tallGrass, PathSurfaceKind.road]) {
    test('$kind across a cliff preserves its surface support', () {
      final catalog = ProjectSmartTileCatalog(
        materials: [
          ProjectSmartTileMaterial(
            id: 'surface',
            name: 'Surface',
            connectionGroupId: 'surface',
            pathSurfaceKind: kind,
          ),
        ],
        atlases: const [
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'tiles',
            cellWidth: 64,
            cellHeight: 64,
            columns: 1,
            rows: 1,
          ),
        ],
        presets: [
          ProjectSmartTilePreset(
            id: 'preset',
            name: 'Surface',
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: const SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: const SmartTileTransformPolicy(),
            defaultMaterialId: 'surface',
            allowedMaterialIds: const ['surface'],
            rules: const [
              SmartTileRule(
                id: 'surface',
                centerMatch: SmartTileSlotMatch.material('surface'),
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
                        footprintWidth: 2,
                        footprintHeight: 2,
                        offsetX: -16,
                        offsetY: -12,
                        spatialHeightOffset: .125,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      const grass = SmartTileLayer(
        id: 'surface',
        name: 'Surface',
        presetId: 'preset',
        usage: SmartTileUsage.path,
        materialPalette: ['', 'surface'],
        field: SmartTileField.cell(
          semanticCells: [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      );
      const empty = SmartTileLayer(
        id: 'empty',
        name: 'Empty',
        presetId: 'preset',
        usage: SmartTileUsage.path,
        materialPalette: ['', 'surface'],
        field: SmartTileField.cell(
          semanticCells: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        spatialScene: MapSpatialScene(
          width: 4,
          depth: 4,
          terrainSurfaces: SpatialTerrainSurfaceSet(
            surfaces: [
              SpatialTerrainSurface(
                id: 'plateau',
                x: 0,
                z: 0,
                height: 3,
                footprints: [
                  BorderGroundFootprint(
                    points: [
                      BorderGroundPoint(x: 0, z: 0),
                      BorderGroundPoint(x: 2, z: 0),
                      BorderGroundPoint(x: 2, z: 4),
                      BorderGroundPoint(x: 0, z: 4),
                    ],
                  ),
                ],
              ),
              SpatialTerrainSurface(
                id: 'lower',
                x: 0,
                z: 0,
                height: 1,
                footprints: [
                  BorderGroundFootprint(
                    points: [
                      BorderGroundPoint(x: 2, z: 0),
                      BorderGroundPoint(x: 4, z: 0),
                      BorderGroundPoint(x: 4, z: 4),
                      BorderGroundPoint(x: 2, z: 4),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        layers: [grass, empty],
      );
      final project = ProjectManifest(
        name: 'Project',
        version: ProjectVersion.v9,
        maps: const [],
        tilesets: const [],
        settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
        smartTileCatalog: catalog,
      );
      final original = SpatialGroundPlan(map, project);
      for (final plan in [
        original,
        original.withLayerVisibility((id) => id != 'empty'),
        original.reordered(map.copyWith(layers: [empty, grass])),
      ]) {
        final visual = plan.resolve(0).single.visual;
        expect(visual.geometry.visualBounds.right, 2.5);
        final vertices = spatialGroundVertices(
          visual.geometry,
          height: visual.spatialHeightOffset,
          followTerrain: visual.spatialFollowTerrain,
          scene: map.spatialScene,
          flatSurface: plan.flatSurfaceFor(visual),
        );
        final heights = vertices.map((vertex) => vertex.position.y).toSet();
        expect(
          heights,
          kind == PathSurfaceKind.tallGrass ? {3.125} : {1.125, 3.125},
        );
      }
      expect(map.spatialScene!.worldHeightAt(2.5, 1.5), 1);
    });
  }
}
