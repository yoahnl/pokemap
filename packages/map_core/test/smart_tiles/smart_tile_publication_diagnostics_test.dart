import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tile publication diagnostics', () {
    test('a complete Edge 16 preset is publishable', () {
      final catalog = _catalog(_edgePreset());

      final diagnostics = validateProjectSmartTileCatalog(
        catalog: catalog,
        projectTilesetIds: const <String>['tileset'],
      );

      expect(diagnostics.where((item) => item.isError), isEmpty);
      expect(
        diagnostics.map((item) => item.code),
        isNot(contains('smart_tiles.coverage.incomplete')),
      );
    });

    test('a complete ERW Corner 12 preset is publishable', () {
      final preset = _corner12Preset();

      expect(_diagnostics(preset).where((item) => item.isError), isEmpty);
      expect(
        _diagnostics(preset).map((item) => item.code),
        isNot(contains('smart_tiles.coverage.incomplete')),
      );

      final incomplete = preset.copyWith(
        rules: preset.rules.where((rule) => rule.id != 'mask_10').toList(),
      );
      final diagnostic = _diagnostics(incomplete).singleWhere(
        (item) => item.code == 'smart_tiles.coverage.incomplete',
      );

      expect(diagnostic.severity, SmartTileDiagnosticSeverity.error);
      expect(diagnostic.missingMasks, <int>[0x10]);
    });

    test('incomplete drafts warn while incomplete published presets fail', () {
      final draft = _edgePreset(
        status: SmartTilePresetStatus.draft,
        rules: <SmartTileRule>[_rule(0)],
      );
      final published = draft.copyWith(status: SmartTilePresetStatus.published);

      final draftDiagnostic = _diagnostics(draft).singleWhere(
        (item) => item.code == 'smart_tiles.coverage.incomplete',
      );
      final publishedDiagnostic = _diagnostics(published).singleWhere(
        (item) => item.code == 'smart_tiles.coverage.incomplete',
      );

      expect(draftDiagnostic.severity, SmartTileDiagnosticSeverity.warning);
      expect(publishedDiagnostic.severity, SmartTileDiagnosticSeverity.error);
      expect(publishedDiagnostic.missingMasks, hasLength(15));
    });

    test('reports ambiguous signatures with rule navigation metadata', () {
      final preset = _edgePreset(
        status: SmartTilePresetStatus.published,
        rules: <SmartTileRule>[
          _rule(0, id: 'first'),
          _rule(0, id: 'second'),
          for (var mask = 1; mask < 16; mask++) _rule(mask),
        ],
      );

      final diagnostic = _diagnostics(preset).singleWhere(
        (item) => item.code == 'smart_tiles.rules.ambiguous',
      );

      expect(diagnostic.presetId, 'edge');
      expect(diagnostic.ruleId, 'second');
      expect(diagnostic.mask, 0);
    });

    test('blocks empty visual candidates and missing fallback rules', () {
      final rules = <SmartTileRule>[
        SmartTileRule(
          id: 'empty-parts',
          signature: smartTileSignatureForMask(
            0,
            topology: SmartTileTopology.cardinal4,
          ),
          candidates: const <SmartTileCandidate>[
            SmartTileCandidate(id: 'empty', parts: <SmartTileVisualPart>[]),
          ],
        ),
        for (var mask = 1; mask < 16; mask++) _rule(mask),
      ];
      final preset = _edgePreset(
        status: SmartTilePresetStatus.published,
        rules: rules,
        fallbackRuleId: 'missing',
      );

      expect(
        _diagnostics(preset).map((item) => item.code),
        containsAll(<String>[
          'smart_tiles.visual.parts_missing',
          'smart_tiles.reference.fallback_rule_missing',
        ]),
      );
    });
  });
}

List<SmartTileDiagnostic> _diagnostics(ProjectSmartTilePreset preset) {
  return validateProjectSmartTileCatalog(
    catalog: _catalog(preset),
    projectTilesetIds: const <String>['tileset'],
  );
}

ProjectSmartTileCatalog _catalog(ProjectSmartTilePreset preset) {
  return ProjectSmartTileCatalog(
    atlases: const <ProjectSmartTileAtlas>[
      ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Atlas',
        tilesetId: 'tileset',
        columns: 4,
        rows: 4,
      ),
    ],
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'grass',
      ),
    ],
    presets: <ProjectSmartTilePreset>[preset],
  );
}

ProjectSmartTilePreset _edgePreset({
  SmartTilePresetStatus status = SmartTilePresetStatus.published,
  List<SmartTileRule>? rules,
  String? fallbackRuleId,
}) {
  return ProjectSmartTilePreset(
    id: 'edge',
    name: 'Edge',
    usage: SmartTileUsage.terrain,
    topology: SmartTileTopology.cardinal4,
    templateHint: SmartTileTemplateHint.edge16,
    status: status,
    defaultMaterialId: 'grass',
    allowedMaterialIds: const <String>['grass'],
    fallbackRuleId: fallbackRuleId,
    rules: rules ??
        <SmartTileRule>[
          for (var mask = 0; mask < 16; mask++) _rule(mask),
        ],
  );
}

ProjectSmartTilePreset _corner12Preset() {
  return ProjectSmartTilePreset(
    id: 'erw-corner-12',
    name: 'ERW Corner 12',
    usage: SmartTileUsage.path,
    topology: SmartTileTopology.wangCorner4,
    templateHint: SmartTileTemplateHint.corner12,
    status: SmartTilePresetStatus.published,
    defaultMaterialId: 'grass',
    allowedMaterialIds: const <String>['grass'],
    rules: <SmartTileRule>[
      for (final mask
          in smartTileCanonicalMasks(SmartTileTemplateHint.corner12))
        _rule(mask, topology: SmartTileTopology.wangCorner4),
    ],
  );
}

SmartTileRule _rule(
  int mask, {
  String? id,
  SmartTileTopology topology = SmartTileTopology.cardinal4,
}) {
  return SmartTileRule(
    id: id ?? smartTileCanonicalRuleId(mask),
    signature: smartTileSignatureForMask(
      mask,
      topology: topology,
    ),
    candidates: const <SmartTileCandidate>[
      SmartTileCandidate(
        id: 'visual',
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
}
