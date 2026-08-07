import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _atlas = ProjectSmartTileAtlas(
  id: 'atlas',
  name: 'Atlas',
  tilesetId: 'tiles',
  columns: 2,
  rows: 1,
);

const _materials = <ProjectSmartTileMaterial>[
  ProjectSmartTileMaterial(
    id: 'grass',
    name: 'Grass',
    connectionGroupId: 'grass',
  ),
];

const _preset = ProjectSmartTilePreset(
  id: 'uniform',
  name: 'Uniform',
  usage: SmartTileUsage.terrain,
  topology: SmartTileTopology.uniform,
  status: SmartTilePresetStatus.published,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.explicit,
  ),
  transformPolicy: SmartTileTransformPolicy(),
  defaultMaterialId: 'grass',
  allowedMaterialIds: <String>['grass'],
  rules: <SmartTileRule>[
    SmartTileRule(
      id: 'fill',
      centerMatch: SmartTileSlotMatch.material('grass'),
      candidates: <SmartTileCandidate>[
        SmartTileCandidate(
          id: 'cand-0',
          weight: 500,
          parts: <SmartTileVisualPart>[
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
              ),
            ),
          ],
        ),
        SmartTileCandidate(
          id: 'cand-1',
          weight: 500,
          parts: <SmartTileVisualPart>[
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(atlasId: 'atlas', column: 1, row: 0),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

List<SmartTileLayerVisual> _visualsFor({
  required Map<String, int> candidateWeights,
}) {
  final layer = SmartTileLayer(
    id: 'terrain',
    name: 'Terrain',
    presetId: 'uniform',
    usage: SmartTileUsage.terrain,
    materialPalette: const <String>['', 'grass'],
    field: SmartTileField.cell(
      semanticCells: List<int>.filled(64, 1),
    ),
    candidateWeights: candidateWeights,
  );
  final map = MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v6,
    size: const GridSize(width: 8, height: 8),
    layers: <MapLayer>[layer],
  );
  return resolveSmartTileLayerVisuals(
    map: map,
    layer: layer,
    catalog: ProjectSmartTileCatalog(
      atlases: const <ProjectSmartTileAtlas>[_atlas],
      materials: _materials,
      presets: const <ProjectSmartTilePreset>[_preset],
    ),
    pass: SmartTileVisualPass.background,
  );
}

void main() {
  test('les visuels respectent la surcharge du calque', () {
    final without = _visualsFor(candidateWeights: const <String, int>{});
    final with0 = _visualsFor(candidateWeights: const <String, int>{
      'cand-1': 0,
    });

    expect(
      without.map((visual) => visual.candidateId).toSet(),
      containsAll(<String>['cand-0', 'cand-1']),
    );
    expect(
      with0.map((visual) => visual.candidateId).toSet(),
      isNot(contains('cand-1')),
    );
    expect(with0, hasLength(without.length));
  });
}
