import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _materials = <ProjectSmartTileMaterial>[
  ProjectSmartTileMaterial(
    id: 'grass',
    name: 'Grass',
    connectionGroupId: 'grass',
  ),
];

ProjectSmartTilePreset _preset() => const ProjectSmartTilePreset(
      id: 'terrain',
      name: 'Terrain',
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
            SmartTileCandidate(id: 'cand-0', weight: 500),
            SmartTileCandidate(id: 'cand-1', weight: 500),
          ],
        ),
      ],
    );

SmartTileLayerReadinessReport _reportFor(Map<String, int> candidateWeights) {
  final layer = SmartTileLayer(
    id: 'terrain',
    name: 'Terrain',
    presetId: 'terrain',
    usage: SmartTileUsage.terrain,
    materialPalette: const <String>['', 'grass'],
    field: const SmartTileField.cell(semanticCells: <int>[1, 1]),
    candidateWeights: candidateWeights,
  );
  final map = MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v6,
    size: const GridSize(width: 2, height: 1),
    layers: <MapLayer>[layer],
  );
  return analyzeSmartTileLayerReadiness(
    map: map,
    layer: layer,
    preset: _preset(),
    materials: _materials,
  );
}

void main() {
  test('une clé hors preset produit un avertissement, pas une erreur', () {
    final report = _reportFor(const <String, int>{
      'cand-0': 500,
      'cand-mort': 500,
    });

    final orphan = report.diagnostics.singleWhere(
      (item) => item.code == 'smart_tiles.layer.candidate_weight_orphan',
    );
    expect(orphan.severity, SmartTileDiagnosticSeverity.warning);
    expect(orphan.message, contains('cand-mort'));
    expect(orphan.message, isNot(contains('cand-0')));
    expect(report.hasErrors, isFalse);
  });

  test('aucune clé morte, aucun diagnostic', () {
    final report = _reportFor(const <String, int>{'cand-0': 500});

    expect(
      report.diagnostics.where(
        (item) => item.code == 'smart_tiles.layer.candidate_weight_orphan',
      ),
      isEmpty,
    );
  });

  test('la surcharge orpheline ne bloque pas la résolution du calque', () {
    final report = _reportFor(const <String, int>{'cand-mort': 500});

    expect(report.unresolvedCellCount, 0);
  });
}
