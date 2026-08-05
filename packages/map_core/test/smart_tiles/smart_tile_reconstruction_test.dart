import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('assessSmartTileLayerReconstruction', () {
    test('reconstructs a literal Wang edge tile and preserves its visual', () {
      final assessment = assessSmartTileLayerReconstruction(
        map: _map(
          palette: const <TileLayerPaletteEntry>[
            TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 1),
          ],
          cells: const <int>[1],
        ),
        sourceLayerId: 'literal',
        manifest: _manifest(preset: _edgePreset),
        presetId: _edgePreset.id,
        targetLayerId: 'native',
        targetLayerName: 'Native path',
      );

      expect(assessment.sourceCellCount, 1);
      expect(assessment.reconstructedCellCount, 1);
      expect(assessment.unresolvedCellIndices, isEmpty);
      expect(assessment.ambiguousCellIndices, isEmpty);
      expect(assessment.conflictCount, 0);
      expect(assessment.coverage, 1);
      expect(assessment.exactVisualMatchCount, 1);
      expect(assessment.visualMismatchCellIndices, isEmpty);
      expect(assessment.assessmentChecksum, startsWith('sha256:'));

      final layer = assessment.proposedLayer!;
      expect(layer.id, 'native');
      expect(layer.name, 'Native path');
      expect(layer.isVisible, isFalse);
      expect(layer.presetId, _edgePreset.id);
      expect(layer.materialPalette, <String>['', 'dirt', 'grass']);
      expect(layer.field, isA<SmartTileEdgeField>());
      final field = layer.field as SmartTileEdgeField;
      expect(field.semanticCells, <int>[1]);
      expect(field.horizontalEdges, <int>[2, 0]);
      expect(field.verticalEdges, <int>[0, 0]);
      expect(layer.properties['reconstruction.sourceLayerId'], 'literal');
      expect(layer.properties['reconstruction.coverage'], '1.000000');
    });

    test('reports ambiguity instead of choosing between semantic signatures',
        () {
      final ambiguous = _edgePreset.copyWith(
        rules: <SmartTileRule>[
          ..._edgePreset.rules,
          _edgePreset.rules.single.copyWith(
            id: 'south_grass',
            signature: const SmartTileSignature(
              southEdge: SmartTileSlotMatch.material('grass'),
            ),
          ),
        ],
      );

      final assessment = assessSmartTileLayerReconstruction(
        map: _map(
          palette: const <TileLayerPaletteEntry>[
            TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 1),
          ],
          cells: const <int>[1],
        ),
        sourceLayerId: 'literal',
        manifest: _manifest(preset: ambiguous),
        presetId: ambiguous.id,
        targetLayerId: 'native',
        targetLayerName: 'Native path',
      );

      expect(assessment.reconstructedCellCount, 0);
      expect(assessment.ambiguousCellIndices, <int>[0]);
      expect(assessment.coverage, 0);
      expect(assessment.proposedLayer, isNull);
    });

    test('recognizes a transformed literal tile', () {
      const quarterTurn = SmartTileSpriteTransform(quarterTurns: 1);
      final transformedPreset = _edgePreset.copyWith(
        transformPolicy: const SmartTileTransformPolicy(
          allowQuarterTurns: true,
        ),
      );
      final assessment = assessSmartTileLayerReconstruction(
        map: _map(
          palette: const <TileLayerPaletteEntry>[
            TileLayerPaletteEntry(
              tilesetId: 'tiles',
              localTileId: 1,
              transform: quarterTurn,
            ),
          ],
          cells: const <int>[1],
        ),
        sourceLayerId: 'literal',
        manifest: _manifest(preset: transformedPreset),
        presetId: transformedPreset.id,
        targetLayerId: 'native',
        targetLayerName: 'Native path',
      );

      expect(assessment.reconstructedCellCount, 1);
      final field = assessment.proposedLayer!.field as SmartTileEdgeField;
      expect(field.horizontalEdges, <int>[0, 0]);
      expect(field.verticalEdges, <int>[0, 2]);
      expect(assessment.exactVisualMatchCount, 1);
    });

    test('recognizes the owning local tile of an imported animation', () {
      const animatedPreset = ProjectSmartTilePreset(
        id: 'animated',
        name: 'Animated',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'dirt',
        allowedMaterialIds: <String>['dirt'],
        rules: <SmartTileRule>[
          SmartTileRule(
            id: 'animated_rule',
            centerMatch: SmartTileSlotMatch.any(),
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'animated_candidate',
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.animation(
                      animationId: 'water_animation',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final assessment = assessSmartTileLayerReconstruction(
        map: _map(
          palette: const <TileLayerPaletteEntry>[
            TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 7),
          ],
          cells: const <int>[1],
        ),
        sourceLayerId: 'literal',
        manifest: _manifest(
          preset: animatedPreset,
          animations: const <ProjectSmartTileAnimation>[
            ProjectSmartTileAnimation(
              id: 'water_animation',
              name: 'Water',
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
                  durationMs: 120,
                ),
              ],
            ),
          ],
          tileAnimations: const <ProjectRegularAtlasTileAnimation>[
            ProjectRegularAtlasTileAnimation(
              tileId: 7,
              frames: <ProjectImageCollectionAnimationFrame>[
                ProjectImageCollectionAnimationFrame(
                  tileId: 0,
                  durationMs: 100,
                ),
                ProjectImageCollectionAnimationFrame(
                  tileId: 1,
                  durationMs: 120,
                ),
              ],
            ),
          ],
        ),
        presetId: animatedPreset.id,
        targetLayerId: 'native',
        targetLayerName: 'Native terrain',
      );

      expect(assessment.reconstructedCellCount, 1);
      expect(assessment.exactVisualMatchCount, 1);
    });

    test('never reconstructs a technical data layer as visual terrain', () {
      final map = _map(
        palette: const <TileLayerPaletteEntry>[
          TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 1),
        ],
        cells: const <int>[1],
      );
      final source = map.layers.single as TileLayer;

      expect(
        () => assessSmartTileLayerReconstruction(
          map: map.copyWith(
            layers: <MapLayer>[
              source.copyWith(purpose: MapLayerPurpose.data),
            ],
          ),
          sourceLayerId: 'literal',
          manifest: _manifest(preset: _edgePreset),
          presetId: _edgePreset.id,
          targetLayerId: 'native',
          targetLayerName: 'Native path',
        ),
        throwsA(
          isA<SmartTileReconstructionException>().having(
            (error) => error.code,
            'code',
            'smart_tile.reconstruction_source_not_visual',
          ),
        ),
      );
    });
  });
}

const _edgePreset = ProjectSmartTilePreset(
  id: 'edge',
  name: 'Edge',
  usage: SmartTileUsage.path,
  topology: SmartTileTopology.wangEdge4,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.explicit,
  ),
  transformPolicy: SmartTileTransformPolicy(),
  defaultMaterialId: 'dirt',
  allowedMaterialIds: <String>['dirt', 'grass'],
  rules: <SmartTileRule>[
    SmartTileRule(
      id: 'north_grass',
      centerMatch: SmartTileSlotMatch.any(),
      signature: SmartTileSignature(
        northEdge: SmartTileSlotMatch.material('grass'),
      ),
      candidates: <SmartTileCandidate>[
        SmartTileCandidate(
          id: 'north_grass_candidate',
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

MapData _map({
  required List<TileLayerPaletteEntry> palette,
  required List<int> cells,
}) =>
    MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: const GridSize(width: 1, height: 1),
      layers: <MapLayer>[
        MapLayer.tile(
          id: 'literal',
          name: 'Literal',
          palette: palette,
          cells: cells,
        ),
      ],
    );

ProjectManifest _manifest({
  required ProjectSmartTilePreset preset,
  List<ProjectSmartTileAnimation> animations =
      const <ProjectSmartTileAnimation>[],
  List<ProjectRegularAtlasTileAnimation> tileAnimations =
      const <ProjectRegularAtlasTileAnimation>[],
}) =>
    ProjectManifest(
      name: 'Project',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
      ],
      tilesets: <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'tiles',
          name: 'Tiles',
          relativePath: 'tiles.png',
          source: ProjectTilesetSource.regularAtlas(
            assetId: 'asset',
            pixelWidth: 64,
            pixelHeight: 32,
            tileWidth: 32,
            tileHeight: 32,
            tileAnimations: tileAnimations,
          ),
        ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: const <ProjectSmartTileAtlas>[
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'tiles',
            columns: 2,
            rows: 1,
          ),
        ],
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'dirt',
            name: 'Dirt',
            connectionGroupId: 'ground',
          ),
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'ground',
          ),
        ],
        animations: animations,
        presets: <ProjectSmartTilePreset>[preset],
      ),
    );
