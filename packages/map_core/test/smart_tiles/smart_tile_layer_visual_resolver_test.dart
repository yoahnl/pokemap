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
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'dirt',
      allowedMaterialIds: <String>['dirt', 'grass'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'fallback',
          centerMatch: SmartTileSlotMatch.any(),
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
          centerMatch: SmartTileSlotMatch.any(),
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
      field: SmartTileField.edge(
        semanticCells: <int>[1],
        horizontalEdges: <int>[2, 0],
        verticalEdges: <int>[0, 0],
      ),
    );
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
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

  for (final scenario in <({
    SmartTileTopology topology,
    SmartTileTemplateHint template,
    Set<int> masks,
  })>[
    (
      topology: SmartTileTopology.blob8,
      template: SmartTileTemplateHint.blob47,
      masks: <int>{0},
    ),
    (
      topology: SmartTileTopology.wangEdge4,
      template: SmartTileTemplateHint.edge16,
      masks: <int>{0x0f, 0x0b, 0x07, 0x0e, 0x0d},
    ),
    (
      topology: SmartTileTopology.wangCorner4,
      template: SmartTileTemplateHint.corner16,
      masks: <int>{0xf0, 0xb0, 0x30, 0x70, 0x60, 0xe0, 0xc0, 0xd0, 0x90},
    ),
    (
      topology: SmartTileTopology.wang8,
      template: SmartTileTemplateHint.mixed256,
      masks: <int>{0xff, 0xbf, 0x3b, 0x7f, 0x67, 0xef, 0xce, 0xdf, 0x9d},
    ),
  ]) {
    test(
        'paint gestures resolve isolated, line, L and rectangle '
        '${scenario.topology.name} visuals', () {
      final preset = ProjectSmartTilePreset(
        id: 'gesture',
        name: 'Gesture',
        usage: SmartTileUsage.path,
        topology: scenario.topology,
        templateHint: scenario.template,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: const SmartTileTransformPolicy(),
        defaultMaterialId: 'dirt',
        allowedMaterialIds: const <String>['dirt', 'grass'],
        rules: <SmartTileRule>[
          for (final mask in smartTileCanonicalMasks(scenario.template))
            SmartTileRule(
              id: 'mask_$mask',
              centerMatch: const SmartTileSlotMatch.any(),
              signature: smartTileSignatureForMask(
                mask,
                topology: scenario.topology,
              ),
              candidates: const <SmartTileCandidate>[
                SmartTileCandidate(
                  id: 'frame',
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
      final source = SmartTileLayer(
        id: 'path',
        name: 'Path',
        presetId: preset.id,
        usage: SmartTileUsage.path,
        materialPalette: const <String>['', 'dirt', 'grass'],
        field: _emptyField(scenario.topology),
      );
      const size = GridSize(width: 3, height: 3);
      final painted = applySmartTileMaterialGesture(
        source,
        mapSize: size,
        cells: const <GridPos>[GridPos(x: 1, y: 1)],
        materialId: 'grass',
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v6,
        size: size,
        layers: <MapLayer>[painted],
      );
      final catalog = ProjectSmartTileCatalog(
        atlases: const <ProjectSmartTileAtlas>[atlas],
        materials: materials,
        presets: <ProjectSmartTilePreset>[preset],
      );

      final visuals = resolveSmartTileLayerVisuals(
        map: map,
        layer: painted,
        catalog: catalog,
        pass: SmartTileVisualPass.background,
      );
      expect(
        visuals.map((visual) => visual.ruleId).toSet(),
        <String>{for (final mask in scenario.masks) 'mask_$mask'},
      );
      expect(visuals, hasLength(scenario.masks.length));

      final erased = applySmartTileMaterialGesture(
        painted,
        mapSize: size,
        cells: const <GridPos>[GridPos(x: 1, y: 1)],
        materialId: null,
      );
      final erasedMap = map.copyWith(layers: <MapLayer>[erased]);
      expect(
        resolveSmartTileLayerVisuals(
          map: erasedMap,
          layer: erased,
          catalog: catalog,
          pass: SmartTileVisualPass.background,
        ),
        isEmpty,
      );

      const largerSize = GridSize(width: 5, height: 5);
      for (final shape in <List<GridPos>>[
        const <GridPos>[
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
        ],
        const <GridPos>[
          GridPos(x: 1, y: 1),
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
        ],
        const <GridPos>[
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
        ],
      ]) {
        final shapedSource = source.copyWith(
          field: _emptyField(
            scenario.topology,
            width: largerSize.width,
            height: largerSize.height,
          ),
        );
        final shaped = applySmartTileMaterialGesture(
          shapedSource,
          mapSize: largerSize,
          cells: shape,
          materialId: 'grass',
        );
        final shapedMap = map.copyWith(
          size: largerSize,
          layers: <MapLayer>[shaped],
        );
        final shapedVisuals = resolveSmartTileLayerVisuals(
          map: shapedMap,
          layer: shaped,
          catalog: catalog,
          pass: SmartTileVisualPass.background,
        );

        expect(
          shapedVisuals
              .map((visual) => (x: visual.cellX, y: visual.cellY))
              .toSet(),
          _expectedVisualCells(
            painted: shape,
            topology: scenario.topology,
            size: largerSize,
          ),
        );

        final cleared = applySmartTileMaterialGesture(
          shaped,
          mapSize: largerSize,
          cells: shape,
          materialId: null,
        );
        expect(
          resolveSmartTileLayerVisuals(
            map: shapedMap.copyWith(layers: <MapLayer>[cleared]),
            layer: cleared,
            catalog: catalog,
            pass: SmartTileVisualPass.background,
          ),
          isEmpty,
        );
      }
    });
  }

  test('splits multi-part visuals into stable background and foreground passes',
      () {
    const preset = ProjectSmartTilePreset(
      id: 'forest',
      name: 'Forest',
      usage: SmartTileUsage.forestSurface,
      topology: SmartTileTopology.cardinal4,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: SmartTileTransformPolicy(allowQuarterTurns: true),
      defaultMaterialId: 'grass',
      allowedMaterialIds: <String>['grass'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'any',
          centerMatch: SmartTileSlotMatch.any(),
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
                  transform: SmartTileSpriteTransform(quarterTurns: 1),
                  footprintWidth: 2,
                  footprintHeight: 3,
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
      field: SmartTileField.cell(semanticCells: <int>[1]),
    );
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
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
    expect(background.single.footprintWidth, 2);
    expect(background.single.footprintHeight, 3);
    expect(
      background.single.transform,
      const SmartTileSpriteTransform(quarterTurns: 1),
    );
    expect(background.single.geometry.destinationRect.width, 2);
    expect(background.single.geometry.destinationRect.height, 3);
    expect(background.single.geometry.visualBounds.width, 3);
    expect(background.single.geometry.visualBounds.height, 2);
    expect(foreground.single.channel, SmartTileRenderChannel.canopy);
  });

  test('composes the generated rule transform with the visual transform', () {
    const preset = ProjectSmartTilePreset(
      id: 'transformed-wang',
      name: 'Transformed Wang',
      usage: SmartTileUsage.path,
      topology: SmartTileTopology.wangEdge4,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
      ),
      transformPolicy: SmartTileTransformPolicy(
        allowQuarterTurns: true,
      ),
      defaultMaterialId: 'dirt',
      allowedMaterialIds: <String>['dirt', 'grass'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'north-grass',
          centerMatch: SmartTileSlotMatch.material('dirt'),
          signature: SmartTileSignature(
            northEdge: SmartTileSlotMatch.material('grass'),
          ),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'north-grass',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 0,
                      row: 0,
                    ),
                  ),
                  transform: SmartTileSpriteTransform(quarterTurns: 2),
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
      presetId: 'transformed-wang',
      usage: SmartTileUsage.path,
      materialPalette: <String>['', 'dirt', 'grass'],
      field: SmartTileField.edge(
        semanticCells: <int>[1],
        horizontalEdges: <int>[0, 0],
        verticalEdges: <int>[0, 2],
      ),
    );
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 1, height: 1),
      layers: <MapLayer>[layer],
    );

    final visual = resolveSmartTileLayerVisuals(
      map: map,
      layer: layer,
      catalog: ProjectSmartTileCatalog(
        atlases: const <ProjectSmartTileAtlas>[atlas],
        materials: materials,
        presets: const <ProjectSmartTilePreset>[preset],
      ),
      pass: SmartTileVisualPass.background,
    ).single;

    expect(
      visual.transform,
      const SmartTileSpriteTransform(quarterTurns: 3),
    );
    expect(visual.geometry.transform, visual.transform);
  });

  test('keeps the same transform when an animation advances frames', () {
    const preset = ProjectSmartTilePreset(
      id: 'animated',
      name: 'Animated',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
      ),
      transformPolicy: SmartTileTransformPolicy(allowQuarterTurns: true),
      defaultMaterialId: 'grass',
      allowedMaterialIds: <String>['grass'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'grass',
          centerMatch: SmartTileSlotMatch.material('grass'),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'animated',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.animation(
                    animationId: 'breeze',
                  ),
                  transform: SmartTileSpriteTransform(quarterTurns: 1),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    const layer = SmartTileLayer(
      id: 'animated',
      name: 'Animated',
      presetId: 'animated',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'grass'],
      field: SmartTileField.cell(semanticCells: <int>[1]),
    );
    const map = MapData(
      id: 'animated-map',
      name: 'Animated map',
      version: ProjectVersion.v6,
      size: GridSize(width: 1, height: 1),
      layers: <MapLayer>[layer],
    );
    final catalog = ProjectSmartTileCatalog(
      atlases: const <ProjectSmartTileAtlas>[atlas],
      materials: materials,
      animations: const <ProjectSmartTileAnimation>[
        ProjectSmartTileAnimation(
          id: 'breeze',
          name: 'Breeze',
          frames: <ProjectSmartTileAnimationFrame>[
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(
                atlasId: 'atlas',
                column: 0,
                row: 0,
              ),
              durationMs: 100,
            ),
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(
                atlasId: 'atlas',
                column: 1,
                row: 0,
              ),
              durationMs: 100,
            ),
          ],
        ),
      ],
      presets: const <ProjectSmartTilePreset>[preset],
    );

    final first = resolveSmartTileLayerVisuals(
      map: map,
      layer: layer,
      catalog: catalog,
      pass: SmartTileVisualPass.background,
      elapsedMs: 0,
    ).single;
    final second = resolveSmartTileLayerVisuals(
      map: map,
      layer: layer,
      catalog: catalog,
      pass: SmartTileVisualPass.background,
      elapsedMs: 100,
    ).single;

    expect(first.sourceRect.x, 0);
    expect(second.sourceRect.x, 32);
    expect(first.transform, const SmartTileSpriteTransform(quarterTurns: 1));
    expect(second.transform, first.transform);
    expect(second.geometry.visualBounds, first.geometry.visualBounds);
  });

  test('large-map resolution is bounded to the requested viewport', () {
    const width = 128;
    const height = 128;
    const preset = ProjectSmartTilePreset(
      id: 'large-terrain',
      name: 'Large terrain',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.cardinal4,
      coveragePolicy: SmartTileCoveragePolicy.complete,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: <String>['grass'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'any',
          centerMatch: SmartTileSlotMatch.any(),
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
      field: SmartTileField.cell(
        semanticCells: List<int>.filled(width * height, 1),
      ),
    );
    final map = MapData(
      id: 'large-map',
      name: 'Large map',
      version: ProjectVersion.v6,
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

  test('keeps an owner outside the viewport when its visual bounds intersect',
      () {
    const preset = ProjectSmartTilePreset(
      id: 'overhang',
      name: 'Overhang',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: <String>['grass'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'ground',
          centerMatch: SmartTileSlotMatch.material('grass'),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'wide',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 0,
                      row: 0,
                    ),
                  ),
                  footprintWidth: 6,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    const layer = SmartTileLayer(
      id: 'overhang',
      name: 'Overhang',
      presetId: 'overhang',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'grass'],
      field: SmartTileField.cell(
        semanticCells: <int>[0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    );
    const map = MapData(
      id: 'overhang-map',
      name: 'Overhang map',
      version: ProjectVersion.v6,
      size: GridSize(width: 10, height: 1),
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
      destinationCellWidth: 32,
      destinationCellHeight: 32,
      sourceCellWidth: 32,
      sourceCellHeight: 32,
      startX: 6,
      endX: 7,
      startY: 0,
      endY: 1,
    );

    expect(visuals, hasLength(1));
    expect(visuals.single.cellX, 1);
    expect(visuals.single.geometry.visualBounds.right, 224);
  });
}

SmartTileField _emptyField(
  SmartTileTopology topology, {
  int width = 3,
  int height = 3,
}) =>
    switch (topology) {
      SmartTileTopology.blob8 => SmartTileField.cell(
          semanticCells: List<int>.filled(width * height, 0),
        ),
      SmartTileTopology.wangEdge4 => SmartTileField.edge(
          semanticCells: List<int>.filled(width * height, 0),
          horizontalEdges: List<int>.filled(width * (height + 1), 0),
          verticalEdges: List<int>.filled((width + 1) * height, 0),
        ),
      SmartTileTopology.wangCorner4 => SmartTileField.corner(
          semanticCells: List<int>.filled(width * height, 0),
          corners: List<int>.filled((width + 1) * (height + 1), 0),
        ),
      SmartTileTopology.wang8 => SmartTileField.mixed(
          semanticCells: List<int>.filled(width * height, 0),
          horizontalEdges: List<int>.filled(width * (height + 1), 0),
          verticalEdges: List<int>.filled((width + 1) * height, 0),
          corners: List<int>.filled((width + 1) * (height + 1), 0),
        ),
      _ => throw ArgumentError.value(topology, 'topology'),
    };

Set<({int x, int y})> _expectedVisualCells({
  required Iterable<GridPos> painted,
  required SmartTileTopology topology,
  required GridSize size,
}) {
  final offsets = switch (topology) {
    SmartTileTopology.blob8 => const <({int x, int y})>[(x: 0, y: 0)],
    SmartTileTopology.wangEdge4 => const <({int x, int y})>[
        (x: 0, y: 0),
        (x: 0, y: -1),
        (x: 1, y: 0),
        (x: 0, y: 1),
        (x: -1, y: 0),
      ],
    SmartTileTopology.wangCorner4 ||
    SmartTileTopology.wang8 =>
      const <({int x, int y})>[
        (x: -1, y: -1),
        (x: 0, y: -1),
        (x: 1, y: -1),
        (x: -1, y: 0),
        (x: 0, y: 0),
        (x: 1, y: 0),
        (x: -1, y: 1),
        (x: 0, y: 1),
        (x: 1, y: 1),
      ],
    _ => throw ArgumentError.value(topology, 'topology'),
  };

  return <({int x, int y})>{
    for (final cell in painted)
      for (final offset in offsets)
        if (cell.x + offset.x >= 0 &&
            cell.x + offset.x < size.width &&
            cell.y + offset.y >= 0 &&
            cell.y + offset.y < size.height)
          (x: cell.x + offset.x, y: cell.y + offset.y),
  };
}
