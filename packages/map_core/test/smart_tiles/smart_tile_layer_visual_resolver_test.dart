import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const atlas = ProjectSmartTileAtlas(
    id: 'atlas',
    name: 'Atlas',
    tilesetId: 'tiles',
    columns: 2,
    rows: 1,
  );
  const materials = <ProjectSmartTileMaterial>[
    ProjectSmartTileMaterial(
      id: 'dirt',
      name: 'Dirt',
      connectionGroupId: 'dirt',
    ),
    ProjectSmartTileMaterial(
      id: 'grass',
      name: 'Grass',
      connectionGroupId: 'grass',
    ),
  ];

  test('native Wang edge lattice participates in rule resolution', () {
    const preset = ProjectSmartTilePreset(
      id: 'wang',
      name: 'Wang',
      usage: SmartTileUsage.path,
      topology: SmartTileTopology.wangEdge4,
      defaultMaterialId: 'dirt',
      allowedMaterialIds: <String>['dirt', 'grass'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'fallback',
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'fallback',
              parts: <SmartTileVisualPart>[
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
        SmartTileRule(
          id: 'grass_north',
          signature: SmartTileSignature(
            northEdge: SmartTileSlotMatch.material('grass'),
          ),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'grass_north',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 1,
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
    const layer = SmartTileLayer(
      id: 'path',
      name: 'Path',
      presetId: 'wang',
      usage: SmartTileUsage.path,
      materialPalette: <String>['', 'dirt', 'grass'],
      materialCells: <int>[1],
      horizontalEdges: <int>[2, 0],
      verticalEdges: <int>[0, 0],
      corners: <int>[0, 0, 0, 0],
    );
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v4,
      size: GridSize(width: 1, height: 1),
      layers: <MapLayer>[layer],
    );

    final visuals = resolveSmartTileLayerVisuals(
      map: map,
      layer: layer,
      catalog: ProjectSmartTileCatalog(
        atlases: const <ProjectSmartTileAtlas>[atlas],
        materials: materials,
        presets: const <ProjectSmartTilePreset>[preset],
      ),
      pass: SmartTileVisualPass.background,
    );

    expect(visuals, hasLength(1));
    expect(visuals.single.ruleId, 'grass_north');
    expect(visuals.single.sourceRect.x, 32);
  });

  test('splits multi-part visuals into stable background and foreground passes',
      () {
    const preset = ProjectSmartTilePreset(
      id: 'forest',
      name: 'Forest',
      usage: SmartTileUsage.forestSurface,
      topology: SmartTileTopology.cardinal4,
      defaultMaterialId: 'grass',
      allowedMaterialIds: <String>['grass'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'any',
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'forest',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 0,
                      row: 0,
                    ),
                  ),
                  channel: SmartTileRenderChannel.ground,
                ),
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 1,
                      row: 0,
                    ),
                  ),
                  channel: SmartTileRenderChannel.canopy,
                  drawOrder: 2,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    const layer = SmartTileLayer(
      id: 'forest',
      name: 'Forest',
      presetId: 'forest',
      usage: SmartTileUsage.forestSurface,
      materialPalette: <String>['', 'grass'],
      materialCells: <int>[1],
      horizontalEdges: <int>[0, 0],
      verticalEdges: <int>[0, 0],
      corners: <int>[0, 0, 0, 0],
    );
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v4,
      size: GridSize(width: 1, height: 1),
      layers: <MapLayer>[layer],
    );
    final catalog = ProjectSmartTileCatalog(
      atlases: const <ProjectSmartTileAtlas>[atlas],
      materials: materials,
      presets: const <ProjectSmartTilePreset>[preset],
    );

    final background = resolveSmartTileLayerVisuals(
      map: map,
      layer: layer,
      catalog: catalog,
      pass: SmartTileVisualPass.background,
    );
    final foreground = resolveSmartTileLayerVisuals(
      map: map,
      layer: layer,
      catalog: catalog,
      pass: SmartTileVisualPass.foreground,
    );

    expect(background.single.channel, SmartTileRenderChannel.ground);
    expect(foreground.single.channel, SmartTileRenderChannel.canopy);
  });

  test('large-map resolution is bounded to the requested viewport', () {
    const width = 128;
    const height = 128;
    const preset = ProjectSmartTilePreset(
      id: 'large-terrain',
      name: 'Large terrain',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.cardinal4,
      defaultMaterialId: 'grass',
      allowedMaterialIds: <String>['grass'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'any',
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'ground',
              parts: <SmartTileVisualPart>[
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
    final layer = SmartTileLayer(
      id: 'large-terrain',
      name: 'Large terrain',
      presetId: preset.id,
      usage: SmartTileUsage.terrain,
      materialPalette: const <String>['', 'grass'],
      materialCells: List<int>.filled(width * height, 1),
      horizontalEdges: List<int>.filled(width * (height + 1), 0),
      verticalEdges: List<int>.filled((width + 1) * height, 0),
      corners: List<int>.filled((width + 1) * (height + 1), 0),
    );
    final map = MapData(
      id: 'large-map',
      name: 'Large map',
      version: ProjectVersion.v4,
      size: const GridSize(width: width, height: height),
      layers: <MapLayer>[layer],
    );

    final visuals = resolveSmartTileLayerVisuals(
      map: map,
      layer: layer,
      catalog: ProjectSmartTileCatalog(
        atlases: const <ProjectSmartTileAtlas>[atlas],
        materials: materials,
        presets: const <ProjectSmartTilePreset>[preset],
      ),
      pass: SmartTileVisualPass.background,
      startX: 37,
      startY: 41,
      endX: 43,
      endY: 46,
    );

    expect(visuals, hasLength(30));
    expect(visuals.map((visual) => visual.cellX),
        everyElement(inInclusiveRange(37, 42)));
    expect(visuals.map((visual) => visual.cellY),
        everyElement(inInclusiveRange(41, 45)));
  });
}
