import 'package:map_core/map_core.dart';

BorderTransformPolicy borderSpatialTransforms() => BorderTransformPolicy(
  allowFlipX: false,
  allowedQuarterTurns: const [0, 1, 2, 3],
);

({ProjectManifest project, MapData map}) spatialBorderFixture({
  Model3dVector3? anchor,
  bool straightOnly = false,
  bool includeCorner = true,
}) {
  final defaults = BorderGenerationParams(
    irregularityPermille: 0,
    detailDensityPermille: 0,
    variationPermille: 1000,
    maxOverlapPx: 0,
    gapTolerancePx: 0,
    depthRows: 1,
  );
  final roles = [
    BorderPrimitiveRole.lineCap,
    BorderPrimitiveRole.lineStraight,
    if (includeCorner) BorderPrimitiveRole.lineCorner,
  ];
  final draft = BorderBlueprintDraftDefinition(
    name: 'Fence',
    previewSeed: BorderSignedInt64.fromInt(17),
    template: BorderBlueprintTemplate.connectedLine,
    straightOnly: straightOnly,
    primitives: [
      for (final role in roles)
        BorderPrimitiveDraft(
          id: role.name,
          sourceModelId: 'unit',
          role: role,
          weight: 1,
          transforms: borderSpatialTransforms(),
          anchorWorld: anchor,
        ),
    ],
    defaults: defaults,
    sortOrder: 0,
  );
  final published = BorderBlueprintPublishedDefinition(
    name: draft.name,
    previewSeed: draft.previewSeed,
    template: draft.template,
    straightOnly: draft.straightOnly,
    primitives: [
      for (final primitive in draft.primitives)
        BorderPublishedPrimitive(
          id: primitive.id,
          sourceModelId: 'unit',
          role: primitive.role,
          weight: primitive.weight,
          transforms: primitive.transforms,
          anchorWorld: anchor,
        ),
    ],
    defaults: defaults,
    sortOrder: 0,
  );
  final model = ProjectModel3dEntry(
    id: 'unit',
    name: 'Unit fence',
    sourceAssetId: 'unit-source',
    relativePath: 'assets/models3d/unit.glb',
    inspection: Model3dInspection(
      bounds: Model3dBounds(
        min: Model3dVector3(x: -.2, y: 0, z: -.2),
        max: Model3dVector3(x: .2, y: 1, z: .2),
      ),
      meshCount: 1,
      triangleCount: 1,
    ),
  );
  final project = ProjectManifest(
    name: 'Native fence',
    version: ProjectVersion.v9,
    maps: const [
      ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
    ],
    tilesets: const [],
    models3d: [model],
    settings: ProjectSettings(
      dimension: ProjectDimension.threeD,
      spatialCamera: SpatialCameraProfile(),
    ),
    borderCatalog: ProjectBorderCatalog(
      formatVersion: 5,
      records: [
        BorderBlueprintRecord(
          id: 'fence',
          draft: BorderBlueprintDraft(baseRevision: 1, definition: draft),
          latestPublished: BorderBlueprintRevision(
            revision: 1,
            definition: published,
          ),
        ),
      ],
    ),
  );
  final feature = BorderFeature(
    id: 'fence',
    name: 'Fence',
    blueprintId: 'fence',
    seed: BorderSignedInt64.fromInt(17),
    geometry: BorderStrokeGeometry(
      strokes: [
        BorderStroke(
          id: 'line',
          points: const [
            GridPos(x: 1, y: 1),
            GridPos(x: 2, y: 1),
            GridPos(x: 3, y: 1),
            GridPos(x: 3, y: 2),
            GridPos(x: 3, y: 3),
          ],
          closed: false,
        ),
      ],
    ),
    overrides: const [],
    keepOutRegions: const [],
  );
  final map = MapData(
    version: ProjectVersion.v9,
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 6, height: 6),
    spatialScene: MapSpatialScene(
      width: 6,
      depth: 6,
      heightLevels: List.filled(36, 1),
    ),
    layers: [
      MapLayer.border(
        id: 'border',
        name: 'Fence',
        content: BorderLayerContent(features: [feature]),
      ),
    ],
  );
  return (project: project, map: map);
}

({ProjectManifest project, MapData map}) surfaceFixture() {
  final own = spatialBorderFixture();
  final raw = encodeBorderBlueprintRecordJson(
    own.project.borderCatalog.records.single,
    formatVersion: 5,
  );
  for (final key in ['draft', 'latestPublished']) {
    for (final primitive
        in ((raw[key] as Map)['definition'] as Map)['primitives'] as List) {
      primitive['groundSurfaces'] = [
        for (final height in [0.0, .5])
          {
            'sourceSmartTilePresetId': 'grass-terrain',
            'materialId': 'grass',
            'height': height,
            'footprints': [
              [
                {'x': -.1, 'z': -.1},
                {'x': .1, 'z': -.1},
                {'x': -.1, 'z': .1},
              ],
            ],
          },
      ];
    }
  }
  final catalog = ProjectSmartTileCatalog(
    atlases: const [
      ProjectSmartTileAtlas(
        id: 'grass-atlas',
        name: 'Grass',
        tilesetId: 'grass',
        cellWidth: 16,
        cellHeight: 16,
        columns: 1,
        rows: 1,
      ),
    ],
    materials: const [
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'grass',
      ),
    ],
    presets: [
      ProjectSmartTilePreset(
        id: 'grass-terrain',
        name: 'Grass',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
        templateHint: SmartTileTemplateHint.simple,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: ['grass'],
        rules: [
          SmartTileRule(
            id: 'grass',
            centerMatch: SmartTileSlotMatch.material('grass'),
            candidates: [
              SmartTileCandidate(
                id: 'base',
                parts: [
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'grass-atlas',
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
  return (
    project: own.project.copyWith(
      smartTileCatalog: catalog,
      tilesets: const [
        ProjectTilesetEntry(
          id: 'grass',
          name: 'Grass',
          relativePath: 'assets/tilesets/grass.png',
        ),
      ],
      borderCatalog: ProjectBorderCatalog(
        formatVersion: 9,
        records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 9)],
      ),
    ),
    map: own.map,
  );
}
