import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('prepares catalog materials once for a whole layer', () {
    final materials = [
      _CountedMaterial(
        const ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'grass',
        ),
      ),
      _CountedMaterial(
        const ProjectSmartTileMaterial(
          id: 'unused',
          name: 'Unused',
          connectionGroupId: 'unused',
        ),
      ),
    ];
    final layer = SmartTileLayer(
      id: 'terrain',
      name: 'Terrain',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: const ['', 'grass'],
      field: SmartTileField.cell(
        semanticCells: List.generate(16, (i) => i.isEven ? 1 : 0),
      ),
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v8,
      size: const GridSize(width: 4, height: 4),
      layers: [layer],
    );
    const preset = ProjectSmartTilePreset(
      id: 'terrain',
      name: 'Terrain',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: ['grass'],
      rules: [
        SmartTileRule(
          id: 'grass',
          centerMatch: SmartTileSlotMatch.material('grass'),
          candidates: [SmartTileCandidate(id: 'grass')],
        ),
      ],
    );
    final report = analyzeSmartTileLayerReadiness(
      map: map,
      layer: layer,
      preset: preset,
      materials: materials,
    );

    expect(report.hasErrors, false);
    expect(report.unassignedCellCount, 8);
    expect(report.unresolvedCellCount, 0);
    for (final material in materials) {
      expect(material.idReads, lessThanOrEqualTo(2));
    }
  });
}

class _CountedMaterial implements ProjectSmartTileMaterial {
  _CountedMaterial(this.value);

  final ProjectSmartTileMaterial value;
  int idReads = 0;

  @override
  String get id {
    idReads++;
    return value.id;
  }

  @override
  String get connectionGroupId => value.connectionGroupId;

  @override
  bool get isEmpty => value.isEmpty;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
