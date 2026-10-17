import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('ordering fixtures use a valid native model catalog', () {
    expect(
      validateProjectSmartTileCatalog(
        catalog: _catalog(),
        spatial: true,
        projectTilesetIds: const [],
        projectModelIds: const ['bank', 'foam', 'cap'],
        projectModelAnimationIndices: const {
          'foam': {0},
        },
      ).where((diagnostic) => diagnostic.isError),
      isEmpty,
    );
  });
  test(
    'removing empty pattern ownership preserves ordered model projection',
    () {
      final catalog = _catalog();
      final layer = _layer([
        const SmartTilePatternStroke(
          id: 'empty-padding',
          patternId: 'empty-padding',
          cells: [
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
            GridPos(x: 2, y: 0),
            GridPos(x: 0, y: 1),
            GridPos(x: 1, y: 1),
            GridPos(x: 2, y: 1),
          ],
        ),
        const SmartTilePatternStroke(
          id: 'edges',
          patternId: 'edge',
          cells: [
            GridPos(x: 2, y: 1),
            GridPos(x: 0, y: 0),
            GridPos(x: 1, y: 0),
          ],
        ),
      ]);
      final sparse = eraseSmartTilePatternCells(
        layer,
        mapSize: const GridSize(width: 3, height: 2),
        cells: layer.patternStrokes.first.cells.where(
          (cell) => cell != const GridPos(x: 0, y: 0),
        ),
        strokeIds: ['empty-padding'],
      );
      final paddedProjection = resolveSpatialSmartTileModelProjection(
        map: _map([layer]),
        catalog: catalog,
      );
      final sparseProjection = resolveSpatialSmartTileModelProjection(
        map: _map([sparse]),
        catalog: catalog,
      );
      expect(
        sparseProjection.instances.toSet(),
        paddedProjection.instances.toSet(),
      );
      expect(
        sparseProjection.groundReplacements,
        paddedProjection.groundReplacements,
      );
      expect(sparseProjection.cellOrigins, paddedProjection.cellOrigins);
      expect(sparseProjection.instances, paddedProjection.instances);
    },
  );

  test('nonoverlapping stroke order does not reorder projected models', () {
    const north = SmartTilePatternStroke(
      id: 'north',
      patternId: 'edge',
      cells: [GridPos(x: 0, y: 0)],
    );
    const south = SmartTilePatternStroke(
      id: 'south',
      patternId: 'edge',
      cells: [GridPos(x: 2, y: 1)],
    );
    final catalog = _catalog();
    final first = resolveSpatialSmartTileInstances(
      map: _map([
        _layer([north, south]),
      ]),
      catalog: catalog,
    );
    final reversed = resolveSpatialSmartTileInstances(
      map: _map([
        _layer([south, north]),
      ]),
      catalog: catalog,
    );
    expect(reversed, first);
  });

  test('last overlapping stroke still owns the cell', () {
    const first = SmartTilePatternStroke(
      id: 'edge',
      patternId: 'edge',
      cells: [GridPos(x: 0, y: 0)],
    );
    const second = SmartTilePatternStroke(
      id: 'cap',
      patternId: 'cap',
      cells: [GridPos(x: 0, y: 0)],
    );
    final catalog = _catalog();
    expect(
      resolveSpatialSmartTileInstances(
        map: _map([
          _layer([first, second]),
        ]),
        catalog: catalog,
      ).single.modelId,
      'cap',
    );
    expect(
      resolveSpatialSmartTileInstances(
        map: _map([
          _layer([second, first]),
        ]),
        catalog: catalog,
      ).map((v) => v.modelId),
      ['bank', 'foam'],
    );
  });

  test('projection preserves layer order and parts within each cell', () {
    const stroke = SmartTilePatternStroke(
      id: 'edge',
      patternId: 'edge',
      cells: [GridPos(x: 0, y: 0)],
    );
    final map = _map([
      _layer([stroke]),
      _layer([stroke]).copyWith(id: 'upper', name: 'Upper'),
    ]);
    final instances = resolveSpatialSmartTileInstances(
      map: map,
      catalog: _catalog(),
    );
    expect(instances.map((v) => v.modelId), ['bank', 'foam', 'bank', 'foam']);
    expect(instances.map((v) => v.id).toSet(), hasLength(4));
    final projected = projectSpatialSmartTileModels(
      map: map,
      catalog: _catalog(),
    );
    expect(
      projectSpatialSmartTileModels(map: projected, catalog: _catalog()),
      projected,
    );
    expect(projected.layers, map.layers);
  });
}

SmartTileLayer _layer(List<SmartTilePatternStroke> strokes) => SmartTileLayer(
  id: 'shore',
  name: 'Shore',
  presetId: 'shore',
  usage: SmartTileUsage.path,
  materialPalette: const ['', 'water'],
  field: const SmartTileField.cell(semanticCells: [0, 0, 0, 0, 0, 0]),
  patternStrokes: strokes,
);

MapData _map(List<MapLayer> layers) => MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v9,
  size: const GridSize(width: 3, height: 2),
  layers: layers,
  spatialScene: MapSpatialScene(
    width: 3,
    depth: 2,
    levelHeight: .25,
    heightLevels: const [1, 1, 1, 2, 2, 2],
  ),
);

ProjectSmartTileCatalog _catalog() => ProjectSmartTileCatalog(
  materials: const [
    ProjectSmartTileMaterial(
      id: 'water',
      name: 'Water',
      connectionGroupId: 'water',
    ),
  ],
  presets: const [
    ProjectSmartTilePreset(
      id: 'shore',
      name: 'Shore',
      usage: SmartTileUsage.path,
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
      defaultMaterialId: 'water',
      allowedMaterialIds: ['water'],
      rules: [
        SmartTileRule(
          id: 'base',
          centerMatch: SmartTileSlotMatch.material('water'),
          candidates: [
            SmartTileCandidate(
              id: 'base',
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.model3d(modelId: 'bank'),
                ),
              ],
            ),
          ],
        ),
      ],
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: SmartTileTransformPolicy(),
    ),
  ],
  patterns: const [
    ProjectSmartTilePattern(
      id: 'empty-padding',
      name: 'Empty padding',
      usage: SmartTileUsage.path,
      width: 3,
      height: 2,
      cells: [
        SmartTilePatternCell(
          x: 0,
          y: 0,
          parts: [
            SmartTileVisualPart(
              source: SmartTileVisualSource.model3d(modelId: 'cap'),
            ),
          ],
        ),
      ],
    ),
    ProjectSmartTilePattern(
      id: 'edge',
      name: 'Edge',
      usage: SmartTileUsage.path,
      width: 1,
      height: 1,
      cells: [
        SmartTilePatternCell(
          x: 0,
          y: 0,
          parts: [
            SmartTileVisualPart(
              source: SmartTileVisualSource.model3d(
                modelId: 'bank',
                replacesGround: true,
              ),
            ),
            SmartTileVisualPart(
              source: SmartTileVisualSource.model3d(
                modelId: 'foam',
                offsetY: .125,
                animationIndex: 0,
              ),
            ),
          ],
        ),
      ],
    ),
    ProjectSmartTilePattern(
      id: 'cap',
      name: 'Cap',
      usage: SmartTileUsage.path,
      width: 1,
      height: 1,
      cells: [
        SmartTilePatternCell(
          x: 0,
          y: 0,
          parts: [
            SmartTileVisualPart(
              source: SmartTileVisualSource.model3d(modelId: 'cap'),
            ),
          ],
        ),
      ],
    ),
  ],
);
