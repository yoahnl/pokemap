import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tile test bench', () {
    test('generates exactly one case per canonical Blob 47 signature', () {
      final scenarios = generateSmartTileTemplateScenarios(
        preset: _preset(
          topology: SmartTileTopology.blob8,
          template: SmartTileTemplateHint.blob47,
        ),
        materialId: 'grass',
      );

      expect(scenarios, hasLength(47));
      expect(
        scenarios.map((item) => item.mask).toSet(),
        smartTileCanonicalMasks(SmartTileTemplateHint.blob47).toSet(),
      );
    });

    test('complete Edge 16 resolves every generated scenario', () {
      final preset = _preset(
        topology: SmartTileTopology.cardinal4,
        template: SmartTileTemplateHint.edge16,
        rules: <SmartTileRule>[
          for (var mask = 0; mask < 16; mask++) _rule(mask),
        ],
      );

      final results = runSmartTileTemplateBench(
        preset: preset,
        materials: _materials,
        materialId: 'grass',
        mapId: 'bench',
        layerId: 'edge',
      );

      expect(results, hasLength(16));
      expect(
        results.every(
          (item) =>
              item.resolution.status == SmartTileResolutionStatus.resolved &&
              item.resolution.ruleId == smartTileCanonicalRuleId(item.mask),
        ),
        isTrue,
      );
    });

    test('manual grid delegates cell resolution to the production resolver',
        () {
      final preset = _preset(
        topology: SmartTileTopology.cardinal4,
        template: SmartTileTemplateHint.edge16,
        rules: <SmartTileRule>[
          for (var mask = 0; mask < 16; mask++) _rule(mask),
        ],
      );
      final grid = SmartTileTestGrid.empty(width: 3, height: 3)
          .paint(x: 1, y: 1, materialId: 'grass')
          .paint(x: 1, y: 0, materialId: 'grass')
          .paint(x: 2, y: 1, materialId: 'grass');

      final fromBench = grid.resolveAt(
        x: 1,
        y: 1,
        preset: preset,
        materials: _materials,
        projectSeed: 42,
        layerSeed: 7,
        mapId: '',
        layerId: '',
      );
      final direct = resolveSmartTile(
        preset: preset,
        materials: _materials,
        neighborhood: SmartTileNeighborhood.fromGrid(
          width: 3,
          height: 3,
          x: 1,
          y: 1,
          materialAt: grid.materialAt,
        ),
        x: 1,
        y: 1,
        projectSeed: 42,
        layerSeed: 7,
      );

      expect(fromBench.ruleId, smartTileCanonicalRuleId(0x03));
      expect(fromBench.ruleId, direct.ruleId);
      expect(fromBench.candidate, direct.candidate);
      expect(fromBench.deterministicHash, direct.deterministicHash);
    });
  });
}

const _materials = <ProjectSmartTileMaterial>[
  ProjectSmartTileMaterial(
    id: 'grass',
    name: 'Grass',
    connectionGroupId: 'grass',
  ),
];

ProjectSmartTilePreset _preset({
  required SmartTileTopology topology,
  required SmartTileTemplateHint template,
  List<SmartTileRule> rules = const <SmartTileRule>[],
}) {
  return ProjectSmartTilePreset(
    id: 'preset',
    name: 'Preset',
    usage: SmartTileUsage.path,
    topology: topology,
    templateHint: template,
    defaultMaterialId: 'grass',
    allowedMaterialIds: const <String>['grass'],
    rules: rules,
  );
}

SmartTileRule _rule(int mask) => SmartTileRule(
      id: smartTileCanonicalRuleId(mask),
      signature: smartTileSignatureForMask(
        mask,
        topology: SmartTileTopology.cardinal4,
      ),
      candidates: const <SmartTileCandidate>[
        SmartTileCandidate(
          id: 'candidate',
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
    );
