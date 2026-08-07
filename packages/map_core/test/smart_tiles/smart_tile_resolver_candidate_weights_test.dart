import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _materials = <ProjectSmartTileMaterial>[
  ProjectSmartTileMaterial(
    id: 'grass',
    name: 'Grass',
    connectionGroupId: 'grass',
  ),
];

ProjectSmartTilePreset _preset() => ProjectSmartTilePreset(
      id: 'test',
      name: 'Test',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: const SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: const <String>['grass'],
      rules: const <SmartTileRule>[
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

/// Résout 400 cellules et rend l'identifiant du candidat retenu par cellule.
List<String> _resolveAll(Map<String, int> candidateWeights) {
  final resolver = PreparedSmartTileResolver(
    preset: _preset(),
    materials: _materials,
    mapId: 'map',
    layerId: 'layer',
    candidateWeights: candidateWeights,
  );
  const context = SmartTileCellContext(centerMaterialId: 'grass');
  return <String>[
    for (var y = 0; y < 20; y += 1)
      for (var x = 0; x < 20; x += 1)
        resolver.resolve(context: context, x: x, y: y).candidate!.id,
  ];
}

void main() {
  group('PreparedSmartTileResolver.candidateWeights', () {
    test('une table vide reproduit le comportement actuel', () {
      final overridden = _resolveAll(const <String, int>{});
      const context = SmartTileCellContext(centerMaterialId: 'grass');
      final compat = <String>[
        for (var y = 0; y < 20; y += 1)
          for (var x = 0; x < 20; x += 1)
            resolveSmartTile(
              preset: _preset(),
              materials: _materials,
              context: context,
              mapId: 'map',
              layerId: 'layer',
              x: x,
              y: y,
            ).candidate!.id,
      ];
      expect(overridden, compat);
    });

    test('un poids nul exclut le candidat du tirage', () {
      final ids = _resolveAll(const <String, int>{'cand-1': 0});
      expect(ids, isNot(contains('cand-1')));
      expect(ids, contains('cand-0'));
    });

    test('un poids écrasant fait presque toujours sortir le même candidat',
        () {
      final ids = _resolveAll(const <String, int>{'cand-0': 999, 'cand-1': 1});
      final share = ids.where((id) => id == 'cand-0').length / ids.length;
      expect(share, greaterThan(0.9));
    });

    test('une clé inconnue est ignorée sans erreur', () {
      expect(
        () => _resolveAll(const <String, int>{'cand-inexistant': 500}),
        returnsNormally,
      );
    });
  });
}
