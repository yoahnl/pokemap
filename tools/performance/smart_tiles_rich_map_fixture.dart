import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'benchmark_support.dart';

const List<int> smartTilesRichMapExtents = <int>[128, 256, 512, 1024];

final class SmartTilesRichMapWorkCounts {
  const SmartTilesRichMapWorkCounts({
    required this.totalCells,
    required this.smartLayerCount,
    required this.literalLayerCount,
    required this.patternStrokeCellCount,
    required this.tileObjectCount,
    required this.placedElementCount,
    required this.collisionCellCount,
  });

  final int totalCells;
  final int smartLayerCount;
  final int literalLayerCount;
  final int patternStrokeCellCount;
  final int tileObjectCount;
  final int placedElementCount;
  final int collisionCellCount;

  Map<String, Object?> toJson() => <String, Object?>{
    'totalCells': totalCells,
    'smartLayerCount': smartLayerCount,
    'literalLayerCount': literalLayerCount,
    'patternStrokeCellCount': patternStrokeCellCount,
    'tileObjectCount': tileObjectCount,
    'placedElementCount': placedElementCount,
    'collisionCellCount': collisionCellCount,
  };
}

final class SmartTilesRichMapFixture {
  SmartTilesRichMapFixture({
    required this.extent,
    required this.manifest,
    required this.map,
    required this.workCounts,
    required Set<SmartTileRenderChannel> renderChannels,
  }) : renderChannels = UnmodifiableSetView(renderChannels),
       structuralChecksum = stableFingerprint(<String, Object?>{
         'manifest': manifest.toJson(),
         'map': map.toJson(),
       });

  final int extent;
  final ProjectManifest manifest;
  final MapData map;
  final SmartTilesRichMapWorkCounts workCounts;
  final Set<SmartTileRenderChannel> renderChannels;
  final String structuralChecksum;
}

SmartTilesRichMapFixture generateSmartTilesRichMapFixture({
  required int extent,
}) {
  if (!smartTilesRichMapExtents.contains(extent)) {
    throw FormatException(
      'extent must be one of ${smartTilesRichMapExtents.join(', ')}',
    );
  }
  final cellCount = extent * extent;
  final terrainCells = List<int>.generate(cellCount, (index) {
    final x = index % extent;
    final y = index ~/ extent;
    if ((x ~/ 24 + y ~/ 24) % 7 == 0) return 3;
    return ((x ~/ 12) + (y ~/ 12)).isEven ? 1 : 2;
  }, growable: false);
  final pathCells = List<int>.generate(cellCount, (index) {
    final x = index % extent;
    final y = index ~/ extent;
    return x % 32 == 16 || y % 32 == 16 ? 1 : 0;
  }, growable: false);
  final forestCells = List<int>.generate(cellCount, (index) {
    final x = index % extent;
    final y = index ~/ extent;
    final noise = (x * 37 + y * 61 + (x * y) % 97) % 17;
    return noise < 5 && pathCells[index] == 0 ? 1 : 0;
  }, growable: false);
  final literalCells = List<int>.generate(
    cellCount,
    (index) => 1 + ((index + index ~/ extent) % 3),
    growable: false,
  );
  var collisionCount = 0;
  final collisionCells = List<bool>.generate(cellCount, (index) {
    final x = index % extent;
    final y = index ~/ extent;
    final collision = (x + y * 3) % 41 == 0 || forestCells[index] == 1;
    if (collision) collisionCount += 1;
    return collision;
  }, growable: false);
  final patternCells = <GridPos>[
    for (var coordinate = 8; coordinate < extent; coordinate += 24)
      GridPos(x: coordinate, y: (coordinate * 3) % extent),
  ];
  final tileObjects = <MapPlacedTile>[
    for (var y = 12; y < extent; y += 32)
      for (var x = 12; x < extent; x += 32)
        MapPlacedTile(
          id: 'tile-object-$x-$y',
          name: 'Rich prop $x,$y',
          className: 'Decoration',
          tile: TileLayerPaletteEntry(
            tilesetId: 'rich-props',
            localTileId: (x ~/ 32 + y ~/ 32) % 4,
            transform: SmartTileSpriteTransform(
              quarterTurns: (x ~/ 32 + y ~/ 32) % 4,
              flipX: (x + y).isEven,
            ),
          ),
          anchorX: x + 0.25,
          anchorY: y + 0.75,
          width: 1.5,
          height: 1,
          opacity: 0.85,
        ),
  ];
  final placedElements = <MapPlacedElement>[
    for (var y = 24; y < extent; y += 64)
      for (var x = 24; x < extent; x += 64)
        MapPlacedElement(
          id: 'placed-element-$x-$y',
          layerId: 'literal-ground',
          elementId: 'rich-animated-prop',
          pos: GridPos(x: x, y: y),
          quarterTurns: (x ~/ 64 + y ~/ 64) % 4,
          applyCollision: true,
        ),
  ];
  final mapId = 'smart-rich-${extent}x$extent';
  final map = MapData(
    id: mapId,
    name: 'Smart Tiles rich ${extent}x$extent',
    version: ProjectVersion.v6,
    size: GridSize(width: extent, height: extent),
    layers: <MapLayer>[
      SmartTileLayer(
        id: 'terrain',
        name: 'Dense terrain',
        presetId: 'rich-terrain',
        usage: SmartTileUsage.terrain,
        materialPalette: const <String>['', 'grass', 'dirt', 'water'],
        field: SmartTileField.cell(semanticCells: terrainCells),
        layerSeed: 101,
      ),
      SmartTileLayer(
        id: 'paths',
        name: 'Connected paths',
        presetId: 'rich-path',
        usage: SmartTileUsage.path,
        materialPalette: const <String>['', 'path'],
        field: SmartTileField.cell(semanticCells: pathCells),
        patternStrokes: <SmartTilePatternStroke>[
          SmartTilePatternStroke(
            id: 'path-pattern-stroke',
            patternId: 'path-marker',
            cells: patternCells,
          ),
        ],
        layerSeed: 202,
      ),
      SmartTileLayer(
        id: 'forest',
        name: 'Multi-pass forest',
        presetId: 'rich-forest',
        usage: SmartTileUsage.forestSurface,
        materialPalette: const <String>['', 'forest'],
        field: SmartTileField.cell(semanticCells: forestCells),
        layerSeed: 303,
      ),
      TileLayer(
        id: 'literal-ground',
        name: 'Literal multi-tileset ground',
        palette: const <TileLayerPaletteEntry>[
          TileLayerPaletteEntry(tilesetId: 'rich-literal-a', localTileId: 0),
          TileLayerPaletteEntry(
            tilesetId: 'rich-literal-b',
            localTileId: 1,
            transform: SmartTileSpriteTransform(flipX: true),
          ),
          TileLayerPaletteEntry(
            tilesetId: 'rich-literal-b',
            localTileId: 2,
            transform: SmartTileSpriteTransform(quarterTurns: 1),
          ),
        ],
        cells: literalCells,
      ),
      CollisionLayer(
        id: 'collision',
        name: 'Rich collision',
        collisions: collisionCells,
      ),
      ObjectLayer(
        id: 'visual-props',
        name: 'Fractional visual props',
        tileObjects: tileObjects,
      ),
    ],
    placedElements: placedElements,
  );
  final catalog = _richCatalog();
  final manifest = ProjectManifest(
    name: 'Smart Tiles rich benchmark',
    version: ProjectVersion.v6,
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: mapId,
        name: map.name,
        relativePath: 'maps/$mapId.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'rich-smart',
        name: 'Rich Smart Tiles',
        relativePath: 'assets/rich-smart.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: 'rich-smart-asset',
          pixelWidth: 256,
          pixelHeight: 256,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
      ProjectTilesetEntry(
        id: 'rich-literal-a',
        name: 'Rich literal A',
        relativePath: 'assets/rich-literal-a.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: 'rich-literal-a-asset',
          pixelWidth: 128,
          pixelHeight: 128,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
      ProjectTilesetEntry(
        id: 'rich-literal-b',
        name: 'Rich literal B',
        relativePath: 'assets/rich-literal-b.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: 'rich-literal-b-asset',
          pixelWidth: 128,
          pixelHeight: 128,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
      ProjectTilesetEntry(
        id: 'rich-props',
        name: 'Rich props',
        relativePath: 'assets/rich-props.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: 'rich-props-asset',
          pixelWidth: 128,
          pixelHeight: 128,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'benchmark', name: 'Benchmark'),
    ],
    elements: const <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'rich-animated-prop',
        name: 'Rich animated prop',
        tilesetId: 'rich-props',
        categoryId: 'benchmark',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
            durationMs: 120,
          ),
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 2, y: 0, width: 2, height: 2),
            durationMs: 180,
          ),
        ],
        collisionProfile: ElementCollisionProfile(
          cells: <GridPos>[GridPos(x: 0, y: 1), GridPos(x: 1, y: 1)],
        ),
      ),
    ],
    settings: const ProjectSettings(
      tileWidth: 32,
      tileHeight: 32,
      displayScale: 1,
    ),
    smartTileCatalog: catalog,
  );
  final channels = <SmartTileRenderChannel>{
    for (final preset in catalog.presets)
      for (final rule in preset.rules)
        for (final candidate in rule.candidates)
          for (final part in candidate.parts) part.channel,
    for (final pattern in catalog.patterns)
      for (final cell in pattern.cells)
        for (final part in cell.parts) part.channel,
  };
  return SmartTilesRichMapFixture(
    extent: extent,
    manifest: manifest,
    map: map,
    renderChannels: channels,
    workCounts: SmartTilesRichMapWorkCounts(
      totalCells: cellCount,
      smartLayerCount: 3,
      literalLayerCount: 1,
      patternStrokeCellCount: patternCells.length,
      tileObjectCount: tileObjects.length,
      placedElementCount: placedElements.length,
      collisionCellCount: collisionCount,
    ),
  );
}

ProjectSmartTileCatalog _richCatalog() => ProjectSmartTileCatalog(
  atlases: <ProjectSmartTileAtlas>[
    ProjectSmartTileAtlas(
      id: 'rich-atlas',
      name: 'Rich atlas',
      tilesetId: 'rich-smart',
      columns: 8,
      rows: 8,
    ),
  ],
  materials: <ProjectSmartTileMaterial>[
    ProjectSmartTileMaterial(
      id: 'grass',
      name: 'Grass',
      connectionGroupId: 'ground',
    ),
    ProjectSmartTileMaterial(
      id: 'dirt',
      name: 'Dirt',
      connectionGroupId: 'ground',
    ),
    ProjectSmartTileMaterial(
      id: 'water',
      name: 'Water',
      connectionGroupId: 'water',
    ),
    ProjectSmartTileMaterial(
      id: 'path',
      name: 'Path',
      connectionGroupId: 'path',
    ),
    ProjectSmartTileMaterial(
      id: 'forest',
      name: 'Forest',
      connectionGroupId: 'forest',
    ),
  ],
  animations: <ProjectSmartTileAnimation>[
    ProjectSmartTileAnimation(
      id: 'global-water',
      name: 'Global water',
      sync: SmartTileAnimationSync.global,
      frames: <ProjectSmartTileAnimationFrame>[
        ProjectSmartTileAnimationFrame(
          frame: SmartTileFrameRef(atlasId: 'rich-atlas', column: 0, row: 1),
          durationMs: 160,
        ),
        ProjectSmartTileAnimationFrame(
          frame: SmartTileFrameRef(atlasId: 'rich-atlas', column: 1, row: 1),
          durationMs: 160,
        ),
      ],
    ),
    ProjectSmartTileAnimation(
      id: 'cell-leaves',
      name: 'Per-cell leaves',
      sync: SmartTileAnimationSync.perCell,
      frames: <ProjectSmartTileAnimationFrame>[
        ProjectSmartTileAnimationFrame(
          frame: SmartTileFrameRef(atlasId: 'rich-atlas', column: 2, row: 1),
          durationMs: 140,
        ),
        ProjectSmartTileAnimationFrame(
          frame: SmartTileFrameRef(atlasId: 'rich-atlas', column: 3, row: 1),
          durationMs: 220,
        ),
      ],
    ),
  ],
  patterns: <ProjectSmartTilePattern>[
    ProjectSmartTilePattern(
      id: 'path-marker',
      name: 'Path marker',
      usage: SmartTileUsage.path,
      width: 2,
      height: 2,
      cells: <SmartTilePatternCell>[
        SmartTilePatternCell(
          x: 0,
          y: 0,
          parts: <SmartTileVisualPart>[
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'rich-atlas',
                  column: 4,
                  row: 0,
                ),
              ),
              channel: SmartTileRenderChannel.foreground,
              drawOrder: 30,
            ),
          ],
        ),
      ],
    ),
  ],
  presets: <ProjectSmartTilePreset>[
    ProjectSmartTilePreset(
      id: 'rich-terrain',
      name: 'Rich terrain',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.blob8,
      coveragePolicy: SmartTileCoveragePolicy.complete,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
        requiredScenarios: <SmartTileCoverageScenario>[
          SmartTileCoverageScenario(
            id: 'terrain-grass',
            centerMaterialId: 'grass',
          ),
        ],
      ),
      transformPolicy: SmartTileTransformPolicy(
        allowHFlip: true,
        allowVFlip: true,
        allowQuarterTurns: true,
      ),
      defaultMaterialId: 'grass',
      allowedMaterialIds: <String>['grass', 'dirt', 'water'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'terrain-any',
          centerMatch: SmartTileSlotMatch.any(),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'terrain-frame',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.animation(
                    animationId: 'global-water',
                  ),
                  channel: SmartTileRenderChannel.ground,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    ProjectSmartTilePreset(
      id: 'rich-path',
      name: 'Rich path',
      usage: SmartTileUsage.path,
      topology: SmartTileTopology.cardinal4,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
        requiredScenarios: <SmartTileCoverageScenario>[
          SmartTileCoverageScenario(
            id: 'path-center',
            centerMaterialId: 'path',
          ),
        ],
      ),
      transformPolicy: SmartTileTransformPolicy(
        allowHFlip: true,
        allowQuarterTurns: true,
      ),
      defaultMaterialId: 'path',
      allowedMaterialIds: <String>['path'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'path',
          centerMatch: SmartTileSlotMatch.material('path'),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'path-frame',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'rich-atlas',
                      column: 1,
                      row: 0,
                    ),
                  ),
                  channel: SmartTileRenderChannel.ground,
                ),
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'rich-atlas',
                      column: 6,
                      row: 0,
                    ),
                  ),
                  channel: SmartTileRenderChannel.actorOcclusion,
                  drawOrder: 20,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    ProjectSmartTilePreset(
      id: 'rich-forest',
      name: 'Rich forest',
      usage: SmartTileUsage.forestSurface,
      topology: SmartTileTopology.cardinal4,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
        requiredScenarios: <SmartTileCoverageScenario>[
          SmartTileCoverageScenario(
            id: 'forest-center',
            centerMaterialId: 'forest',
          ),
        ],
      ),
      transformPolicy: SmartTileTransformPolicy(allowHFlip: true),
      defaultMaterialId: 'forest',
      allowedMaterialIds: <String>['forest'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'forest',
          centerMatch: SmartTileSlotMatch.material('forest'),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'forest-multipass',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'rich-atlas',
                      column: 2,
                      row: 0,
                    ),
                  ),
                  channel: SmartTileRenderChannel.ground,
                ),
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'rich-atlas',
                      column: 3,
                      row: 0,
                    ),
                  ),
                  channel: SmartTileRenderChannel.understory,
                  drawOrder: 10,
                ),
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'rich-atlas',
                      column: 4,
                      row: 0,
                    ),
                  ),
                  channel: SmartTileRenderChannel.shadow,
                  offsetX: 6,
                  offsetY: 4,
                  drawOrder: 15,
                ),
                SmartTileVisualPart(
                  source: SmartTileVisualSource.animation(
                    animationId: 'cell-leaves',
                  ),
                  channel: SmartTileRenderChannel.canopy,
                  footprintWidth: 2,
                  footprintHeight: 3,
                  anchorX: 1,
                  anchorY: 2,
                  offsetY: -12,
                  drawOrder: 20,
                ),
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'rich-atlas',
                      column: 5,
                      row: 0,
                    ),
                  ),
                  channel: SmartTileRenderChannel.foreground,
                  offsetY: -8,
                  drawOrder: 40,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
