import 'package:map_core/map_core.dart';

({MapData map, ProjectManifest project}) spatialGrassFixture({
  SmartTileAnimationActivation activation =
      SmartTileAnimationActivation.onEnter,
  List<SmartTilePatternStroke> strokes = const [],
  List<ProjectSmartTilePattern> patterns = const [],
}) {
  final map = MapData(
    version: ProjectVersion.v9,
    id: 'field',
    name: 'Field',
    size: const GridSize(width: 8, height: 8),
    layers: [
      SmartTileLayer(
        id: 'grass',
        name: 'Grass',
        presetId: 'grass-path',
        usage: SmartTileUsage.path,
        animationActivation: activation,
        materialPalette: const ['', 'grass-material'],
        patternStrokes: strokes,
        field: SmartTileField.cell(
          semanticCells: [
            for (var i = 0; i < 64; i++) i == 44 || i == 45 ? 1 : 0,
          ],
        ),
      ),
    ],
    spatialScene: MapSpatialScene(
      width: 8,
      depth: 8,
      navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4)),
    ),
  );
  final project = ProjectManifest(
    version: ProjectVersion.v9,
    name: 'Grass',
    settings: const ProjectSettings(dimension: ProjectDimension.threeD),
    tilesets: const [],
    maps: const [
      ProjectMapEntry(
        id: 'field',
        name: 'Field',
        relativePath: 'maps/field.json',
      ),
    ],
    models3d: [
      ProjectModel3dEntry(
        id: 'grass-model',
        name: 'Grass',
        sourceAssetId: 'grass-source',
        relativePath: 'assets/models3d/grass-model.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3.zero,
            max: Model3dVector3(x: 1, y: 1, z: 1),
          ),
          meshCount: 1,
          triangleCount: 2,
          animations: [
            Model3dAnimation(index: 0, name: 'Step', durationSeconds: .4),
          ],
        ),
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      materials: const [
        ProjectSmartTileMaterial(
          id: 'grass-material',
          name: 'Grass',
          connectionGroupId: 'grass',
        ),
      ],
      patterns: patterns,
      presets: [
        ProjectSmartTilePreset(
          id: 'grass-path',
          name: 'Grass',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.uniform,
          templateHint: SmartTileTemplateHint.simple,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: const SmartTileTransformPolicy(),
          defaultMaterialId: 'grass-material',
          allowedMaterialIds: const ['grass-material'],
          rules: [
            SmartTileRule(
              id: 'grass-rule',
              centerMatch: const SmartTileSlotMatch.material('grass-material'),
              candidates: const [
                SmartTileCandidate(
                  id: 'grass',
                  parts: [
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.model3d(
                        modelId: 'grass-model',
                        animationIndex: 0,
                        offsetX: .75,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
  return (map: map, project: project);
}

({MapData map, ProjectManifest project}) spatialRasterGrassFixture({
  SmartTileAnimationActivation activation =
      SmartTileAnimationActivation.onEnter,
}) {
  final fixture = spatialGrassFixture(activation: activation);
  final catalog = fixture.project.smartTileCatalog;
  final preset = catalog.presets.single;
  final rule = preset.rules.single;
  return (
    map: fixture.map,
    project: fixture.project.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: catalog.materials,
        atlases: const [
          ProjectSmartTileAtlas(
            id: 'raster-atlas',
            name: 'Raster',
            tilesetId: 'raster-tiles',
            columns: 2,
            rows: 1,
          ),
        ],
        animations: const [
          ProjectSmartTileAnimation(
            id: 'raster-reaction',
            name: 'Reaction',
            loop: SmartTileAnimationLoop.once,
            frames: [
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'raster-atlas',
                  column: 0,
                  row: 0,
                ),
                durationMs: 100,
              ),
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'raster-atlas',
                  column: 1,
                  row: 0,
                ),
                durationMs: 100,
              ),
            ],
          ),
        ],
        presets: [
          preset.copyWith(rules: [
            rule.copyWith(candidates: const [
              SmartTileCandidate(
                id: 'raster',
                parts: [
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.animation(
                      animationId: 'raster-reaction',
                    ),
                  ),
                ],
              ),
            ]),
          ]),
        ],
      ),
    ),
  );
}
